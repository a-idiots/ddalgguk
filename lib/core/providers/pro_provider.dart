import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kProKey = 'pro_enabled';
const _kLegacyProKey = 'debug_pro_enabled';

/// 무료 유저 고정 기본 주종 ID: 소주, 맥주, 막걸리, 와인, 칵테일
const List<int> kFreeDefaultDrinkIds = [1, 2, 5, 4, 3];

class ProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    // 구(舊) 키(`debug_pro_enabled`)에 저장된 값이 있으면 새 키로 이관.
    if (!prefs.containsKey(_kProKey) && prefs.containsKey(_kLegacyProKey)) {
      final legacy = prefs.getBool(_kLegacyProKey) ?? false;
      await prefs.setBool(_kProKey, legacy);
      await prefs.remove(_kLegacyProKey);
    }
    return prefs.getBool(_kProKey) ?? false;
  }

  Future<void> setValue(bool value) async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProKey, value);
    state = AsyncValue.data(value);
  }
}

final proProvider = AsyncNotifierProvider<ProNotifier, bool>(ProNotifier.new);
