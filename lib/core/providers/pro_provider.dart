import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kProKey = 'debug_pro_enabled';

/// 무료 유저 고정 기본 주종 ID: 소주, 맥주, 막걸리, 와인, 칵테일
const List<int> kFreeDefaultDrinkIds = [1, 2, 5, 4, 3];

class ProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProKey) ?? false;
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    final next = !current;
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProKey, next);
    state = AsyncValue.data(next);
  }

  Future<void> setValue(bool value) async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProKey, value);
    state = AsyncValue.data(value);
  }
}

final proProvider = AsyncNotifierProvider<ProNotifier, bool>(ProNotifier.new);
