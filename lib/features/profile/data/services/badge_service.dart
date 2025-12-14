import 'package:ddalgguk/features/auth/data/repositories/auth_repository.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Status of a day in the calendar
enum DayStatus {
  none(0),
  sober(1),
  drinking(2);

  const DayStatus(this.value);

  final int value;

  static DayStatus fromInt(int? value) {
    if (value == 1) {
      return DayStatus.sober;
    }
    if (value == 2) {
      return DayStatus.drinking;
    }
    return DayStatus.none;
  }
}

/// Service to handle Badges, Streaks, and Stats locally
class BadgeService {
  // Singleton
  BadgeService._();
  static final BadgeService instance = BadgeService._();

  final SecureStorageService _storage = SecureStorageService.instance;
  // We'll inject AuthRepository dynamically or assume it's available via a Provider when needed.
  // For simplicity, we might need to pass the AppUser or fetch it via a callback/function if passing AuthRepo is circular.
  // For now, let's accept user data in the methods or use a manual dependency setter.
  AuthRepository? _authRepository;

  void setAuthRepository(AuthRepository repo) {
    _authRepository = repo;
  }

  // Local State
  Map<String, int> _calendarStatus = {}; // "YYYY-MM-DD": 1(Sober)|2(Drinking)
  Map<String, bool> _excessiveDays = {}; // "YYYY-MM-DD": true
  Map<String, double> _monthlyAlcohol = {}; // "YYYY-MM": 1234.5 (ml)
  // Helper: internal daily alcohol tracking
  final Map<String, double> _dailyAlcohol = {};

  Map<String, dynamic> _streaks = {
    'current_sober': 0,
    'current_drinking': 0,
    'longest_sober': 0,
    'longest_drinking': 0,
    'last_streak_update': null,
  };

  bool _isInitialized = false;

