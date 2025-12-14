import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/profile/data/services/profile_stats_service.dart';
import 'package:ddalgguk/features/auth/domain/models/badge.dart';
import 'package:ddalgguk/features/profile/domain/models/achievement.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';

/// Profile stats service provider
final profileStatsServiceProvider = Provider<ProfileStatsService>((ref) {
  final drinkingRecordService = ref.watch(drinkingRecordServiceProvider);
  return ProfileStatsService(drinkingRecordService);
});

/// Profile Bottom Color Provider
/// Stores the interpolated color of the bottom of the profile screen
/// Updated by ProfileScreen as the user scrolls between Main and Detail views
final profileBottomColorProvider = StateProvider<Color?>((ref) => null);

/// User badges provider (real-time)
final userBadgesProvider = StreamProvider<List<Badge>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.appUserChanges.map((user) {
    if (user == null) {
      return [];
    }

    final pinnedBadges = user.pinnedBadges;
    final badges = user.badges.map((b) {
      final isPinned = pinnedBadges.contains(b.id);
      return b.copyWith(isPinned: isPinned);
    }).toList();

    // Sort by pinned status (pinned first) then by date descending (newest first)
    badges.sort((a, b) {
      if (a.isPinned && !b.isPinned) {
        return -1;
      }
      if (!a.isPinned && b.isPinned) {
        return 1;
      }
      return b.achievedDay.compareTo(a.achievedDay);
    });

    return badges;
  });
});

/// Weekly stats provider (last 7 days)
/// Weekly stats provider (last 7 days)
final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  // Watch for data updates
  ref.watch(drinkingRecordsLastUpdatedProvider);

  // Try to get data from current user first
  final user = await ref.watch(currentUserProvider.future);
  if (user != null &&
      user.weeklyDrunkLevels != null &&
      user.weeklyDrunkLevels!.length == 7) {
    return ProfileStatsService.createWeeklyStatsFromList(
      weeklyLevels: user.weeklyDrunkLevels,
      endDate: DateTime.now(),
    );
  }

  // Fallback to calculation from records
  final service = ref.watch(profileStatsServiceProvider);
  return service.calculateWeeklyStats();
});

/// Weekly stats provider with offset (0 = this week, 1 = last week, etc.)
/// Week starts on Monday and ends on Sunday
final weeklyStatsOffsetProvider = FutureProvider.family<WeeklyStats, int>((
  ref,
  offset,
) {
  ref.watch(drinkingRecordsLastUpdatedProvider);
  final service = ref.watch(profileStatsServiceProvider);
  final now = DateTime.now();

  // Calculate the Monday of this week
  final weekday = now.weekday; // 1=Monday, 7=Sunday
  final mondayOffset = weekday - 1;
  final thisWeekMonday = now.subtract(Duration(days: mondayOffset));

  // Go back by offset weeks
  final targetWeekMonday = thisWeekMonday.subtract(Duration(days: 7 * offset));

  return service.calculateWeeklyStats(targetWeekMonday);
});

/// Current profile stats provider (alcohol breakdown, drunk level, etc.)
final currentProfileStatsProvider = FutureProvider<ProfileStats>((ref) {
  ref.watch(drinkingRecordsLastUpdatedProvider);
  final service = ref.watch(profileStatsServiceProvider);
  final userInfoAsync = ref.watch(userPhysicalInfoProvider);
  return service.calculateCurrentStats(userInfoAsync.valueOrNull);
});

/// Achievements provider
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  ref.watch(drinkingRecordsLastUpdatedProvider);
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

/// Provider for user physical info
final userPhysicalInfoProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return {};
  }

  return {
    'gender': user.gender,
    'birthDate': user.birthDate,
    'height': user.height,
    'weight': user.weight,
    'coefficient': user.coefficient,
  };
});
