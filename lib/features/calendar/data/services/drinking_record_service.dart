import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/social/data/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 음주 기록을 관리하는 Firebase 서비스
/// Firestore 구조: users/{userId}/drinkingRecords/{recordId}
class DrinkingRecordService {
  DrinkingRecordService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FriendService? friendService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = firebaseAuth ?? FirebaseAuth.instance,
       _friendService = friendService ?? FriendService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FriendService _friendService;

  /// 현재 로그인한 사용자 ID 가져오기
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 사용자의 음주 기록 컬렉션 참조
  CollectionReference<Map<String, dynamic>> _getRecordsCollection() {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('drinkingRecords');
  }

  /// 음주 기록 생성
  /// 같은 날짜에 여러 기록이 있을 수 있으므로 sessionNumber를 자동으로 계산
  Future<String> createRecord(DrinkingRecord record) async {
    try {
      debugPrint('=== DrinkingRecordService.createRecord ===');
      debugPrint('현재 사용자 ID: $_currentUserId');
      debugPrint('저장 경로: users/$_currentUserId/drinkingRecords');

      if (_currentUserId == null) {
        throw Exception('User not logged in - cannot create record');
      }

      // 같은 날짜의 기록 개수를 확인하여 sessionNumber 결정
      final dateStart = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      final dateEnd = dateStart.add(const Duration(days: 1));

      final existingRecords = await _getRecordsCollection()
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .get();

      final sessionNumber = existingRecords.docs.length + 1;

      // sessionNumber를 포함한 새로운 record 생성
      final recordWithSession = record.copyWith(sessionNumber: sessionNumber);

      debugPrint('저장할 데이터: ${recordWithSession.toMap()}');

      final docRef = await _getRecordsCollection().add(
        recordWithSession.toMap(),
      );
      debugPrint('Created drinking record: ${docRef.id}');
      debugPrint('전체 경로: ${docRef.path}');

      // 친구들에게 음주 데이터 업데이트 (해당 날짜의 평균 계산)
      try {
        // 해당 날짜의 모든 기록을 다시 조회 (방금 추가한 기록 포함)
        final allRecordsForDate = await _getRecordsCollection()
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart),
            )
            .where('date', isLessThan: Timestamp.fromDate(dateEnd))
            .get();

        // 평균 drunkLevel 계산
        final records = allRecordsForDate.docs
            .map((doc) => DrinkingRecord.fromFirestore(doc))
            .toList();
        final totalDrunkLevel = records.fold<int>(
          0,
          (total, r) => total + r.drunkLevel,
        );
        final avgDrunkLevel = (totalDrunkLevel / records.length).round();

        debugPrint(
          'Records for date: ${records.length}, Average drunk level: $avgDrunkLevel',
        );

        await _friendService.updateMyDrinkingData(
          drunkLevel: avgDrunkLevel,
          lastDrinkDate: record.date,
        );
        debugPrint('Updated friend drinking data with average');
      } catch (e) {
        // 친구 데이터 업데이트 실패해도 기록 생성은 성공으로 처리
        debugPrint('Failed to update friend drinking data: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating drinking record: $e');
      rethrow;
    }
  }

  /// 음주 기록 읽기 (단건)
  Future<DrinkingRecord?> getRecord(String recordId) async {
    try {
      final doc = await _getRecordsCollection().doc(recordId).get();
      if (!doc.exists) {
        return null;
      }
      return DrinkingRecord.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting drinking record: $e');
      rethrow;
    }
  }

  /// 특정 날짜의 모든 음주 기록 가져오기
  Future<List<DrinkingRecord>> getRecordsByDate(DateTime date) async {
    try {
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      final querySnapshot = await _getRecordsCollection()
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .orderBy('date')
          .orderBy('sessionNumber')
          .get();

      return querySnapshot.docs
          .map((doc) => DrinkingRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting records by date: $e');
      rethrow;
    }
  }

  /// 특정 사용자의 특정 날짜 음주 기록 가져오기
  Future<List<DrinkingRecord>> getRecordsByDateForUser(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('drinkingRecords')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .orderBy('date')
          .orderBy('sessionNumber')
          .get();

      return querySnapshot.docs
          .map((doc) => DrinkingRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting records by date for user $userId: $e');
      return []; // 에러 발생 시 빈 리스트 반환
    }
  }

  /// 특정 기간의 모든 음주 기록 가져오기
  Future<List<DrinkingRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _getRecordsCollection()
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .orderBy('sessionNumber')
          .get();

      return querySnapshot.docs
          .map((doc) => DrinkingRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting records by date range: $e');
      rethrow;
    }
  }

  /// 특정 월의 모든 음주 기록 가져오기
  Future<List<DrinkingRecord>> getRecordsByMonth(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      return await getRecordsByDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error getting records by month: $e');
      rethrow;
    }
  }

  /// 음주 기록 업데이트
  Future<void> updateRecord(DrinkingRecord record) async {
    try {
      await _getRecordsCollection().doc(record.id).update(record.toMap());
      debugPrint('Updated drinking record: ${record.id}');

      // 친구들에게 음주 데이터 업데이트 (해당 날짜의 평균 재계산)
      try {
        final dateStart = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        final dateEnd = dateStart.add(const Duration(days: 1));

        // 해당 날짜의 모든 기록 조회
        final allRecordsForDate = await _getRecordsCollection()
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart),
            )
            .where('date', isLessThan: Timestamp.fromDate(dateEnd))
            .get();

        // 평균 drunkLevel 계산
        final records = allRecordsForDate.docs
            .map((doc) => DrinkingRecord.fromFirestore(doc))
            .toList();
        final totalDrunkLevel = records.fold<int>(
          0,
          (total, r) => total + r.drunkLevel,
        );
        final avgDrunkLevel = records.isNotEmpty
            ? (totalDrunkLevel / records.length).round()
            : 0;

        await _friendService.updateMyDrinkingData(
          drunkLevel: avgDrunkLevel,
          lastDrinkDate: record.date,
        );
        debugPrint('Updated friend drinking data after record update');
      } catch (e) {
        debugPrint('Failed to update friend drinking data: $e');
      }
    } catch (e) {
      debugPrint('Error updating drinking record: $e');
      rethrow;
    }
  }

  /// 음주 기록 삭제
  Future<void> deleteRecord(String recordId) async {
    try {
      // 삭제 전에 기록 조회 (날짜 정보 필요)
      final recordDoc = await _getRecordsCollection().doc(recordId).get();
      if (!recordDoc.exists) {
        debugPrint('Record not found: $recordId');
        return;
      }

      final recordToDelete = DrinkingRecord.fromFirestore(recordDoc);
      final recordDate = recordToDelete.date;

      // 기록 삭제
      await _getRecordsCollection().doc(recordId).delete();
      debugPrint('Deleted drinking record: $recordId');

      // 친구들에게 음주 데이터 업데이트 (해당 날짜의 평균 재계산)
      try {
        final dateStart = DateTime(
          recordDate.year,
          recordDate.month,
          recordDate.day,
        );
        final dateEnd = dateStart.add(const Duration(days: 1));

        // 삭제 후 남은 기록 조회
        final remainingRecords = await _getRecordsCollection()
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart),
            )
            .where('date', isLessThan: Timestamp.fromDate(dateEnd))
            .get();

        if (remainingRecords.docs.isEmpty) {
          // 해당 날짜의 기록이 모두 삭제됨 - 0으로 업데이트하지 않고 그냥 둠
          debugPrint('No records left for date: $recordDate');
        } else {
          // 평균 drunkLevel 재계산
          final records = remainingRecords.docs
              .map((doc) => DrinkingRecord.fromFirestore(doc))
              .toList();
          final totalDrunkLevel = records.fold<int>(
            0,
            (total, r) => total + r.drunkLevel,
          );
          final avgDrunkLevel = (totalDrunkLevel / records.length).round();

          await _friendService.updateMyDrinkingData(
            drunkLevel: avgDrunkLevel,
            lastDrinkDate: recordDate,
          );
          debugPrint('Updated friend drinking data after record deletion');
        }
      } catch (e) {
        debugPrint('Failed to update friend drinking data: $e');
      }
    } catch (e) {
      debugPrint('Error deleting drinking record: $e');
      rethrow;
    }
  }

  /// 실시간 음주 기록 스트림 (특정 날짜)
  Stream<List<DrinkingRecord>> streamRecordsByDate(DateTime date) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    return _getRecordsCollection()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .orderBy('date')
        .orderBy('sessionNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DrinkingRecord.fromFirestore(doc))
              .toList(),
        );
  }

  /// 실시간 음주 기록 스트림 (특정 월)
  Stream<List<DrinkingRecord>> streamRecordsByMonth(int year, int month) {
    // 사용자가 로그인하지 않았으면 빈 스트림 반환
    if (_currentUserId == null) {
      debugPrint('ERROR: User not logged in - returning empty stream');
      return Stream.value([]);
    }

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return _getRecordsCollection()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .orderBy('sessionNumber')
        .snapshots()
        .handleError((error) {
          debugPrint('ERROR in streamRecordsByMonth: $error');
        })
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DrinkingRecord.fromFirestore(doc))
              .toList(),
        );
  }
}
