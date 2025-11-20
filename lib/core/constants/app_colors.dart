import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 정의
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  /// 메인 핑크 색상 (#F27B7B)
  /// - 선택된 네비게이션 아이템
  /// - 플로팅 액션 버튼
  /// - 슬라이더 등에 사용
  static const Color primaryPink = Color(0xFFF27B7B);
  static const Color secondaryPink = Color(0xFFE35252);

  /// 메인 초록 색상 (#D3FBEB)
  /// - 금주중일 때 메인 색상
  static const Color primaryGreen = Color(0xFFD3FBE8);
  static const Color secondaryGreen = Color(0xFF27D681);

  /// 비활성화/회색 색상
  static const Color grey = Colors.grey;

  /// 배경 흰색
  static const Color white = Colors.white;

  /// Saku gradient 10 단계별 중간 색상
  /// - 친구 카드 배경색으로 사용
  /// - 술 레벨(0-100)에 따른 색상 매핑
  static const Map<int, Color> sakuGradientColors = {
    0: Color(0xFFF1FCEC), // Light green
    10: Color(0xFFFFCDC2), // Light peach
    20: Color(0xFFFBB5AB), // Peachy pink
    30: Color(0xFFFBA99E), // Coral pink
    40: Color(0xFFFF978C), // Salmon
    50: Color(0xFFFF93B3), // Pink
    60: Color(0xFFE6B5FF), // Light purple
    70: Color(0xFFAF8BFA), // Medium purple
    80: Color(0xFFBC6DF4), // Violet
    90: Color(0xFFAE3995), // Deep pink-purple
    100: Color(0xFF2C6270), // Dark teal
  };

  /// 술 레벨에 따른 배경색 반환
  /// [drunkLevel] 0-100 사이의 술 레벨 (혈중 알콜 농도%)
  /// 10단위로 반올림하여 색상 반환
  static Color getSakuBackgroundColor(int drunkLevel) {
    // 0-100 범위를 10단위로 반올림 (예: 45 -> 40, 23 -> 20)
    final level = (drunkLevel ~/ 10) * 10;
    return sakuGradientColors[level] ?? sakuGradientColors[0]!;
  }

  /// 현재 음주 상태에 따른 테마 반환
  static AppTheme getTheme(int drunkDays) {
    if (drunkDays == 0) {
      return AppTheme(
        primaryColor: primaryGreen,
        secondaryColor: secondaryGreen,
      );
    } else {
      return AppTheme(primaryColor: primaryPink, secondaryColor: secondaryPink);
    }
  }
}

class AppTheme {
  const AppTheme({required this.primaryColor, required this.secondaryColor});

  final Color primaryColor;
  final Color secondaryColor;
}
