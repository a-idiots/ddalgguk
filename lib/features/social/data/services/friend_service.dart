import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/social/domain/models/daily_status.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';

/// 친구 관계 및 친구 요청 관리 서비스
class FriendService {
  FriendService({FirebaseFirestore? firestore, auth.FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = firebaseAuth ?? auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;

  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== 친구 관계 ====================

  /// 현재 사용자의 친구 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _getFriendsCollection() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends');
  }

  /// 친구 목록 스트림
  Stream<List<Friend>> streamFriends() {
    try {
      return _getFriendsCollection()
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Friend.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      debugPrint('Error streaming friends: $e');
      return Stream.value([]);
    }
  }

  /// 친구 목록 조회
  Future<List<Friend>> getFriends() async {
    debugPrint('=== getFriends ===');
    debugPrint('Current User ID: $_currentUserId');

    try {
      final snapshot = await _getFriendsCollection().orderBy('name').get();
      debugPrint('Found ${snapshot.docs.length} friends');

      final friends = snapshot.docs.map((doc) {
        final friend = Friend.fromFirestore(doc);
        debugPrint('Friend: ${friend.name} (userId: ${friend.userId})');
        return friend;
      }).toList();

      return friends;
    } catch (e) {
      debugPrint('❌ Error getting friends: $e');
      return [];
    }
  }

  /// 특정 친구 조회
  Future<Friend?> getFriend(String friendUserId) async {
    try {
      final doc = await _getFriendsCollection().doc(friendUserId).get();
      if (doc.exists) {
        return Friend.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting friend: $e');
    }
    return null;
  }

  /// 친구 추가 (양방향)
  /// 양쪽 사용자의 friends 컬렉션에 서로 추가
  Future<void> addFriend(String friendUserId, AppUser friendUser) async {
    debugPrint('=== addFriend START ===');
    debugPrint('Current User ID (me): $_currentUserId');
    debugPrint('Friend User ID: $friendUserId');

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final now = DateTime.now();

      // 현재 사용자의 Firestore 데이터 가져오기 (name 필드 사용)
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['name'] as String? ?? 'Unknown';

      debugPrint('My name: $currentUserName');
      debugPrint('Friend name: ${friendUser.name}');

      // Batch write로 양방향 관계 생성
      final batch = _firestore.batch();

      // 현재 사용자의 friends 컬렉션에 친구 추가
      final myFriendRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendUserId);

      debugPrint(
        'Adding to MY friends: users/$_currentUserId/friends/$friendUserId',
      );

      batch.set(myFriendRef, {
        'userId': friendUserId,
        'name': friendUser.name ?? 'Unknown',
        'createdAt': Timestamp.fromDate(now),
      });

      // 친구의 friends 컬렉션에 현재 사용자 추가
      final theirFriendRef = _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('friends')
          .doc(_currentUserId);

      debugPrint(
        'Adding to THEIR friends: users/$friendUserId/friends/$_currentUserId',
      );

      batch.set(theirFriendRef, {
        'userId': _currentUserId,
        'name': currentUserName,
        'createdAt': Timestamp.fromDate(now),
      });

      debugPrint('Committing batch...');
      await batch.commit();
      debugPrint('✅ Friend added successfully (both sides): $friendUserId');
      debugPrint('=== addFriend END ===');
    } catch (e) {
      debugPrint('❌ Error adding friend: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 친구 삭제 (양방향)
  Future<void> removeFriend(String friendUserId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final batch = _firestore.batch();

      // 내 friends 컬렉션에서 삭제
      final myFriendRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendUserId);
      batch.delete(myFriendRef);

      // 친구의 friends 컬렉션에서 삭제
      final theirFriendRef = _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('friends')
          .doc(_currentUserId);
      batch.delete(theirFriendRef);

      await batch.commit();
      debugPrint('Friend removed successfully: $friendUserId');
    } catch (e) {
      debugPrint('Error removing friend: $e');
      rethrow;
    }
  }

  /// 친구 여부 확인
  Future<bool> isFriend(String userId) async {
    try {
      final doc = await _getFriendsCollection().doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking friend status: $e');
      return false;
    }
  }

  // ==================== 일일 상태 ====================

  /// 나의 일일 상태 업데이트
  /// 내 프로필에만 저장 (친구들은 users 컬렉션에서 직접 조회)
  Future<void> updateMyDailyStatus(String message) async {
    debugPrint('=== updateMyDailyStatus START ===');
    debugPrint('Current User ID: $_currentUserId');
    debugPrint('Status Message: $message');

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final status = DailyStatus.create(message);
      debugPrint('Created DailyStatus: ${status.toMap()}');

      // 내 프로필에 상태 저장
      debugPrint('Updating my profile: users/$_currentUserId');
      await _firestore.collection('users').doc(_currentUserId).update({
        'dailyStatus': status.toMap(),
      });
      debugPrint('✅ My profile status updated');
      debugPrint('=== updateMyDailyStatus END ===');
    } catch (e) {
      debugPrint('❌ Error updating daily status: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 나의 일일 상태 조회
  Future<DailyStatus?> getMyDailyStatus() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      final data = doc.data();
      if (data != null && data['dailyStatus'] != null) {
        final status = DailyStatus.fromFirestore(
          data['dailyStatus'] as Map<String, dynamic>,
        );
        return status.isExpired ? null : status;
      }
    } catch (e) {
      debugPrint('Error getting my daily status: $e');
    }
    return null;
  }

  // ==================== 나의 프로필 ====================

  /// 나의 프로필을 AppUser 형식으로 가져오기
  Future<AppUser?> getMyProfile() async {
    debugPrint('=== getMyProfile ===');
    debugPrint('Current User ID: $_currentUserId');

    if (_currentUserId == null) {
      debugPrint('❌ User not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      debugPrint('Document exists: ${doc.exists}');

      if (!doc.exists) {
        debugPrint('❌ User document does not exist');
        return null;
      }

      final data = doc.data()!;
      debugPrint('User data: $data');

      final profile = AppUser.fromJson(data);

      debugPrint('✅ My profile loaded: ${profile.name}');
      return profile;
    } catch (e) {
      debugPrint('❌ Error getting my profile: $e');
      return null;
    }
  }

  /// 친구의 프로필을 AppUser 형식으로 가져오기
  Future<AppUser?> getFriendProfile(String friendUserId) async {
    debugPrint('=== getFriendProfile ===');
    debugPrint('Friend User ID: $friendUserId');

    try {
      final doc = await _firestore.collection('users').doc(friendUserId).get();

      if (!doc.exists) {
        debugPrint('❌ Friend document does not exist');
        return null;
      }

      final data = doc.data()!;
      final profile = AppUser.fromJson(data);

      debugPrint('✅ Friend profile loaded: ${profile.name}');
      return profile;
    } catch (e) {
      debugPrint('❌ Error getting friend profile: $e');
      return null;
    }
  }

  // ==================== 음주 데이터 ====================

  /// 나의 음주 데이터 업데이트
  /// 내 프로필에만 저장 (친구들은 users 컬렉션에서 직접 조회)
  Future<void> updateMyDrinkingData({
    required int drunkLevel,
    required DateTime lastDrinkDate,
  }) async {
    debugPrint('=== updateMyDrinkingData START ===');
    debugPrint('Current User ID: $_currentUserId');
    debugPrint('Drunk Level: $drunkLevel');
    debugPrint('Last Drink Date: $lastDrinkDate');

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 주간 음주 레벨 계산 (최근 7일)
      final weeklyDrunkLevels = await _calculateWeeklyDrunkLevels();
      debugPrint('Weekly drunk levels: $weeklyDrunkLevels');

      // 내 프로필에 음주 데이터 저장
      debugPrint('Updating my profile: users/$_currentUserId');
      await _firestore.collection('users').doc(_currentUserId).update({
        'currentDrunkLevel': drunkLevel,
        'lastDrinkDate': Timestamp.fromDate(lastDrinkDate),
        'weeklyDrunkLevels': weeklyDrunkLevels,
      });
      debugPrint('✅ My profile updated');
      debugPrint('=== updateMyDrinkingData END ===');
    } catch (e) {
      debugPrint('❌ Error updating drinking data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 최근 7일 간의 음주 레벨 계산
  /// -1: 기록 없음, 0: 금주(기록 있지만 안 마심), 1-100: 음주 레벨
  Future<List<int>> _calculateWeeklyDrunkLevels() async {
    if (_currentUserId == null) {
      return List.filled(7, -1);
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDate = today.subtract(const Duration(days: 6));

      // 최근 7일 간의 모든 음주 기록 가져오기
      final recordsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('drinkingRecords')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(
            'date',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .get();

      // 날짜별로 그룹화
      final Map<String, List<int>> recordsByDate = {};
      for (final doc in recordsSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final drunkLevel = data['drunkLevel'] as int;
        recordsByDate.putIfAbsent(dateKey, () => []).add(drunkLevel);
      }

      // 7일 배열 생성
      final List<int> weeklyLevels = [];
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final dayRecords = recordsByDate[dateKey];

        if (dayRecords == null || dayRecords.isEmpty) {
          // 기록 없음
          weeklyLevels.add(-1);
        } else {
          // 최대 음주 레벨 찾기
          final maxLevel = dayRecords.reduce((a, b) => a > b ? a : b);
          // 0-10 범위를 0-100으로 변환
          weeklyLevels.add(maxLevel * 10);
        }
      }

      return weeklyLevels;
    } catch (e) {
      debugPrint('Error calculating weekly drunk levels: $e');
      return List.filled(7, -1);
    }
  }

  // ==================== 친구 요청 ====================

  /// 친구 요청 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _getFriendRequestsCollection() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friendRequests');
  }

  /// 받은 친구 요청 스트림 (pending만)
  Stream<List<FriendRequest>> streamReceivedFriendRequests() {
    try {
      return _getFriendRequestsCollection()
          .where('toUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FriendRequest.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      debugPrint('Error streaming friend requests: $e');
      return Stream.value([]);
    }
  }

  /// 받은 친구 요청 조회
  Future<List<FriendRequest>> getReceivedFriendRequests() async {
    try {
      final snapshot = await _getFriendRequestsCollection()
          .where('toUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting friend requests: $e');
      return [];
    }
  }

  /// 친구 요청 보내기
  Future<void> sendFriendRequest({
    required String toUserId,
    required String toUserName,
    String? toUserPhoto,
    required String message,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 현재 사용자의 Firestore 데이터 가져오기 (name 필드 사용)
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['name'] as String? ?? 'Unknown';
      final currentUserPhotoURL = currentUserData?['photoURL'] as String?;

      debugPrint('=== sendFriendRequest ===');
      debugPrint('From: $_currentUserId ($currentUserName)');
      debugPrint('To: $toUserId ($toUserName)');

      // 자기 자신에게 요청 보내는지 확인
      if (toUserId == _currentUserId) {
        throw Exception('자기 자신에게는 친구 신청을 보낼 수 없습니다');
      }

      // 이미 친구인지 확인
      final alreadyFriends = await isFriend(toUserId);
      if (alreadyFriends) {
        throw Exception('이미 친구로 등록된 사용자입니다');
      }

      // 이미 요청을 보냈는지 확인
      final existingRequest = await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('이미 친구 신청을 보낸 유저입니다');
      }

      // 상대방의 friendRequests 컬렉션에 요청 추가
      final request = {
        'fromUserId': _currentUserId,
        'fromUserName': currentUserName,
        'fromUserPhoto': currentUserPhotoURL,
        'toUserId': toUserId,
        'message': message,
        'createdAt': Timestamp.now(),
        'status': FriendRequestStatus.pending.name,
      };

      debugPrint('Request data: $request');
      debugPrint('Target path: users/$toUserId/friendRequests');

      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .add(request);

      debugPrint('✅ Friend request sent successfully to: $toUserId');
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      rethrow;
    }
  }

  /// 친구 요청 수락
  Future<void> acceptFriendRequest(FriendRequest request) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 요청 보낸 사용자 정보 조회
      final friendDoc = await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .get();
      if (!friendDoc.exists) {
        throw Exception('Friend user not found');
      }

      final friendData = friendDoc.data()!;
      final friendUser = AppUser(
        uid: request.fromUserId,
        name: friendData['name'] as String?,
        photoURL: friendData['photoURL'] as String?,
        provider:
            LoginProvider.fromString(friendData['provider'] as String?) ??
            LoginProvider.google,
        hasCompletedProfileSetup: true,
      );

      // 친구 관계 생성
      await addFriend(request.fromUserId, friendUser);

      // 친구 관계가 생성되었으므로 요청을 삭제
      await _getFriendRequestsCollection().doc(request.id).delete();

      debugPrint('Friend request accepted and deleted: ${request.id}');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// 친구 요청 거절
  Future<void> declineFriendRequest(String requestId) async {
    try {
      // 거절한 요청은 삭제
      await _getFriendRequestsCollection().doc(requestId).delete();

      debugPrint('Friend request declined and deleted: $requestId');
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      rethrow;
    }
  }

  /// 친구 요청 삭제
  Future<void> deleteFriendRequest(String requestId) async {
    try {
      await _getFriendRequestsCollection().doc(requestId).delete();
      debugPrint('Friend request deleted: $requestId');
    } catch (e) {
      debugPrint('Error deleting friend request: $e');
      rethrow;
    }
  }

  // ==================== 사용자 검색 ====================

  /// ID로 사용자 검색 ('id' 필드로 검색)
  Future<AppUser?> searchUserById(String userId) async {
    try {
      // 'id' 필드로 검색
      final snapshot = await _firestore
          .collection('users')
          .where('id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        return AppUser(
          uid: doc.id,
          name: data['name'] as String?,
          photoURL: data['photoURL'] as String?,
          provider:
              LoginProvider.fromString(data['provider'] as String?) ??
              LoginProvider.google,
          hasCompletedProfileSetup:
              data['hasCompletedProfileSetup'] as bool? ?? false,
          id: data['id'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error searching user: $e');
    }
    return null;
  }

  /// ID prefix로 사용자 목록 검색 (자동완성용)
  Future<List<AppUser>> searchUsersByIdPrefix(
    String prefix, {
    int limit = 10,
  }) async {
    if (prefix.isEmpty) {
      return [];
    }

    try {
      // Firestore의 범위 쿼리를 사용하여 prefix 검색
      // prefix로 시작하는 모든 문서를 찾기 위해 '>=' 와 '<' 사용
      final String endPrefix =
          prefix.substring(0, prefix.length - 1) +
          String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);

      final snapshot = await _firestore
          .collection('users')
          .where('id', isGreaterThanOrEqualTo: prefix)
          .where('id', isLessThan: endPrefix)
          .orderBy('id')
          .limit(limit)
          .get();

      final users = <AppUser>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // 현재 사용자는 제외
        if (doc.id == _currentUserId) {
          continue;
        }

        users.add(
          AppUser(
            uid: doc.id,
            name: data['name'] as String?,
            photoURL: data['photoURL'] as String?,
            provider:
                LoginProvider.fromString(data['provider'] as String?) ??
                LoginProvider.google,
            hasCompletedProfileSetup:
                data['hasCompletedProfileSetup'] as bool? ?? false,
            id: data['id'] as String?,
          ),
        );
      }

      return users;
    } catch (e) {
      debugPrint('Error searching users by prefix: $e');
      return [];
    }
  }
}
