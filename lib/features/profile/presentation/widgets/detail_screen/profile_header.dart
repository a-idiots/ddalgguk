import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.drunkLevel,
    this.isExpanded = true,
  });

  final AppUser user;
  final int drunkLevel;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final sakuSize = isExpanded ? 80.0 : 50.0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isExpanded ? 20 : 12,
      ),
      child: Row(
        children: [
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name ?? user.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: isExpanded ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${user.id ?? 'username'}',
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Saku avatar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sakuSize,
            height: sakuSize,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: ClipOval(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SakuCharacter(size: sakuSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
