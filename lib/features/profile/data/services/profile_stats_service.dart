import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/shared/utils/alcohol_calculator.dart';

/// Profile statistics calculation service
/// Calculates various stats from drinking records for profile display
class ProfileStatsService {
  ProfileStatsService(this._drinkingRecordService);

  final DrinkingRecordService _drinkingRecordService;

  /// Calculate weekly stats for the week containing [referenceDate] (default: today)
  /// Week starts on Monday and ends on Sunday
  Future<WeeklyStats> calculateWeeklyStats([DateTime? referenceDate]) async {
    final now = referenceDate ?? DateTime.now();
    final startDate = _getMondayOfWeek(now);
    final endDate = startDate.add(const Duration(days: 6)); // Sunday

    try {
      // Fetch records for the week (Monday to Sunday)
      final records = await _drinkingRecordService.getRecordsByDateRange(
        startDate,
        endDate.add(const Duration(days: 1)), // Include Sunday
      );

      return _createWeeklyStatsFromRecords(records, startDate, endDate);
    } catch (e) {
      return WeeklyStats.empty(startDate);
    }
  }

  /// Calculate weekly stats stream
  /// Week starts on Monday and ends on Sunday
  Stream<WeeklyStats> calculateWeeklyStatsStream([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final startDate = _getMondayOfWeek(now);
    final endDate = startDate.add(const Duration(days: 6)); // Sunday

    return _drinkingRecordService
        .streamRecordsByDateRange(
          startDate,
          endDate.add(const Duration(days: 1)),
        )
        .map(
          (records) =>
              _createWeeklyStatsFromRecords(records, startDate, endDate),
        );
  }

  WeeklyStats _createWeeklyStatsFromRecords(
    List<DrinkingRecord> records,
    DateTime startDate,
    DateTime today,
  ) {
    // Group records by date
    final Map<String, List<DrinkingRecord>> recordsByDate = {};
    for (final record in records) {
      final dateKey = _getDateKey(record.date);
      recordsByDate.putIfAbsent(dateKey, () => []).add(record);
    }

    // Calculate daily data for each of the 7 days
    final dailyData = <DailySakuData>[];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      final dayRecords = recordsByDate[dateKey] ?? [];

      int avgDrunkLevel = 0;
      double totalAlcoholMl = 0;
      if (dayRecords.isNotEmpty) {
        final total = dayRecords.fold(0, (sum, r) => sum + r.drunkLevel);
        avgDrunkLevel = (total / dayRecords.length).round();

        for (final record in dayRecords) {
          for (final drink in record.drinkAmount) {
            totalAlcoholMl += drink.amount * (drink.alcoholContent / 100);
          }
        }
      }

      dailyData.add(
        DailySakuData(
          date: date,
          drunkLevel: avgDrunkLevel * 10, // Convert 0-10 to 0-100
          hasRecords: dayRecords.isNotEmpty,
          totalAlcoholMl: totalAlcoholMl,
        ),
      );
    }

    // Calculate totals and drink type stats
    final Map<int, DrinkTypeStat> drinkTypeStatsMap = {};

    for (final record in records) {
      for (final drink in record.drinkAmount) {
        // Aggregate drink type stats
        final type = drink.drinkType;
        final currentStat =
            drinkTypeStatsMap[type] ??
            DrinkTypeStat(
              drinkType: type,
              totalAmountMl: 0,
              maxAmountMl: 0,
              pureAlcoholMl: 0,
            );

        drinkTypeStatsMap[type] = currentStat.copyWith(
          totalAmountMl: currentStat.totalAmountMl + drink.amount,
          maxAmountMl: drink.amount > currentStat.maxAmountMl
              ? drink.amount.toDouble()
              : currentStat.maxAmountMl,
          pureAlcoholMl:
              currentStat.pureAlcoholMl +
              (drink.amount * (drink.alcoholContent / 100)),
        );
      }
    }

    final int soberDays = dailyData.where((d) => !d.hasRecords).length;

    return WeeklyStats(
      startDate: startDate,
      endDate: today,
      dailyData: dailyData,
      soberDays: soberDays,
      drinkTypeStats: drinkTypeStatsMap.values.toList(),
    );
  }

  /// Calculate current profile stats including alcohol breakdown
  Future<ProfileStats> calculateCurrentStats([
    Map<String, dynamic>? userInfo,
  ]) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      // Fetch records for the last 30 days to calculate streaks
      final startDate = today.subtract(const Duration(days: 30));
      final records = await _drinkingRecordService.getRecordsByDateRange(
        startDate,
        today.add(const Duration(days: 1)),
      );

