import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/weekly_saku_section.dart';
import 'package:ddalgguk/features/ranking/data/providers/ranking_providers.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingProfileDialog extends ConsumerStatefulWidget {
  const RankingProfileDialog({super.key, required this.entry});

  final RankingEntryWithUser entry;

  @override
  ConsumerState<RankingProfileDialog> createState() =>
      _RankingProfileDialogState();
}

class _RankingProfileDialogState extends ConsumerState<RankingProfileDialog> {
  bool _requestSent = false;

  WeeklyStats _createWeeklyStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceMonday = today.weekday - 1;
    final thisMonday = today.subtract(Duration(days: daysSinceMonday));
    final thisSunday = thisMonday.add(const Duration(days: 6));

    final weeklyLevels = widget.entry.weeklyDrunkLevels;
    if (weeklyLevels == null || weeklyLevels.length != 7) {
      return WeeklyStats.empty(thisMonday);
    }

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

  Future<void> _sendFriendRequest() async {
    try {
      final friendService = ref.read(friendServiceProvider);
      await friendService.sendFriendRequest(
        toUserId: widget.entry.uid,
        toUserName: widget.entry.name,
        message: '',
      );
      if (mounted) {
        setState(() => _requestSent = true);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.entry.name}님께 친구 신청을 보냈습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('친구 신청 중 오류가 발생했습니다: $e')));
      }
    }
  }

  Widget _buildTopDrinkTypesSection() {
    final topDrinkTypesAsync = ref.watch(
      friendTopDrinkTypesProvider(widget.entry.uid),
    );
    return topDrinkTypesAsync.when(
      skipLoadingOnReload: true,
      data: (topDrinks) {
        if (topDrinks.isEmpty) {
          return const SizedBox.shrink();
        }
        // FriendProfileDialog._buildTopDrinkTypesSection 과 동일한 레이아웃
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '메인 기록 주종',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: topDrinks.map((dt) {
                        return Image.asset(
                          getDrinkIconPath(dt),
                          width: 46,
                          height: 46,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: topDrinks.map((dt) {
                        return SizedBox(
                          width: 46,
                          child: Text(
                            getDrinkTypeName(dt),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklyStats = _createWeeklyStats();
    final profileStatsAsync = ref.watch(
      friendProfileStatsProvider(widget.entry.uid),
    );
    final profileStats = profileStatsAsync.valueOrNull;

    final hasDrunkLevel =
        profileStats != null && profileStats.currentAlcoholInBody > 0;
    final theme = AppColors.getTheme(hasDrunkLevel ? 1 : 0);

    final currentUserUid = ref.read(currentUserProvider).valueOrNull?.uid;
    final isSelf = currentUserUid == widget.entry.uid;
    final canAddFriend =
        !isSelf && widget.entry.addFriendPermission && !_requestSent;

    return Column(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // 프로필 헤더
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
                            widget.entry.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '@${widget.entry.customId ?? ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (canAddFriend)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: _sendFriendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          '친구 신청',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTopDrinkTypesSection(),
              const SizedBox(height: 8),
              WeeklySakuSection(
                weeklyStats: weeklyStats,
                theme: theme,
                isScrollable: false,
              ),
              const SizedBox(height: 16),
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
      ],
    );
  }
}
