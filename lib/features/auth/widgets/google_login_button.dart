import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/widgets/base_social_login_button.dart';

/// Google Login Button Widget
class GoogleLoginButton extends BaseSocialLoginButton {
  const GoogleLoginButton({
    required super.onPressed,
    super.isLoading = false,
    super.key,
  });

  @override
  Color get backgroundColor => Colors.white;

  @override
  Color get foregroundColor => Colors.black87;

  @override
  String get logoAssetPath => 'assets/images/google_logo.png';

  @override
  IconData get fallbackIcon => Icons.g_mobiledata;

  @override
  String get buttonText => 'Google로 계속하기';

  @override
  Color get progressIndicatorColor => Colors.black54;

  @override
  BorderSide? get borderSide => BorderSide(
        color: Colors.grey.shade300,
        width: 1,
      );

  @override
  double get fallbackIconSize => 32;
}
