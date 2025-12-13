import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/features/social/domain/models/friend_with_data.dart';
import 'package:ddalgguk/features/social/widgets/dialogs/daily_status_dialog.dart';
import 'package:ddalgguk/features/social/widgets/dialogs/friend_profile_dialog.dart';
import 'package:ddalgguk/features/social/widgets/friend_card.dart';
import 'package:ddalgguk/features/social/widgets/screens/add_friends.dart';
import 'package:ddalgguk/features/social/widgets/screens/postbox_screen.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:ddalgguk/shared/widgets/bottom_handle_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final hasFriendRequests = ref.watch(hasFriendRequestsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final postboxSize = screenWidth / 3; // 화면 가로의 1/3

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TabPageHeader(
        title: 'SAKU Village',
        fontSize: 28,
        height: 64,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 32, color: Colors.black),
          ),
        ],
      ),
      body: Stack(
        children: [
          friendsAsync.when(
            data: (friends) {
              // 친구가 아무도 없으면 (내 프로필도 없으면) Empty State 표시
              if (friends.isEmpty) {
                return _buildEmptyStateWithRefresh(context, ref);
              }
              // 항상 그리드 표시 (나의 프로필은 항상 첫 번째)
              return _buildFriendsGridWithRefresh(ref, friends);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            ),
            error: (error, stack) => _buildErrorStateWithRefresh(ref, error),
          ),
          // 우체통 아이콘 - 네비게이션 바 바로 위 우측 하단
          Positioned(
            bottom: 0, // 네비게이션 바 바로 위
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PostboxScreen(),
                  ),
                );
              },
              child: Image.asset(
                hasFriendRequests
                    ? 'assets/imgs/socials/alarm_postbox.png'
                    : 'assets/imgs/socials/empty_postbox.png',
                width: postboxSize,
                height: postboxSize,
              ),
            ),
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

  Widget _buildFriendsGridWithRefresh(
    WidgetRef ref,
    List<FriendWithData> friends,
  ) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryPink,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3열
          childAspectRatio: 0.65, // 세로로 더 길게 (이름 버튼이 카드 외부에 있음)
          crossAxisSpacing: 4, // 카드 간 간격 최소화
          mainAxisSpacing: 16,
        ),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friendData = friends[index];
          final isMe = index == 0; // 첫 번째는 항상 나

          return FriendCard(
            friendData: friendData,
            onTap: isMe
                ? () {
                    // 나 자신 클릭 시 일일 상태 다이얼로그 표시
                    showDialog(
                      context: context,
                      builder: (context) => const DailyStatusDialog(),
                    );
                  }
                : () {
                    // 친구 프로필 미리보기 바텀 시트 표시
                    showBottomHandleDialogue(
                      context: context,
                      child: FriendProfileDialog(friendData: friendData),
                    );
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
                  'assets/imgs/socials/empty_postbox.png',
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddFriendScreen(),
                      ),
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
