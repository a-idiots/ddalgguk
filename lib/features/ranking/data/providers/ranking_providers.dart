import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/features/ranking/data/services/ranking_service.dart';
import 'package:ddalgguk/features/ranking/domain/models/ranking_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 랭킹 항목에 users/{uid} 데이터를 합친 모델
class RankingEntryWithUser {
  const RankingEntryWithUser({
    required this.uid,
    required this.amount,
    required this.addFriendPermission,
    required this.name,
    this.customId,
    required this.profilePhoto,
    this.weeklyDrunkLevels,
    required this.currentDrunkLevel,
    this.isAnonymous = false,
  });

  final String uid;

  /// 이번 주/달 순수 알코올량 (ml, RankingService에서 누적한 값)
  final double amount;
  final bool addFriendPermission;
  final String name;
  final String? customId;

  /// 0–9 색상 인덱스 (AppColors.sakuGradientColors[profilePhoto * 10])
  final int profilePhoto;

  /// [월, 화, 수, 목, 금, 토, 일] — -1=기록 없음, 0=금주, 1-100=취함 정도
  final List<int>? weeklyDrunkLevels;
  final int currentDrunkLevel;

  /// 랭킹 노출 설정이 꺼진 유저 (익명 처리)
  final bool isAnonymous;

  /// UI 표시용 알코올량 (g = ml × 에탄올 밀도 0.789)
  double get displayGrams => amount * 0.789;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final rankingServiceProvider = Provider<RankingService>(
  (ref) => RankingService(),
);

final weeklyRankingProvider =
    FutureProvider<List<RankingEntryWithUser>>((ref) async {
      final entries = await ref.read(rankingServiceProvider).getWeeklyRanking();
      return _joinWithUserData(entries);
    });

final monthlyRankingProvider =
    FutureProvider<List<RankingEntryWithUser>>((ref) async {
      final entries = await ref
          .read(rankingServiceProvider)
          .getMonthlyRanking();
      return _joinWithUserData(entries);
    });

// ---------------------------------------------------------------------------
// 내부 헬퍼: RankingEntry 목록에 users/{uid} 데이터를 병렬로 조인
// ---------------------------------------------------------------------------

Future<List<RankingEntryWithUser>> _joinWithUserData(
  List<RankingEntry> entries,
) async {
  if (entries.isEmpty) {
    return [];
  }

  final firestore = FirebaseFirestore.instance;
  final userDocs = await Future.wait(
    entries.map((e) => firestore.collection('users').doc(e.uid).get()),
  );

  final result = <RankingEntryWithUser>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final data = userDocs[i].data();
    if (data == null) {
      continue; // 삭제된 계정 건너뜀
    }

    // rankingPermission이 false면 익명 처리 (null = 기본 true)
    final rankingPermission = data['rankingPermission'] as bool? ?? true;
    final isAnonymous = !rankingPermission;

    final rawLevels = data['weeklyDrunkLevels'];
    final weeklyDrunkLevels = rawLevels is List
        ? rawLevels.map((e) => (e as num).toInt()).toList()
        : null;

    // addFriendPermission도 users 문서에서 읽음 (null = 기본 true)
    final addFriendPermission = data['addFriendPermission'] as bool? ?? true;

    result.add(
      RankingEntryWithUser(
        uid: entry.uid,
        amount: entry.amount,
        addFriendPermission: isAnonymous ? false : addFriendPermission,
        name: isAnonymous ? '익명의 유저' : (data['name'] as String? ?? ''),
        customId: isAnonymous ? null : (data['id'] as String?),
        profilePhoto: (data['profilePhoto'] as num? ?? 0).toInt(),
        weeklyDrunkLevels: isAnonymous
            ? null
            : (weeklyDrunkLevels?.length == 7 ? weeklyDrunkLevels : null),
        currentDrunkLevel: isAnonymous
            ? 0
            : (data['currentDrunkLevel'] as num? ?? 0).toInt(),
        isAnonymous: isAnonymous,
      ),
    );
  }
  return result;
}
