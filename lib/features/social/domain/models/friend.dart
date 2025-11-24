import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/features/social/domain/models/daily_status.dart';

/// 친구 관계 모델
class Friend {
  const Friend({
    required this.userId,
    required this.name,
    this.photoURL,
    required this.createdAt,
    this.dailyStatus,
    this.currentDrunkLevel,
    this.lastDrinkDate,
    this.daysSinceLastDrink,
    this.yesterdayAvgDrunkLevel,
    this.weeklyDrunkLevels,
  });

  /// Firestore에서 불러오기
  factory Friend.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // lastDrinkDate가 있으면 실시간으로 daysSince 계산
    final lastDrinkDate = data['lastDrinkDate'] != null
        ? (data['lastDrinkDate'] as Timestamp).toDate()
        : null;

    final daysSinceLastDrink = lastDrinkDate != null
        ? DateTime.now().difference(lastDrinkDate).inDays
        : null;

    return Friend(
      userId: data['userId'] as String,
      name: data['name'] as String,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dailyStatus: data['dailyStatus'] != null
          ? DailyStatus.fromFirestore(
              data['dailyStatus'] as Map<String, dynamic>,
            )
          : null,
      currentDrunkLevel: data['currentDrunkLevel'] as int?,
      lastDrinkDate: lastDrinkDate,
      daysSinceLastDrink: daysSinceLastDrink,
      yesterdayAvgDrunkLevel: null, // Provider에서 계산하여 설정
      weeklyDrunkLevels: data['weeklyDrunkLevels'] != null
          ? List<int>.from(data['weeklyDrunkLevels'] as List)
          : null,
    );
  }

  final String userId; // 친구의 사용자 ID
  final String name; // 친구 이름
  final String? photoURL; // 프로필 사진 URL
  final DateTime createdAt; // 친구 관계 생성 시간
  final DailyStatus? dailyStatus; // 오늘의 상태 메시지
  final int? currentDrunkLevel; // 현재 술 레벨 (0-10)
  final DateTime? lastDrinkDate; // 마지막 음주 날짜
  final int? daysSinceLastDrink; // 마지막 음주 이후 일수
  final int? yesterdayAvgDrunkLevel; // 어제의 평균 음주 레벨 (0-10)
  final List<int>?
  weeklyDrunkLevels; // 최근 7일 술 레벨 (-1: 기록없음, 0: 금주, 1-100: 음주레벨)

  /// Firestore에 저장하기
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'dailyStatus': dailyStatus?.toMap(),
      'currentDrunkLevel': currentDrunkLevel,
      'lastDrinkDate': lastDrinkDate != null
          ? Timestamp.fromDate(lastDrinkDate!)
          : null,
      'daysSinceLastDrink': daysSinceLastDrink,
      'weeklyDrunkLevels': weeklyDrunkLevels,
    };
  }

  /// 상태 메시지 반환 (만료된 경우 기본값)
  String get displayStatus {
    if (dailyStatus == null || dailyStatus!.isExpired) {
      return DailyStatus.defaultMessage;
    }
    return dailyStatus!.message;
  }

  /// 음주 레벨 반환 (주간 레벨 우선, 없으면 currentDrunkLevel, 없으면 0)
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

  Friend copyWith({
    String? userId,
    String? name,
    String? photoURL,
    DateTime? createdAt,
    DailyStatus? dailyStatus,
    int? currentDrunkLevel,
    DateTime? lastDrinkDate,
    int? daysSinceLastDrink,
    int? yesterdayAvgDrunkLevel,
    List<int>? weeklyDrunkLevels,
  }) {
    return Friend(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      currentDrunkLevel: currentDrunkLevel ?? this.currentDrunkLevel,
      lastDrinkDate: lastDrinkDate ?? this.lastDrinkDate,
      daysSinceLastDrink: daysSinceLastDrink ?? this.daysSinceLastDrink,
      yesterdayAvgDrunkLevel:
          yesterdayAvgDrunkLevel ?? this.yesterdayAvgDrunkLevel,
      weeklyDrunkLevels: weeklyDrunkLevels ?? this.weeklyDrunkLevels,
    );
  }
}
