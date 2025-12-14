import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/achievements_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/weekly_saku_section.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/features/social/domain/models/friend_with_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 친구 프로필 미리보기 다이얼로그
class FriendProfileDialog extends ConsumerWidget {
  const FriendProfileDialog({super.key, required this.friendData});

  final FriendWithData friendData;

  WeeklyStats _createWeeklyStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));

    // weeklyDrunkLevels가 없으면 빈 통계 반환
    final weeklyLevels = friendData.weeklyDrunkLevels;
    if (weeklyLevels == null || weeklyLevels.length != 7) {
      return WeeklyStats.empty(startDate);
    }

    // 일일 데이터 생성
    final dailyData = <DailySakuData>[];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final level = weeklyLevels[i];

      dailyData.add(
        DailySakuData(
          date: date,
          drunkLevel: level == -1 ? 0 : level,
          hasRecords: level != -1,
        ),
      );
    }

    return WeeklyStats(
      startDate: startDate,
      endDate: today,
      dailyData: dailyData,
      soberDays: weeklyLevels.where((l) => l == -1).length,
      drinkTypeStats: [],
    );
  }

  ProfileStats? _createProfileStats() {
    final lastDrinkDate = friendData.lastDrinkDate;
    final currentDrunkLevel = friendData.currentDrunkLevel;

    if (lastDrinkDate == null ||
        currentDrunkLevel == null ||
        currentDrunkLevel == 0) {
      return ProfileStats.empty();
    }

    final now = DateTime.now();
    final estimatedTotalAlcohol = currentDrunkLevel * 10.0;
    final hoursSinceLastDrink = now.difference(lastDrinkDate).inMinutes / 60.0;
    final alcoholProcessed = hoursSinceLastDrink * 7;
    final alcoholRemaining = (estimatedTotalAlcohol - alcoholProcessed)
        .clamp(0.0, estimatedTotalAlcohol)
        .toDouble();
    final progressPercentage = estimatedTotalAlcohol > 0
        ? ((alcoholProcessed / estimatedTotalAlcohol) * 100)
              .clamp(0.0, 100.0)
              .toDouble()
        : 100.0;
    final timeToSober = alcoholRemaining > 0 ? alcoholRemaining / 7 : 0.0;

    final weeklyLevels = friendData.weeklyDrunkLevels;
    int thisMonthDrunkDays = 0;
    if (weeklyLevels != null) {
      final today = DateTime(now.year, now.month, now.day);
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: 6 - i));
        if (date.month == now.month && weeklyLevels[i] > 0) {
          thisMonthDrunkDays++;
        }
      }
    }

    return ProfileStats(
      thisMonthDrunkDays: thisMonthDrunkDays,
      currentAlcoholInBody: alcoholRemaining,
      timeToSober: timeToSober,
      statusMessage: alcoholRemaining > 0 ? '분해 중' : '깨끗한 상태',
      breakdown: AlcoholBreakdown(
        alcoholRemaining: alcoholRemaining,
        progressPercentage: progressPercentage,
        lastDrinkTime: lastDrinkDate,
        estimatedSoberTime: timeToSober > 0
            ? lastDrinkDate.add(
                Duration(hours: (hoursSinceLastDrink + timeToSober).ceil()),
              )
            : lastDrinkDate,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUserName = currentUserAsync.valueOrNull?.name ?? '사용자';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${friendData.name} 님을 정말 친구에서 삭제하시겠어요?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '*상대방의 친구 탭에서 $currentUserName 님도 사라져요',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소하기',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primaryPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '삭제하기',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteFriend(context, ref);
    }
  }

  Future<void> _deleteFriend(BuildContext context, WidgetRef ref) async {
    try {
      final friendService = ref.read(friendServiceProvider);
      await friendService.removeFriend(friendData.userId);

      if (context.mounted) {
        ref.invalidate(friendsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friendData.name}님을 친구에서 삭제했습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('친구 삭제 중 오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = _createWeeklyStats();
    final profileStats = _createProfileStats();
    final theme = AppColors.getTheme(profileStats?.thisMonthDrunkDays ?? 0);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // 프로필 헤더 + 메뉴
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friendData.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '@${friendData.userData.id ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      surfaceTintColor: Colors.transparent,
                      color: Colors.grey[200],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('친구 삭제'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 주간 통계
                WeeklySakuSection(weeklyStats: weeklyStats, theme: theme),
                const SizedBox(height: 16),
                // 업적
                AchievementsSection(theme: theme),
                const SizedBox(height: 16),
                // 알콜 분해 정보
                if (profileStats != null)
                  AlcoholBreakdownSection(
                    stats: profileStats,
                    theme: theme,
                    extraComment: false,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
