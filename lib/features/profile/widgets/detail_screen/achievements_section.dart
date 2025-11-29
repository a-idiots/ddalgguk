import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/auth/domain/models/badge.dart';
import 'package:ddalgguk/features/profile/domain/models/badge_data.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/widgets/reusable_section.dart';

class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key, required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }

        final badges = List<Badge>.from(user.badges);
        // Sort by date descending (newest first)
        badges.sort((a, b) => b.achievedDay.compareTo(a.achievedDay));

        return ProfileSection(
          title: '나의 업적',
          titleOutside: true,
          subtitle: GestureDetector(
            onTap: () {
              _showAllAchievements(context, user.badges);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.secondaryColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                '더 많은 뱃지 확인하기',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.secondaryColor.withValues(alpha: 1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 110,
              child: badges.isEmpty
                  ? const Center(
                      child: Text(
                        '아직 획득한 뱃지가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        final badgeData = badge.group == 'drinking'
                            ? drinkingBadges[badge.idx]
                            : sobrietyBadges[badge.idx];

                        if (badgeData == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: AchievementItem(
                            data: badgeData,
                            isUnlocked: true,
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAllAchievements(BuildContext context, List<Badge> userBadges) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(width: double.infinity),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDA4444)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '음주 뱃지',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFDA4444),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBadgeGrid(drinkingBadges, userBadges, 'drinking'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF11BC6A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '금주 뱃지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF11BC6A),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildBadgeGrid(sobrietyBadges, userBadges, 'sobriety'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(
    Map<int, BadgeData> badgeMap,
    List<Badge> userBadges,
    String group,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: badgeMap.length,
      itemBuilder: (context, index) {
        final badgeData = badgeMap[index]!;
        final isUnlocked = userBadges.any(
          (b) => b.group == group && b.idx == index,
        );

        return AchievementItem(
          data: badgeData,
          isUnlocked: isUnlocked,
          compact: true,
        );
      },
    );
  }
}

class AchievementItem extends StatelessWidget {
  const AchievementItem({
    super.key,
    required this.data,
    required this.isUnlocked,
    this.compact = false,
  });

  final BadgeData data;
  final bool isUnlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AchievementIcon(
          text1: data.iconText1,
          text2: data.iconText2,
          color: isUnlocked ? data.color : Colors.grey[300]!,
          size: compact ? 50 : 60,
        ),
        const SizedBox(height: 8),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: 2),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: compact ? 8 : 9, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.text1,
    this.text2,
    required this.color,
    this.size = 60,
  });

  final String text1;
  final String? text2;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Check if text1 is 2 characters
    final bool isTwoChars = text1.length == 2;
    // If text2 is present, we force standard size for text1 to match text2
    final bool hasSubtitle = text2 != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text1,
              style: TextStyle(
                color: Colors.white,
                // Use large font only if 2 chars AND no subtitle
                fontSize: (isTwoChars && !hasSubtitle)
                    ? size * 0.4
                    : size * 0.3,
                fontWeight: (isTwoChars && !hasSubtitle)
                    ? FontWeight.w300
                    : FontWeight.w400,
                height: 1.0,
              ),
            ),
            if (text2 != null)
              Text(
                text2!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
