import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  String get logoAssetPath => 'assets/imgs/login_icon/apple_logo.svg';

  @override
  String get buttonText => 'Apple로 로그인';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 52,
      child: SignInWithAppleButton(
        onPressed: isLoading ? () {} : onPressed,
        text: buttonText,
        height: 52,
        borderRadius: BorderRadius.circular(26),
        style: SignInWithAppleButtonStyle.black,
      ),
    );
  }
}
