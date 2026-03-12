import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/profile/data/services/profile_stats_service.dart';
import 'package:ddalgguk/features/auth/domain/models/badge.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';

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

/// Friend badges provider (for specific user)
final friendBadgesProvider = FutureProvider.autoDispose.family<List<Badge>, String>((
  ref,
  userId,
) async {
  debugPrint('=== friendBadgesProvider ===');
  debugPrint('Fetching badges for user: $userId');

  final friendService = ref.watch(friendServiceProvider);
  final friendProfile = await friendService.getFriendProfile(userId);

  if (friendProfile == null) {
    debugPrint('❌ Friend profile is null');
    return <Badge>[];
  }

  debugPrint('✅ Friend profile badges: ${friendProfile.badges.length}');
  debugPrint('📌 Friend pinnedBadges list: ${friendProfile.pinnedBadges}');

  final pinnedBadges = friendProfile.pinnedBadges;
  final List<Badge> badges = friendProfile.badges.map((Badge b) {
    final isPinned = pinnedBadges.contains(b.id);
    debugPrint(
      '  Badge ${b.id}: isPinned = $isPinned (checking if ${b.id} is in $pinnedBadges)',
    );
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

  final pinnedCount = badges.where((b) => b.isPinned).length;
  debugPrint('📍 Final pinned badges count: $pinnedCount');

  return badges;
});

/// Weekly stats provider (last 7 days)
final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  // Watch for data updates
  ref.watch(drinkingRecordsLastUpdatedProvider);

  // Always calculate from records to ensure real-time updates when records change
  final service = ref.watch(profileStatsServiceProvider);
  return service.calculateWeeklyStats();
});

