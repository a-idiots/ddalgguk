import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ddalgguk/core/services/entitlement_service.dart';

/// 마지막으로 확인된 PRO 여부(캐시). 오프라인일 때 이 값으로 버틴다.
/// 예전 버전에서 쓰던 키를 그대로 유지해야 업데이트 시 기존 구매자가 강등되지 않는다.
const _kProKey = 'pro_enabled';

/// 캐시의 전체 내용(상품 종류·만료 시각까지). 구독 만료를 오프라인에서도
/// 존중하려면 bool 하나로는 부족하다.
const _kProCacheKey = 'pro_cache';

/// 개발용 수동 토글(설정 화면의 숨은 제스처). 서버 판단보다 우선한다.
const _kProOverrideKey = 'pro_override';

const _kLegacyProKey = 'debug_pro_enabled';

/// 무료 유저 고정 기본 주종 ID: 소주, 맥주, 막걸리, 와인, 칵테일
const List<int> kFreeDefaultDrinkIds = [1, 2, 5, 4, 3];

/// PRO 여부를 판단한다.
///
/// 우선순위:
///   1. 로컬 수동 override — 설정 화면의 숨은 토글(의도된 기능)
///   2. 서버 권한 문서 — 스토어 영수증이 서버에서 검증된 결과
///   3. 마지막으로 알던 값(캐시) — 오프라인이거나 아직 검증 전일 때
///
/// 3번이 필요한 이유: 서버 문서가 "없음"인 것과 "권한 없음"인 것은 다르다.
/// 네트워크가 없다고 유료 사용자를 강등하면 안 되고, 반대로 스토어가 "가진 구매가
/// 없다"고 확인해준 경우에는 캐시를 지워야 한다
/// ([markStoreReportedNoPurchases]).
class ProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final entitlementAsync = ref.watch(entitlementProvider);
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyKeys(prefs);

    final override = _readOverride(prefs);
    if (override != null) {
      return override;
    }

    if (entitlementAsync.hasValue) {
      final entitlement = entitlementAsync.value;
      if (entitlement != null) {
        // 서버가 판단한 값이 정답. 다음 오프라인 실행을 위해 캐시에 저장한다.
        await _writeCache(prefs, entitlement);
        return entitlement.isActiveAt(DateTime.now());
      }
      // 문서가 아직 없다 = 서버가 검증한 결제가 없다. 캐시를 지우지는 않는다.
      // (업데이트 직후 기존 구매자는 복원이 끝나기 전이라 문서가 없을 수 있다.)
    }

    return _readCache(prefs)?.isActiveAt(DateTime.now()) ?? false;
  }

  /// 설정 화면의 숨은 토글용.
  ///
  /// true는 override를 켜고, false는 override를 지워 실제 권한 상태로 되돌린다.
  /// false를 그대로 고정해버리면 실제 유료 사용자가 실수로 토글했을 때 영구히
  /// PRO를 잃게 되므로 이렇게 나눈다.
  Future<void> setValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_kProOverrideKey, true);
    } else {
      await prefs.remove(_kProOverrideKey);
    }
    ref.invalidateSelf();
  }

  /// 서버 검증이 성공한 직후 호출한다.
  ///
  /// Firestore 스트림도 곧 같은 값을 전달하지만, 결제 직후 화면 반응을 기다리게
  /// 하지 않기 위해 응답으로 받은 값을 즉시 반영한다.
  Future<void> applyVerifiedEntitlement(Entitlement entitlement) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeCache(prefs, entitlement);
    final override = _readOverride(prefs);
    if (override != null) {
      return;
    }
    state = AsyncValue.data(entitlement.isActiveAt(DateTime.now()));
  }

  /// 스토어가 "이 계정에는 유효한 구매가 없다"고 확인해준 경우에만 호출한다.
  ///
  /// 복원이 정상적으로 끝났고 PRO 상품이 하나도 없을 때만 해당한다. 타임아웃이나
  /// 오류로는 절대 호출하면 안 된다 — 그게 예전 구현이 유료 사용자를 잠깐
  /// 강등시켰던 원인이다.
  Future<void> markStoreReportedNoPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProCacheKey);
    await prefs.setBool(_kProKey, false);
    if (_readOverride(prefs) != null) {
      return;
    }
    ref.invalidateSelf();
  }

  bool? _readOverride(SharedPreferences prefs) {
    if (!prefs.containsKey(_kProOverrideKey)) {
      return null;
    }
    return prefs.getBool(_kProOverrideKey);
  }

  Future<void> _writeCache(
    SharedPreferences prefs,
    Entitlement entitlement,
  ) async {
    await prefs.setString(
      _kProCacheKey,
      jsonEncode({
        ...entitlement.toJson(),
        // 캐시가 어느 계정 것인지 남긴다. 같은 기기에서 다른 계정으로 로그인했을 때
        // 이전 사용자의 PRO가 새어 나가지 않도록 하기 위한 것이다.
        'uid': FirebaseAuth.instance.currentUser?.uid,
      }),
    );
    // 사람이 읽기 쉬운 요약값. 예전 키를 계속 채워두면 다운그레이드 시에도 동작한다.
    await prefs.setBool(_kProKey, entitlement.isPro);
  }

  Entitlement? _readCache(SharedPreferences prefs) {
    final raw = prefs.getString(_kProCacheKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && !_cacheBelongsToCurrentUser(decoded)) {
          return null;
        }
        return Entitlement.fromJson(decoded);
      } catch (e) {
        debugPrint('PRO cache is unreadable, falling back to the flag: $e');
      }
    }
    // 캐시가 없는 경우: 이 버전으로 업데이트한 기존 사용자다. 예전에는 bool
    // 하나만 저장했으므로 만료 정보가 없고, 서버가 판단을 내려줄 때까지
    // 평생 구매처럼 취급한다.
    if (prefs.getBool(_kProKey) == true) {
      return const Entitlement(isPro: true);
    }
    return null;
  }

  /// 캐시가 지금 로그인한 계정 것인지 확인한다.
  ///
  /// 아직 계정을 모르는 시점(앱 시작 직후 Firebase가 세션을 복구하는 중)에는
  /// 검사를 건너뛴다. 그러지 않으면 콜드 스타트마다 유료 사용자가 잠깐
  /// 무료로 보인다.
  bool _cacheBelongsToCurrentUser(Map<dynamic, dynamic> cache) {
    final cachedUid = cache['uid'];
    if (cachedUid is! String || cachedUid.isEmpty) {
      // 계정 정보가 없는 캐시 = 이 기능 이전 버전에서 넘어온 값. 인정한다.
      return true;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return true;
    }
    return cachedUid == currentUid;
  }

  Future<void> _migrateLegacyKeys(SharedPreferences prefs) async {
    if (!prefs.containsKey(_kProKey) && prefs.containsKey(_kLegacyProKey)) {
      final legacy = prefs.getBool(_kLegacyProKey) ?? false;
      await prefs.setBool(_kProKey, legacy);
      await prefs.remove(_kLegacyProKey);
    }
  }
}

final proProvider = AsyncNotifierProvider<ProNotifier, bool>(ProNotifier.new);
