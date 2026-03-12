import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final drinkSettingsServiceProvider = Provider<DrinkSettingsService>((ref) {
  return DrinkSettingsService();
});

class DrinkSettingsService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // mainDrinkIds
  // ---------------------------------------------------------------------------

  /// SharedPreferences → Firestore 순으로 로드 (재로그인 후 복구 포함)
  Future<List<int>> loadMainDrinkIds() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(StorageKeys.mainDrinkIds);
    if (cached != null && cached.isNotEmpty) {
      return cached.map(int.parse).toList();
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

    final ids = List<int>.from(raw as List);
    // 로컬에 캐시해 다음 로드 속도 개선
    await prefs.setStringList(
      StorageKeys.mainDrinkIds,
      ids.map((e) => e.toString()).toList(),
    );
    return ids;
  }

  /// SharedPreferences + Firestore 동시 저장
  Future<void> saveMainDrinkIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      StorageKeys.mainDrinkIds,
      ids.map((e) => e.toString()).toList(),
    );

    final uid = _uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'mainDrinkIds': ids,
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
        defaultAlcoholContent:
            (json['defaultAlcoholContent'] as num).toDouble(),
        defaultUnit: json['defaultUnit'] as String? ?? '잔',
        glassVolume: (json['glassVolume'] as num?)?.toDouble() ?? 50.0,
        bottleVolume: (json['bottleVolume'] as num?)?.toDouble() ?? 360.0,
      );
    }).toList();

    // 로컬에 캐시
    await _saveCustomDrinksInternal(prefs, drinks);
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
    current.removeWhere((d) => d.id == id);
    await _saveCustomDrinksInternal(prefs, current);

    final uid = _uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'customDrinks': _drinksToFirestoreList(current),
      });
    }
  }

  Future<void> removeCustomDrink(int id) => deleteCustomDrink(id);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<Drink> _parseDrinksFromJsonList(List<String> jsonList) {
    return jsonList.map((jsonStr) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Drink(
        id: json['id'] as int,
        name: json['name'] as String,
        imagePath:
            json['imagePath'] as String? ??
            'assets/imgs/alcohol_icons/soju.png',
        defaultAlcoholContent:
            (json['defaultAlcoholContent'] as num).toDouble(),
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