/// Weekly stats provider for a specific week by its Monday date
final weeklyStatsByMondayProvider =
    FutureProvider.family<WeeklyStats, DateTime>((ref, monday) {
      ref.watch(drinkingRecordsLastUpdatedProvider);
      final service = ref.watch(profileStatsServiceProvider);
      return service.calculateWeeklyStats(monday);
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

/// Current month total alcohol consumed in bottles (1병 = 360ml)
/// Uses DateTime(year, month) key so the same provider instance is reused
/// throughout the month, avoiding repeated fetches on every rebuild.
final currentMonthAlcoholBottlesProvider = Provider<AsyncValue<double>>((ref) {
  final now = DateTime.now();
  final monthKey = DateTime(now.year, now.month);
  final recordsAsync = ref.watch(monthRecordsProvider(monthKey));
  return recordsAsync.whenData((records) {
    double totalMl = 0;
    for (final record in records) {
      for (final drink in record.drinkAmount) {
        totalMl += drink.amount;
      }
    }
    return totalMl / 360.0;
  });
});

/// Monthly alcohol consumed in bottles for any month
/// Family version of currentMonthAlcoholBottlesProvider
final monthlyAlcoholBottlesProvider =
    Provider.family<AsyncValue<double>, DateTime>((ref, date) {
      final recordsAsync = ref.watch(monthRecordsProvider(date));
      return recordsAsync.whenData((records) {
        double totalMl = 0;
        for (final record in records) {
          for (final drink in record.drinkAmount) {
            totalMl += drink.amount;
          }
        }
        return totalMl / 360.0;
      });
    });

/// Previous month average spending per drinking session
/// Default 30,000원 if no records with cost exist
final prevMonthAvgSpendingProvider = FutureProvider<double>((ref) async {
  ref.watch(drinkingRecordsLastUpdatedProvider);
  final now = DateTime.now();
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  final service = ref.watch(drinkingRecordServiceProvider);
  final records = await service.getRecordsByMonth(prevYear, prevMonth);
  final sessionsWithCost = records.where((r) => r.cost > 0).toList();
  if (sessionsWithCost.isEmpty) {
    return 30000.0;
  }
  final totalCost = sessionsWithCost.fold<int>(0, (sum, r) => sum + r.cost);
  return totalCost / sessionsWithCost.length;
});

// ---------------------------------------------------------------------------
// Alcohol Guideline Data
// ---------------------------------------------------------------------------

/// Per-drink-type breakdown for the guideline popup info box
class DrinkBreakdownItem {
  const DrinkBreakdownItem({
    required this.drinkType,
    required this.name,
    required this.totalAmountMl,
    required this.grams,
  });

  final int drinkType;
  final String name;
  final double totalAmountMl;
  final double grams;
}

/// Data class for the drinking guideline widget
class AlcoholGuidelineData {
  const AlcoholGuidelineData({
    required this.hasRecord,
    required this.isToday,
    required this.totalAlcoholGrams,
    this.breakdown = const [],
  });

  /// Whether any drinking record was found (today or yesterday)
  final bool hasRecord;

  /// true = today's record, false = yesterday's record
  final bool isToday;

  /// Total pure alcohol in grams (volume × abv × 0.8)
  final double totalAlcoholGrams;

  /// Per-drink-type breakdown
  final List<DrinkBreakdownItem> breakdown;
}

/// Aggregates records by drinkType and calculates grams (× 0.8)
List<DrinkBreakdownItem> _buildBreakdown(List<DrinkingRecord> records) {
  final Map<int, ({double totalMl, double grams})> map = {};

  for (final r in records) {
    for (final d in r.drinkAmount) {
      if (d.amount <= 0) {
        continue;
      }
      final g = d.amount * (d.alcoholContent / 100) * 0.8;
      final prev = map[d.drinkType];
      map[d.drinkType] = prev == null
          ? (totalMl: d.amount, grams: g)
          : (totalMl: prev.totalMl + d.amount, grams: prev.grams + g);
    }
  }

  return map.entries.map((e) {
    // Resolve name from the shared drinks list via the int ID
    // We use a simple inline lookup to avoid importing drink_helpers into providers
    const nameMap = {
      -1: '기타',
      0: '알 수 없음',
      1: '소주',
      2: '맥주',
      3: '칵테일',
      4: '와인',
      5: '막걸리',
      6: '위스키',
      7: '하이볼',
      8: '사케',
      9: '보드카',
    };
    return DrinkBreakdownItem(
      drinkType: e.key,
      name: nameMap[e.key] ?? '기타',
      totalAmountMl: e.value.totalMl,
      grams: e.value.grams,
    );
  }).toList();
}

double _sumGrams(List<DrinkingRecord> records) {
  double total = 0;
  for (final r in records) {
    for (final d in r.drinkAmount) {
      if (d.amount > 0) {
        total += d.amount * (d.alcoholContent / 100) * 0.8;
      }
    }
  }
  return total;
}

/// Provides today-or-yesterday alcohol consumption for the guideline widget.
/// Fetches today first; falls back to yesterday if today has no drinking records.
final alcoholGuidelineDataProvider = FutureProvider<AlcoholGuidelineData>((
  ref,
) async {
  ref.watch(drinkingRecordsLastUpdatedProvider);

  final service = ref.watch(drinkingRecordServiceProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // Today
  final todayAll = await service.getRecordsByDate(today);
  final todayDrinking = todayAll
      .where((r) => r.drinkAmount.any((d) => d.amount > 0))
      .toList();
  if (todayDrinking.isNotEmpty) {
    return AlcoholGuidelineData(
      hasRecord: true,
      isToday: true,
      totalAlcoholGrams: _sumGrams(todayDrinking),
      breakdown: _buildBreakdown(todayDrinking),
    );
  }

  // Yesterday
  final yesterdayAll = await service.getRecordsByDate(yesterday);
  final yesterdayDrinking = yesterdayAll
      .where((r) => r.drinkAmount.any((d) => d.amount > 0))
      .toList();
  if (yesterdayDrinking.isNotEmpty) {
    return AlcoholGuidelineData(
      hasRecord: true,
      isToday: false,
      totalAlcoholGrams: _sumGrams(yesterdayDrinking),
      breakdown: _buildBreakdown(yesterdayDrinking),
    );
  }

  return const AlcoholGuidelineData(
    hasRecord: false,
    isToday: false,
    totalAlcoholGrams: 0,
  );
});

/// Provider for user physical info
/// Uses [UserPhysicalInfo] with [Equatable] and [selectAsync] to ensure
/// this provider ONLY updates when relevant physical data changes
final userPhysicalInfoProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final info = await ref.watch(
    currentUserProvider.selectAsync((user) {
      if (user == null) {
        return const UserPhysicalInfo.empty();
      }
      return UserPhysicalInfo.fromAppUser(user);
    }),
  );

  return info.toMap();
});

/// Helper class to track only physical info changes
class UserPhysicalInfo extends Equatable {
  const UserPhysicalInfo({
    this.gender,
    this.birthDate,
    this.height,
    this.weight,
    this.coefficient,
  });

  const UserPhysicalInfo.empty()
    : gender = null,
      birthDate = null,
      height = null,
      weight = null,
      coefficient = null;

  factory UserPhysicalInfo.fromAppUser(AppUser user) {
    return UserPhysicalInfo(
      gender: user.gender,
      birthDate: user.birthDate,
      height: user.height,
      weight: user.weight,
      coefficient: user.coefficient,
    );
  }

  final String? gender;
  final DateTime? birthDate;
  final double? height;
  final double? weight;
  final double? coefficient;

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'birthDate': birthDate,
      'height': height,
      'weight': weight,
      'coefficient': coefficient,
    };
  }

  @override
  List<Object?> get props => [gender, birthDate, height, weight, coefficient];
}
