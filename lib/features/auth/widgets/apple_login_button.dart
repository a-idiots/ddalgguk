import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/widgets/base_social_login_button.dart';

/// Apple Login Button Widget
class AppleLoginButton extends BaseSocialLoginButton {
  const AppleLoginButton({
    required super.onPressed,
    super.isLoading = false,
    super.key,
  });

  @override
  Color get backgroundColor => Colors.black;

  @override
  Color get foregroundColor => Colors.white;

  @override
  String get logoAssetPath => 'assets/images/apple_logo.png';

  @override
  IconData get fallbackIcon => Icons.apple;

  @override
  String get buttonText => 'Apple로 계속하기';

  @override
  Color get progressIndicatorColor => Colors.white;

  @override
  Color? get logoColor => Colors.white;

  @override
  double get fallbackIconSize => 28;
}
