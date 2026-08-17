import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/core/services/entitlement_service.dart';
import 'package:ddalgguk/core/services/pending_verification_store.dart';

// ── Product IDs ────────────────────────────────────────────────────────────
// Register these exact IDs in App Store Connect and Google Play Console.
// functions/src/products.ts must list the same set.
const kProLifetimeProductId = 'lifetime_v1';
const kProAnnualProductId = 'yearly_v2';

/// 2026년 4월에 잠깐 존재했던 연간 상품 ID. 더 이상 판매하지 않지만, 그때 구독한
/// 사용자의 복원 내역에는 이 ID로 올라오므로 계속 인정해야 한다.
const kLegacyProAnnualProductId = 'yearly_v1';

/// PRO 권한을 주는 모든 상품 ID.
const Set<String> kProProductIds = {
  kProLifetimeProductId,
  kProAnnualProductId,
  kLegacyProAnnualProductId,
};

/// 결제 화면에 연간 구독을 노출할지 여부.
///
/// 현재 배포판은 일회성 결제만 판매한다. 연간 구독 로직(구매·복원·만료·서버 검증)은
/// 전부 완성되어 있으므로, 다시 판매하려면 이 값만 true로 바꾸면 된다.
/// App Store Connect / Play Console에서 `yearly_v2`가 판매 중인지 먼저 확인할 것.
const bool kAnnualPlanEnabled = false;

/// 결제 화면에서 살 수 있는 상품 목록.
List<String> get kPurchasableProductIds => [
  kProLifetimeProductId,
  if (kAnnualPlanEnabled) kProAnnualProductId,
];

// ── Events ─────────────────────────────────────────────────────────────────

enum IapEventType {
  /// 스토어가 결제를 보류했다(가족 승인 대기 등).
  pending,

  /// 결제·복원이 서버 검증까지 끝났다.
  succeeded,

  /// 사용자가 결제를 취소했다.
  canceled,

  /// 결제는 됐지만 지금 서버 검증을 마칠 수 없었다. 재시도 대기열에 넣었다.
  verificationDeferred,

  /// 결제에 실패했다.
  failed,
}

@immutable
class IapEvent {
  const IapEvent(this.type, {this.productId, this.message});

  final IapEventType type;
  final String? productId;
  final String? message;
}

@immutable
class RestoreOutcome {
  const RestoreOutcome({
    required this.completed,
    required this.foundPurchase,
    this.message,
  });

  /// 복원 요청이 정상적으로 끝났는지. false면 결과를 신뢰할 수 없다.
  final bool completed;

  /// PRO 상품이 하나라도 발견됐는지.
  final bool foundPurchase;

  final String? message;
}

// ── Service ────────────────────────────────────────────────────────────────

/// 스토어 결제와 서버 검증을 연결한다.
///
/// 이 서비스는 스스로 PRO 여부를 결정하지 않는다. 영수증을 서버에 보내고,
/// 서버가 쓴 권한 문서를 [proProvider]가 읽는다.
class IapService {
  IapService(this._ref, {PendingVerificationStore? pendingStore})
    : _pendingStore = pendingStore ?? PendingVerificationStore();

  /// 결제 시트가 열린 뒤 아무 소식도 없을 때 잠금을 풀어주는 상한.
  static const Duration _purchaseWatchdog = Duration(minutes: 3);

  /// restorePurchases()가 끝난 뒤 복원 배치가 스트림으로 도착할 유예 시간.
  ///
  /// 네이티브 구현은 모든 트랜잭션을 채널로 보낸 *다음* 완료를 알리므로, 남은 건
  /// 채널 전달 지연뿐이다. 예전처럼 고정 3초/15초를 기다리는 것과 달리 실제
  /// 완료 신호를 쓰기 때문에 유료 사용자를 잘못 강등할 위험이 없다.
  static const Duration _restoreDrain = Duration(seconds: 2);

  final Ref _ref;
  final PendingVerificationStore _pendingStore;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  StreamSubscription<User?>? _authSubscription;
  final StreamController<IapEvent> _events =
      StreamController<IapEvent>.broadcast();

