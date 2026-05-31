import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/features/settings/services/custom_drink_icon_service.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final drinkSettingsServiceProvider = Provider<DrinkSettingsService>((ref) {
  return DrinkSettingsService(ref);
});

class DrinkSettingsService {
  DrinkSettingsService(this._ref);

  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // mainDrinkIds
  // ---------------------------------------------------------------------------

  /// SharedPreferences → Firestore 순으로 로드 (재로그인 후 복구 포함).
  /// 유효한 메인 주종 ID(표준 1–9, 커스텀 ≥ 1000)만 반환 — 과거 데이터에 섞일 수
  /// 있는 -1(기타)/0(알 수 없음) 등은 제거.
  Future<List<int>> loadMainDrinkIds() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(StorageKeys.mainDrinkIds);
    if (cached != null && cached.isNotEmpty) {
      return cached.map(int.parse).where((id) => id > 0).toList();
    }

    // 캐시 없으면 Firestore에서 복구
    final uid = _uid;
    if (uid == null) {
      return [];
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final raw = doc.data()?['mainDrinkIds'];
    if (raw == null) {
      return [];
    }

    final ids = List<int>.from(raw as List).where((id) => id > 0).toList();
    // 로컬에 캐시해 다음 로드 속도 개선
    await prefs.setStringList(
      StorageKeys.mainDrinkIds,
      ids.map((e) => e.toString()).toList(),
    );
    return ids;
  }

  /// SharedPreferences + Firestore 동시 저장. 유효 ID만 저장.
  Future<void> saveMainDrinkIds(List<int> ids) async {
    final clean = ids.where((id) => id > 0).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      StorageKeys.mainDrinkIds,
      clean.map((e) => e.toString()).toList(),
    );

    final uid = _uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'mainDrinkIds': clean,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // customDrinks
  // ---------------------------------------------------------------------------

  /// SharedPreferences → Firestore 순으로 로드 (재로그인 후 복구 포함)
  Future<List<Drink>> loadCustomDrinks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(StorageKeys.customDrinks);

    if (jsonList != null && jsonList.isNotEmpty) {
      final drinks = _parseDrinksFromJsonList(jsonList);
      updateCustomDrinksCache(drinks);
      _restoreIconCacheFromPrefs(prefs);
      return drinks;
    }

    // 캐시 없으면 Firestore에서 복구
    final uid = _uid;
    if (uid == null) {
      updateCustomDrinksCache([]);
      return [];
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final raw = doc.data()?['customDrinks'];
    if (raw == null) {
      updateCustomDrinksCache([]);
      return [];
    }

    final drinks = (raw as List).map((item) {
      final json = Map<String, dynamic>.from(item as Map);
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

    // 로컬에 캐시
    await _saveCustomDrinksInternal(prefs, drinks);

    // 업로드된 아이콘이 있는 주종이 하나라도 있으면 Firestore에서 아이콘 일괄 복원.
    if (drinks.any((d) => parseCustomDrinkIconId(d.imagePath) != null)) {
      await _ref.read(customDrinkIconServiceProvider).restoreFromFirestore();
    }
    return drinks;
  }

  Future<void> addCustomDrink(Drink drink) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomDrinks();
    if (current.any((d) => d.id == drink.id)) {
      return;
    }

    current.add(drink);
    await _saveCustomDrinksInternal(prefs, current);

    final uid = _uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'customDrinks': _drinksToFirestoreList(current),
      });
    }
  }

  Future<void> deleteCustomDrink(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomDrinks();
    final removed = current.where((d) => d.id == id).firstOrNull;
    current.removeWhere((d) => d.id == id);
    await _saveCustomDrinksInternal(prefs, current);

    final uid = _uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'customDrinks': _drinksToFirestoreList(current),
      });
    }

    // 업로드한 아이콘이었다면 스토리지/캐시에서도 제거.
    if (removed != null && parseCustomDrinkIconId(removed.imagePath) != null) {
      await _ref.read(customDrinkIconServiceProvider).delete(id);
    }
  }

  Future<void> removeCustomDrink(int id) => deleteCustomDrink(id);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// SharedPreferences에 저장된 base64 아이콘을 인메모리 캐시에 복원.
  /// 캐시가 이미 채워져 있으면 건너뛴다 (cold start 직후 한 번만 비용 부담).
  void _restoreIconCacheFromPrefs(SharedPreferences prefs) {
    if (customDrinkIconCacheSnapshot().isNotEmpty) {
      return;
    }
    final raw = prefs.getString(StorageKeys.customDrinkIcons);
    if (raw == null) {
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final newCache = <int, Uint8List>{};
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is String) {
          try {
            newCache[id] = base64Decode(v);
          } catch (_) {}
        }
      });
      if (newCache.isNotEmpty) {
        updateCustomDrinkIconCache(newCache);
      }
    } catch (_) {}
  }

  List<Drink> _parseDrinksFromJsonList(List<String> jsonList) {
    return jsonList.map((jsonStr) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
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

  Future<void> _saveCustomDrinksInternal(
    SharedPreferences prefs,
    List<Drink> drinks,
  ) async {
    final jsonList = drinks.map((drink) {
      return jsonEncode({
        'id': drink.id,
        'name': drink.name,
        'imagePath': drink.imagePath,
        'defaultAlcoholContent': drink.defaultAlcoholContent,
        'defaultUnit': drink.defaultUnit,
        'glassVolume': drink.glassVolume,
        'bottleVolume': drink.bottleVolume,
      });
    }).toList();

    await prefs.setStringList(StorageKeys.customDrinks, jsonList);
    updateCustomDrinksCache(drinks);
  }

  List<Map<String, dynamic>> _drinksToFirestoreList(List<Drink> drinks) {
    return drinks
        .map(
          (d) => {
            'id': d.id,
            'name': d.name,
            'imagePath': d.imagePath,
            'defaultAlcoholContent': d.defaultAlcoholContent,
            'defaultUnit': d.defaultUnit,
            'glassVolume': d.glassVolume,
            'bottleVolume': d.bottleVolume,
          },
        )
        .toList();
  }
}
