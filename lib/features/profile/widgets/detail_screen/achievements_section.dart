import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/auth/domain/models/badge.dart';
import 'package:ddalgguk/features/profile/domain/models/badge_data.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/reusable_section.dart';

class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({
    super.key,
    required this.theme,
    this.onlyPinned = false,
    this.customTitle,
    this.showMoreButton = true,
    this.friendUserId,
  });

  final AppTheme theme;
  final bool onlyPinned;
  final String? customTitle;
  final bool showMoreButton;
  final String? friendUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 친구 뱃지 또는 내 뱃지 선택
    final badgesAsync = friendUserId != null
        ? ref.watch(friendBadgesProvider(friendUserId!))
        : ref.watch(userBadgesProvider);

    return badgesAsync.when(
      skipLoadingOnReload: true,
      data: (allBadges) {
        final displayBadges = onlyPinned
            ? allBadges.where((b) => b.isPinned).toList()
            : allBadges;

        return ProfileSection(
          title: customTitle ?? '나의 업적',
          titleOutside: true,
          subtitle: showMoreButton
              ? GestureDetector(
                  onTap: () {
                    _showAllAchievements(context, allBadges, ref);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 1,
                    ),
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
                        fontSize: 11,
                        color: theme.secondaryColor.withValues(alpha: 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : null,
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 110,
              child: displayBadges.isEmpty
                  ? Center(
                      child: Text(
                        friendUserId != null
                            ? '친구가 고정한 뱃지가 없습니다.'
                            : '아직 획득한 뱃지가 없습니다.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayBadges.length,
                      itemBuilder: (context, index) {
                        final badge = displayBadges[index];
                        final badgeData = badge.group == 'drink'
                            ? drinkingBadges[badge.idx]
                            : sobrietyBadges[badge.idx];

                        if (badgeData == null) {
                          return const SizedBox.shrink();
                        }

                        final pinnedCount = allBadges
                            .where((b) => b.isPinned)
                            .length;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12, top: 8),
                          child: AchievementItem(
                            data: badgeData,
                            isUnlocked: true,
                            isPinned: badge.isPinned,
                            showPin: badge.isPinned || pinnedCount < 4,
                            onPin: onlyPinned
                                ? null
                                : () => ref
                                      .read(authRepositoryProvider)
                                      .toggleBadgePin(badge.id),
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

  void _showAllAchievements(
    BuildContext context,
    List<Badge> userBadges,
    WidgetRef ref,
  ) {
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
              const SizedBox(height: 20),
              _buildBadgeGrid(drinkingBadges, userBadges, 'drink'),
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
              const SizedBox(height: 20),
              _buildBadgeGrid(sobrietyBadges, userBadges, 'sober'),
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
        // Find if user has this badge
        final userBadge = userBadges
            .where((b) => b.group == group && b.idx == index)
            .firstOrNull;
        final isUnlocked = userBadge != null;

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
    this.isPinned = false,
    this.showPin = false,
    this.onPin,
  });

  final BadgeData data;
  final bool isUnlocked;
  final bool compact;
  final bool isPinned;
  final bool showPin;
  final VoidCallback? onPin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            AchievementIcon(
              imagePath: data.imagePath,
              isUnlocked: isUnlocked,
              size: compact ? 50 : 60,
            ),
            if (showPin && !compact)
              Positioned(
                top: -10,
                right: -5,
                child: GestureDetector(
                  onTap: onPin,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.transparent,
                    child: Transform.rotate(
                      angle: 0.785398, // 45 degrees in radians (π/4)
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
    required this.imagePath,
    required this.isUnlocked,
    this.size = 60,
  });

  final String imagePath;
  final bool isUnlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.withValues(alpha: 0.1), // Placeholder background
        child: isUnlocked
            ? Image.asset(
                imagePath,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    imagePath,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
      ),
    );
  }
}