  bool _initialized = false;
  String? _bootstrappedUid;
  Future<RestoreOutcome>? _activeRestore;
  bool _restoreFoundPro = false;
  String? _inFlightProductId;
  Timer? _watchdog;

  /// 검증 중인 작업들. 복원 결과를 판단하기 전에 이들을 기다린다.
  final Set<Future<void>> _inFlightVerifications = {};

  List<ProductDetails>? _cachedProducts;

  Stream<IapEvent> get events => _events.stream;

  EntitlementService get _entitlements =>
      _ref.read(entitlementServiceProvider);

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// 인앱 결제가 동작하는 플랫폼인지.
  ///
  /// in_app_purchase는 iOS/Android에만 등록된다. 개발 중 macOS나 웹으로 실행할 때
  /// 플러그인이 없는 상태로 스트림을 구독하려 하면 앱 시작이 실패한다.
  static bool get isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  /// 앱 시작 시 한 번 호출한다.
  ///
  /// 트랜잭션 옵저버를 즉시 붙이는 것이 핵심이다. purchaseStream을 구독하지 않으면
  /// StoreKit의 Transaction.updates 리스너 자체가 시작되지 않아서, 앱이 백그라운드
  /// 상태일 때 완료된 결제나 가족 승인 결과를 놓친다.
  void init() {
    if (_initialized || !isSupportedPlatform) {
      return;
    }
    _initialized = true;

    // 앱 시작 경로에서 호출되므로 무슨 일이 있어도 예외를 밖으로 내보내지 않는다.
    // 결제 기능이 죽는 것보다 앱이 뜨지 않는 게 훨씬 나쁘다.
    try {
      _subscription = InAppPurchase.instance.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (dynamic e) => debugPrint('IAP stream error: $e'),
      );

      // 서버 검증에는 로그인이 필요하다. 앱 시작 시점에는 Firebase가 세션을 아직
      // 복구하지 못했을 수 있으므로, 계정이 확정되는 순간에 맞춰 정리 작업을 돌린다.
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        if (user == null) {
          _bootstrappedUid = null;
          return;
        }
        if (_bootstrappedUid == user.uid) {
          return;
        }
        _bootstrappedUid = user.uid;
        unawaited(_bootstrap());
      });
    } catch (e) {
      debugPrint('IAP initialization failed: $e');
    }
  }

  /// 로그인이 확인된 뒤 한 번 수행하는 정리 작업.
  Future<void> _bootstrap() async {
    try {
      await retryPendingVerifications();
      await refreshEntitlement();
    } catch (e) {
      debugPrint('IAP bootstrap failed: $e');
    }
  }

  /// 스토어 사용 가능 여부. 미지원 플랫폼과 스토어 접속 실패를 함께 걸러낸다.
  Future<bool> _storeAvailable() async {
    if (!isSupportedPlatform) {
      return false;
    }
    try {
      return await InAppPurchase.instance.isAvailable();
    } catch (e) {
      debugPrint('IAP availability check failed: $e');
      return false;
    }
  }

  void dispose() {
    _watchdog?.cancel();
    _authSubscription?.cancel();
    _subscription?.cancel();
    _events.close();
  }

  // ── Purchase ─────────────────────────────────────────────────────────────

  /// 결제를 시작한다. 실패 사유가 있으면 문자열로, 없으면 null을 돌려준다.
  ///
  /// 성공/취소/실패는 [events]로 전달된다 — 스토어 결제는 결제 시트가 닫힌 뒤에
  /// 결과가 오기 때문에 이 함수의 반환값만으로는 알 수 없다.
  Future<String?> buy(String productId) async {
    if (_inFlightProductId != null) {
      return '결제가 진행 중입니다. 잠시만 기다려 주세요.';
    }

    if (!await _storeAvailable()) {
      return '스토어에 연결할 수 없습니다.';
    }

    final products = await loadProducts();
    final matches = products.where((p) => p.id == productId).toList();
    if (matches.isEmpty) {
      return '상품 정보를 불러올 수 없습니다.\n($productId)';
    }
    final product = matches.first;

    _beginPurchase(productId);
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          // Apple의 appAccountToken으로 전달된다. 이 값이 있으면 서버가 갱신·환불
          // 알림을 받았을 때 어느 계정의 결제인지 바로 찾을 수 있다.
          applicationUserName: _appAccountToken(),
        ),
      );
    } on PlatformException catch (e) {
      _endPurchase();
      if (_isCancellation(e.code)) {
        return null;
      }
      return '결제를 시작할 수 없습니다.\n(${e.message ?? e.code})';
    } catch (e) {
      _endPurchase();
      return '결제를 시작할 수 없습니다.\n$e';
    }
    return null;
  }

  bool _isCancellation(String code) =>
      code == 'userCancelled' || code == 'storekit2_purchase_cancelled';

  String? _appAccountToken() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    return EntitlementService.appAccountTokenForUid(uid);
  }

  void _beginPurchase(String productId) {
    _inFlightProductId = productId;
    _watchdog?.cancel();
    _watchdog = Timer(_purchaseWatchdog, () {
      if (_inFlightProductId != null) {
        debugPrint('IAP purchase watchdog fired for $_inFlightProductId');
        _endPurchase();
      }
    });
  }

  void _endPurchase() {
    _inFlightProductId = null;
    _watchdog?.cancel();
    _watchdog = null;
  }

  // ── Products ─────────────────────────────────────────────────────────────

  /// 판매 상품 정보를 불러온다(가격 표시에 사용). 성공한 결과는 캐시한다.
  ///
  /// 화면에 가격을 하드코딩하지 않기 위해 필요하다. 하드코딩한 가격은 스토어에서
  /// 가격을 바꾸거나 한국 외 스토어프론트에서 실제 청구액과 달라진다.
  Future<List<ProductDetails>> loadProducts({bool forceRefresh = false}) async {
    final cached = _cachedProducts;
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (!await _storeAvailable()) {
      return const [];
    }
    final response = await InAppPurchase.instance.queryProductDetails(
      kPurchasableProductIds.toSet(),
    );
    if (response.error != null) {
      debugPrint('IAP product query error: ${response.error?.message}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
    if (response.productDetails.isNotEmpty) {
      _cachedProducts = response.productDetails;
    }
    return response.productDetails;
  }

  // ── Restore ──────────────────────────────────────────────────────────────

  /// 구매 복원. 결과를 호출자가 판단할 수 있도록 [RestoreOutcome]을 돌려준다.
  ///
  /// [clearCacheIfEmpty]가 true면, 복원이 정상적으로 끝났고 PRO 상품이 전혀 없을
  /// 때 로컬 캐시를 지운다. 만료된 구독을 정리하는 경로다.
  Future<RestoreOutcome> restorePurchases({
    bool clearCacheIfEmpty = false,
  }) {
    // 복원은 `_restoreFoundPro` 하나로 결과를 모으기 때문에 동시에 두 번 돌면
    // 서로의 결과를 지운다. 앱 시작 시 자동 복원과 사용자가 누른 복원이 겹칠 수
    // 있으므로, 이미 진행 중이면 그 결과를 함께 쓴다.
    final active = _activeRestore;
    if (active != null) {
      return active;
    }
    final restore = _runRestore(clearCacheIfEmpty: clearCacheIfEmpty);
    _activeRestore = restore;
    return restore.whenComplete(() {
      if (_activeRestore == restore) {
        _activeRestore = null;
      }
    });
  }

  Future<RestoreOutcome> _runRestore({
    required bool clearCacheIfEmpty,
  }) async {
    if (!await _storeAvailable()) {
      return const RestoreOutcome(
        completed: false,
        foundPurchase: false,
        message: '스토어에 연결할 수 없습니다.',
      );
    }

    _restoreFoundPro = false;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore failed: $e');
      return RestoreOutcome(
        completed: false,
        foundPurchase: false,
        message: e.toString(),
      );
    }

    // 네이티브가 완료를 알린 시점에는 트랜잭션이 이미 전송된 상태다. 채널 전달과
    // 그에 따른 서버 검증이 끝날 때까지만 기다린다.
    await Future<void>.delayed(_restoreDrain);
    await _awaitVerifications();

    if (!_restoreFoundPro && clearCacheIfEmpty) {
      // 스토어가 "가진 구매가 없다"고 확인해준 유일한 경우.
      await _ref.read(proProvider.notifier).markStoreReportedNoPurchases();
    }

    return RestoreOutcome(completed: true, foundPurchase: _restoreFoundPro);
  }

  Future<void> _awaitVerifications() async {
    while (_inFlightVerifications.isNotEmpty) {
      await Future.wait(_inFlightVerifications.toList());
    }
  }

  /// 서버에 저장된 결제를 스토어와 다시 맞춘다.
  ///
  /// 만료·환불 알림이 유실됐거나 아직 웹훅이 등록되지 않았더라도, 이 호출로 권한이
  /// 결국 정확해진다.
  ///
  /// 응답을 로컬 상태에 직접 반영하지는 않는다. 서버가 권한 문서를 바꾸면
  /// [entitlementProvider]의 실시간 구독이 알려주기 때문이다. 응답으로 상태를
  /// 덮어쓰면 "서버가 아는 결제가 아직 없음"을 "권한 없음"으로 오해해서, 복원이
  /// 끝나기 전인 유료 사용자를 강등시킬 수 있다.
  Future<void> syncWithStore({bool force = false}) async {
    final result = await _entitlements.sync(force: force);
    if (result.status != VerificationStatus.verified) {
      debugPrint('Entitlement sync deferred: ${result.message}');
    }
  }

  /// 앱 시작·복귀 시 호출한다. 스토어 복원과 서버 동기화를 함께 수행한다.
  Future<void> refreshEntitlement({bool restoreFromStore = true}) async {
    if (restoreFromStore) {
      await restorePurchases(clearCacheIfEmpty: true);
    }
    await syncWithStore();
  }

  // ── Stream handling ──────────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleOwnedPurchase(purchase);
        case PurchaseStatus.pending:
          debugPrint('IAP purchase pending: ${purchase.productID}');
          _emit(IapEvent(IapEventType.pending, productId: purchase.productID));
        case PurchaseStatus.canceled:
          _resolveInFlight(purchase.productID);
          _emit(IapEvent(IapEventType.canceled, productId: purchase.productID));
        case PurchaseStatus.error:
          debugPrint('IAP purchase error: ${purchase.error}');
          _resolveInFlight(purchase.productID);
          _emit(
            IapEvent(
              IapEventType.failed,
              productId: purchase.productID,
              message: purchase.error?.message,
            ),
          );
      }

      // 보류 중이 아닌 트랜잭션은 반드시 마무리한다. 그러지 않으면 iOS 큐에 남아
      // 이후 결제가 실패하고, Android에서는 3일 후 자동 환불된다.
      if (purchase.status != PurchaseStatus.pending &&
          purchase.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(purchase);
        } catch (e) {
          debugPrint('IAP completePurchase failed: $e');
        }
      }
    }
  }

  Future<void> _handleOwnedPurchase(PurchaseDetails purchase) async {
    if (!kProProductIds.contains(purchase.productID)) {
      return;
    }

    final isRestore = purchase.status == PurchaseStatus.restored;
    if (isRestore) {
      _restoreFoundPro = true;
    }

    final verificationData = purchase.verificationData.serverVerificationData;
    if (verificationData.isEmpty) {
      debugPrint('IAP transaction has no verification data — cannot verify');
      _resolveInFlight(purchase.productID);
      _emit(
        IapEvent(
          IapEventType.failed,
          productId: purchase.productID,
          message: '영수증을 읽을 수 없습니다.',
        ),
      );
      return;
    }

    // 새 결제는 검증 전에 먼저 디스크에 남긴다. 검증 도중 앱이 죽어도 영수증이
    // 사라지지 않는다. 복원은 매번 다시 흘러오므로 큐에 넣지 않는다.
    PendingVerification? queued;
    if (!isRestore) {
      queued = PendingVerification.create(
        platform: _platform,
        productId: purchase.productID,
        verificationData: verificationData,
        now: DateTime.now(),
      );
      await _pendingStore.add(queued);
    }

    final future = _verify(
      platform: _platform,
      productId: purchase.productID,
      verificationData: verificationData,
      queuedId: queued?.id,
      isRestore: isRestore,
    );
    _track(future);
    await future;
  }

  void _track(Future<void> future) {
    _inFlightVerifications.add(future);
    future.whenComplete(() => _inFlightVerifications.remove(future));
  }

  Future<void> _verify({
    required String platform,
    required String productId,
    required String verificationData,
    required String? queuedId,
    required bool isRestore,
  }) async {
    final result = await _entitlements.verifyPurchase(
      platform: platform,
      productId: productId,
      verificationData: verificationData,
    );

    switch (result.status) {
      case VerificationStatus.verified:
        if (queuedId != null) {
          await _pendingStore.remove(queuedId);
        }
        final entitlement = result.entitlement;
        if (entitlement != null) {
          await _ref
              .read(proProvider.notifier)
              .applyVerifiedEntitlement(entitlement);
        }
        _resolveInFlight(productId);
        if (!isRestore) {
          _emit(IapEvent(IapEventType.succeeded, productId: productId));
        }

      case VerificationStatus.rejected:
        // 서버가 영수증을 거부했다. 다시 보내도 같은 결과이므로 대기열에서 뺀다.
        if (queuedId != null) {
          await _pendingStore.remove(queuedId);
        }
        _resolveInFlight(productId);
        if (!isRestore) {
          _emit(
            IapEvent(
              IapEventType.failed,
              productId: productId,
              message: '결제를 확인할 수 없습니다. 고객센터에 문의해 주세요.',
            ),
          );
        }

      case VerificationStatus.retryLater:
      case VerificationStatus.unauthenticated:
        // 결제 자체는 성공했다. 검증만 나중에 다시 한다.
        _resolveInFlight(productId);
        if (!isRestore) {
          _emit(
            IapEvent(
              IapEventType.verificationDeferred,
              productId: productId,
              message: '결제가 완료됐습니다. 잠시 후 자동으로 확인됩니다.',
            ),
          );
        }
    }
  }

  /// 밀린 검증을 다시 시도한다. 앱 시작·복귀·로그인 후에 호출한다.
  Future<void> retryPendingVerifications() async {
    final pending = await _pendingStore.load();
    if (pending.isEmpty) {
      return;
    }
    debugPrint('Retrying ${pending.length} pending purchase verification(s)');
    for (final entry in pending) {
      final result = await _entitlements.verifyPurchase(
        platform: entry.platform,
        productId: entry.productId,
        verificationData: entry.verificationData,
      );
      switch (result.status) {
        case VerificationStatus.verified:
          await _pendingStore.remove(entry.id);
          final entitlement = result.entitlement;
          if (entitlement != null) {
            await _ref
                .read(proProvider.notifier)
                .applyVerifiedEntitlement(entitlement);
          }
        case VerificationStatus.rejected:
          await _pendingStore.remove(entry.id);
        case VerificationStatus.retryLater:
        case VerificationStatus.unauthenticated:
          final dropped = await _pendingStore.recordFailure(entry.id);
          if (dropped) {
            debugPrint(
              'Gave up verifying ${entry.productId} after '
              '${PendingVerificationStore.maxAttempts} attempts',
            );
          }
          // 지금 네트워크/로그인이 안 되는 상황이면 나머지도 마찬가지다.
          return;
      }
    }
  }

  void _resolveInFlight(String productId) {
    if (_inFlightProductId == productId) {
      _endPurchase();
    }
  }

  void _emit(IapEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService(ref);
  service.init();
  ref.onDispose(service.dispose);
  return service;
});
