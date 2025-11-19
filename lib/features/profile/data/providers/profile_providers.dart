import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/calendar/calendar_screen.dart';
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
final monthlySpendingProvider = FutureProvider.family<int, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(profileStatsServiceProvider);
  return service.calculateMonthlySpending(date.year, date.month);
});
