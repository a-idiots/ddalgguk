import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/domain/models/friend.dart';
import 'package:ddalgguk/features/social/providers/friend_providers.dart';
import 'package:ddalgguk/features/social/widgets/dialogs/add_friend_dialog.dart';
import 'package:ddalgguk/features/social/widgets/dialogs/daily_status_dialog.dart';
import 'package:ddalgguk/features/social/widgets/friend_card.dart';
import 'package:ddalgguk/features/social/widgets/screens/postbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final hasFriendRequests = ref.watch(hasFriendRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(context, ref, hasFriendRequests),
            // 친구 목록
            Expanded(
              child: friendsAsync.when(
                data: (friends) {
                  // 친구가 아무도 없으면 (내 프로필도 없으면) Empty State 표시
                  if (friends.isEmpty) {
                    return _buildEmptyStateWithRefresh(context, ref);
                  }
                  // 항상 그리드 표시 (나의 프로필은 항상 첫 번째)
                  return _buildFriendsGridWithRefresh(ref, friends);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                  ),
                ),
                error: (error, stack) =>
                    _buildErrorStateWithRefresh(ref, error),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DailyStatusFAB(),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool hasFriendRequests,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 타이틀
          const Text(
            'SAKU Village',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              // 우편함 아이콘 (친구 요청)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PostboxScreen(),
                    ),
                  );
                },
                child: Image.asset(
                  hasFriendRequests
                      ? 'assets/socials/alarm_postbox.png'
                      : 'assets/socials/empty_postbox.png',
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 12),
              // 친구 추가 버튼
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddFriendDialog(),
                  );
                },
                child: const Icon(Icons.add, size: 32, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    // Provider를 invalidate하여 새로 로드
    ref.invalidate(friendsProvider);
    ref.invalidate(friendRequestsProvider);

    // 새로운 데이터가 로드될 때까지 대기
    await ref.read(friendsProvider.future);
  }

  Widget _buildFriendsGridWithRefresh(WidgetRef ref, List<Friend> friends) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryPink,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3열
          childAspectRatio: 0.58, // 세로로 더 길게 (이름 버튼이 카드 외부에 있음)
          crossAxisSpacing: 4, // 카드 간 간격 최소화
          mainAxisSpacing: 16,
        ),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          final isMe = index == 0; // 첫 번째는 항상 나

          return FriendCard(
            friend: friend,
            onTap: isMe
                ? () {
                    // 나 자신 클릭 시 일일 상태 다이얼로그 표시
                    showDialog(
                      context: context,
                      builder: (context) => const DailyStatusDialog(),
                    );
                  }
                : () {
                    // TODO: 친구 프로필 상세 보기
                  },
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateWithRefresh(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/socials/empty_postbox.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  '아직 친구가 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '+ 버튼을 눌러 친구를 추가해보세요',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddFriendDialog(),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('친구 추가하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorStateWithRefresh(WidgetRef ref, Object error) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('오류가 발생했습니다: $error'),
                const SizedBox(height: 16),
                const Text(
                  '아래로 당겨서 새로고침',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 플로팅 액션 버튼 - 일일 상태 추가
class DailyStatusFAB extends ConsumerWidget {
  const DailyStatusFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const DailyStatusDialog(),
        );
      },
      backgroundColor: AppColors.primaryPink,
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }
}
