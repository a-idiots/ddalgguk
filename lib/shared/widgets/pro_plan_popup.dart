import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ddalgguk/core/services/iap_service.dart';

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

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 40),
            Image.asset(
              'assets/imgs/pro_plan/pro_logo.png',
              height: 90,
            ),
            const SizedBox(height: 6),
            const Text(
              '딸꾹 프로 기능을 이용해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 1),
            // Vertically centered content
            Expanded(
              child: Center(
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
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
                              originalPrice: '49,000원',
                              price: '24,900원',
                              isHighlighted: true,
                              isLoading: _isLoading,
                              onTap: () =>
                                  _handlePurchase(kProLifetimeProductId),
                            ),
                            const SizedBox(height: 12),
                            _PaymentCard(
                              title: '연간 결제',
                              subtitle: '월 1,240원',
                              originalPrice: '29,000원',
                              price: '14,900원',
                              isHighlighted: false,
                              isLoading: _isLoading,
                              onTap: () =>
                                  _handlePurchase(kProAnnualProductId),
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
    required this.isHighlighted,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String originalPrice;
  final String price;
  final bool isHighlighted;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(color: const Color(0xFFF08080), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
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
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF08080),
                ),
              )
            else
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
                      color: Color(0xFFF08080),
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
