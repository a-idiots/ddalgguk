import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/core/services/iap_service.dart';

const _kTermsUrl =
    'https://melodic-music-7c1.notion.site/2cd5a6752e1b80889671e04b2283c00d';
const _kPrivacyUrl =
    'https://melodic-music-7c1.notion.site/2cb5a6752e1b80eeb44dc1763020d324';

/// 할인 전 정가(마케팅 표기).
///
/// 실제 청구 금액은 항상 스토어에서 받아온 값을 쓴다. 정가는 스토어가 알려주지
/// 않는 값이라 여기 둘 수밖에 없는데, 원화 가격일 때만 보여준다 — 다른 나라
/// 스토어프론트에서 원화 정가를 취소선으로 붙이면 사실과 달라진다.
const Map<String, String> _kKrwListPrice = {
  kProLifetimeProductId: '29,900원',
  kProAnnualProductId: '14,900원',
};

const String _kKrwCurrencyCode = 'KRW';

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// Feature indices (used as `triggerFeatureIndex`):
//   0 = goal setting      (set_goal.png)
//   1 = custom drinks     (custom_drinks.png)
//   2 = drinking guideline (alcohol_guideline.png)
//   3 = ranking           (ranking.png)
//   4 = past report       (past_report.png)

const _featureImages = [
  'assets/imgs/pro_plan/set_goal.png',
  'assets/imgs/pro_plan/custom_drinks.png',
  'assets/imgs/pro_plan/alcohol_guideline.png',
  'assets/imgs/pro_plan/ranking.png',
  'assets/imgs/pro_plan/past_report.png',
];

void showProPlanPopup(BuildContext context, int triggerFeatureIndex) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ProPlanPopup(initialFeatureIndex: triggerFeatureIndex),
    ),
  );
}

class ProPlanPopup extends ConsumerStatefulWidget {
  const ProPlanPopup({super.key, required this.initialFeatureIndex});

  final int initialFeatureIndex;

  @override
  ConsumerState<ProPlanPopup> createState() => _ProPlanPopupState();
}

class _ProPlanPopupState extends ConsumerState<ProPlanPopup> {
  late final PageController _pageController;
  late final List<String> _images;
  int _currentPage = 0;

  List<ProductDetails> _products = const [];
  bool _loadingProducts = true;
  String? _productError;

  String _selectedProductId = kProLifetimeProductId;
  bool _purchasing = false;
  bool _restoring = false;

  StreamSubscription<IapEvent>? _eventSubscription;

  bool get _busy => _purchasing || _restoring;

