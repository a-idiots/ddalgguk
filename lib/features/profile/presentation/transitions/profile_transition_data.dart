import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';

/// Shared data between ProfileScreen and ProfileDetailScreen for smooth transition
class ProfileTransitionData {
  const ProfileTransitionData({
    required this.user,
    required this.drunkLevel,
    required this.stats,
    required this.sakuImagePath,
  });

  final AppUser user;
  final int drunkLevel;
  final ProfileStats stats;
  final String sakuImagePath;
}
