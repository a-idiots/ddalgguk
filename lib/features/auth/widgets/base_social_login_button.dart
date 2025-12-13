import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// 버튼 테두리 (선택사항)
  BorderSide? get borderSide => null;

  /// 버튼 텍스트
  String get buttonText;

  /// 버튼 텍스트 폰트 크기 (선택사항)
  double get fontSize => 16;

  /// 버튼 텍스트 폰트 굵기 (선택사항)
  FontWeight get fontWeight => FontWeight.w600;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 52,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: borderSide ?? BorderSide.none,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                logoAssetPath,
                height: 20,
                width: 20,
                placeholderBuilder: (context) => const SizedBox.shrink(),
              ),
              Expanded(
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
