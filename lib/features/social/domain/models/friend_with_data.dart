import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';

/// 친구 관계 정보와 실제 유저 데이터를 함께 담는 모델
class FriendWithData {
  const FriendWithData({required this.friend, required this.userData});

  final Friend friend; // 친구 관계 정보 (userId, name, createdAt)
  final AppUser userData; // 실제 유저 데이터 (users 컬렉션에서 조회)

  /// 편의성을 위한 getter들
  String get userId => friend.userId;
  String get name => userData.name ?? friend.name;
  int get profilePhoto => userData.profilePhoto;
  DateTime? get lastDrinkDate => userData.lastDrinkDate;
  int? get currentDrunkLevel => userData.currentDrunkLevel;
  List<int>? get weeklyDrunkLevels => userData.weeklyDrunkLevels;

  /// 마지막 음주 이후 일수 (실시간 계산)
  int? get daysSinceLastDrink {
    if (lastDrinkDate == null) {
      return null;
    }
    return DateTime.now().difference(lastDrinkDate!).inDays;
  }

  /// 상태 메시지
  String get displayStatus {
    if (userData.dailyStatus == null || userData.dailyStatus!.isExpired) {
      return 'zZZ'; // 기본 메시지
    }
    return userData.dailyStatus!.message;
  }

  /// 표시용 음주 레벨 (0-100)
  int get displayDrunkLevel {
    // weeklyDrunkLevels가 있으면 가장 최근 값(어제) 사용
    if (weeklyDrunkLevels != null && weeklyDrunkLevels!.isNotEmpty) {
      // 마지막에서 두번째 값 (오늘은 제외하고 어제)
      final yesterdayIndex = weeklyDrunkLevels!.length >= 2
          ? weeklyDrunkLevels!.length - 2
          : weeklyDrunkLevels!.length - 1;
      final level = weeklyDrunkLevels![yesterdayIndex];
      // -1(기록없음)이면 0으로, 그 외에는 그대로 반환
      return level == -1 ? 0 : level;
    }
    // weeklyDrunkLevels가 없으면 currentDrunkLevel 사용 (0-10 -> 0-100 변환)
    if (currentDrunkLevel != null) {
      return currentDrunkLevel! * 10;
    }
    return 0;
  }
}
