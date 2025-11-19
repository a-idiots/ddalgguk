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
    try {
      final snapshot = await _getFriendsCollection().orderBy('name').get();
      return snapshot.docs.map((doc) => Friend.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting friends: $e');
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
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final currentUser = _auth.currentUser!;
      final now = DateTime.now();

      // Batch write로 양방향 관계 생성
      final batch = _firestore.batch();

      // 현재 사용자의 friends 컬렉션에 친구 추가
      final myFriendRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendUserId);

      batch.set(myFriendRef, {
        'userId': friendUserId,
        'name': friendUser.name ?? friendUser.displayName ?? 'Unknown',
        'photoURL': friendUser.photoURL,
        'createdAt': Timestamp.fromDate(now),
        'dailyStatus': null,
        'currentDrunkLevel': null,
        'lastDrinkDate': null,
        'daysSinceLastDrink': null,
      });

      // 친구의 friends 컬렉션에 현재 사용자 추가
      final theirFriendRef = _firestore
          .collection('users')
          .doc(friendUserId)
          .collection('friends')
          .doc(_currentUserId);

      batch.set(theirFriendRef, {
        'userId': _currentUserId,
        'name': currentUser.displayName ?? 'Unknown',
        'photoURL': currentUser.photoURL,
        'createdAt': Timestamp.fromDate(now),
        'dailyStatus': null,
        'currentDrunkLevel': null,
        'lastDrinkDate': null,
        'daysSinceLastDrink': null,
      });

      await batch.commit();
      debugPrint('Friend added successfully: $friendUserId');
    } catch (e) {
      debugPrint('Error adding friend: $e');
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
  /// 내 프로필과 모든 친구들의 friends 컬렉션에 반영
  Future<void> updateMyDailyStatus(String message) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final status = DailyStatus.create(message);

      // 내 프로필에 상태 저장
      await _firestore.collection('users').doc(_currentUserId).update({
        'dailyStatus': status.toMap(),
      });

      // 모든 친구의 friends 컬렉션에서 나를 업데이트
      final myFriends = await getFriends();
      final batch = _firestore.batch();

      for (final friend in myFriends) {
        final friendRef = _firestore
            .collection('users')
            .doc(friend.userId)
            .collection('friends')
            .doc(_currentUserId);
        batch.update(friendRef, {'dailyStatus': status.toMap()});
      }

      await batch.commit();
      debugPrint('Daily status updated successfully');
    } catch (e) {
      debugPrint('Error updating daily status: $e');
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

  /// 나의 프로필을 Friend 형식으로 가져오기
  Future<Friend?> getMyProfile() async {
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

      final currentUser = _auth.currentUser!;

      // lastDrinkDate가 있으면 실시간으로 daysSince 계산
      final lastDrinkDate = data['lastDrinkDate'] != null
          ? (data['lastDrinkDate'] as Timestamp).toDate()
          : null;

      final daysSinceLastDrink = lastDrinkDate != null
          ? DateTime.now().difference(lastDrinkDate).inDays
          : null;

      debugPrint('lastDrinkDate from Firestore: $lastDrinkDate');
      debugPrint('Calculated daysSinceLastDrink: $daysSinceLastDrink');
      debugPrint(
        'daysSinceLastDrink from Firestore: ${data['daysSinceLastDrink']}',
      );

      final profile = Friend(
        userId: _currentUserId!,
        name: data['name'] as String? ?? currentUser.displayName ?? 'Me',
        photoURL: data['photoURL'] as String? ?? currentUser.photoURL,
        createdAt: DateTime.now(),
        dailyStatus: data['dailyStatus'] != null
            ? DailyStatus.fromFirestore(
                data['dailyStatus'] as Map<String, dynamic>,
              )
            : null,
        currentDrunkLevel: data['currentDrunkLevel'] as int?,
        lastDrinkDate: lastDrinkDate,
        daysSinceLastDrink: daysSinceLastDrink,
      );

      debugPrint(
        '✅ My profile loaded: ${profile.name}, drunkLevel: ${profile.currentDrunkLevel}, daysSince: ${profile.daysSinceLastDrink}',
      );
      return profile;
    } catch (e) {
      debugPrint('❌ Error getting my profile: $e');
      return null;
    }
  }

  // ==================== 음주 데이터 ====================

  /// 나의 음주 데이터 업데이트
  /// 내 프로필과 모든 친구들의 friends 컬렉션에 반영
  Future<void> updateMyDrinkingData({
    required int drunkLevel,
    required DateTime lastDrinkDate,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 마지막 음주 이후 일수 계산
      final now = DateTime.now();
      final daysSince = now.difference(lastDrinkDate).inDays;

      // 내 프로필에 음주 데이터 저장
      await _firestore.collection('users').doc(_currentUserId).update({
        'currentDrunkLevel': drunkLevel,
        'lastDrinkDate': Timestamp.fromDate(lastDrinkDate),
        'daysSinceLastDrink': daysSince,
      });

      // 모든 친구의 friends 컬렉션에서 나를 업데이트
      final myFriends = await getFriends();
      final batch = _firestore.batch();

      for (final friend in myFriends) {
        final friendRef = _firestore
            .collection('users')
            .doc(friend.userId)
            .collection('friends')
            .doc(_currentUserId);
        batch.update(friendRef, {
          'currentDrunkLevel': drunkLevel,
          'lastDrinkDate': Timestamp.fromDate(lastDrinkDate),
          'daysSinceLastDrink': daysSince,
        });
      }

      await batch.commit();
      debugPrint('Drinking data updated successfully');
    } catch (e) {
      debugPrint('Error updating drinking data: $e');
      rethrow;
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
      final currentUser = _auth.currentUser!;

      debugPrint('=== sendFriendRequest ===');
      debugPrint('From: $_currentUserId (${currentUser.displayName})');
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
        'fromUserName': currentUser.displayName ?? 'Unknown',
        'fromUserPhoto': currentUser.photoURL,
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
      // 요청 상태를 accepted로 변경
      await _getFriendRequestsCollection().doc(request.id).update({
        'status': FriendRequestStatus.accepted.name,
      });

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
        displayName: friendData['name'] as String?,
        photoURL: friendData['photoURL'] as String?,
        provider:
            LoginProvider.fromString(friendData['provider'] as String?) ??
            LoginProvider.google,
        createdAt: friendData['createdAt'] != null
            ? DateTime.parse(friendData['createdAt'] as String)
            : DateTime.now(),
        hasCompletedProfileSetup: true,
      );

      // 친구 관계 생성
      await addFriend(request.fromUserId, friendUser);

      debugPrint('Friend request accepted: ${request.id}');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// 친구 요청 거절
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _getFriendRequestsCollection().doc(requestId).update({
        'status': FriendRequestStatus.declined.name,
      });

      debugPrint('Friend request declined: $requestId');
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
          email: data['email'] as String?,
          displayName: data['name'] as String?,
          photoURL: data['photoURL'] as String?,
          provider:
              LoginProvider.fromString(data['provider'] as String?) ??
              LoginProvider.google,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
          hasCompletedProfileSetup:
              data['hasCompletedProfileSetup'] as bool? ?? false,
          id: data['id'] as String?,
          name: data['name'] as String?,
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
            email: data['email'] as String?,
            displayName: data['name'] as String?,
            photoURL: data['photoURL'] as String?,
            provider:
                LoginProvider.fromString(data['provider'] as String?) ??
                LoginProvider.google,
            createdAt: data['createdAt'] != null
                ? DateTime.parse(data['createdAt'] as String)
                : DateTime.now(),
            hasCompletedProfileSetup:
                data['hasCompletedProfileSetup'] as bool? ?? false,
            id: data['id'] as String?,
            name: data['name'] as String?,
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