  @override
  void initState() {
    super.initState();
    final start = widget.initialFeatureIndex.clamp(
      0,
      _featureImages.length - 1,
    );
    _images = [
      for (int i = 0; i < _featureImages.length; i++)
        _featureImages[(start + i) % _featureImages.length],
    ];
    _pageController = PageController();

    // 결제 결과는 결제 시트가 닫힌 뒤에 스트림으로 온다. 그래서 buy()가 반환한
    // 시점에 스피너를 끄면 안 되고, 이벤트를 받아서 처리해야 중복 탭도 막힌다.
    _eventSubscription = ref
        .read(iapServiceProvider)
        .events
        .listen(_onIapEvent);

    _loadProducts();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(iapServiceProvider).loadProducts();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = products;
        _loadingProducts = false;
        _productError = products.isEmpty ? '상품 정보를 불러올 수 없습니다.' : null;
        if (!products.any((p) => p.id == _selectedProductId) &&
            products.isNotEmpty) {
          _selectedProductId = products.first.id;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingProducts = false;
        _productError = '상품 정보를 불러올 수 없습니다.';
      });
    }
  }

  void _onIapEvent(IapEvent event) {
    if (!mounted) {
      return;
    }
    switch (event.type) {
      case IapEventType.pending:
        _showMessage('결제 승인을 기다리고 있습니다.');
      case IapEventType.succeeded:
        // proProvider가 true로 바뀌면 아래 ref.listen이 팝업을 닫는다.
        setState(() => _purchasing = false);
      case IapEventType.canceled:
        setState(() => _purchasing = false);
      case IapEventType.failed:
        setState(() => _purchasing = false);
        _showMessage(event.message ?? '결제에 실패했습니다.');
      case IapEventType.verificationDeferred:
        setState(() => _purchasing = false);
        _showMessage(event.message ?? '결제가 완료됐습니다. 잠시 후 자동으로 확인됩니다.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePurchase() async {
    if (_busy) {
      return;
    }
    setState(() => _purchasing = true);
    final error = await ref.read(iapServiceProvider).buy(_selectedProductId);
    if (!mounted) {
      return;
    }
    if (error != null) {
      // 결제 시트를 열지도 못한 경우. 이벤트가 오지 않으므로 여기서 정리한다.
      setState(() => _purchasing = false);
      _showMessage(error);
    }
    // 성공적으로 시작됐다면 스피너를 유지한 채 이벤트를 기다린다.
  }

  Future<void> _handleRestore() async {
    if (_busy) {
      return;
    }
    setState(() => _restoring = true);
    // 사용자가 직접 누른 복원은 캐시를 지우지 않는다. 다른 Apple ID로 로그인한
    // 상태에서 눌렀다고 해서 이미 확인된 권한을 잃게 만들 이유가 없다.
    final outcome = await ref
        .read(iapServiceProvider)
        .restorePurchases(clearCacheIfEmpty: false);
    if (!mounted) {
      return;
    }
    setState(() => _restoring = false);

    if (!outcome.completed) {
      _showMessage(outcome.message ?? '복원에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      return;
    }
    if (!outcome.foundPurchase) {
      _showMessage('복원할 구매 내역이 없습니다.');
      return;
    }
    // restorePurchases()는 서버 검증까지 끝난 뒤에 반환한다.
    final isPro = ref.read(proProvider).valueOrNull ?? false;
    if (isPro) {
      Navigator.of(context).pop();
    } else {
      _showMessage('구매를 확인하는 중입니다. 잠시만 기다려 주세요.');
    }
  }

  bool get _selectionIsSubscription =>
      _selectedProductId == kProAnnualProductId;

  String get _ctaLabel =>
      _selectionIsSubscription ? '딸꾹PRO 구독하기' : '딸꾹PRO 시작하기';

  @override
  Widget build(BuildContext context) {
    // 구매 성공 시 자동으로 팝업 닫기
    ref.listen<AsyncValue<bool>>(proProvider, (prev, next) {
      if (next.valueOrNull == true && prev?.valueOrNull != true) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAEAEA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // X button pinned at top
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
            ),
            // Pro logo pinned near top
            const SizedBox(height: 0),
            Image.asset('assets/imgs/pro_plan/pro_logo.png', height: 90),
            const SizedBox(height: 6),
            const Text(
              '딸꾹 프로 기능을 이용해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            // Top-aligned content so the subscribe button + links have room below.
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Feature image carousel (fixed height)
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Image.asset(_images[i], fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Dots indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < _images.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _currentPage ? 10 : 8,
                              height: i == _currentPage ? 10 : 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _currentPage
                                    ? const Color(0xFFF08080)
                                    : Colors.grey[300],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Payment options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(children: _buildPurchaseSection()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPurchaseSection() {
    if (_loadingProducts) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: Color(0xFFF08080)),
        ),
      ];
    }

    if (_productError != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            _productError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _loadingProducts = true;
              _productError = null;
            });
            _loadProducts();
          },
          child: const Text('다시 시도'),
        ),
        const SizedBox(height: 8),
        _BottomLinks(onRestore: _busy ? null : _handleRestore),
      ];
    }

    // 여러 상품을 파는 경우에만 선택 UI를 보여준다.
    final showSelection = _products.length > 1;

    return [
      for (final product in _products) ...[
        _PaymentCard(
          product: product,
          selectable: showSelection,
          isSelected: !showSelection || product.id == _selectedProductId,
          onTap: !showSelection || _busy
              ? null
              : () => setState(() => _selectedProductId = product.id),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _handlePurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF08080),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(
              0xFFF08080,
            ).withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _ctaLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
      if (_selectionIsSubscription) ...[
        const SizedBox(height: 10),
        Text(
          '구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 자동으로 갱신됩니다.\n'
          '구독 관리와 해지는 스토어 계정 설정에서 할 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4),
        ),
      ],
      const SizedBox(height: 14),
      _BottomLinks(onRestore: _busy ? null : _handleRestore),
    ];
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.product,
    required this.selectable,
    required this.isSelected,
    required this.onTap,
  });

  final ProductDetails product;
  final bool selectable;
  final bool isSelected;
  final VoidCallback? onTap;

  bool get _isSubscription => product.id == kProAnnualProductId;

  String get _title => _isSubscription ? '연간 결제' : '일회성 결제';

  String get _subtitle =>
      _isSubscription ? '1년마다 자동 갱신' : '한번의 결제로 프로 기능을 영원히!';

  /// 스토어가 알려주지 않는 정가는 원화 가격일 때만 취소선으로 보여준다.
  String? get _listPrice =>
      product.currencyCode == _kKrwCurrencyCode ? _kKrwListPrice[product.id] : null;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF08080);
    final listPrice = _listPrice;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accent : Colors.black12,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          if (selectable) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accent : Colors.white,
                border: Border.all(
                  color: isSelected ? accent : Colors.black26,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (listPrice != null)
                Text(
                  listPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.black38,
                  ),
                ),
              Text(
                // 실제 청구 금액. 스토어에서 받은 현지 통화 표기를 그대로 쓴다.
                product.price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _BottomLinks extends StatelessWidget {
  const _BottomLinks({required this.onRestore});

  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey[600],
      decoration: TextDecoration.underline,
      decorationColor: Colors.grey[600],
    );
    final separator = Text(
      '  ·  ',
      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onRestore,
          child: Text('구매 복원', style: linkStyle),
        ),
        separator,
        GestureDetector(
          onTap: () => _launchUrl(_kPrivacyUrl),
          child: Text('개인정보처리방침', style: linkStyle),
        ),
        separator,
        GestureDetector(
          onTap: () => _launchUrl(_kTermsUrl),
          child: Text('이용약관', style: linkStyle),
        ),
      ],
    );
  }
}
