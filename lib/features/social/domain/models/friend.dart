import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구 관계 모델
/// 친구 컬렉션에는 기본 정보만 저장하고, 나머지는 user 컬렉션에서 조회
class Friend {
  const Friend({
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  /// Firestore에서 불러오기
  factory Friend.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return Friend(
      userId: data['userId'] as String,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  final String userId; // 친구의 사용자 ID
  final String name; // 친구 이름
  final DateTime createdAt; // 친구 관계 생성 시간

  /// Firestore에 저장하기
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Friend copyWith({String? userId, String? name, DateTime? createdAt}) {
    return Friend(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
