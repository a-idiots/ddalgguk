import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/ranking/data/providers/ranking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// 모델
// ---------------------------------------------------------------------------

class MonthRecord {
  const MonthRecord({
    required this.year,
    required this.month,
    this.amount,
    this.rank,
  });

  final int year;
  final int month;

  /// null = 기록 없음("-"), 0.0 = WOW!, > 0 = 정상 기록
  final double? amount;

  /// null = 등수 없음 (amount==null 또는 0, 또는 인덱스 미생성)
  final int? rank;

  // amount 는 이미 g 단위 (음주량(ml) × 도수 / 100 × 0.8)
  double? get displayGrams => amount;

  bool get isFuture {
    final now = DateTime.now();
    if (year > now.year) {
      return true;
    }
    if (year == now.year && month > now.month) {
      return true;
    }
    return false;
  }

  bool get isCurrent {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
}

class WeekRecord {
  const WeekRecord({
    required this.weekKey,
    required this.weekOfMonth,
    required this.isFuture,
    this.amount,
    this.rank,
  });

  final String weekKey;
  final int weekOfMonth; // 1-based, 해당 달 내 순서
  final bool isFuture;

  /// null = 기록 없음("-"), 0.0 = WOW!, > 0 = 정상 기록
  final double? amount;

  /// null = 등수 없음
  final int? rank;

  // amount 는 이미 g 단위 (음주량(ml) × 도수 / 100 × 0.8)
  double? get displayGrams => amount;
}

// ---------------------------------------------------------------------------
// 연도 상태 — 나의 기록 탭에서 선택된 연도 공유
// ---------------------------------------------------------------------------

final myRecordsYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// 특정 연도의 12개월 기록 목록
final myYearlyRecordsProvider = FutureProvider.family
    .autoDispose<List<MonthRecord>, int>((ref, year) async {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        return List.generate(12, (i) => MonthRecord(year: year, month: i + 1));
      }

      final uid = user.uid;
      final service = ref.read(rankingServiceProvider);
      final now = DateTime.now();

      // 2026 이전: 소급 적용 없음 — 전부 hyphen
      if (year < 2026) {
        return List.generate(12, (i) => MonthRecord(year: year, month: i + 1));
      }

      final results = <MonthRecord>[];
      for (int month = 1; month <= 12; month++) {
        final isFutureMonth =
            year > now.year || (year == now.year && month > now.month);

        if (isFutureMonth) {
          results.add(MonthRecord(year: year, month: month));
          continue;
        }

        final monthKey = service.monthKeyForDate(DateTime(year, month));
        final amount = await service.getUserMonthlyAmount(uid, monthKey);
        final rank = (amount != null && amount > 0)
            ? await service.getMonthlyRankForUser(uid, monthKey)
            : null;

        results.add(
          MonthRecord(year: year, month: month, amount: amount, rank: rank),
        );
      }
      return results;
    });

/// 특정 연/월의 주차별 기록 목록
final myMonthWeeklyRecordsProvider = FutureProvider.family
    .autoDispose<List<WeekRecord>, (int, int)>((ref, params) async {
      final (year, month) = params;
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        return [];
      }

      final uid = user.uid;
      final service = ref.read(rankingServiceProvider);
      final now = DateTime.now();
      final currentWeekKey = service.weekKeyForDate(now);

      final weekKeys = service.weekKeysForMonth(year, month);
      final results = <WeekRecord>[];

      for (int i = 0; i < weekKeys.length; i++) {
        final weekKey = weekKeys[i];
        // 문자열 비교: "2026_W10" 형식이므로 lexicographic 정렬 == 시간 순
        final isFuture = weekKey.compareTo(currentWeekKey) > 0;

        if (isFuture) {
          results.add(
            WeekRecord(weekKey: weekKey, weekOfMonth: i + 1, isFuture: true),
          );
          continue;
        }

        final amount = await service.getUserWeeklyAmount(uid, weekKey);
        final rank = (amount != null && amount > 0)
            ? await service.getWeeklyRankForUser(uid, weekKey)
            : null;

        results.add(
          WeekRecord(
            weekKey: weekKey,
            weekOfMonth: i + 1,
            isFuture: false,
            amount: amount,
            rank: rank,
          ),
        );
      }
      return results;
    });
