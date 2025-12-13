import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple Login Button Widget
class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 52,
      child: SignInWithAppleButton(
        onPressed: isLoading ? () {} : onPressed,
        text: 'Apple로 로그인',
        height: 52,
        borderRadius: BorderRadius.circular(26),
        style: SignInWithAppleButtonStyle.black,
      ),
    );
  }
}
