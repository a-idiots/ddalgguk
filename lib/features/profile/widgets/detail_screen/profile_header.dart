import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/shared/widgets/speech_bubble.dart';

import 'package:ddalgguk/core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.theme,
    this.showCharacter = true,
  });

  final AppUser user;
  final AppTheme theme;
  final bool showCharacter;

  @override
  Widget build(BuildContext context) {
    final userName = user.name ?? 'User';
    final userId = user.id ?? 'username';
    final userMaxAlcohol = user.maxAlcohol ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@$userId',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Speech bubble on the left
          Expanded(
            child: SpeechBubble(
              text: '주량 $userMaxAlcohol병',
              tailPosition: TailPosition.right,
              backgroundColor: Colors.white,
              textColor: Colors.black87,
            ),
          ),

          const SizedBox(width: 12),

          // Saku character on the right
          SizedBox(
            width: 60,
            height: 60,
            child: showCharacter ? SakuCharacter(size: 60) : null,
          ),
        ],
      ),
    );
  }
}
