import 'dart:async';

import 'package:flutter/foundation.dart';
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

  Future<void> _restoreOnLaunch() async {
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        return;
      }
      _foundValidPurchase = false;
      await InAppPurchase.instance.restorePurchases();
      // purchaseStream으로 결과가 오기까지 대기
      await Future<void>.delayed(const Duration(seconds: 3));
      // 유효한 구매가 없으면 (구독 만료 등) pro 해제
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
          if (p.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(p);
          }
        case PurchaseStatus.error:
          debugPrint('IAP purchase error: ${p.error}');
        case PurchaseStatus.canceled:
          debugPrint('IAP purchase canceled');
        case PurchaseStatus.pending:
          break;
      }
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
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
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
