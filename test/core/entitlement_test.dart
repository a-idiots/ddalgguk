import 'package:flutter_test/flutter_test.dart';

import 'package:ddalgguk/core/services/entitlement_service.dart';

void main() {
  // DateTime.fromMillisecondsSinceEpoch은 로컬 시간대의 DateTime을 돌려주므로
  // (cloud_firestore의 Timestamp.toDate()도 마찬가지) 비교 대상도 로컬로 둔다.
  final now = DateTime(2026, 8, 17, 12);

  group('Entitlement.isActiveAt', () {
    test('평생 상품은 만료되지 않는다', () {
      const entitlement = Entitlement(
        isPro: true,
        activeProductId: 'lifetime_v1',
        activeKind: 'lifetime',
      );
      expect(entitlement.isActiveAt(now), isTrue);
      expect(
        entitlement.isActiveAt(now.add(const Duration(days: 3650))),
        isTrue,
      );
      expect(entitlement.isLifetime, isTrue);
    });

    test('구독은 만료 시각까지만 유효하다', () {
      final entitlement = Entitlement(
        isPro: true,
        activeProductId: 'yearly_v2',
        activeKind: 'subscription',
        expiresAt: now.add(const Duration(days: 10)),
      );
      expect(entitlement.isActiveAt(now), isTrue);
      expect(
        entitlement.isActiveAt(now.add(const Duration(days: 11))),
        isFalse,
      );
    });

    test('서버가 isPro=true로 남겨둔 값이라도 만료가 지나면 인정하지 않는다', () {
      // 만료 알림이 늦거나 유실되면 서버 문서의 isPro가 낡은 값으로 남는다.
      // 클라이언트에서 한 번 더 확인하는 이유가 이것.
      final stale = Entitlement(
        isPro: true,
        activeKind: 'subscription',
        expiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(stale.isActiveAt(now), isFalse);
    });

    test('isPro=false면 만료 시각이 미래여도 유효하지 않다', () {
      final revoked = Entitlement(
        isPro: false,
        activeKind: 'subscription',
        expiresAt: now.add(const Duration(days: 30)),
      );
      expect(revoked.isActiveAt(now), isFalse);
    });
  });

  group('Entitlement 직렬화', () {
    test('Firestore 문서를 읽는다', () {
      final entitlement = Entitlement.fromMap({
        'isPro': true,
        'activeProductId': 'yearly_v2',
        'activeKind': 'subscription',
        'expiresAtMs': now.millisecondsSinceEpoch,
      });
      expect(entitlement.isPro, isTrue);
      expect(entitlement.activeProductId, 'yearly_v2');
      expect(entitlement.expiresAt, now);
    });

    test('필드가 비어 있어도 안전하게 읽는다', () {
      final entitlement = Entitlement.fromMap({});
      expect(entitlement.isPro, isFalse);
      expect(entitlement.expiresAt, isNull);
      expect(entitlement.activeProductId, isNull);
    });

    test('expiresAtMs가 숫자가 아니면 무시한다', () {
      final entitlement = Entitlement.fromMap({
        'isPro': true,
        'expiresAtMs': 'not-a-number',
      });
      expect(entitlement.expiresAt, isNull);
    });

    test('캐시로 저장한 뒤 다시 읽어도 같다', () {
      final entitlement = Entitlement(
        isPro: true,
        activeProductId: 'lifetime_v1',
        activeKind: 'lifetime',
        expiresAt: now,
      );
      expect(Entitlement.fromJson(entitlement.toJson()), entitlement);
    });

    test('캐시가 Map이 아니면 null을 준다', () {
      expect(Entitlement.fromJson('garbage'), isNull);
      expect(Entitlement.fromJson(null), isNull);
    });
  });

  group('appAccountTokenForUid', () {
    test('같은 uid면 항상 같은 값이 나온다', () {
      // 서버가 갱신·환불 알림에서 uid를 찾으려면 이 값이 안정적이어야 한다.
      final first = EntitlementService.appAccountTokenForUid('abc123');
      final second = EntitlementService.appAccountTokenForUid('abc123');
      expect(first, second);
    });

    test('uid가 다르면 값도 다르다', () {
      expect(
        EntitlementService.appAccountTokenForUid('abc123'),
        isNot(EntitlementService.appAccountTokenForUid('abc124')),
      );
    });

    test('Apple이 요구하는 UUID 형식이다', () {
      // appAccountToken이 UUID가 아니면 StoreKit이 결제를 거부한다.
      final token = EntitlementService.appAccountTokenForUid(
        'firebase-uid-28-characters-x',
      );
      expect(
        token,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });
}
