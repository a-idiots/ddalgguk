import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/profile/domain/models/achievement.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';

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
  Future<ProfileStats> calculateCurrentStats() async {
    final now = DateTime.now();

    try {
      // Get today's records
      final todayRecords = await _drinkingRecordService.getRecordsByDate(now);

      if (todayRecords.isEmpty) {
        return ProfileStats.empty();
      }

      // Get the most recent record to calculate current status
      todayRecords.sort((a, b) => b.date.compareTo(a.date));
      final latestRecord = todayRecords.first;

      // Calculate total alcohol consumed today
      double totalAlcoholGrams = 0;
      for (final drink in latestRecord.drinkAmount) {
        // Alcohol density: 0.789 g/ml
        // Pure alcohol ml = amount * alcoholContent / 100
        // Alcohol in grams = pure alcohol ml * 0.789
        final pureAlcoholMl = drink.amount * (drink.alcoholContent / 100);
        totalAlcoholGrams += pureAlcoholMl * 0.789;
      }

      // Calculate time elapsed since drinking
      final hoursSinceDrinking =
          now.difference(latestRecord.date).inMinutes / 60;

      // Average alcohol metabolism rate: ~7-10g per hour
      // Using 8g per hour as average
      const alcoholMetabolismRate = 8.0; // grams per hour
      final alcoholProcessed = hoursSinceDrinking * alcoholMetabolismRate;
      final alcoholRemaining = (totalAlcoholGrams - alcoholProcessed).clamp(
        0.0,
        totalAlcoholGrams,
      );

      // Calculate time to sober (when alcohol hits 0)
      final timeToSober = alcoholRemaining / alcoholMetabolismRate;

      // Calculate progress percentage
      final progressPercentage = totalAlcoholGrams > 0
          ? ((alcoholProcessed / totalAlcoholGrams) * 100).clamp(0.0, 100.0)
          : 0.0;

      // Generate status message
      String statusMessage;
      if (alcoholRemaining <= 0) {
        statusMessage = '깨끗한 상태입니다! 이미 모든 알콜이 분해되었어요 ☘';
      } else if (timeToSober < 1) {
        statusMessage = '곧 회복될 거예요! 조금만 더 기다리세요 ⏰';
      } else if (timeToSober < 3) {
        statusMessage = '${timeToSober.toStringAsFixed(1)}시간 후면 완전히 깰 거예요 🌱';
      } else {
        statusMessage =
            '아직 ${timeToSober.toStringAsFixed(1)}시간이 필요해요. 충분히 쉬세요 💤';
      }

      final breakdown = AlcoholBreakdown(
        totalAlcoholConsumed: totalAlcoholGrams,
        alcoholRemaining: alcoholRemaining,
        alcoholProcessed: alcoholProcessed,
        progressPercentage: progressPercentage,
        lastDrinkTime: latestRecord.date,
        estimatedSoberTime: now.add(
          Duration(minutes: (timeToSober * 60).round()),
        ),
      );

      return ProfileStats(
        thisMonthDrunkDays: (latestRecord.drunkLevel * 10).clamp(
          0,
          100,
        ), // Convert 0-10 to 0-100
        currentAlcoholInBody: alcoholRemaining,
        timeToSober: timeToSober,
        statusMessage: statusMessage,
        breakdown: breakdown,
      );
    } catch (e) {
      return ProfileStats.empty();
    }
  }

  /// Calculate achievements based on drinking records
  Future<List<Achievement>> calculateAchievements() async {
    final achievements = <Achievement>[];

    try {
      final now = DateTime.now();

      // Get current month's records
      final monthRecords = await _drinkingRecordService.getRecordsByMonth(
        now.year,
        now.month,
      );

      // Get last 7 days for streak calculations
      final weeklyStats = await calculateWeeklyStats();

      // Achievement 1: Consistent Tracker
      final trackingProgress = (monthRecords.length / 30).clamp(0.0, 1.0);
      achievements.add(
        Achievement(
          id: 'consistent_tracker',
          title: '꾸준한 기록자',
          description: '이번 달 ${monthRecords.length}일 기록 중',
          iconPath: 'assets/achievements/tracker.png',
          isUnlocked: monthRecords.length >= 15,
          progress: trackingProgress,
          type: AchievementType.tracking,
        ),
      );

      // Achievement 2: Sober Week
      final soberDays = weeklyStats.soberDays;
      achievements.add(
        Achievement(
          id: 'sober_week',
          title: '금주의 달인',
          description: '이번 주 $soberDays일 금주 성공',
          iconPath: 'assets/achievements/sober.png',
          isUnlocked: soberDays >= 5,
          progress: (soberDays / 7).clamp(0.0, 1.0),
          type: AchievementType.sober,
        ),
      );

      // Achievement 3: Low Level Drinker
      final avgDrunkLevel = weeklyStats.averageDrunkLevel;
      final lowLevelProgress = avgDrunkLevel <= 5
          ? 1.0
          : (5 / avgDrunkLevel).clamp(0.0, 1.0);
      achievements.add(
        Achievement(
          id: 'moderate_drinker',
          title: '절제의 달인',
          description: '평균 취기 ${avgDrunkLevel.toStringAsFixed(1)}% 유지',
          iconPath: 'assets/achievements/moderate.png',
          isUnlocked: avgDrunkLevel <= 5 && weeklyStats.totalSessions > 0,
          progress: lowLevelProgress,
          type: AchievementType.drinking,
        ),
      );

      // Achievement 4: VT 5초 횟플
      final vt5Sessions = monthRecords.where((r) {
        // VT 5초 means: drunkLevel 5 (50%)
        return r.drunkLevel == 5;
      }).length;
      achievements.add(
        Achievement(
          id: 'vt5_master',
          title: 'VT 5초 횟플이',
          description: '이번 달 $vt5Sessions회 VT 5초 달성',
          iconPath: 'assets/achievements/vt5.png',
          isUnlocked: vt5Sessions >= 3,
          progress: (vt5Sessions / 5).clamp(0.0, 1.0),
          type: AchievementType.special,
        ),
      );

      // Achievement 5: Monthly Goal
      achievements.add(
        Achievement(
          id: 'monthly_record',
          title: '이번달 완벽',
          description: '한 달 내내 기록 완료',
          iconPath: 'assets/achievements/perfect.png',
          isUnlocked: monthRecords.length >= 30,
          progress: (monthRecords.length / 30).clamp(0.0, 1.0),
          type: AchievementType.tracking,
        ),
      );

      return achievements;
    } catch (e) {
      return achievements;
    }
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
}
