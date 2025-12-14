import 'package:flutter/material.dart';

class Drink {
  const Drink({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.defaultAlcoholContent,
    required this.defaultUnit,
  });

  final int id;
  final String name;
  final String imagePath;
  final double defaultAlcoholContent;
  final String defaultUnit;
}

const List<Drink> drinks = [
  Drink(
    id: 0,
    name: '알 수 없음',
    imagePath: 'assets/imgs/alcohol_icons/undecided.png',
    defaultAlcoholContent: 0.0,
    defaultUnit: '잔',
  ),
  Drink(
    id: 1,
    name: '소주',
    imagePath: 'assets/imgs/alcohol_icons/soju.png',
    defaultAlcoholContent: 16.5,
    defaultUnit: '병',
  ),
  Drink(
    id: 2,
    name: '맥주',
    imagePath: 'assets/imgs/alcohol_icons/beer.png',
    defaultAlcoholContent: 5.0,
    defaultUnit: 'ml',
  ),
  Drink(
    id: 3,
    name: '칵테일',
    imagePath: 'assets/imgs/alcohol_icons/cocktail.png',
    defaultAlcoholContent: 10.0,
    defaultUnit: '잔',
  ),
  Drink(
    id: 4,
    name: '와인',
    imagePath: 'assets/imgs/alcohol_icons/wine.png',
    defaultAlcoholContent: 12.0,
    defaultUnit: '잔',
  ),
  Drink(
    id: 5,
    name: '막걸리',
    imagePath: 'assets/imgs/alcohol_icons/makgulli.png',
    defaultAlcoholContent: 6.0,
    defaultUnit: '병',
  ),
  Drink(
    id: 6,
    name: '위스키',
    imagePath: 'assets/imgs/alcohol_icons/whiskey.png',
    defaultAlcoholContent: 40.0,
    defaultUnit: '잔',
  ),
];

/// 술 종류에 따른 아이콘 반환
Widget getDrinkIcon(int drinkType) {
  final iconPath = getDrinkIconPath(drinkType);
  return Image.asset(iconPath, width: 28, height: 28, fit: BoxFit.contain);
}

/// 술 종류에 따른 아이콘 경로 반환
String getDrinkIconPath(int drinkType) {
  final drink = drinks.where((d) => d.id == drinkType).firstOrNull;
  return drink?.imagePath ?? 'assets/imgs/alcohol_icons/undecided.png';
}

/// 주종별 기본 도수
double getDefaultAlcoholContent(int drinkType) {
  final drink = drinks.where((d) => d.id == drinkType).firstOrNull;
  return drink?.defaultAlcoholContent ?? 0.0;
}

/// 주종별 기본 단위
String getDefaultUnit(int drinkType) {
  final drink = drinks.where((d) => d.id == drinkType).firstOrNull;
  return drink?.defaultUnit ?? '잔';
}

/// 단위별 ml 변환
double getUnitMultiplier(String unit) {
  switch (unit) {
    case '병':
      return 360.0; // 소주 기준 (일반적으로 360ml) - 하지만 막걸리는 750ml, 맥주는 500ml 등 다양함.
    // TODO: 주종별 병 용량 차이 처리가 필요할 수 있음. 현재는 단순 단위 변환만 수행.
    case '잔':
      return 50.0; // 소주잔 기준? 와인잔 150ml? 위스키잔 30ml?
    // 로직 수정 필요할 수 있으나 기존 로직 유지
    case 'ml':
      return 1.0;
    default:
      return 1.0;
  }
}

/// 주종 이름
String getDrinkTypeName(int drinkType) {
  final drink = drinks.where((d) => d.id == drinkType).firstOrNull;
  return drink?.name ?? '기타';
}

/// 알딸딸 지수에 따른 body 이미지 경로 반환
String getBodyImagePath(int drunkLevel) {
  // drunkLevel: 0-100, but clamp to ensure it's in valid range
  // Round down to nearest 10 (e.g., 45 -> 40, 23 -> 20)
  final clampedLevel = drunkLevel.clamp(0, 100);
  final level = (clampedLevel ~/ 10) * 10;
  return 'assets/imgs/saku_gradient_10/saku_${level.toString().padLeft(2, '0')}.png';
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
