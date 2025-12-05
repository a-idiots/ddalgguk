import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/social/data/services/friend_service.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/features/social/domain/models/friend_with_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FriendService 프로바이더
final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

/// 친구 목록 프로바이더 (나 + 친구들)
/// FriendWithData를 반환: Friend 정보 + 전체 AppUser 데이터
final friendsProvider = FutureProvider.autoDispose<List<FriendWithData>>((
  ref,
) async {
  final friendService = ref.watch(friendServiceProvider);

  // 나의 프로필과 친구 목록을 동시에 가져오기
  final results = await Future.wait([
    friendService.getMyProfile(),
    friendService.getFriends(),
  ]);

  final myProfile = results[0] as AppUser?;
  final friends = results[1] as List<Friend>;

  final friendsWithData = <FriendWithData>[];

  // 나의 프로필 추가 (Friend 객체를 임시로 생성)
  if (myProfile != null) {
    final myFriendInfo = Friend(
      userId: myProfile.uid,
      name: myProfile.name ?? 'Me',
      createdAt: DateTime.now(),
    );
    friendsWithData.add(
      FriendWithData(friend: myFriendInfo, userData: myProfile),
    );
  }

  // 친구들의 전체 데이터 가져오기
  for (final friend in friends) {
    final friendUserData = await friendService.getFriendProfile(friend.userId);
    if (friendUserData != null) {
      friendsWithData.add(
        FriendWithData(friend: friend, userData: friendUserData),
      );
    }
  }

  return friendsWithData;
});

/// 받은 친구 요청 프로바이더 (필요할 때만 fetch)
final friendRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((
  ref,
) async {
  final friendService = ref.watch(friendServiceProvider);
  return friendService.getReceivedFriendRequests();
});

/// 보낸 친구 요청 프로바이더
final sentFriendRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequest>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  return friendService.getSentFriendRequests();
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
