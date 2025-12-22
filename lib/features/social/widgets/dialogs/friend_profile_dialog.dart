import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
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

    // 이번 주 월요일 계산 (weekday: 1=월요일, 7=일요일)
    final daysSinceMonday = today.weekday - 1;
    final thisMonday = today.subtract(Duration(days: daysSinceMonday));
    final thisSunday = thisMonday.add(const Duration(days: 6));

    // weeklyDrunkLevels가 없으면 빈 통계 반환
    final weeklyLevels = friendData.weeklyDrunkLevels;
    if (weeklyLevels == null || weeklyLevels.length != 7) {
      return WeeklyStats.empty(thisMonday);
    }

    // 일일 데이터 생성 [월(0), 화(1), 수(2), 목(3), 금(4), 토(5), 일(6)]
    final dailyData = <DailySakuData>[];
    for (int i = 0; i < 7; i++) {
      final date = thisMonday.add(Duration(days: i));
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
      startDate: thisMonday,
      endDate: thisSunday,
      dailyData: dailyData,
      soberDays: weeklyLevels.where((l) => l == -1).length,
      drinkTypeStats: [],
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${friendData.name}님을 친구에서 삭제했습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('친구 삭제 중 오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = _createWeeklyStats();
    final profileStatsAsync = ref.watch(
      friendProfileStatsProvider(friendData.userId),
    );
    final profileStats = profileStatsAsync.valueOrNull;

    // 친구가 아직 술이 분해되지 않았으면 빨간색 테마, 아니면 초록색 테마
    final hasDrunkLevel =
        profileStats != null && profileStats.currentAlcoholInBody > 0;
    final theme = AppColors.getTheme(hasDrunkLevel ? 1 : 0);

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
                        padding: const EdgeInsets.only(top: 8, left: 16),
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
                // 주간 통계
                WeeklySakuSection(
                  weeklyStats: weeklyStats,
                  theme: theme,
                  isScrollable: false,
                ),
                const SizedBox(height: 16),
                // 업적
                AchievementsSection(
                  theme: theme,
                  customTitle: '업적',
                  showMoreButton: false,
                  onlyPinned: true,
                  friendUserId: friendData.userId,
                ),
                const SizedBox(height: 16),
                // 알콜 분해 정보 - provider에서 가져온 정확한 통계 사용
                if (profileStats != null &&
                    profileStats.currentAlcoholInBody > 0)
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
