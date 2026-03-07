import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/features/ranking/domain/models/ranking_entry.dart';
import 'package:flutter/foundation.dart';

/// 주간/월간 음주량 랭킹을 관리하는 서비스
///
/// Firestore 구조:
///   rankings/{uid}                      — 현재 주/월 빠른 조회용
///     weeklyAmount:        double
///     weeklyKey:           String  (예: "2026_W10")
///     monthlyAmount:       double
///     monthlyKey:          String  (예: "2026_03")
///     rankingPermission:   bool
///     addFriendPermission: bool
///
///   rankings/{uid}/weekly/{weekKey}     — 주간 히스토리
///     amount:    double  (ml)
///     periodKey: String  (weekKey — 컬렉션 그룹 쿼리용)
///     uid:       String  (부모 uid — 컬렉션 그룹 쿼리용)
///
///   rankings/{uid}/monthly/{monthKey}   — 월간 히스토리
///     amount:    double  (ml)
///     periodKey: String  (monthKey — 컬렉션 그룹 쿼리용)
///     uid:       String  (부모 uid — 컬렉션 그룹 쿼리용)
///
/// 히스토리 서브컬렉션:
///   - 문서 존재 + amount >= 0 → 기록 있음 (0ml 이면 "0g" 표시)
///   - 문서 없음              → 해당 기간 기록 없음 ("-" 표시)

class RankingService {
  RankingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rankings =>
      _firestore.collection('rankings');

  // ---------------------------------------------------------------------------
  // 공개 메서드 — 키 변환 (나의 기록 탭에서 사용)
  // ---------------------------------------------------------------------------

  /// 날짜 → 월 키 (예: "2026_03")
  String monthKeyForDate(DateTime date) => _monthKeyForDate(date);

  /// 날짜 → 주차 키 (예: "2026_W10")
  String weekKeyForDate(DateTime date) => _weekKeyForDate(date);

