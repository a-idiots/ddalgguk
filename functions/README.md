# 딸꾹 결제 검증 백엔드

인앱 결제 영수증을 **서버에서** 검증하고, 그 결과만을 PRO 권한의 근거로 삼는다.
클라이언트는 `entitlements/{uid}` 문서를 읽기만 하고, 이 문서는 이 백엔드만 쓴다.

## 왜 필요한가

이전 구조에서는 앱이 스토어에 직접 물어보고 스스로 `SharedPreferences`에
`pro_enabled = true`를 기록했다. 그래서

- 앱 데이터를 조작하면 결제 없이 PRO를 켤 수 있었고,
- 환불·해지·만료를 서버에서 반영할 방법이 없었고,
- 기기 간 동기화가 불가능했다.

## 엔드포인트

세 개 모두 `asia-northeast3`에 배포된다 (`src/config.ts`의 `REGION`).
리전을 바꾸면 클라이언트의 `kFunctionsRegion`도 함께 바꿔야 한다.

### `POST /verifyPurchase`

앱이 결제·복원 직후 호출한다. `Authorization: Bearer <Firebase ID 토큰>` 필요.

```jsonc
// 요청
{
  "platform": "ios",            // 'ios' | 'android'
  "productId": "lifetime_v1",
  "verificationData": "eyJ..."  // iOS: StoreKit 2 JWS / Android: purchaseToken
}

// 200
{
  "isPro": true,
  "activeProductId": "lifetime_v1",
  "activeKind": "lifetime",     // 'lifetime' | 'subscription'
  "activeSource": "app_store",
  "expiresAtMs": null,          // 구독이면 만료 시각(epoch ms)
  "authoritative": true         // App Store Server API로 현재 상태까지 확인했는지
}
```

상태 코드가 클라이언트 동작을 결정한다. **4xx는 이 영수증으로는 영구히 실패**
(대기열에서 제거), **5xx는 일시적 실패**(대기열에 남겨 재시도).

| 코드 | 의미 |
| --- | --- |
| 401 `unauthenticated` | ID 토큰 없음/무효 |
| 403 `untrusted_payload` | 서명 검증 실패, 다른 앱의 영수증 |
| 409 `unsupported_product` | PRO를 주지 않는 상품 |
| 422 `malformed_transaction` | 영수증 내용이 앞뒤가 안 맞음 |
| 503 `store_unavailable` / `server_misconfigured` | 지금은 확인 불가 → 재시도 |

### `POST /syncEntitlement`

앱 시작·복귀 시 호출한다. 저장된 결제를 스토어에서 다시 읽어 권한을 최신화한다.
바디는 `{"force": false}` (기본). 알림 웹훅이 유실되거나 아직 등록되지 않았더라도
이 경로로 결국 정확해진다.

바깥으로 나가는 스토어 조회는 15분 창으로 스로틀링되지만, 만료 재계산은 매번 한다.

### `POST /appStoreNotifications`

App Store Server Notifications V2 수신용. 갱신·만료·환불·취소를 즉시 반영한다.

Apple은 5xx면 최대 3일간 재시도하고 2xx면 재시도하지 않는다. 그래서 "아직 처리
못 한 것"은 반드시 5xx, "의도적으로 무시한 것"은 2xx로 응답한다.

## 데이터 모델

```
entitlements/{uid}              클라이언트 읽기 전용 (firestore.rules)
  isPro, activeProductId, activeKind, activeSource, expiresAtMs
  records: { "<source>_<transactionId>": PurchaseRecord }
  updatedAt

purchaseIndex/{source_txId}     서버 전용 — 결제 → uid 역인덱스
purchaseAccountTokens/{token}   서버 전용 — appAccountToken → uid
purchaseSecrets/{uid}           서버 전용 — Google purchaseToken 보관
```

설계상 중요한 점 몇 가지:

- **결제를 `records` 맵으로 여러 건 보관한다.** 한 사용자가 연간 구독과 평생 구매를
  모두 가질 수 있고, 그때 옛 구독의 `EXPIRED` 알림이 나중의 평생 구매를 지워버리면
  안 된다. `isPro`는 항상 전체 레코드에서 다시 계산한다.
- **`signedAtMs`로 신선도를 비교한다.** 알림은 순서가 뒤바뀌어 도착한다.
  `DID_RENEW` 다음에 온 `EXPIRED`가 갱신을 되돌리면 안 되므로, 처리 시각이 아니라
  스토어가 서명한 시각을 기준으로 더 새로운 것만 반영한다.
