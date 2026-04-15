import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:ddalgguk/core/providers/pro_provider.dart';

// ── Product IDs ────────────────────────────────────────────────────────────
// Register these exact IDs in App Store Connect and Google Play Console.
const kProLifetimeProductId = 'lifetime_v1';
const kProAnnualProductId = 'yearly_v2';

// ── Service ────────────────────────────────────────────────────────────────

class IapService {
  IapService(this._ref);

  final Ref _ref;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  void init() {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (dynamic e) => debugPrint('IAP stream error: $e'),
    );
    // 앱 시작 시 기존 구매 복원하여 pro 상태 동기화
    _restoreOnLaunch();
  }

  bool _foundValidPurchase = false;
  Completer<void>? _restoreCompleter;

  Future<void> _restoreOnLaunch() async {
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        return;
      }
      _foundValidPurchase = false;
      _restoreCompleter = Completer<void>();
      await InAppPurchase.instance.restorePurchases();
      // 스트림이 복원 배치를 전달할 때까지 대기 — 최대 15초.
      // (고정 3초는 느린 네트워크/App Store 지연 시 유료 사용자를
      // 잠깐 Pro=false로 잘못 내려버려 심사 리젝 위험이 있어 제거함.)
      await Future.any<void>([
        _restoreCompleter!.future,
        Future<void>.delayed(const Duration(seconds: 15)),
      ]);
      _restoreCompleter = null;
      if (!_foundValidPurchase) {
        await _ref.read(proProvider.notifier).setValue(false);
      }
    } catch (e) {
      debugPrint('IAP restore on launch error: $e');
    }
  }

  void dispose() => _subscription?.cancel();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == kProLifetimeProductId ||
              p.productID == kProAnnualProductId) {
            _foundValidPurchase = true;
            await _ref.read(proProvider.notifier).setValue(true);
          }
        case PurchaseStatus.error:
          debugPrint('IAP purchase error: ${p.error}');
        case PurchaseStatus.canceled:
          debugPrint('IAP purchase canceled');
        case PurchaseStatus.pending:
          debugPrint('IAP purchase pending: ${p.productID}');
      }
      // 비완료 상태를 제외한 모든 트랜잭션은 반드시 마무리 — 그렇지 않으면
      // iOS 큐에 stuck 상태로 남아 향후 구매가 실패할 수 있음 (Apple 권장).
      if (p.status != PurchaseStatus.pending && p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
    // 복원 스트림 배치가 한 번이라도 전달되면 즉시 완료 처리.
    final c = _restoreCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  /// Returns null on success (result comes via stream), error message on failure.
  Future<String?> buy(String productId) async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      return '스토어에 연결할 수 없습니다.';
    }

    final response = await InAppPurchase.instance.queryProductDetails({
      productId,
    });
    if (response.productDetails.isEmpty) {
      return '상품 정보를 불러올 수 없습니다.\n(${response.error?.message ?? productId})';
    }

    final param = PurchaseParam(productDetails: response.productDetails.first);
    try {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } on PlatformException catch (e) {
      if (e.code == 'userCancelled' ||
          e.code == 'storekit2_purchase_cancelled') {
        return null;
      }
      return '결제를 시작할 수 없습니다.\n(${e.message ?? e.code})';
    }
    return null;
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService(ref);
  service.init();
  ref.onDispose(service.dispose);
  return service;
});