  /// 주어진 연/월에 속하는 ISO 주차 키 목록을 순서대로 반환한다.
  List<String> weekKeysForMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final seen = <String>{};
    final result = <String>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final key = _weekKeyForDate(DateTime(year, month, day));
      if (seen.add(key)) {
        result.add(key);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // 공개 메서드 — 개인 히스토리 조회 (나의 기록 탭)
  // ---------------------------------------------------------------------------

  /// 특정 달 유저 누적 알코올량 조회.
  /// 문서 없음 → null (기록 없음), 0.0 이상 → 기록 있음.
  Future<double?> getUserMonthlyAmount(String uid, String monthKey) async {
    try {
      final doc =
          await _rankings.doc(uid).collection('monthly').doc(monthKey).get();
      if (!doc.exists) {
        return null;
      }
      return (doc.data()!['amount'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('RankingService.getUserMonthlyAmount error: $e');
      return null;
    }
  }

  /// 특정 주차 유저 누적 알코올량 조회.
  /// 문서 없음 → null (기록 없음), 0.0 이상 → 기록 있음.
  Future<double?> getUserWeeklyAmount(String uid, String weekKey) async {
    try {
      final doc =
          await _rankings.doc(uid).collection('weekly').doc(weekKey).get();
      if (!doc.exists) {
        return null;
      }
      return (doc.data()!['amount'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('RankingService.getUserWeeklyAmount error: $e');
      return null;
    }
  }

  /// 특정 달 유저 등수 계산 (컬렉션 그룹 쿼리).
  ///
  /// periodKey 필드가 없는 구버전 문서는 결과에 포함되지 않음.
  /// 인덱스 미생성 등 오류 시 null 반환.
  Future<int?> getMonthlyRankForUser(String uid, String monthKey) async {
    try {
      // orderBy 제거 → 복합 인덱스 불필요, 클라이언트 정렬
      final snapshot =
          await _firestore
              .collectionGroup('monthly')
              .where('periodKey', isEqualTo: monthKey)
              .get();

      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aAmt = (a.data()['amount'] as num?)?.toDouble() ?? 0.0;
          final bAmt = (b.data()['amount'] as num?)?.toDouble() ?? 0.0;
          return bAmt.compareTo(aAmt); // 내림차순
        });

      double? myAmount;
      for (final doc in docs) {
        if (doc.data()['uid'] == uid) {
          myAmount = (doc.data()['amount'] as num?)?.toDouble();
          break;
        }
      }
      if (myAmount == null) {
        return null;
      }

      // 1224 방식: 나보다 amount 가 많은 유저 수 + 1
      int rank = 1;
      for (final doc in docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        if (amount > myAmount) {
          rank++;
        } else {
          break;
        }
      }
      return rank;
    } catch (e) {
      debugPrint('RankingService.getMonthlyRankForUser error: $e');
      return null;
    }
  }

  /// 특정 주차 유저 등수 계산 (컬렉션 그룹 쿼리).
  Future<int?> getWeeklyRankForUser(String uid, String weekKey) async {
    try {
      // orderBy 제거 → 복합 인덱스 불필요, 클라이언트 정렬
      final snapshot =
          await _firestore
              .collectionGroup('weekly')
              .where('periodKey', isEqualTo: weekKey)
              .get();

      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aAmt = (a.data()['amount'] as num?)?.toDouble() ?? 0.0;
          final bAmt = (b.data()['amount'] as num?)?.toDouble() ?? 0.0;
          return bAmt.compareTo(aAmt);
        });

      double? myAmount;
      for (final doc in docs) {
        if (doc.data()['uid'] == uid) {
          myAmount = (doc.data()['amount'] as num?)?.toDouble();
          break;
        }
      }
      if (myAmount == null) {
        return null;
      }

      int rank = 1;
      for (final doc in docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        if (amount > myAmount) {
          rank++;
        } else {
          break;
        }
      }
      return rank;
    } catch (e) {
      debugPrint('RankingService.getWeeklyRankForUser error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 공개 메서드 — 기존 랭킹 쓰기/조회
  // ---------------------------------------------------------------------------

  /// 랭킹 알코올량을 [delta]만큼 조정한다 (양수=증가, 음수=감소).
  ///
  /// 음주 기록 수정·삭제 시 사용한다.
  /// - 서브컬렉션 문서가 없으면 delta < 0 이더라도 아무것도 하지 않는다.
  /// - 루트 문서의 weeklyAmount/monthlyAmount 는 0 미만으로 내려가지 않도록 클램핑.
  Future<void> adjustAlcohol(
    String uid,
    double delta,
    DateTime recordDate,
  ) async {
    if (delta == 0) {
      return;
    }

    final weekKey  = _weekKeyForDate(recordDate);
    final monthKey = _monthKeyForDate(recordDate);
    final docRef   = _rankings.doc(uid);

    try {
      final weeklyRef  = docRef.collection('weekly').doc(weekKey);
      final monthlyRef = docRef.collection('monthly').doc(monthKey);

      if (delta > 0) {
        // 양수: 문서가 없으면 생성, 있으면 증가
        await Future.wait([
          weeklyRef.set(
            {'amount': FieldValue.increment(delta), 'periodKey': weekKey,  'uid': uid},
            SetOptions(merge: true),
          ),
          monthlyRef.set(
            {'amount': FieldValue.increment(delta), 'periodKey': monthKey, 'uid': uid},
            SetOptions(merge: true),
          ),
        ]);
      } else {
        // 음수: 문서가 존재할 때만 감소, 0 미만으로 내려가지 않도록 클램핑
        await _firestore.runTransaction<void>((tx) async {
          final weeklyDoc  = await tx.get(weeklyRef);
          final monthlyDoc = await tx.get(monthlyRef);

          if (weeklyDoc.exists) {
            final cur = (weeklyDoc.data()!['amount'] as num?)?.toDouble() ?? 0.0;
            tx.update(weeklyRef, {'amount': math.max(0.0, cur + delta)});
          }
          if (monthlyDoc.exists) {
            final cur = (monthlyDoc.data()!['amount'] as num?)?.toDouble() ?? 0.0;
            tx.update(monthlyRef, {'amount': math.max(0.0, cur + delta)});
          }
        });
      }

      // 루트 문서(현재 주/월 빠른 조회용) 업데이트
      final currentWeekKey  = _currentWeekKey();
      final currentMonthKey = _currentMonthKey();
      final isCurrentWeek   = weekKey == currentWeekKey;
      final isCurrentMonth  = monthKey == currentMonthKey;

      if (!isCurrentWeek && !isCurrentMonth) {
        return;
      }

      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
        }

        final data    = snapshot.data()!;
        final updates = <String, dynamic>{};

        if (isCurrentWeek) {
          final storedWeekKey = data['weeklyKey'] as String? ?? '';
          if (storedWeekKey == currentWeekKey) {
            final cur = (data['weeklyAmount'] as num? ?? 0).toDouble();
            updates['weeklyAmount'] = math.max(0.0, cur + delta);
          }
        }
        if (isCurrentMonth) {
          final storedMonthKey = data['monthlyKey'] as String? ?? '';
          if (storedMonthKey == currentMonthKey) {
            final cur = (data['monthlyAmount'] as num? ?? 0).toDouble();
            updates['monthlyAmount'] = math.max(0.0, cur + delta);
          }
        }

        if (updates.isNotEmpty) {
          transaction.update(docRef, updates);
        }
      });
    } catch (e) {
      debugPrint('RankingService.adjustAlcohol error: $e');
      rethrow;
    }
  }

  Future<void> addAlcohol(
    String uid,
    double alcoholMl,
    DateTime recordDate,
  ) async {
    if (alcoholMl < 0) {
      return;
    }

    final weekKey  = _weekKeyForDate(recordDate);
    final monthKey = _monthKeyForDate(recordDate);
    final docRef   = _rankings.doc(uid);

    try {
      final weeklyRef  = docRef.collection('weekly').doc(weekKey);
      final monthlyRef = docRef.collection('monthly').doc(monthKey);

      // periodKey / uid 를 함께 저장해 컬렉션 그룹 쿼리(등수 계산) 지원
      await Future.wait([
        weeklyRef.set(
          {
            'amount': FieldValue.increment(alcoholMl),
            'periodKey': weekKey,
            'uid': uid,
          },
          SetOptions(merge: true),
        ),
        monthlyRef.set(
          {
            'amount': FieldValue.increment(alcoholMl),
            'periodKey': monthKey,
            'uid': uid,
          },
          SetOptions(merge: true),
        ),
      ]);

      final currentWeekKey  = _currentWeekKey();
      final currentMonthKey = _currentMonthKey();
      final isCurrentWeek   = weekKey == currentWeekKey;
      final isCurrentMonth  = monthKey == currentMonthKey;

      if (!isCurrentWeek && !isCurrentMonth) {
        return;
      }

      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          transaction.set(docRef, {
            'weeklyAmount':        isCurrentWeek  ? alcoholMl : 0.0,
            'weeklyKey':           currentWeekKey,
            'monthlyAmount':       isCurrentMonth ? alcoholMl : 0.0,
            'monthlyKey':          currentMonthKey,
            'rankingPermission':   true,
            'addFriendPermission': true,
          });
          return;
        }

        final data    = snapshot.data()!;
        final updates = <String, dynamic>{};

        if (isCurrentWeek) {
          final storedWeekKey = data['weeklyKey'] as String? ?? '';
          updates['weeklyAmount'] =
              storedWeekKey == currentWeekKey
                  ? (data['weeklyAmount'] as num? ?? 0).toDouble() + alcoholMl
                  : alcoholMl; // 새 주차 -> 리셋
          updates['weeklyKey'] = currentWeekKey;
        }

        if (isCurrentMonth) {
          final storedMonthKey = data['monthlyKey'] as String? ?? '';
          updates['monthlyAmount'] =
              storedMonthKey == currentMonthKey
                  ? (data['monthlyAmount'] as num? ?? 0).toDouble() + alcoholMl
                  : alcoholMl; // 새 달 -> 리셋
          updates['monthlyKey'] = currentMonthKey;
        }

        // 권한 필드는 건드리지 않음
        if (updates.isNotEmpty) {
          transaction.update(docRef, updates);
        }
      });
    } catch (e) {
      debugPrint('RankingService.addAlcohol error: $e');
      rethrow;
    }
  }

  /// 이번 주 랭킹 조회 (rankingPermission == true 유저만, weeklyAmount 내림차순)
  Future<List<RankingEntry>> getWeeklyRanking({int limit = 20}) async {
    try {
      final snapshot =
          await _rankings
              .where('rankingPermission', isEqualTo: true)
              .where('weeklyKey', isEqualTo: _currentWeekKey())
              .orderBy('weeklyAmount', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RankingEntry(
          uid: doc.id,
          amount: (data['weeklyAmount'] as num).toDouble(),
          addFriendPermission: data['addFriendPermission'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('RankingService.getWeeklyRanking error: $e');
      rethrow;
    }
  }

  /// 이번 달 랭킹 조회 (rankingPermission == true 유저만, monthlyAmount 내림차순)
  Future<List<RankingEntry>> getMonthlyRanking({int limit = 20}) async {
    try {
      final snapshot =
          await _rankings
              .where('rankingPermission', isEqualTo: true)
              .where('monthlyKey', isEqualTo: _currentMonthKey())
              .orderBy('monthlyAmount', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RankingEntry(
          uid: doc.id,
          amount: (data['monthlyAmount'] as num).toDouble(),
          addFriendPermission: data['addFriendPermission'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('RankingService.getMonthlyRanking error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 권한 설정 메서드
  // ---------------------------------------------------------------------------

  /// 유저의 랭킹 노출 / 친구 요청 수락 여부를 업데이트한다.
  Future<void> updatePermissions(
    String uid, {
    bool? rankingPermission,
    bool? addFriendPermission,
  }) async {
    final updates = <String, dynamic>{};
    if (rankingPermission != null) {
      updates['rankingPermission'] = rankingPermission;
    }
    if (addFriendPermission != null) {
      updates['addFriendPermission'] = addFriendPermission;
    }
    if (updates.isEmpty) {
      return;
    }

    try {
      await _rankings.doc(uid).set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('RankingService.updatePermissions error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 비공개 헬퍼
  // ---------------------------------------------------------------------------

  String _currentWeekKey()  => _weekKeyForDate(DateTime.now());
  String _currentMonthKey() => _monthKeyForDate(DateTime.now());

  /// 주어진 날짜의 ISO 8601 주차 키를 반환한다.
  ///
  /// 형식: "{ISO 연도}_W{주차 두 자리}" (예: "2026_W01", "2026_W52")
  /// - 주 시작: 월요일
  /// - 1주차: 해당 연도의 첫 번째 목요일이 포함된 주
  String _weekKeyForDate(DateTime date) {
    // 이번 주 월요일 (weekday: 1=월 … 7=일)
    final monday  = date.subtract(Duration(days: date.weekday - 1));
    // 이번 주 목요일 (ISO 연도는 목요일의 연도로 결정)
    final thursday = monday.add(const Duration(days: 3));

    final isoYear = thursday.year;

    // 해당 ISO 연도의 1주차 월요일 (1월 4일은 항상 1주차에 포함)
    final jan4 = DateTime(isoYear, 1, 4);
    final firstIsoMonday = jan4.subtract(Duration(days: jan4.weekday - 1));

    final weekNum = monday.difference(firstIsoMonday).inDays ~/ 7 + 1;

    return '${isoYear}_W${weekNum.toString().padLeft(2, '0')}';
  }

  /// 주어진 날짜의 월 키를 반환한다.
  ///
  /// 형식: "{연도}_{월 두 자리}" (예: "2026_03")
  String _monthKeyForDate(DateTime date) {
    return '${date.year}_${date.month.toString().padLeft(2, '0')}';
  }
}
