import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.white,
      child: Container(
        height: 80, // Fixed height to prevent layout shifts
        padding: const EdgeInsets.only(top: 6, bottom: 24, left: 4, right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 5;
            final itemHeight = constraints.maxHeight;

            return Stack(
              children: [
                // Sliding Highlight Pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: currentIndex * itemWidth,
                  top: 0,
                  width: itemWidth,
                  height: itemHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F2F2F),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                // Navigation Items
                Row(
                  children: [
                    _buildNavItem(0, Icons.person, '마이페이지', itemWidth),
                    _buildNavItem(1, Icons.people, '친구', itemWidth),
                    _buildNavItem(2, Icons.calendar_today, '캘린더', itemWidth),
                    _buildNavItem(3, Icons.bar_chart, '리포트', itemWidth),
                    _buildNavItem(4, Icons.settings, '설정', itemWidth),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, double width) {
    final isSelected = currentIndex == index;

    // Colors
    final color = isSelected ? const Color(0xFFF27B7B) : Colors.grey[400];

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: icon == Icons.calendar_today ? 20 : 24,
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
