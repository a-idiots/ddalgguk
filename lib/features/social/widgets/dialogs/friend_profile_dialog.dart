import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/profile_header.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/weekly_saku_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/achievements_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/widgets/gradient_background.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 친구 프로필 미리보기 다이얼로그
class FriendProfileDialog extends ConsumerStatefulWidget {
  const FriendProfileDialog({
    super.key,
    required this.friend,
  });

  final Friend friend;

  @override
  ConsumerState<FriendProfileDialog> createState() =>
      _FriendProfileDialogState();
}

class _FriendProfileDialogState extends ConsumerState<FriendProfileDialog> {
  AppUser? _friendUser;
  WeeklyStats? _weeklyStats;
  ProfileStats? _profileStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriendProfile();
  }

  Future<void> _loadFriendProfile() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 친구 프로필 가져오기
      final doc = await firestore
          .collection('users')
          .doc(widget.friend.userId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = '친구 프로필을 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final friendUser = AppUser.fromJson({
        ...doc.data()!,
        'uid': doc.id,
      });

      // Friend 데이터로 주간 통계 생성
      final weeklyStats = _createWeeklyStatsFromFriend();

      // Friend 데이터로 알콜 분해 현황 생성
      final profileStats = _createProfileStatsFromFriend();

      setState(() {
        _friendUser = friendUser;
        _weeklyStats = weeklyStats;
        _profileStats = profileStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '프로필을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// Friend 데이터로 주간 통계 생성
  WeeklyStats _createWeeklyStatsFromFriend() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 6));

    // weeklyDrunkLevels가 없으면 빈 통계 반환
    final weeklyLevels = widget.friend.weeklyDrunkLevels;
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
          drunkLevel: level == -1 ? 0 : level, // -1은 0으로 표시 (기록 없음)
          hasRecords: level != -1, // -1이 아니면 기록 있음
        ),
      );
    }

    return WeeklyStats(
      startDate: startDate,
      endDate: today,
      dailyData: dailyData,
      totalSessions: 0, // 통계는 계산하지 않음
      totalAlcoholMl: 0,
      totalCost: 0,
      averageDrunkLevel: 0,
      soberDays: weeklyLevels.where((l) => l == -1).length,
    );
  }

  /// Friend 데이터로 알콜 분해 현황 생성
  ProfileStats? _createProfileStatsFromFriend() {
    final lastDrinkDate = widget.friend.lastDrinkDate;
    final currentDrunkLevel = widget.friend.currentDrunkLevel;

    // 음주 기록이 없으면 빈 통계 반환
    if (lastDrinkDate == null || currentDrunkLevel == null || currentDrunkLevel == 0) {
      return ProfileStats.empty();
    }

    final now = DateTime.now();

    // 대략적인 알콜량 추정 (drunkLevel 1 = 약 10g)
    final estimatedTotalAlcohol = currentDrunkLevel * 10.0;

    // 마지막 음주 이후 경과 시간
    final hoursSinceLastDrink = now.difference(lastDrinkDate).inMinutes / 60.0;

    // 시간당 7g씩 분해
    final alcoholProcessed = hoursSinceLastDrink * 7;
    final alcoholRemaining = (estimatedTotalAlcohol - alcoholProcessed).clamp(0.0, estimatedTotalAlcohol).toDouble();
    final progressPercentage = estimatedTotalAlcohol > 0
        ? ((alcoholProcessed / estimatedTotalAlcohol) * 100).clamp(0.0, 100.0).toDouble()
        : 100.0;
    final timeToSober = alcoholRemaining > 0 ? alcoholRemaining / 7 : 0.0;

    // 이번 달 음주일 계산 (weeklyDrunkLevels 기반)
    final weeklyLevels = widget.friend.weeklyDrunkLevels;
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
        totalAlcoholConsumed: estimatedTotalAlcohol,
        alcoholRemaining: alcoholRemaining,
        alcoholProcessed: alcoholProcessed.clamp(0.0, estimatedTotalAlcohol).toDouble(),
        progressPercentage: progressPercentage,
        lastDrinkTime: lastDrinkDate,
        estimatedSoberTime: timeToSober > 0
            ? lastDrinkDate.add(Duration(hours: (hoursSinceLastDrink + timeToSober).ceil()))
            : lastDrinkDate,
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    // 현재 사용자 이름 가져오기
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
                '${widget.friend.name} 님을 정말 친구에서 삭제하시겠어요?',
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

    if (confirmed == true) {
      await _deleteFriend();
    }
  }

  Future<void> _deleteFriend() async {
    try {
      final friendService = ref.read(friendServiceProvider);
      await friendService.removeFriend(widget.friend.userId);

      if (mounted) {
        // 친구 목록 새로고침
        ref.invalidate(friendsProvider);

        // 다이얼로그 닫기
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.friend.name}님을 친구에서 삭제했습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 배경색 결정: daysSinceLastDrink가 0이면 분홍, 아니면 연두
    final daysSince = widget.friend.daysSinceLastDrink ?? 999;
    final theme = AppColors.getTheme(daysSince == 0 ? 1 : 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ProfileGradientBackground(
            theme: theme,
            child: Stack(
              children: [
                // 프로필 내용
                SafeArea(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPink,
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : _buildProfileContent(theme),
                ),
                // X 닫기 버튼 (우측 상단)
                Positioned(
                  top: 8,
                  right: 8,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(AppTheme theme) {
    if (_friendUser == null) {
      return const Center(
        child: Text('프로필 정보를 불러올 수 없습니다.'),
      );
    }

    return Column(
      children: [
        // 프로필 내용 (스크롤 가능)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 48), // X 버튼 공간
                // 프로필 헤더
                ProfileHeader(
                  user: _friendUser!,
                  theme: theme,
                  showCharacter: true,
                ),
                const SizedBox(height: 16),
                // 주간 사쿠 섹션
                if (_weeklyStats != null)
                  WeeklySakuSection(
                    weeklyStats: _weeklyStats!,
                    theme: theme,
                  ),
                const SizedBox(height: 8),
                // 업적 섹션
                AchievementsSection(theme: theme),
                const SizedBox(height: 8),
                // 알콜 분해 현황
                if (_profileStats != null)
                  AlcoholBreakdownSection(
                    stats: _profileStats!,
                    theme: theme,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // 친구 삭제 버튼 (하단 고정)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: TextButton(
            onPressed: _showDeleteConfirmation,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primaryPink),
              ),
            ),
            child: const Text(
              '친구 삭제',
              style: TextStyle(
                color: AppColors.primaryPink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
