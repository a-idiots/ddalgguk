import 'package:flutter/material.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';

class ProfileGradientBackground extends StatelessWidget {
  const ProfileGradientBackground({
    super.key,
    required this.theme,
    required this.child,
    this.reversed = false,
  });

  final AppTheme theme;
  final Widget child;
  final bool reversed; // If true, gradient goes from bottom to top

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: reversed
              ? [theme.primaryColor, AppColors.white, AppColors.white]
              : [AppColors.white, AppColors.white, theme.primaryColor],
          stops: reversed ? const [0.0, 0.2, 1.0] : const [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}
