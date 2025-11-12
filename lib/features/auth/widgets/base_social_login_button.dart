import 'package:flutter/material.dart';

/// Base Social Login Button Widget
/// 모든 소셜 로그인 버튼의 공통 구조를 정의하는 추상 클래스
abstract class BaseSocialLoginButton extends StatelessWidget {
  const BaseSocialLoginButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  /// 버튼 배경색
  Color get backgroundColor;

  /// 버튼 전경색 (텍스트 및 아이콘 색상)
  Color get foregroundColor;

  /// 로고 이미지 경로
  String get logoAssetPath;

  /// 이미지 로드 실패 시 대체 아이콘
  IconData get fallbackIcon;

  /// 버튼 텍스트
  String get buttonText;

  /// 로딩 인디케이터 색상
  Color get progressIndicatorColor;

  /// 버튼 테두리 (선택사항)
  BorderSide? get borderSide => null;

  /// 로고 색상 (선택사항)
  Color? get logoColor => null;

  /// fallback 아이콘 크기 (선택사항)
  double get fallbackIconSize => 24;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderSide ?? BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressIndicatorColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    logoAssetPath,
                    height: 24,
                    width: 24,
                    color: logoColor,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image is not found
                      return Icon(
                        fallbackIcon,
                        size: fallbackIconSize,
                        color: foregroundColor,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
