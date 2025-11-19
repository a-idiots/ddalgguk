import 'package:flutter/material.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';

class ProfileGradientBackground extends StatelessWidget {
  const ProfileGradientBackground({
    super.key,
    required this.drunkenDays,
    required this.child,
    this.reversed = false,
  });

  final int drunkenDays; // >=0
  final Widget child;
  final bool reversed; // If true, gradient goes from bottom to top

  @override
  Widget build(BuildContext context) {
    // Calculate gradient colors based on drunk level
    // Low level (0-30): Green gradient
    // Mid level (31-60): Yellow/Orange gradient
    // High level (61-100): Red/Pink gradient

    final colors = _getGradientColors(drunkenDays);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reversed ? Alignment.bottomCenter : Alignment.topCenter,
          end: reversed ? Alignment.topCenter : Alignment.bottomCenter,
          colors: reversed ? colors : [Color(0xFFFFFFFF)] + colors,
          stops: reversed ? const [0.0, 1.0] : const [0.0, 0.67, 1.0],
        ),
      ),
      child: child,
    );
  }

  List<Color> _getGradientColors(int days) {
    if (days == 0) {
      // Green gradient for low/sober state
      return const [
        Color(0xFFFFFFFF),
        AppColors.primaryGreen, // Green
      ];
    } else {
      // Red/Pink gradient for high drunk level (matches original design)
      return const [
        Color(0xFFFFFFFF),
        AppColors.primaryPink, // Pink
      ];
    }
  }
}
