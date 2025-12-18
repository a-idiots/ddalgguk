import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구 요청 상태
enum FriendRequestStatus {
  pending, // 대기 중
  accepted, // 수락됨
  declined, // 거절됨
}

/// 친구 요청 모델
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhoto,
    this.fromUserProfilePhoto = 0,
    required this.toUserId,
    this.toUserName,
    this.toUserProfilePhoto = 0,
    required this.message,
    required this.createdAt,
    required this.status,
  });

  /// Firestore에서 불러오기
  factory FriendRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String,
      fromUserPhoto: data['fromUserPhoto'] as String?,
      fromUserProfilePhoto: data['fromUserProfilePhoto'] as int? ?? 0,
      toUserId: data['toUserId'] as String,
      toUserName: data['toUserName'] as String?,
      toUserProfilePhoto: data['toUserProfilePhoto'] as int? ?? 0,
      message: data['message'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
    );
  }

  /// 요청 메시지 최대 길이
  static const int maxMessageLength = 100;

  final String id; // Firestore 문서 ID
  final String fromUserId; // 요청 보낸 사용자 ID
  final String fromUserName; // 요청 보낸 사용자 이름
  final String? fromUserPhoto; // 요청 보낸 사용자 프로필 사진
  final int? fromUserProfilePhoto; // 요청 보낸 사용자 프로필 사진 인덱스
  final String toUserId; // 요청 받은 사용자 ID
  final String? toUserName; // 요청 받은 사용자 이름 (선택)
  final int? toUserProfilePhoto; // 요청 받은 사용자 프로필 사진 인덱스
  final String message; // 요청 메시지
  final DateTime createdAt; // 요청 생성 시간
  final FriendRequestStatus status; // 요청 상태

  /// Firestore에 저장하기
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhoto': fromUserPhoto,
      'fromUserProfilePhoto': fromUserProfilePhoto,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'toUserProfilePhoto': toUserProfilePhoto,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  /// 요청 수락으로 상태 변경
  FriendRequest accept() {
    return copyWith(status: FriendRequestStatus.accepted);
  }

  /// 요청 거절로 상태 변경
  FriendRequest decline() {
    return copyWith(status: FriendRequestStatus.declined);
  }

  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? fromUserPhoto,
    int? fromUserProfilePhoto,
    String? toUserId,
    String? toUserName,
    int? toUserProfilePhoto,
    String? message,
    DateTime? createdAt,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPhoto: fromUserPhoto ?? this.fromUserPhoto,
      fromUserProfilePhoto: fromUserProfilePhoto ?? this.fromUserProfilePhoto,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      toUserProfilePhoto: toUserProfilePhoto ?? this.toUserProfilePhoto,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
