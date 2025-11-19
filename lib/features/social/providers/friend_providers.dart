import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/social/data/services/friend_service.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FriendService 프로바이더
final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

/// DrinkingRecordService 프로바이더
final drinkingRecordServiceProvider = Provider<DrinkingRecordService>((ref) {
  return DrinkingRecordService();
});

/// 특정 사용자의 어제 평균 음주 레벨 계산
Future<int> _calculateYesterdayAvgDrunkLevel(
  String userId,
  DrinkingRecordService drinkingRecordService,
) async {
  try {
    // 어제 날짜 계산
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStart = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
    );

    // 해당 사용자의 어제 음주 기록 조회
    final records = await drinkingRecordService.getRecordsByDateForUser(
      userId,
      yesterdayStart,
    );

    if (records.isEmpty) {
      return 0; // 어제 음주 기록이 없으면 0 (금주)
    }

    // 평균 drunkLevel 계산
    final totalDrunkLevel = records.fold<int>(
      0,
      (sum, record) => sum + record.drunkLevel,
    );
    return (totalDrunkLevel / records.length).round();
  } catch (e) {
    return 0; // 에러 발생 시 0 반환
  }
}

/// 친구 목록 프로바이더 (나 + 친구들)
final friendsProvider = FutureProvider.autoDispose<List<Friend>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  final drinkingRecordService = ref.watch(drinkingRecordServiceProvider);

  // 나의 프로필과 친구 목록을 동시에 가져오기
  final results = await Future.wait([
    friendService.getMyProfile(),
    friendService.getFriends(),
  ]);

  final myProfile = results[0] as Friend?;
  final friends = results[1] as List<Friend>;

  // 어제 날짜 계산 (시간 정보 제거)
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayStart = DateTime(
    yesterday.year,
    yesterday.month,
    yesterday.day,
  );

  // 각 친구(나 포함)의 어제 평균 음주 레벨 계산
  final friendsWithYesterday = <Friend>[];

  if (myProfile != null) {
    // 나의 어제 평균 음주 레벨 계산 (내 기록은 직접 조회 가능)
    final myYesterdayLevel = await _calculateYesterdayAvgDrunkLevel(
      myProfile.userId,
      drinkingRecordService,
    );
    friendsWithYesterday.add(
      myProfile.copyWith(yesterdayAvgDrunkLevel: myYesterdayLevel),
    );
  }

  // 친구들의 어제 평균 음주 레벨은 lastDrinkDate로 판단
  for (final friend in friends) {
    int friendYesterdayLevel = 0;

    // lastDrinkDate가 어제인 경우에만 currentDrunkLevel 사용
    if (friend.lastDrinkDate != null) {
      final lastDrink = friend.lastDrinkDate!;
      final lastDrinkDay = DateTime(
        lastDrink.year,
        lastDrink.month,
        lastDrink.day,
      );

      // 어제 마신 경우에만 레벨 표시
      if (lastDrinkDay.isAtSameMomentAs(yesterdayStart)) {
        friendYesterdayLevel = friend.currentDrunkLevel ?? 0;
      }
    }

    friendsWithYesterday.add(
      friend.copyWith(yesterdayAvgDrunkLevel: friendYesterdayLevel),
    );
  }

  return friendsWithYesterday;
});

/// 받은 친구 요청 프로바이더 (필요할 때만 fetch)
final friendRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((
  ref,
) async {
  final friendService = ref.watch(friendServiceProvider);
  return friendService.getReceivedFriendRequests();
});

/// 친구 요청 개수 프로바이더
final friendRequestCountProvider = Provider.autoDispose<int>((ref) {
  final friendRequestsAsync = ref.watch(friendRequestsProvider);
  return friendRequestsAsync.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 친구 요청이 있는지 여부 프로바이더
final hasFriendRequestsProvider = Provider.autoDispose<bool>((ref) {
  final count = ref.watch(friendRequestCountProvider);
  return count > 0;
});
