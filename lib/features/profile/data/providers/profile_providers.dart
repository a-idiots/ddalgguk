import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/profile/data/services/profile_stats_service.dart';
import 'package:ddalgguk/features/profile/domain/models/achievement.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';

/// Profile stats service provider
final profileStatsServiceProvider = Provider<ProfileStatsService>((ref) {
  final drinkingRecordService = ref.watch(drinkingRecordServiceProvider);
  return ProfileStatsService(drinkingRecordService);
});

/// Weekly stats provider (last 7 days)
final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final service = ref.watch(profileStatsServiceProvider);
  return service.calculateWeeklyStats();
});

/// Weekly stats provider with offset (0 = this week, 1 = last week, etc.)
final weeklyStatsOffsetProvider = FutureProvider.family<WeeklyStats, int>((
  ref,
  offset,
) async {
  final service = ref.watch(profileStatsServiceProvider);
  final now = DateTime.now();
  // Calculate end date for the requested week
  // offset 0: ends today
  // offset 1: ends 7 days ago
  final endDate = now.subtract(Duration(days: 7 * offset));
  return service.calculateWeeklyStats(endDate);
});

/// Current profile stats provider (alcohol breakdown, drunk level, etc.)
final currentProfileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final service = ref.watch(profileStatsServiceProvider);
  return service.calculateCurrentStats();
});

/// Achievements provider
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final service = ref.watch(profileStatsServiceProvider);
  return service.calculateAchievements();
});

/// Monthly spending provider
/// Calculates total spending from monthly drinking records
final monthlySpendingProvider = Provider.family<AsyncValue<int>, DateTime>((
  ref,
  date,
) {
  final recordsAsync = ref.watch(monthRecordsProvider(date));
  return recordsAsync.whenData((records) {
    return records.fold<int>(0, (sum, record) => sum + record.cost);
  });
});

/// Monthly spending comparison provider
/// Returns the difference between previous month and current month spending
/// Positive value means saved money (spent less than last month)
/// Negative value means spent more (spent more than last month)
final monthlySpendingComparisonProvider =
    Provider.family<AsyncValue<int>, DateTime>((ref, date) {
      final currentAsync = ref.watch(monthRecordsProvider(date));

      // Calculate previous month correctly (handle January -> December)
      final prevMonth = date.month == 1 ? 12 : date.month - 1;
      final prevYear = date.month == 1 ? date.year - 1 : date.year;
      final prevDate = DateTime(prevYear, prevMonth);

      final prevAsync = ref.watch(monthRecordsProvider(prevDate));

      if (currentAsync.isLoading || prevAsync.isLoading) {
        return const AsyncValue.loading();
      }

      if (currentAsync.hasError) {
        return AsyncValue.error(currentAsync.error!, currentAsync.stackTrace!);
      }
      if (prevAsync.hasError) {
        return AsyncValue.error(prevAsync.error!, prevAsync.stackTrace!);
      }

      final currentSum =
          currentAsync.valueOrNull?.fold<int>(
            0,
            (sum, record) => sum + record.cost,
          ) ??
          0;
      final prevSum =
          prevAsync.valueOrNull?.fold<int>(
            0,
            (sum, record) => sum + record.cost,
          ) ??
          0;

      return AsyncValue.data(prevSum - currentSum);
    });
