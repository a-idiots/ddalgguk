import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/shared/widgets/speech_bubble.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.drunkLevel,
  });

  final AppUser user;
  final int drunkLevel;

  @override
  Widget build(BuildContext context) {
    final userName = user.name ?? 'User';
    final userId = user.id ?? 'username';
    final userMaxAlcohol = user.maxAlcohol ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@$userId',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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

          // Saku character on the left
          SizedBox(width: 60, height: 60, child: SakuCharacter(size: 60)),
        ],
      ),
    );
  }
}
