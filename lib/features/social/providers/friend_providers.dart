import 'package:ddalgguk/features/social/data/services/friend_service.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FriendService 프로바이더
final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

/// 친구 목록 프로바이더 (나 + 친구들)
final friendsProvider = FutureProvider.autoDispose<List<Friend>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);

  // 나의 프로필과 친구 목록을 동시에 가져오기
  final results = await Future.wait([
    friendService.getMyProfile(),
    friendService.getFriends(),
  ]);

  final myProfile = results[0] as Friend?;
  final friends = results[1] as List<Friend>;

  // 나를 첫 번째로, 나머지 친구들을 뒤에 배치
  if (myProfile != null) {
    return [myProfile, ...friends];
  }

  return friends;
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
