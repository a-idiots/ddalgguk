import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/ranking/data/services/ranking_service.dart';
import 'package:ddalgguk/features/social/data/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ddalgguk/features/profile/data/services/badge_service.dart';
import 'package:flutter/foundation.dart';

/// 음주 기록을 관리하는 Firebase 서비스
/// Firestore 구조: users/{userId}/drinkingRecords/{recordId}
class DrinkingRecordService {
  DrinkingRecordService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FriendService? friendService,
    BadgeService? badgeService, // Injected
    RankingService? rankingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = firebaseAuth ?? FirebaseAuth.instance,
       _friendService = friendService ?? FriendService(),
       _badgeService = badgeService ?? BadgeService.instance,
       _rankingService = rankingService ?? RankingService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FriendService _friendService;
  final BadgeService _badgeService;
  final RankingService _rankingService;

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
      // UTC 자정 기준으로 쿼리: 해외 타임존에서도 날짜 일치
      final dateStart = DateTime.utc(
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

      // 부수효과를 병렬 실행 (서로 독립적)
      final recordWithId = recordWithSession.copyWith(id: docRef.id);
      await Future.wait([
        // 1. 내 weeklyDrunkLevels 업데이트
        _updateMyDrinkingDataForRecord(recordWithId).catchError(
          (e) => debugPrint('Failed to update drinking data: $e'),
        ),
        // 2. 뱃지/로컬 통계
        _updateLocalStats(record.date).catchError(
          (e) => debugPrint('Failed to update local stats: $e'),
        ),
        // 3. 랭킹
        if (_currentUserId != null && record.drinkAmount.isNotEmpty)
          () async {
            final totalAlcoholG = record.drinkAmount.fold<double>(
              0.0,
              (acc, d) => acc + d.amount * d.alcoholContent / 100 * 0.8,
            );
            await _rankingService.addAlcohol(
              _currentUserId!,
              totalAlcoholG,
              record.date,
            );
          }().catchError(
            (e) => debugPrint('Failed to update ranking: $e'),
          ),
      ]);

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
      // UTC 자정 기준으로 쿼리: 해외 타임존에서도 날짜 일치
      final dateStart = DateTime.utc(date.year, date.month, date.day);
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
      // UTC 자정 기준으로 쿼리: 해외 타임존에서도 날짜 일치
      final dateStart = DateTime.utc(date.year, date.month, date.day);
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
      // UTC 자정 기준으로 쿼리: 해외 타임존에서도 월 경계가 정확함
      final startDate = DateTime.utc(year, month, 1);
      final endDate = DateTime.utc(year, month + 1, 0, 23, 59, 59);

      return await getRecordsByDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error getting records by month: $e');
      rethrow;
    }
  }

  /// 음주 기록 업데이트
  Future<void> updateRecord(DrinkingRecord record) async {
    try {
      // Firestore write와 oldRecord 조회를 병렬 실행
      final results = await Future.wait([
        _getRecordsCollection().doc(record.id).update(record.toMap()),
        getRecord(record.id),
      ]);
      final oldRecord = results[1] as DrinkingRecord?;
      debugPrint('Updated drinking record: ${record.id}');

      // 부수효과를 병렬 실행 (서로 독립적)
      await Future.wait([
        // 1. 내 weeklyDrunkLevels 업데이트
        _updateMyDrinkingDataForRecord(record).catchError(
          (e) => debugPrint('Failed to update drinking data: $e'),
        ),
        // 2. 뱃지/로컬 통계
        _updateLocalStats(record.date).catchError(
          (e) => debugPrint('Failed to update local stats: $e'),
        ),
        // 3. 랭킹 delta (이전 기록과 새 기록의 차이만 반영)
        _updateRankingDelta(oldRecord, record).catchError(
          (e) => debugPrint('Failed to update ranking: $e'),
        ),
      ]);
    } catch (e) {
      debugPrint('Error updating drinking record: $e');
      rethrow;
    }
  }

  /// 내 weeklyDrunkLevels + lastDrinkDate 업데이트 (해당 날짜 기록 기반)
  Future<void> _updateMyDrinkingDataForRecord(DrinkingRecord record) async {
    final dateStart = DateTime.utc(
      record.date.year,
      record.date.month,
      record.date.day,
    );
    final dateEnd = dateStart.add(const Duration(days: 1));

    final allRecordsForDate = await _getRecordsCollection()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .get();

    final records = allRecordsForDate.docs
        .map((doc) => DrinkingRecord.fromFirestore(doc))
        .toList();

    if (records.isEmpty) {
      return;
    }

    final avgDrunkLevel = records.fold<double>(
          0.0,
          (total, r) => total + r.drunkLevel,
        ) /
        records.length;

    final isDrinkingRecord = records.any(
      (r) => r.drunkLevel > 0 || r.drinkAmount.any((d) => d.amount > 0),
    );

    if (isDrinkingRecord) {
      final latestDrinkDate = await _findLatestDrinkDate();
      await _friendService.updateMyDrinkingData(
        drunkLevel: avgDrunkLevel,
        lastDrinkDate: latestDrinkDate ?? record.date,
      );
    }
  }

  /// 랭킹 delta 업데이트 (old → new 알코올량 차이만 adjust)
  Future<void> _updateRankingDelta(
    DrinkingRecord? oldRecord,
    DrinkingRecord newRecord,
  ) async {
    if (_currentUserId == null) {
      return;
    }

    double calcAlcohol(DrinkingRecord r) => r.drinkAmount.fold<double>(
      0.0,
      (acc, d) => acc + d.amount * d.alcoholContent / 100 * 0.8,
    );

    final oldAlcohol =
        oldRecord != null ? calcAlcohol(oldRecord) : 0.0;
    final newAlcohol = calcAlcohol(newRecord);
    final delta = newAlcohol - oldAlcohol;

    if (delta.abs() > 0.001) {
      await _rankingService.adjustAlcohol(
        _currentUserId!,
        delta,
        newRecord.date,
      );
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

      // 부수효과를 병렬 실행
      await Future.wait([
        // 1. 내 weeklyDrunkLevels 업데이트
        _updateMyDrinkingDataAfterDelete(recordToDelete).catchError(
          (e) => debugPrint('Failed to update drinking data: $e'),
        ),
        // 2. 뱃지/로컬 통계
        _updateLocalStats(recordDate).catchError(
          (e) => debugPrint('Failed to update local stats: $e'),
        ),
        // 3. 랭킹 차감
        if (_currentUserId != null && recordToDelete.drinkAmount.isNotEmpty)
          () async {
            final alcoholToRemove = recordToDelete.drinkAmount.fold<double>(
              0.0,
              (acc, d) => acc + d.amount * d.alcoholContent / 100 * 0.8,
            );
            if (alcoholToRemove > 0) {
              await _rankingService.adjustAlcohol(
                _currentUserId!,
                -alcoholToRemove,
                recordToDelete.date,
              );
            }
          }().catchError(
            (e) => debugPrint('Failed to update ranking: $e'),
          ),
      ]);
    } catch (e) {
      debugPrint('Error deleting drinking record: $e');
      rethrow;
    }
  }

  /// 삭제 후 내 weeklyDrunkLevels + lastDrinkDate 업데이트
  Future<void> _updateMyDrinkingDataAfterDelete(
    DrinkingRecord deletedRecord,
  ) async {
    final dateStart = DateTime.utc(
      deletedRecord.date.year,
      deletedRecord.date.month,
      deletedRecord.date.day,
    );
    final dateEnd = dateStart.add(const Duration(days: 1));

    final remainingSnap = await _getRecordsCollection()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .get();

    if (remainingSnap.docs.isEmpty) {
      // 해당 날짜 기록 전부 삭제 → 최근 음주 기록으로 업데이트
      final latestDrinkDate = await _findLatestDrinkDate();
      if (latestDrinkDate != null) {
        await _friendService.updateMyDrinkingData(
          drunkLevel: 0,
          lastDrinkDate: latestDrinkDate,
        );
      } else {
        await _friendService.updateMyDrinkingData(
          drunkLevel: 0,
          lastDrinkDate: DateTime.now(),
        );
      }
    } else {
      // 같은 날 남은 기록으로 평균 재계산
      final records = remainingSnap.docs
          .map((doc) => DrinkingRecord.fromFirestore(doc))
          .toList();
      final avgDrunkLevel = records.fold<double>(
            0.0,
            (total, r) => total + r.drunkLevel,
          ) /
          records.length;

      final isDrinking = records.any(
        (r) => r.drunkLevel > 0 || r.drinkAmount.any((d) => d.amount > 0),
      );

      if (isDrinking) {
        final latestDrinkDate = await _findLatestDrinkDate();
        await _friendService.updateMyDrinkingData(
          drunkLevel: avgDrunkLevel,
          lastDrinkDate: latestDrinkDate ?? deletedRecord.date,
        );
      }
    }
  }

  /// sessionNumber만 업데이트 (friend/ranking/badge 부수효과 없이)
  Future<void> updateSessionNumber(String recordId, int sessionNumber) async {
    await _getRecordsCollection().doc(recordId).update({
      'sessionNumber': sessionNumber,
    });
  }

  /// 실시간 음주 기록 스트림 (특정 날짜)
  Stream<List<DrinkingRecord>> streamRecordsByDate(DateTime date) {
    // UTC 자정 기준으로 쿼리: 해외 타임존에서도 날짜 일치
    final dateStart = DateTime.utc(date.year, date.month, date.day);
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

    // yearMonth 필드로 쿼리 (예: "2025-11")
    final yearMonthStr =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

    return _getRecordsCollection()
        .where('yearMonth', isEqualTo: yearMonthStr)
        .snapshots()
        .handleError((error) {
          debugPrint('ERROR in streamRecordsByMonth: $error');
        })
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => DrinkingRecord.fromFirestore(doc))
              .toList();

          // 메모리에서 정렬
          records.sort((a, b) {
            final dateCompare = a.date.compareTo(b.date);
            if (dateCompare != 0) {
              return dateCompare;
            }
            return a.sessionNumber.compareTo(b.sessionNumber);
          });

          return records;
        });
  }

  /// 실시간 음주 기록 스트림 (특정 기간)
  Stream<List<DrinkingRecord>> streamRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _getRecordsCollection()
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .orderBy('sessionNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DrinkingRecord.fromFirestore(doc))
              .toList(),
        );
  }

  /// 전체 기록에서 가장 최근 음주 날짜(금주 제외) 찾기
  Future<DateTime?> _findLatestDrinkDate() async {
    final latestRecords = await _getRecordsCollection()
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    for (final doc in latestRecords.docs) {
      final record = DrinkingRecord.fromFirestore(doc);
      final isDrinking =
          record.drunkLevel > 0 || record.drinkAmount.any((d) => d.amount > 0);
      if (isDrinking) {
        return record.date;
      }
    }
    return null;
  }

  /// Helper: Update local stats for a specific date
  Future<void> _updateLocalStats(DateTime date) async {
    final records = await getRecordsByDate(date);

    // 1. Determine DayStatus
    DayStatus status = DayStatus.none;
    if (records.isNotEmpty) {
      // Check if ANY record is a "Drinking" record
      final isDrinkingDay = records.any((r) {
        if (r.drunkLevel > 0) {
          return true;
        }

        // If there are any drink amounts > 0, it's drinking
        // We check drinkAmount list.
        if (r.drinkAmount.any((d) => d.amount > 0)) {
          return true;
        }

        // Otherwise, it's a sober record (e.g. '금주' or plain record with 0 alcohol)
        return false;
      });

      debugPrint(
        'DRService.updateLocalStats: Date $date, Records: ${records.length}',
      );
      debugPrint(' - isDrinkingDay: $isDrinkingDay');

      if (isDrinkingDay) {
        status = DayStatus.drinking;
      } else {
        // If all are sober (no alcohol), then Sober
        status = DayStatus.sober;
      }
    }
    await _badgeService.updateDailyStatus(date, status);

    // 2. Calculate Total Pure Alcohol
    double totalAlcohol = 0.0;
    for (final record in records) {
      for (final drink in record.drinkAmount) {
        final pureAlc = drink.amount * (drink.alcoholContent / 100);
        totalAlcohol += pureAlc;
      }
    }

    await _badgeService.updateDailyAlcohol(date, totalAlcohol);
  }
}
