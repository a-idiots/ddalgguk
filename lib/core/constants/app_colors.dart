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
}
