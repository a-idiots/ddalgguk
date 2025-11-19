import 'package:ddalgguk/core/constants/app_colors.dart';
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
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // 상태 메시지 말풍선
            _StatusBubble(status: status),
            const SizedBox(height: 8),
            // 캐릭터 이미지
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 캐릭터 바디
                  Image.asset(bodyImagePath, fit: BoxFit.contain),
                  // 눈 오버레이
                  Image.asset('assets/saku/eyes.png', fit: BoxFit.contain),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 최근 음주 정보
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                daysSinceText,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // 친구 이름 버튼
            _NameButton(name: friend.name),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 상태 메시지 말풍선
class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
