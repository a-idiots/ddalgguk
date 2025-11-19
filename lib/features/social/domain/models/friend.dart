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
  });

  /// Firestore에서 불러오기
  factory Friend.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
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
      lastDrinkDate: data['lastDrinkDate'] != null
          ? (data['lastDrinkDate'] as Timestamp).toDate()
          : null,
      daysSinceLastDrink: data['daysSinceLastDrink'] as int?,
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
    };
  }

  /// 상태 메시지 반환 (만료된 경우 기본값)
  String get displayStatus {
    if (dailyStatus == null || dailyStatus!.isExpired) {
      return DailyStatus.defaultMessage;
    }
    return dailyStatus!.message;
  }

  /// 음주 레벨 반환 (없으면 0)
  int get displayDrunkLevel => currentDrunkLevel ?? 0;

  Friend copyWith({
    String? userId,
    String? name,
    String? photoURL,
    DateTime? createdAt,
    DailyStatus? dailyStatus,
    int? currentDrunkLevel,
    DateTime? lastDrinkDate,
    int? daysSinceLastDrink,
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
    );
  }
}
