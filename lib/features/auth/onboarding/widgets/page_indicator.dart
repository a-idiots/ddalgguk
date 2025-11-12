import 'package:flutter/material.dart';

/// Page indicator widget (navigation dots)
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    this.activeColor = const Color.fromRGBO(217, 00, 00, 1),
    this.inactiveColor = const Color.fromRGBO(239, 239, 239, 1),
    this.dotSize = 8.0,
    this.spacing = 8.0,
  });

  final int currentPage;
  final int pageCount;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        pageCount,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentPage == index ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