  /// Initialize and load data
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    await _loadState();
    _isInitialized = true;
  }

  Future<void> _loadState() async {
    final data = await _storage.getBadgeStats();
    if (data != null) {
      if (data['calendar_status'] != null) {
        _calendarStatus = Map<String, int>.from(data['calendar_status'] as Map);
      }
      if (data['excessive_days'] != null) {
        _excessiveDays = Map<String, bool>.from(data['excessive_days'] as Map);
      }
      if (data['monthly_alcohol'] != null) {
        _monthlyAlcohol = Map<String, double>.from(
          data['monthly_alcohol'] as Map,
        );
      }
      if (data['daily_alcohol'] != null) {
        _dailyAlcohol.clear();
        _dailyAlcohol.addAll(
          Map<String, double>.from(data['daily_alcohol'] as Map),
        );
      }
      if (data['streaks'] != null) {
        _streaks = Map<String, dynamic>.from(data['streaks'] as Map);
      }
    }
  }

  Future<void> _saveState() async {
    final data = {
      'calendar_status': _calendarStatus,
      'excessive_days': _excessiveDays,
      'monthly_alcohol': _monthlyAlcohol,
      'daily_alcohol': _dailyAlcohol,
      'streaks': _streaks,
    };
    await _storage.saveBadgeStats(data);
  }

  // ===========================================================================
  // Core Updates
  // ===========================================================================

  /// Update the status of a specific day
  /// Called whenever records for a day change (add/edit/delete)
  Future<void> updateDailyStatus(DateTime date, DayStatus newStatus) async {
    if (!_isInitialized) {
      await init();
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final oldStatus = DayStatus.fromInt(_calendarStatus[dateKey]);

    if (newStatus == DayStatus.none) {
      _calendarStatus.remove(dateKey);
    } else {
      _calendarStatus[dateKey] = newStatus.value;
    }

    // Only recalculate if status actually changed
    if (oldStatus != newStatus) {
      debugPrint(
        'BadgeService: Status changed for $dateKey: $oldStatus -> $newStatus',
      );
      await _recalculateStreaks(date);
    } else {
      // Even if status didn't change (e.g. Drinking -> Drinking),
      // we might save just to be safe if other things updated? No, optimization.
      debugPrint('BadgeService: Status same for $dateKey: $newStatus');
      // FORCE recalculate for verification during dev
      await _recalculateStreaks(date);
    }

    // Always save state
    await _saveState();
  }

  /// Update daily alcohol total and check for excessive drinking
  Future<void> updateDailyAlcohol(
    DateTime date,
    double totalPureAlcoholMl,
  ) async {
    if (!_isInitialized) {
      await init();
    }

    // 1. Update Monthly Total
    final monthKey = DateFormat('yyyy-MM').format(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // To update monthly strictly correctly, we'd need to subtract the old value for this day.
    // BUT, we don't store daily totals to subtract.
    // So, updateDailyAlcohol is expected to be called with the *CORRECT FINAL TOTAL* for that day.
    // We need to re-aggregate the month? That's expensive (DB Scan).
    // Alternative: We store daily totals in a map?
    // User requested "Minimal calculation".
    // Best approach: Store daily totals locally too?
    // If we only store monthly sum, we can't easily correct it if a record changes without knowing the delta.
    // Since we are building a robust local cache, let's keep a separate map for 'daily_alcohol_map' inside monthly_alcohol logic?
    // Actually, let's change `_monthly_alcohol` to dynamically sum from a stored `_daily_alcohol_totals`.
    // It's safer. A year of data is 365 entries. 10 years = 3650 doubles. ~30KB RAM. Trivial.
    // Let's add `_dailyAlcohol` map.

    debugPrint(
      'BadgeService: Updating alcohol for $dateKey: $totalPureAlcoholMl ml',
    );
    await _updateDailyAlcoholValue(dateKey, totalPureAlcoholMl);

    await _updateMonthlyTotal(monthKey);
    debugPrint(
      'BadgeService: Updated monthly total for $monthKey: ${_monthlyAlcohol[monthKey]} ml',
    );

    await _checkExcessiveDrinking(dateKey, totalPureAlcoholMl);

    await _saveState();
  }

  // Helper: internal daily alcohol tracking
  // Defined at top now
  // Map<String, double> _dailyAlcohol = {};

  Future<void> _updateDailyAlcoholValue(String dateKey, double amount) async {
    // We need to load this if not loaded.
    // Assuming _dailyAlcohol is loaded in _loadState (need to add it)
    _dailyAlcohol[dateKey] = amount;
    if (amount == 0) {
      _dailyAlcohol.remove(dateKey);
    }
  }

  Future<void> _updateMonthlyTotal(String monthKey) async {
    // Sum up all days in this month
    double sum = 0;
    _dailyAlcohol.forEach((key, value) {
      if (key.startsWith(monthKey)) {
        sum += value;
      }
    });
    _monthlyAlcohol[monthKey] = sum;
  }

  Future<void> _checkExcessiveDrinking(String dateKey, double amount) async {
    if (_authRepository == null) {
      debugPrint(
        'BadgeService: AuthRepository not set. Skipping excessive check.',
      );
      return;
    }

    final user = await _authRepository!.getCurrentUser();
    if (user == null || user.maxAlcohol == null) {
      return;
    }

    // Soju (360ml, 16.5%) = ~59.4ml pure alcohol
    const double oneBottlePureAlc = 360 * 0.165;
    final limitMl = user.maxAlcohol! * oneBottlePureAlc;

    if (amount > limitMl) {
      _excessiveDays[dateKey] = true;
      debugPrint(
        'BadgeService: Excessive drinking detected on $dateKey (Limit: $limitMl, Amount: $amount)',
      );
    } else {
      _excessiveDays.remove(dateKey);
      debugPrint(
        'BadgeService: Drinking within limit on $dateKey (Limit: $limitMl, Amount: $amount)',
      );
    }
  }

  // ===========================================================================
  // Streak Calculation
  // ===========================================================================

  /// Recalculate streaks
  /// We mainly care about the "Current" streak ending today or yesterday.
  /// And "Longest" streak updates.
  Future<void> _recalculateStreaks(DateTime changedDate) async {
    // To be perfectly accurate for "Longest" streak, we might need to scan the whole history
    // if a record in the middle was broken.
    // However, for "Current", we just scan back from today.

    // Sort keys to scan
    final sortedKeys = _calendarStatus.keys.toList()..sort();
    if (sortedKeys.isEmpty) {
      _resetStreaks();
      return;
    }

    // 1. Calculate Current Streak (Sober or Drinking)
    // Scan backwards from Today (or Yesterday if Today is empty)
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    // Start point
    String? startKey;
    if (_calendarStatus.containsKey(today)) {
      startKey = today;
    } else if (_calendarStatus.containsKey(yesterday)) {
      startKey = yesterday;
    }

    if (startKey == null) {
      // No recent records
      _streaks['current_sober'] = 0;
      _streaks['current_drinking'] = 0;
    } else {
      final currentType = _calendarStatus[startKey]!; // 1 or 2
      int count = 0;

      var pointerDate = DateTime.parse(startKey);

      // We assume max streak is size of map, just loop integers
      // But we need to check CONSECUTIVE days
      // If we skip the sortedKeys.indexOf logic and just subtract days logically
      // it might be cleaner but slower if we check non-existent keys.
      // Given sorting:
      // We can just iterate backwards from 'startKey' using sortedKeys?
      // No, sortedKeys is low->high.
      // We need to find index of startKey and iterate down.

      // Warning: 'startIndex' unused warning was here.
      // Let's use it for optimization or just use logical date subtraction?
      // Logical subtraction is safest for 'Consecutive'.
      // If map is dense, fast. If sparse, we stop immediately.

      // Actually, to use 'sortedKeys', we would do:
      // int index = sortedKeys.indexOf(startKey);
      // for (int i = index; i >= 0; i--) { ... }
      // But 'consecutive' check is harder with list access. Dates are clearer.

      // Let's stick to Date subtraction loop as it's visibly correct for 'Status at Date'.
      // We'll limit the loop to avoid infinite if something goes wrong (e.g. 10 years).
      for (int i = 0; i < 3650; i++) {
        final dateStr = DateFormat('yyyy-MM-dd').format(pointerDate);
        final status = _calendarStatus[dateStr];

        if (status == currentType) {
          count++;
          pointerDate = pointerDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      if (currentType == DayStatus.sober.value) {
        _streaks['current_sober'] = count;
        _streaks['current_drinking'] = 0;
      } else {
        _streaks['current_sober'] = 0;
        _streaks['current_drinking'] = count;
      }
      debugPrint(
        'BadgeService: Current Streak Updated -> Sober: ${_streaks['current_sober']}, Drinking: ${_streaks['current_drinking']}',
      );
    }

    // 2. Calculate Longest Streak (Expensive?)
    // If we inserted a record connecting two streaks, longest might change.
    // We can do a full pass if `sortedKeys.length` is reasonable (< 5000).
    // Let's do a full pass for correctness. It's just iterating integers.

    int maxSober = 0;
    int maxDrinking = 0;

    int tempSober = 0;
    int tempDrinking = 0;
    DateTime? prevDate;

    for (final key in sortedKeys) {
      final date = DateTime.parse(key);
      final status = _calendarStatus[key];

      // Check continuity
      bool isConsecutive = false;
      if (prevDate != null) {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          isConsecutive = true;
        }
      } else {
        isConsecutive = true; // First item
      }

      if (!isConsecutive) {
        // Gap -> Reset temps
        tempSober = 0;
        tempDrinking = 0;
      }

      if (status == DayStatus.sober.value) {
        tempSober++;
        tempDrinking = 0; // Break drinking streak
      } else if (status == DayStatus.drinking.value) {
        tempDrinking++;
        tempSober = 0; // Break sober streak
      }

      if (tempSober > maxSober) {
        maxSober = tempSober;
      }
      if (tempDrinking > maxDrinking) {
        maxDrinking = tempDrinking;
      }

      prevDate = date;
    }

    _streaks['longest_sober'] = maxSober;
    _streaks['longest_drinking'] = maxDrinking;

    // TODO: Check Badges here
  }

  void _resetStreaks() {
    _streaks['current_sober'] = 0;
    _streaks['current_drinking'] = 0;
    _streaks['longest_sober'] = 0;
    _streaks['longest_drinking'] = 0;
  }

  // ===========================================================================
  // Getters
  // ===========================================================================

  Map<String, dynamic> getStats() {
    return {
      'streaks': _streaks,
      'excessive_days_count': _excessiveDays.length,
      'monthly_alcohol': _monthlyAlcohol,
      'excessive_days_map': _excessiveDays, // for debugging or calendar UI
    };
  }

  /// Get status for a specific date
  DayStatus getStatusForDate(DateTime date) {
    if (!_isInitialized) {
      return DayStatus.none; // Warning: naive sync return
    }
    final key = DateFormat('yyyy-MM-dd').format(date);
    return DayStatus.fromInt(_calendarStatus[key]);
  }
}
