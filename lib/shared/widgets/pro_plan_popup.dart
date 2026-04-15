import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/core/services/iap_service.dart';

const _kTermsUrl =
    'https://melodic-music-7c1.notion.site/2cd5a6752e1b80889671e04b2283c00d';
const _kPrivacyUrl =
    'https://melodic-music-7c1.notion.site/2cb5a6752e1b80eeb44dc1763020d324';

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
  bool _isLoading = false;
  // 기본 선택: 일회성 결제 (기존 강조와 동일).
  String _selectedProductId = kProLifetimeProductId;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(String productId) async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final error = await ref.read(iapServiceProvider).buy(productId);
      if (!mounted) {
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(iapServiceProvider).restorePurchases();
      if (!mounted) {
        return;
      }
      // 복원 결과는 purchaseStream을 통해 proProvider에 반영됨
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) {
        return;
      }
      final isPro = ref.read(proProvider).valueOrNull ?? false;
      if (isPro) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('복원할 구매 내역이 없습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                  onPressed: () => Navigator.of(context).pop(),
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
                        child: Column(
                          children: [
                            _PaymentCard(
                              title: '일회성 결제',
                              subtitle: '한번의 결제로 프로 기능을 영원히!',
                              originalPrice: '29,900원',
                              price: '19,900원',
                              isSelected:
                                  _selectedProductId == kProLifetimeProductId,
                              onTap: _isLoading
                                  ? null
                                  : () => setState(
                                        () => _selectedProductId =
                                            kProLifetimeProductId,
                                      ),
                            ),
                            const SizedBox(height: 12),
                            _PaymentCard(
                              title: '연간 결제',
                              subtitle: '월 825원 (자동갱신)',
                              originalPrice: '14,900원',
                              price: '9,900원',
                              isSelected:
                                  _selectedProductId == kProAnnualProductId,
                              onTap: _isLoading
                                  ? null
                                  : () => setState(
                                        () => _selectedProductId =
                                            kProAnnualProductId,
                                      ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () =>
                                          _handlePurchase(_selectedProductId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF08080),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFF08080,
                                  ).withValues(alpha: 0.5),
                                  disabledForegroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        '딸꾹PRO 구독하기',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _BottomLinks(
                              onRestore: _isLoading ? null : _handleRestore,
                            ),
                          ],
                        ),
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
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.title,
    required this.subtitle,
    required this.originalPrice,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String originalPrice;
  final String price;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF08080);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
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
            // Radio indicator — 왼쪽, 세로 중앙.
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  originalPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.black38,
                  ),
                ),
                Text(
                  price,
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
      ),
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
