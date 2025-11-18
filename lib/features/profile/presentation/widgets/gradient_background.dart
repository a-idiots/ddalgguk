import 'package:flutter/material.dart';

class ProfileGradientBackground extends StatelessWidget {
  const ProfileGradientBackground({
    super.key,
    required this.drunkLevel,
    required this.child,
  });

  final int drunkLevel; // 0-100
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Calculate gradient colors based on drunk level
    // Low level (0-30): Green gradient
    // Mid level (31-60): Yellow/Orange gradient
    // High level (61-100): Red/Pink gradient

    final colors = _getGradientColors(drunkLevel);

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

  List<Color> _getGradientColors(int level) {
    if (level <= 30) {
      // Green gradient for low/sober state
      return const [
        Color(0xFFA3FFB3), // Light green
        Color(0xFF52E370), // Green
      ];
    } else if (level <= 60) {
      // Orange/Yellow gradient for moderate state
      return const [
        Color(0xFFFFCBA3), // Light orange
        Color(0xFFFFA552), // Orange
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
