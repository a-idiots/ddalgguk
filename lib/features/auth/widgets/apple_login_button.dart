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
  String get logoAssetPath => 'assets/login_icon/apple_logo.svg';

  @override
  String get buttonText => '애플로 로그인';
}