- **`purchaseToken`은 클라이언트가 읽는 문서에 넣지 않는다.** Play Developer API에
  대한 사실상의 자격증명이라 별도 컬렉션에 둔다.
- **같은 결제가 두 계정을 동시에 살리지 않는다.** 이미 다른 uid에 연결된 결제가
  들어오면 이전 계정에서 떼어내고 새 계정으로 이전한다.
- **`isPro`는 materialized 값이라 시간이 지나면 낡는다.** 그래서 클라이언트도
  `expiresAt`을 한 번 더 확인한다 (`Entitlement.isActiveAt`).

## 설치

```bash
cd functions
npm install
npm run certs   # Apple 루트 인증서 (공개 파일, 리포에 커밋되어 있음)
```

### 1. App Store Connect API 키

App Store Connect → Users and Access → Integrations → App Store Connect API에서
**In-App Purchase** 권한이 있는 키를 만들고 `.p8`을 내려받는다.

```bash
firebase functions:secrets:set APP_STORE_KEY_ID       # 예: 2X9R4HXF34
firebase functions:secrets:set APP_STORE_ISSUER_ID    # 예: 57246542-96fe-1a63-...
firebase functions:secrets:set APP_STORE_PRIVATE_KEY  # .p8 파일 내용 전체를 붙여넣기
```

`.p8`은 절대 리포에 넣지 않는다 (`.gitignore`에 걸려 있다).

### 2. 앱의 숫자 Apple ID

```bash
cp .env.example .env.a-idiot-ddalgguk
# APPLE_APP_APPLE_ID 를 채운다 (App Store Connect → App Information → Apple ID)
```

프로덕션 서명 검증에 필수다. 없으면 검증이 503으로 실패한다 (권한을 잃지는 않는다).

### 3. 알림 URL 등록

배포 후 출력되는 `appStoreNotifications` URL을 App Store Connect →
App Information → App Store Server Notifications의 **Production**과 **Sandbox**
양쪽에 등록한다. Version 2를 선택한다.

App Store Connect의 "Test Notification" 버튼으로 확인할 수 있다. 로그에
`App Store test notification received`가 찍히면 정상.

### 4. Google Play (Android도 검증하려면)

배포된 함수의 서비스 계정(`<project-id>@appspot.gserviceaccount.com`)을
Play Console → Users and permissions에 초대하고, "View financial data, orders,
and cancellation survey responses" 권한을 준다. 별도 키 파일은 필요 없다.

## 배포

```bash
nvm use 22        # engines.node = 22
cd functions
npm run lint && npm run build && npm test
cd ..
firebase deploy --only functions,firestore:rules
```

`firebase.json`의 predeploy가 lint와 build를 다시 돌린다.

## 개발

```bash
npm run build:watch
npm test                    # node:test, 네트워크/Firestore 없이 순수 로직만
firebase emulators:start --only functions,firestore
```

에뮬레이터를 쓸 때는 앱의 `.env`에
`FUNCTIONS_BASE_URL=http://<로컬IP>:5001/<project-id>/asia-northeast3`
를 넣으면 그쪽으로 붙는다.

## Sandbox 테스트 시나리오

1. Sandbox Apple ID로 `lifetime_v1` 구매 → `entitlements/{uid}`에
   `isPro: true`, `activeKind: 'lifetime'`이 생기는지 확인.
2. 앱 삭제 후 재설치 → 실행만 해도 복원되어 PRO가 유지되는지 확인
   (앱 시작 시 옵저버가 붙기 때문에 결제 화면을 열지 않아도 된다).
3. `kAnnualPlanEnabled = true`로 바꾸고 `yearly_v2` 구독 → Sandbox 구독은 빠르게
   갱신/만료되므로 `DID_RENEW`, `EXPIRED` 알림과 `expiresAtMs` 변화를 관찰.
4. App Store Connect에서 환불 처리 → `REFUND` 알림으로 `isPro`가 false가 되는지 확인.

## 아직 안 되어 있는 것

- **Play 실시간 개발자 알림(RTDN)** 은 붙이지 않았다. Android 구독의 만료·환불은
  `syncEntitlement`(앱 시작/복귀)로 반영된다. iOS는 알림 웹훅이 있어 즉시 반영된다.
- **주기적 만료 청소 작업**이 없다. `isPro`가 낡은 채 남아 있을 수 있지만, 클라이언트가
  `expiresAt`을 다시 확인하므로 접근 권한이 새지는 않는다. 집계·통계 용도로 정확한
  값이 필요해지면 스케줄 함수를 추가하면 된다.
