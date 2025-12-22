import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/social/domain/models/daily_status.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/shared/utils/alcohol_calculator.dart';
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

        // 만료된 경우 데이터베이스에서도 삭제
        if (status.isExpired) {
          await _deleteMyDailyStatus();
          return null;
        }

        return status;
      }
    } catch (e) {
      debugPrint('Error getting my daily status: $e');
    }
    return null;
  }

  /// 나의 일일 상태 삭제 (내부용)
  Future<void> _deleteMyDailyStatus() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'dailyStatus': FieldValue.delete(),
      });
      debugPrint('✅ Expired daily status deleted from my profile');
    } catch (e) {
      debugPrint('❌ Error deleting daily status: $e');
    }
  }

  /// 모든 친구들의 만료된 일일 상태를 정리
  /// 소셜 화면 접속 시 호출
  Future<void> cleanupExpiredDailyStatuses(List<String> friendUserIds) async {
    debugPrint('=== cleanupExpiredDailyStatuses START ===');
    debugPrint('Checking ${friendUserIds.length} friends...');

    try {
      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final userId in friendUserIds) {
        final doc = await _firestore.collection('users').doc(userId).get();
        final data = doc.data();

        if (data != null && data['dailyStatus'] != null) {
          try {
            final status = DailyStatus.fromFirestore(
              data['dailyStatus'] as Map<String, dynamic>,
            );

            if (status.isExpired) {
              batch.update(_firestore.collection('users').doc(userId), {
                'dailyStatus': FieldValue.delete(),
              });
              deleteCount++;
              debugPrint(
                'Marked for deletion: $userId (expired ${DateTime.now().difference(status.expiresAt).inHours}h ago)',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing dailyStatus for $userId: $e');
          }
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        debugPrint('✅ Deleted $deleteCount expired daily statuses');
      } else {
        debugPrint('✅ No expired statuses to delete');
      }

      debugPrint('=== cleanupExpiredDailyStatuses END ===');
    } catch (e) {
      debugPrint('❌ Error cleaning up expired statuses: $e');
    }
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
    required double drunkLevel,
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
      // 주간 음주 레벨 계산 (이번 주 월~일)
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

  /// 이번 주차(월요일~일요일) 음주 레벨 계산
  /// -1: 기록 없음, 0: 금주(기록 있지만 안 마심), 1-100: 음주 레벨
  /// 배열 인덱스: [월(0), 화(1), 수(2), 목(3), 금(4), 토(5), 일(6)]
  Future<List<int>> _calculateWeeklyDrunkLevels() async {
    if (_currentUserId == null) {
      return List.filled(7, -1);
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 이번 주 월요일 계산 (weekday: 1=월요일, 7=일요일)
      final daysSinceMonday = today.weekday - 1;
      final thisMonday = today.subtract(Duration(days: daysSinceMonday));
      final thisSunday = thisMonday.add(const Duration(days: 6));

      // 이번 주 월요일~일요일 범위의 모든 음주 기록 가져오기
      final recordsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('drinkingRecords')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonday))
          .where(
            'date',
            isLessThan: Timestamp.fromDate(
              thisSunday.add(const Duration(days: 1)),
            ),
          )
          .get();

      // 날짜별로 그룹화
      final Map<String, List<double>> recordsByDate = {};
      for (final doc in recordsSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final drunkLevel = (data['drunkLevel'] as num).toDouble();
        recordsByDate.putIfAbsent(dateKey, () => []).add(drunkLevel);
      }

      // 7일 배열 생성 [월, 화, 수, 목, 금, 토, 일]
      final List<int> weeklyLevels = [];
      for (int i = 0; i < 7; i++) {
        final date = thisMonday.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final dayRecords = recordsByDate[dateKey];

        if (dayRecords == null || dayRecords.isEmpty) {
          // 기록 없음
          weeklyLevels.add(-1);
        } else {
          // 평균 음주 레벨 계산
          final totalLevel = dayRecords.fold<double>(
            0.0,
            (total, level) => total + level,
          );
          final avgLevel = totalLevel / dayRecords.length;
          // 0-10 범위를 0-100으로 변환
          weeklyLevels.add((avgLevel * 10).round());
        }
      }

      return weeklyLevels;
    } catch (e) {
      debugPrint('Error calculating weekly drunk levels: $e');
      return List.filled(7, -1);
    }
  }

  /// 특정 사용자의 이번 주차(월요일~일요일) 음주 레벨 계산 (친구용)
  /// -1: 기록 없음, 0: 금주(기록 있지만 안 마심), 1-100: 음주 레벨
  /// 배열 인덱스: [월(0), 화(1), 수(2), 목(3), 금(4), 토(5), 일(6)]
  Future<List<int>> _calculateWeeklyDrunkLevelsForUser(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 이번 주 월요일 계산 (weekday: 1=월요일, 7=일요일)
      final daysSinceMonday = today.weekday - 1;
      final thisMonday = today.subtract(Duration(days: daysSinceMonday));
      final thisSunday = thisMonday.add(const Duration(days: 6));

      // 이번 주 월요일~일요일 범위의 모든 음주 기록 가져오기
      final recordsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinkingRecords')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonday))
          .where(
            'date',
            isLessThan: Timestamp.fromDate(
              thisSunday.add(const Duration(days: 1)),
            ),
          )
          .get();

      // 날짜별로 그룹화
      final Map<String, List<double>> recordsByDate = {};
      for (final doc in recordsSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final drunkLevel = (data['drunkLevel'] as num).toDouble();
        recordsByDate.putIfAbsent(dateKey, () => []).add(drunkLevel);
      }

      // 7일 배열 생성 [월, 화, 수, 목, 금, 토, 일]
      final List<int> weeklyLevels = [];
      for (int i = 0; i < 7; i++) {
        final date = thisMonday.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final dayRecords = recordsByDate[dateKey];

        if (dayRecords == null || dayRecords.isEmpty) {
          // 기록 없음
          weeklyLevels.add(-1);
        } else {
          // 평균 음주 레벨 계산
          final totalLevel = dayRecords.fold<double>(
            0.0,
            (total, level) => total + level,
          );
          final avgLevel = totalLevel / dayRecords.length;
          // 0-10 범위를 0-100으로 변환
          weeklyLevels.add((avgLevel * 10).round());
        }
      }

      return weeklyLevels;
    } catch (e) {
      debugPrint('Error calculating weekly drunk levels for user $userId: $e');
      return List.filled(7, -1);
    }
  }

  /// 특정 사용자의 현재 취한 정도 계산 (친구용)
  /// AlcoholCalculator를 사용하여 최근 3일 기록 기반으로 정확하게 계산
  Future<int?> _calculateCurrentDrunkLevelForUser(String userId) async {
    try {
      final result = await calculateFriendAlcoholStats(userId);
      return result?.currentDrunkLevel.round();
    } catch (e) {
      debugPrint('Error calculating current drunk level for user $userId: $e');
      return null;
    }
  }

  /// 친구의 알코올 통계 전체 계산 (프로필 다이얼로그용)
  /// 친구의 체중, 키, 성별 등을 모두 고려하여 정확한 혈중 알코올 농도와 분해 시간 계산
  Future<AlcoholCalculationResult?> calculateFriendAlcoholStats(
    String userId,
  ) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final threeDaysAgo = today.subtract(const Duration(days: 2));

      // 최근 3일간의 음주 기록 가져오기
      final recordsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinkingRecords')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .get();

      if (recordsSnapshot.docs.isEmpty) {
        return null;
      }

      // DrinkingRecord 리스트로 변환
      final records = recordsSnapshot.docs.map((doc) {
        return DrinkingRecord.fromFirestore(doc);
      }).toList();

      // 친구의 userInfo 가져오기
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      Map<String, dynamic>? userInfo;
      if (userData != null) {
        userInfo = {
          'gender': userData['gender'],
          'birthDate': userData['birthDate'] != null
              ? (userData['birthDate'] as Timestamp).toDate()
              : null,
          'height': userData['height'],
          'weight': userData['weight'],
          'coefficient': userData['coefficient'],
        };

        // 기본값 적용 및 로그
        if (userInfo['weight'] == null) {
          debugPrint(
            '⚠️ Friend $userId has no weight data, using default 60kg',
          );
          userInfo['weight'] = 60.0;
        }
        if (userInfo['height'] == null) {
          debugPrint(
            '⚠️ Friend $userId has no height data, using default 170cm',
          );
          userInfo['height'] = 170.0;
        }
      } else {
        debugPrint('⚠️ Friend $userId has no user data, using all defaults');
        userInfo = {'weight': 60.0, 'height': 170.0};
      }

      // AlcoholCalculator로 정확한 계산 - 전체 결과 반환
      final result = AlcoholCalculator.calculate(
        userInfo: userInfo,
        records: records,
        now: now,
        today: today,
      );

      return result;
    } catch (e) {
      debugPrint('Error calculating friend alcohol stats for user $userId: $e');
      return null;
    }
  }

  /// 특정 친구의 음주 데이터 업데이트
  Future<void> updateFriendDrinkingData(String friendUserId) async {
    debugPrint('=== updateFriendDrinkingData START ===');
    debugPrint('Friend User ID: $friendUserId');

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 주간 음주 레벨 계산
      final weeklyDrunkLevels = await _calculateWeeklyDrunkLevelsForUser(
        friendUserId,
      );
      debugPrint('Weekly drunk levels for $friendUserId: $weeklyDrunkLevels');

      // 현재 취한 정도 계산
      final currentDrunkLevel = await _calculateCurrentDrunkLevelForUser(
        friendUserId,
      );
      debugPrint('Current drunk level for $friendUserId: $currentDrunkLevel');

      // 친구의 프로필 업데이트
      final updateData = <String, dynamic>{
        'weeklyDrunkLevels': weeklyDrunkLevels,
      };

      if (currentDrunkLevel != null) {
        updateData['currentDrunkLevel'] = currentDrunkLevel;
      }

      await _firestore.collection('users').doc(friendUserId).update(updateData);
      debugPrint('✅ Friend $friendUserId profile updated');
      debugPrint('=== updateFriendDrinkingData END ===');
    } catch (e) {
      debugPrint('❌ Error updating friend drinking data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // 에러가 발생해도 계속 진행 (다른 친구들은 업데이트되어야 함)
    }
  }

  /// 모든 친구들의 음주 데이터 업데이트
  Future<void> updateAllFriendsDrinkingData() async {
    debugPrint('=== updateAllFriendsDrinkingData START ===');

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 친구 목록 가져오기
      final friends = await getFriends();
      debugPrint('Updating drinking data for ${friends.length} friends');

      // 모든 친구의 데이터를 병렬로 업데이트
      await Future.wait(
        friends.map((friend) => updateFriendDrinkingData(friend.userId)),
      );

      debugPrint('✅ All friends drinking data updated');
      debugPrint('=== updateAllFriendsDrinkingData END ===');
    } catch (e) {
      debugPrint('❌ Error updating all friends drinking data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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

  /// 보낸 친구 요청 조회 (collectionGroup 사용)
  Future<List<FriendRequest>> getSentFriendRequests() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _getFriendRequestsCollection()
          .where('fromUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting sent friend requests: $e');
      return [];
    }
  }

  /// 친구 요청 보내기
  Future<void> sendFriendRequest({
    required String toUserId,
    required String toUserName,
    String? toUserPhoto,
    int? toUserProfilePhoto,
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
      final currentUserProfilePhoto =
          currentUserData?['profilePhoto'] as int? ?? 0;

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

      // toUser의 프로필 정보 가져오기
      int finalToUserProfilePhoto = toUserProfilePhoto ?? 0;
      if (toUserProfilePhoto == null) {
        final toUserDoc = await _firestore
            .collection('users')
            .doc(toUserId)
            .get();
        final toUserData = toUserDoc.data();
        finalToUserProfilePhoto = toUserData?['profilePhoto'] as int? ?? 0;
      }

      // 이미 요청을 보냈는지 확인
      final existingRequest = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: _currentUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('이미 친구 신청을 보낸 유저입니다');
      }

      // 요청 데이터
      final request = {
        'fromUserId': _currentUserId,
        'fromUserName': currentUserName,
        'fromUserPhoto': currentUserPhotoURL,
        'fromUserProfilePhoto': currentUserProfilePhoto,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'toUserProfilePhoto': finalToUserProfilePhoto,
        'message': message,
        'createdAt': Timestamp.now(),
        'status': FriendRequestStatus.pending.name,
      };

      // 양쪽 friendRequests 컬렉션에 동일한 ID로 기록
      final myRequestRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friendRequests')
          .doc();
      final theirRequestRef = _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .doc(myRequestRef.id);

      debugPrint('Request data: $request');
      debugPrint(
        'My path: users/$_currentUserId/friendRequests/${myRequestRef.id}',
      );
      debugPrint(
        'Their path: users/$toUserId/friendRequests/${theirRequestRef.id}',
      );

      final batch = _firestore.batch();
      batch.set(myRequestRef, request);
      batch.set(theirRequestRef, request);
      await batch.commit();

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
        profilePhoto: friendData['profilePhoto'] as int? ?? 0,
        provider:
            LoginProvider.fromString(friendData['provider'] as String?) ??
            LoginProvider.google,
        hasCompletedProfileSetup: true,
      );

      // 친구 관계 생성
      await addFriend(request.fromUserId, friendUser);

      // 양쪽 friendRequests에서 삭제
      final myRequestRef = _getFriendRequestsCollection().doc(request.id);
      final theirRequestRef = _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('friendRequests')
          .doc(request.id);

      final batch = _firestore.batch();
      batch.delete(myRequestRef);
      batch.delete(theirRequestRef);
      await batch.commit();

      debugPrint('Friend request accepted and deleted: ${request.id}');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// 친구 요청 거절
  Future<void> declineFriendRequest(String requestId) async {
    try {
      final myRequestRef = _getFriendRequestsCollection().doc(requestId);
      final snapshot = await myRequestRef.get();
      if (!snapshot.exists) {
        return;
      }
      final data = snapshot.data()!;
      final fromUserId = data['fromUserId'] as String?;

      final batch = _firestore.batch();
      batch.delete(myRequestRef);

      if (fromUserId != null) {
        final theirRequestRef = _firestore
            .collection('users')
            .doc(fromUserId)
            .collection('friendRequests')
            .doc(requestId);
        batch.delete(theirRequestRef);
      }

      await batch.commit();

      debugPrint('Friend request declined and deleted: $requestId');
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      rethrow;
    }
  }

  /// 보낸 친구 요청 취소 (보낸 사람이 취소)
  Future<void> cancelSentFriendRequest({
    required String requestId,
    required String toUserId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 보낸 요청 여부 확인
      final myRequestRef = _getFriendRequestsCollection().doc(requestId);
      final snapshot = await myRequestRef.get();
      if (!snapshot.exists) {
        throw Exception('Request not found');
      }
      final data = snapshot.data()!;
      final fromUserId = data['fromUserId'] as String?;
      if (fromUserId != _currentUserId) {
        throw Exception('Not request owner');
      }

      final theirRequestRef = _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friendRequests')
          .doc(requestId);

      final batch = _firestore.batch();
      batch.delete(myRequestRef);
      batch.delete(theirRequestRef);

      await batch.commit();
      debugPrint('Friend request cancelled: $requestId');
    } catch (e) {
      debugPrint('Error cancelling friend request: $e');
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

        // 자기 자신은 검색 결과에서 제외
        if (doc.id == _currentUserId) {
          return null;
        }

        final data = doc.data();
        return AppUser(
          uid: doc.id,
          name: data['name'] as String?,
          profilePhoto: data['profilePhoto'] as int? ?? 0,
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
            profilePhoto: data['profilePhoto'] as int? ?? 0,
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
