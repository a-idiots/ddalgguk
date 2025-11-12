import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/widgets/base_social_login_button.dart';

/// Kakao Login Button Widget
class KakaoLoginButton extends BaseSocialLoginButton {
  const KakaoLoginButton({
    required super.onPressed,
    super.isLoading = false,
    super.key,
  });

  @override
  Color get backgroundColor => const Color(0xFFFEE500); // Kakao Yellow

  @override
  Color get foregroundColor => Colors.black87;

  @override
  String get logoAssetPath => 'assets/images/kakao_logo.png';

  @override
  IconData get fallbackIcon => Icons.chat_bubble;

  @override
  String get buttonText => '카카오로 계속하기';

  @override
  Color get progressIndicatorColor => Colors.black54;
}
