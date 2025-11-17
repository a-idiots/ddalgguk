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
  String get logoAssetPath => 'assets/login_icon/google_logo.svg';

  @override
  BorderSide? get borderSide =>
    BorderSide(color: Colors.grey.shade300, width: 1);

  @override
  String get buttonText => '구글로 로그인';
}
