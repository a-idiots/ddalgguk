import 'package:flutter/material.dart';

class ProfileGradientBackground extends StatelessWidget {
  const ProfileGradientBackground({
    super.key,
    required this.drunkenDays,
    required this.child,
  });

  final int drunkenDays; // >=0
  final Widget child;

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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.85],
        ),
      ),
      child: child,
    );
  }

  List<Color> _getGradientColors(int days) {
    if (days == 0) {
      // Green gradient for low/sober state
      return const [
        Color(0xFFFFFFFF), // Light green
        Color(0xFFD3FBE8), // Green
      ];
    } else {
      // Red/Pink gradient for high drunk level (matches original design)
      return const [
        Color(0xFFFFA3A3), // Light pink/red
        Color(0xFFE35252), // Red
      ];
    }
  }
}
