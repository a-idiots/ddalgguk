import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구의 일일 상태 메시지
/// - 매일 업데이트 가능
/// - 24시간 후 만료
class DailyStatus {
  const DailyStatus({
    required this.message,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Firestore에서 불러오기
  factory DailyStatus.fromFirestore(Map<String, dynamic> data) {
    return DailyStatus(
      message: data['message'] as String? ?? defaultMessage,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  /// 새 상태 생성 (24시간 만료)
  factory DailyStatus.create(String message) {
    final now = DateTime.now();
    return DailyStatus(
      message: message.isEmpty ? defaultMessage : message,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }

  /// 기본 상태 (zZZ)
  static const String defaultMessage = 'zZZ';

  /// 상태 메시지 최대 길이
  static const int maxLength = 30;

  final String message; // 상태 메시지 (기본: "zZZ")
  final DateTime createdAt; // 생성 시간
  final DateTime expiresAt; // 만료 시간

  /// 만료 여부 확인
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Firestore에 저장하기
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  DailyStatus copyWith({
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return DailyStatus(
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
