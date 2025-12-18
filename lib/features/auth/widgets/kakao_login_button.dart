import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/widgets/base_social_login_button.dart';

/// Kakao Login Button Widget
/// 카카오 디자인 가이드라인 준수:
/// - 색상: #FEE500 (카카오 노란색)
/// - 텍스트: "카카오 로그인" 또는 "로그인"
/// - 모서리 반경: 12px
/// - 심볼: 말풍선 모양
class KakaoLoginButton extends BaseSocialLoginButton {
  const KakaoLoginButton({
    required super.onPressed,
    super.isLoading = false,
    super.key,
  });

  @override
  Color get backgroundColor => const Color(0xFFFEE500); // Kakao Yellow #FEE500

  @override
  Color get foregroundColor => Colors.black.withValues(alpha: 0.85); // 85% opacity

  @override
  String get logoAssetPath => 'assets/imgs/login_icon/kakao_logo.svg';

  @override
  String get buttonText => '카카오 로그인';
}
