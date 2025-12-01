import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/domain/models/friend_with_data.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/speech_bubble.dart';
import 'package:flutter/material.dart';

/// 친구 카드 위젯
class FriendCard extends StatelessWidget {
  const FriendCard({required this.friendData, this.onTap, super.key});

  final FriendWithData friendData;
  final VoidCallback? onTap;

  void _showFullStatus(BuildContext context, String status) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Material(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 말풍선 탭 시 이벤트 전파 방지
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: SpeechBubble(
                  text: status,
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drunkLevel = friendData.displayDrunkLevel; // 이미 0-100 범위
    final backgroundColor = AppColors.getSakuBackgroundColor(drunkLevel);
    final status = friendData.displayStatus;

    // 마지막 음주 이후 일수 계산
    String daysSinceText = '최근 음주: ?일 전';
    if (friendData.daysSinceLastDrink != null) {
      daysSinceText = '최근 음주: ${friendData.daysSinceLastDrink}일 전';
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 메인 카드 (rounded rectangle)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // 상태 메시지 말풍선
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SpeechBubble(
                      text: status,
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      fontSize: 11,
                      maxLines: 1,
                      onTap: () => _showFullStatus(context, status),
                    ),
                  ),
                  // 캐릭터 이미지
                  Expanded(
                    child: Center(
                      child: SakuCharacter(size: 60, drunkLevel: drunkLevel),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 최근 음주 정보
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      daysSinceText,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 친구 이름 버튼 (카드 외부 하단)
          _NameButton(name: friendData.name),
        ],
      ),
    );
  }
}

/// 이름 버튼
class _NameButton extends StatelessWidget {
  const _NameButton({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
