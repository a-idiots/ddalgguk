import 'dart:convert';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final drinkSettingsServiceProvider = Provider<DrinkSettingsService>((ref) {
  return DrinkSettingsService();
});

class DrinkSettingsService {
  Future<List<int>> loadMainDrinkIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? ids = prefs.getStringList(StorageKeys.mainDrinkIds);
    if (ids == null) {
      return [];
    }
    return ids.map((e) => int.parse(e)).toList();
  }

  Future<void> saveMainDrinkIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      StorageKeys.mainDrinkIds,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<List<Drink>> loadCustomDrinks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(
      StorageKeys.customDrinks,
    );

    if (jsonList == null) {
      return [];
    }

    return jsonList.map((jsonStr) {
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

  Future<void> addCustomDrink(Drink drink) async {
    final prefs = await SharedPreferences.getInstance();
    final customDrinks = await loadCustomDrinks();

    // Check for duplicate ID just in case
    if (customDrinks.any((d) => d.id == drink.id)) {
      return;
    }

    customDrinks.add(drink);
    await _saveCustomDrinksInternal(prefs, customDrinks);
  }

  Future<void> removeCustomDrink(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final customDrinks = await loadCustomDrinks();
    customDrinks.removeWhere((d) => d.id == id);
    await _saveCustomDrinksInternal(prefs, customDrinks);
  }

  Future<void> _saveCustomDrinksInternal(
    SharedPreferences prefs,
    List<Drink> drinks,
  ) async {
    final List<String> jsonList = drinks.map((drink) {
      final Map<String, dynamic> json = {
        'id': drink.id,
        'name': drink.name,
        'imagePath': drink.imagePath,
        'defaultAlcoholContent': drink.defaultAlcoholContent,
        'defaultUnit': drink.defaultUnit,
        'glassVolume': drink.glassVolume,
        'bottleVolume': drink.bottleVolume,
      };
      return jsonEncode(json);
    }).toList();

    await prefs.setStringList(StorageKeys.customDrinks, jsonList);
  }
}