      return _calculateStatsFromRecords(records, now, today, userInfo);
    } catch (e) {
      return ProfileStats.empty();
    }
  }

  /// Calculate current profile stats stream
  Stream<ProfileStats> calculateCurrentStatsStream([
    Map<String, dynamic>? userInfo,
  ]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 30));

    return _drinkingRecordService
        .streamRecordsByDateRange(startDate, today.add(const Duration(days: 1)))
        .map(
          (records) =>
              _calculateStatsFromRecords(records, now, today, userInfo),
        );
  }

  ProfileStats _calculateStatsFromRecords(
    List<DrinkingRecord> records,
    DateTime now,
    DateTime today,
    Map<String, dynamic>? userInfo,
  ) {
    // 1. Filter records for this month only
    final currentYearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final recordsInThisMonth = records
        .where((r) => r.yearMonth == currentYearMonth)
        .toList();

    // 2. Identify drinking days (drinkAmount > 0)
    final drinkingDays = <String>{};
    final soberDays = <String>{};
    for (var r in recordsInThisMonth) {
      // Check if any drink amount > 0
      final hasDrink = r.drinkAmount.any((d) => d.amount > 0);
      if (hasDrink) {
        drinkingDays.add(_getDateKey(r.date));
      } else {
        soberDays.add(_getDateKey(r.date));
      }
    }

    // Remove days that have both drinking and sober records (count as drinking)
    soberDays.removeAll(drinkingDays);

    // 3. Count drinking days and sober days in this month
    final drinkingCount = drinkingDays.length;
    final soberCount = soberDays.length;

    // 4. Check today's status
    final todayKey = _getDateKey(today);
    // Find records for today
    final todayRecords = recordsInThisMonth
        .where((r) => _getDateKey(r.date) == todayKey)
        .toList();

    final hasTodayRecord = todayRecords.isNotEmpty;
    // Today is drinking if any record today has drinkAmount > 0
    final isTodayDrinking = todayRecords.any(
      (r) => r.drinkAmount.any((d) => d.amount > 0),
    );

    // Calculate today's drunk level (max of today's records)
    int todayDrunkLevel = 0;
    if (todayRecords.isNotEmpty) {
      todayDrunkLevel = todayRecords.fold(
        0,
        (max, r) => r.drunkLevel > max ? r.drunkLevel : max,
      );
    }

    // --- Alcohol Calculation using User Info and 3-day history ---
    final alcoholStats = AlcoholCalculator.calculate(
      userInfo: userInfo,
      records: records,
      now: now,
      today: today,
    );

    final breakdown = AlcoholBreakdown(
      alcoholRemaining: alcoholStats.currentAlcoholRemaining,
      progressPercentage: alcoholStats.progressPercentage,
      lastDrinkTime: alcoholStats.lastDrinkTime,
      estimatedSoberTime: alcoholStats.estimatedSoberTime,
    );

    return ProfileStats(
      thisMonthDrunkDays: (todayDrunkLevel * 10).clamp(
        0,
        100,
      ), // Convert 0-10 to 0-100
      currentAlcoholInBody: alcoholStats.currentAlcoholRemaining,
      timeToSober: alcoholStats.timeToSober,
      statusMessage: alcoholStats.statusMessage,
      breakdown: breakdown,
      thisMonthDrinkingCount: drinkingCount,
      thisMonthSoberCount: soberCount,
      todayDrunkLevel: alcoholStats.currentDrunkLevel.round(),
      hasTodayRecord: hasTodayRecord,
      isTodayDrinking: isTodayDrinking,
    );
  }

  /// Helper to get date key for grouping
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get the Monday of the week containing [date]
  DateTime _getMondayOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final weekday = normalized.weekday; // 1=Monday, 7=Sunday
    final mondayOffset =
        weekday - 1; // Days since Monday (0 if today is Monday)
    return normalized.subtract(Duration(days: mondayOffset));
  }

  /// Calculate monthly spending
  Future<int> calculateMonthlySpending(int year, int month) async {
    try {
      final records = await _drinkingRecordService.getRecordsByMonth(
        year,
        month,
      );
      return records.fold<int>(0, (sum, record) => sum + record.cost);
    } catch (e) {
      return 0;
    }
  }

  /// Get monthly records grouped by date
  Future<Map<DateTime, List<DrinkingRecord>>> getMonthlyRecordsByDate(
    int year,
    int month,
  ) async {
    try {
      final records = await _drinkingRecordService.getRecordsByMonth(
        year,
        month,
      );
      final Map<DateTime, List<DrinkingRecord>> groupedRecords = {};

      for (final record in records) {
        final dateKey = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        groupedRecords.putIfAbsent(dateKey, () => []).add(record);
      }

      return groupedRecords;
    } catch (e) {
      return {};
    }
  }

  /// Create WeeklyStats from a list of drunk levels (e.g. from AppUser or FriendData)
  /// Assumes the list represents the last 7 days ending on [endDate]
  /// [weeklyLevels]: List of 7 integers (-1: no record, 0: sober, >0: drunk level)
  static WeeklyStats createWeeklyStatsFromList({
    required List<int>? weeklyLevels,
    required DateTime endDate,
  }) {
    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );
    final startDate = normalizedEndDate.subtract(const Duration(days: 6));

    // Handle empty or invalid data
    if (weeklyLevels == null || weeklyLevels.length != 7) {
      return WeeklyStats.empty(startDate);
    }

    final dailyData = <DailySakuData>[];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final level = weeklyLevels[i];

      dailyData.add(
        DailySakuData(
          date: date,
          drunkLevel: level == -1 ? 0 : level,
          hasRecords: level != -1,
          totalAlcoholMl: 0, // Not available from simple int list
        ),
      );
    }

    final soberDays = weeklyLevels.where((l) => l == -1 || l == 0).length;

    return WeeklyStats(
      startDate: startDate,
      endDate: normalizedEndDate,
      dailyData: dailyData,
      soberDays: soberDays,
      drinkTypeStats: [], // Not available
    );
  }
}
