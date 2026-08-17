import 'dart:convert';
import 'dart:typed_data';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Drink {
  const Drink({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.defaultAlcoholContent,
    required this.defaultUnit,
    required this.glassVolume,
    required this.bottleVolume,
  });

  final int id;
  final String name;
  final String imagePath;
  final double defaultAlcoholContent;
  final String defaultUnit;
  final double glassVolume; // 1잔 용량 (ml)
  final double bottleVolume; // 1병 용량 (ml)
}

const List<Drink> drinks = [
  Drink(
    id: -1,
    name: '기타',
    imagePath: 'assets/imgs/alcohol_icons/undecided.png',
    defaultAlcoholContent: 0.0,
    defaultUnit: '잔',
    glassVolume: 50.0,
    bottleVolume: 360.0,
  ),
  Drink(
    id: 0,
    name: '알 수 없음',
    imagePath: 'assets/imgs/alcohol_icons/undecided.png',
    defaultAlcoholContent: 0.0,
    defaultUnit: '잔',
    glassVolume: 50.0,
    bottleVolume: 360.0,
  ),
  Drink(
    id: 1,
    name: '소주',
    imagePath: 'assets/imgs/alcohol_icons/soju.png',
    defaultAlcoholContent: 16.5,
    defaultUnit: '병',
    glassVolume: 50.0,
    bottleVolume: 360.0,
  ),
  Drink(
    id: 2,
    name: '맥주',
    imagePath: 'assets/imgs/alcohol_icons/beer.png',
    defaultAlcoholContent: 5.0,
    defaultUnit: 'ml',
    glassVolume: 300.0,
    bottleVolume: 500.0,
  ),
  Drink(
    id: 3,
    name: '칵테일',
    imagePath: 'assets/imgs/alcohol_icons/cocktail.png',
    defaultAlcoholContent: 10.0,
    defaultUnit: '잔',
    glassVolume: 200.0,
    bottleVolume: 0.0, // 병 없음
  ),
  Drink(
    id: 4,
    name: '와인',
    imagePath: 'assets/imgs/alcohol_icons/wine.png',
    defaultAlcoholContent: 12.0,
    defaultUnit: '잔',
    glassVolume: 150.0,
    bottleVolume: 750.0,
  ),
  Drink(
    id: 5,
    name: '막걸리',
    imagePath: 'assets/imgs/alcohol_icons/makgulli.png',
    defaultAlcoholContent: 6.0,
    defaultUnit: '병',
    glassVolume: 200.0,
    bottleVolume: 750.0,
  ),
  Drink(
    id: 6,
    name: '위스키',
    imagePath: 'assets/imgs/alcohol_icons/whiskey.png',
    defaultAlcoholContent: 40.0,
    defaultUnit: '잔',
    glassVolume: 30.0,
    bottleVolume: 750.0,
  ),
  Drink(
    id: 7,
    name: '하이볼',
    imagePath: 'assets/imgs/alcohol_icons/highball.png',
    defaultAlcoholContent: 7.0,
    defaultUnit: '잔',
    glassVolume: 300.0,
    bottleVolume: 0.0, // 병 없음
  ),
  Drink(
    id: 8,
    name: '사케',
    imagePath: 'assets/imgs/alcohol_icons/sake.png',
    defaultAlcoholContent: 15.0,
    defaultUnit: '잔',
    glassVolume: 30.0,
    bottleVolume: 180.0,
  ),
  Drink(
    id: 9,
    name: '보드카',
    imagePath: 'assets/imgs/alcohol_icons/vodka.png',
    defaultAlcoholContent: 40.0,
    defaultUnit: '잔',
    glassVolume: 30.0,
    bottleVolume: 750.0,
  ),
];

// Custom drinks cache
List<Drink> _customDrinksCache = [];

// 커스텀 주종 아이콘(업로드 이미지) 인메모리 캐시 — drinkId → JPEG bytes.
Map<int, Uint8List> _customDrinkIconCache = {};

