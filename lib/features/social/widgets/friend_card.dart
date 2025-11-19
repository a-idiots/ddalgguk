import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/shared/widgets/speech_bubble.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:flutter/material.dart';

/// 친구 카드 위젯
class FriendCard extends StatelessWidget {
  const FriendCard({required this.friend, this.onTap, super.key});

  final Friend friend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final drunkLevel = friend.displayDrunkLevel;
    final backgroundColor = AppColors.getSakuBackgroundColor(drunkLevel);
    final bodyImagePath = getBodyImagePath(drunkLevel);
    final status = friend.displayStatus;

    // 마지막 음주 이후 일수 계산
    String daysSinceText = '최근 음주: ?일 전';
    if (friend.daysSinceLastDrink != null) {
      daysSinceText = '최근 음주: ${friend.daysSinceLastDrink}일 전';
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // 상태 메시지 말풍선
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SpeechBubble(
                      text: status,
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      fontSize: 11,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 캐릭터 이미지
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.95,
                      heightFactor: 0.75,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 캐릭터 바디
                          Image.asset(bodyImagePath, fit: BoxFit.contain),
                          // 눈 오버레이
                          Image.asset(
                            'assets/saku/eyes.png',
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
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
          _NameButton(name: friend.name),
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
