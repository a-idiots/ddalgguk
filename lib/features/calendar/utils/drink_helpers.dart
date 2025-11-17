import 'package:flutter/material.dart';

/// 술 종류에 따른 아이콘 반환
Widget getDrinkIcon(int drinkType) {
  final iconPath = getDrinkIconPath(drinkType);
  return Image.asset(iconPath, width: 28, height: 28, fit: BoxFit.contain);
}

/// 술 종류에 따른 아이콘 경로 반환
String getDrinkIconPath(int drinkType) {
  switch (drinkType) {
    case 1: // 소주
      return 'assets/alcohol_icons/soju.png';
    case 2: // 맥주
      return 'assets/alcohol_icons/beer.png';
    case 3: // 와인
      return 'assets/alcohol_icons/wine.png';
    case 4: // 막걸리
      return 'assets/alcohol_icons/makgulli.png';
    case 5: // 칵테일
      return 'assets/alcohol_icons/cocktail.png';
    case 6: // 기타
      return 'assets/alcohol_icons/undecided.png';
    default: // 미정
      return 'assets/alcohol_icons/undecided.png';
  }
}

/// 주종별 기본 도수
double getDefaultAlcoholContent(int drinkType) {
  switch (drinkType) {
    case 1: // 소주
      return 16.5;
    case 2: // 맥주
      return 5.0;
    case 3: // 와인
      return 12.0;
    case 4: // 막걸리
      return 4.0;
    case 5: // 칵테일
      return 0.0;
    case 6: // 기타
      return 0.0;
    default: // 미정
      return 0.0;
  }
}

/// 주종별 기본 단위
String getDefaultUnit(int drinkType) {
  switch (drinkType) {
    case 1: // 소주
      return '병';
    case 2: // 맥주
      return 'ml';
    case 3: // 와인
      return '잔';
    case 4: // 막걸리
      return '병';
    case 5: // 칵테일
      return '잔';
    case 6: // 기타
      return '잔';
    default: // 미정
      return '병';
  }
}

/// 단위별 ml 변환
double getUnitMultiplier(String unit) {
  switch (unit) {
    case '병':
      return 500.0;
    case '잔':
      return 150.0;
    case 'ml':
      return 1.0;
    default:
      return 500.0;
  }
}

/// 주종 이름
String getDrinkTypeName(int drinkType) {
  switch (drinkType) {
    case 1:
      return '소주';
    case 2:
      return '맥주';
    case 3:
      return '와인';
    case 4:
      return '막걸리';
    case 5:
      return '칵테일';
    case 6:
      return '기타';
    default:
      return '미정';
  }
}

/// 알딸딸 지수에 따른 body 이미지 경로 반환
String getBodyImagePath(int drunkLevel) {
  // drunkLevel: 0-100
  // Round down to nearest 10 (e.g., 45 -> 40, 23 -> 20)
  final level = (drunkLevel ~/ 10) * 10;
  return 'assets/saku_gradient_10/saku_${level.toString().padLeft(2, '0')}.png';
}

/// 음주량 포맷팅 (간단 버전)
String formatDrinkAmount(double amountInMl) {
  if (amountInMl >= 1000) {
    final bottles = amountInMl / 500;
    if (bottles % 1 == 0) {
      return '${bottles.toInt()}병';
    }
    return '${bottles.toStringAsFixed(1)}병';
  } else if (amountInMl >= 150) {
    final glasses = amountInMl / 150;
    if (glasses % 1 == 0) {
      return '${glasses.toInt()}잔';
    }
    return '${glasses.toStringAsFixed(1)}잔';
  } else {
    return '${amountInMl.toInt()}ml';
  }
}