/// Initialize custom drinks cache from SharedPreferences
Future<void> initializeDrinkHelper() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(
      StorageKeys.customDrinks,
    );

    if (jsonList != null) {
      _customDrinksCache = jsonList.map((jsonStr) {
        final Map<String, dynamic> json =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        return Drink(
          id: json['id'] as int,
          name: json['name'] as String,
          imagePath:
              json['imagePath'] as String? ??
              'assets/imgs/alcohol_icons/soju.png',
          defaultAlcoholContent: (json['defaultAlcoholContent'] as num)
              .toDouble(),
          defaultUnit: json['defaultUnit'] as String? ?? '잔',
          glassVolume: (json['glassVolume'] as num?)?.toDouble() ?? 50.0,
          bottleVolume: (json['bottleVolume'] as num?)?.toDouble() ?? 360.0,
        );
      }).toList();
    }

    final iconsRaw = prefs.getString(StorageKeys.customDrinkIcons);
    if (iconsRaw != null) {
      final map = jsonDecode(iconsRaw) as Map<String, dynamic>;
      final newCache = <int, Uint8List>{};
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is String) {
          try {
            newCache[id] = base64Decode(v);
          } catch (_) {}
        }
      });
      _customDrinkIconCache = newCache;
    }
  } catch (e) {
    debugPrint('Failed to initialize drink helper: $e');
  }
}

/// Update custom drinks cache manually
void updateCustomDrinksCache(List<Drink> newCache) {
  _customDrinksCache = newCache;
}

/// 커스텀 주종 아이콘(업로드 이미지) 캐시 교체.
void updateCustomDrinkIconCache(Map<int, Uint8List> newCache) {
  _customDrinkIconCache = Map<int, Uint8List>.from(newCache);
}

/// 현재 캐시의 읽기 전용 스냅샷.
Map<int, Uint8List> customDrinkIconCacheSnapshot() =>
    Map<int, Uint8List>.unmodifiable(_customDrinkIconCache);

/// 업로드된 커스텀 아이콘 바이트 조회. 없으면 null.
Uint8List? getCustomDrinkIconBytes(int drinkId) =>
    _customDrinkIconCache[drinkId];

/// Find a drink by ID (checks standard then custom)
Drink? _findDrink(int id) {
  return drinks.where((d) => d.id == id).firstOrNull ??
      _customDrinksCache.where((d) => d.id == id).firstOrNull;
}

/// 술 종류에 따른 아이콘 반환
Widget getDrinkIcon(int drinkType) {
  final iconPath = getDrinkIconPath(drinkType);
  final customId = _extractCustomIconId(iconPath);
  if (customId != null) {
    final bytes = _customDrinkIconCache[customId];
    if (bytes != null) {
      // 업로드 사진은 원형으로 크롭 (짧은 변 기준 cover).
      return ClipOval(
        child: Image.memory(bytes, width: 28, height: 28, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      'assets/imgs/alcohol_icons/undecided.png',
      width: 28,
      height: 28,
      fit: BoxFit.contain,
    );
  }
  return Image.asset(iconPath, width: 28, height: 28, fit: BoxFit.contain);
}

const String _customIconPrefix = 'custom://';
int? _extractCustomIconId(String imagePath) {
  if (!imagePath.startsWith(_customIconPrefix)) {
    return null;
  }
  return int.tryParse(imagePath.substring(_customIconPrefix.length));
}

/// 술 종류에 따른 아이콘 경로 반환
String getDrinkIconPath(int drinkType) {
  final drink = _findDrink(drinkType);
  return drink?.imagePath ?? 'assets/imgs/alcohol_icons/undecided.png';
}

/// 주종별 기본 도수
double getDefaultAlcoholContent(int drinkType) {
  final drink = _findDrink(drinkType);
  return drink?.defaultAlcoholContent ?? 0.0;
}

/// 주종별 기본 단위
String getDefaultUnit(int drinkType) {
  final drink = _findDrink(drinkType);
  return drink?.defaultUnit ?? '잔';
}

/// 주종별 단위를 ml로 변환
/// drinkType: 주종 ID, unit: 단위 (잔/병/ml)
double getUnitMultiplier(int drinkType, String unit) {
  final drink = _findDrink(drinkType);

  if (drink == null) {
    // 주종을 찾을 수 없는 경우 기본값 반환
    switch (unit) {
      case '병':
        return 360.0;
      case '잔':
        return 50.0;
      case 'ml':
        return 1.0;
      default:
        return 1.0;
    }
  }

  switch (unit) {
    case '병':
      return drink.bottleVolume;
    case '잔':
      return drink.glassVolume;
    case 'ml':
      return 1.0;
    default:
      return 1.0;
  }
}

/// 주종 이름
String getDrinkTypeName(int drinkType) {
  final drink = _findDrink(drinkType);
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
