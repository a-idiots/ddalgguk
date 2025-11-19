import 'package:flutter/material.dart';
import 'package:ddalgguk/features/profile/domain/models/achievement.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/reusable_section.dart';

import 'package:ddalgguk/core/constants/app_colors.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({
    super.key,
    required this.achievements,
    required this.theme,
  });

  final List<Achievement> achievements;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: '나의 업적',
      titleOutside: true,
      subtitle: SectionSubtitleButton(
        text: '더 많은 뱃지 확인하기',
        onTap: () {
          _showAllAchievements(context);
        },
      ),
      content: SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return _AchievementCard(achievement: achievements[index]);
          },
        ),
      ),
    );
  }

  void _showAllAchievements(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '나의 업적',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    return _AchievementCard(
                      achievement: achievements[index],
                      compact: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, this.compact = true});

  final Achievement achievement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLocked = !achievement.isUnlocked;

    return Container(
      width: compact ? 100 : null,
      margin: EdgeInsets.only(right: compact ? 12 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement icon/badge
          Container(
            width: compact ? 60 : 50,
            height: compact ? 60 : 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isLocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getAchievementGradient(achievement.type),
                    ),
              boxShadow: [
                if (!isLocked)
                  BoxShadow(
                    color: _getAchievementGradient(
                      achievement.type,
                    )[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                _getAchievementIcon(achievement.type),
                color: Colors.white,
                size: compact ? 30 : 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12 : 11,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey : Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 10 : 9,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Color> _getAchievementGradient(AchievementType type) {
    switch (type) {
      case AchievementType.drinking:
        return [const Color(0xFFF27B7B), const Color(0xFFE35252)];
      case AchievementType.sober:
        return [const Color(0xFF52E370), const Color(0xFF3BC95B)];
      case AchievementType.tracking:
        return [const Color(0xFF5B9FFF), const Color(0xFF3D7FE0)];
      case AchievementType.social:
        return [const Color(0xFFFFB347), const Color(0xFFFF9F1C)];
      case AchievementType.special:
        return [const Color(0xFFB47BFF), const Color(0xFF9B5DE5)];
    }
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.drinking:
        return Icons.local_bar;
      case AchievementType.sober:
        return Icons.favorite;
      case AchievementType.tracking:
        return Icons.emoji_events;
      case AchievementType.social:
        return Icons.people;
      case AchievementType.special:
        return Icons.star;
    }
  }
}
