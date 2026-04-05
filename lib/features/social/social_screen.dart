import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/features/ranking/data/providers/my_records_providers.dart';
import 'package:ddalgguk/features/ranking/data/providers/ranking_providers.dart';
import 'package:ddalgguk/features/ranking/widgets/my_records_tab.dart';
import 'package:ddalgguk/features/ranking/widgets/ranking_tab.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/shared/widgets/pro_plan_popup.dart';
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

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const int _myRecordsTabIndex = 2;
  static const int _rankingTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      return;
    }
    final targetTab = _tabController.index;
    if (targetTab == _rankingTabIndex || targetTab == _myRecordsTabIndex) {
      final isPro = ref.read(proProvider).valueOrNull ?? false;
      if (!isPro) {
        final previousTab = _tabController.previousIndex;
        _tabController.index = previousTab;
        showProPlanPopup(context, 3);
        return;
      }
    }
    if (targetTab == _rankingTabIndex) {
      // 랭킹 탭 진입 시 항상 새로 로드
      ref.invalidate(weeklyRankingProvider);
      ref.invalidate(monthlyRankingProvider);
    }
    if (targetTab == _myRecordsTabIndex) {
      // 나의 기록 탭 진입 시 항상 새로 로드
      final year = ref.read(myRecordsYearProvider);
      ref.invalidate(myYearlyRecordsProvider(year));
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(friendsProvider);
    ref.invalidate(friendRequestsProvider);
    await ref.read(friendsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final hasFriendRequests = ref.watch(hasFriendRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TabPageHeader(
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PostboxScreen(),
                    ),
                  );
                },
                icon: Image.asset(
                  'assets/icons/alarm_icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
              if (hasFriendRequests)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
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
      body: Column(
        children: [
          // 탭 바 — 좌측 정렬
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.only(left: 4),
            tabs: const [
              Tab(height: 36, text: '나의 친구'),
              Tab(
                height: 36,
                child: Text(
                  '과음관리구역',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Tab(height: 36, text: '나의 기록'),
            ],
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.black, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            dividerColor: Color(0xFFE0E0E0),
            dividerHeight: 1,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 15),
          ),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── 나의 친구 탭 ─────────────────────────────────────────
                friendsAsync.when(
                  data: (friends) {
                    if (friends.isEmpty) {
                      return _buildEmptyStateWithRefresh(context);
                    }
                    return _buildFriendsGridWithRefresh(friends);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPink,
                    ),
                  ),
                  error: (error, _) => _buildErrorStateWithRefresh(error),
                ),
                // ── 과음관리구역 탭 ──────────────────────────────────────
                const RankingTab(),
                // ── 나의 기록 탭 ─────────────────────────────────────────
                const MyRecordsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsGridWithRefresh(List<FriendWithData> friends) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primaryPink,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 6,
          mainAxisSpacing: 20,
        ),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friendData = friends[index];
          final isMe = index == 0;

          return FriendCard(
            friendData: friendData,
            onTap: isMe
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => const DailyStatusDialog(),
                    );
                  }
                : () {
                    showBottomHandleDialogue(
                      context: context,
                      fitContent: true,
                      child: FriendProfileDialog(friendData: friendData),
                    );
                  },
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateWithRefresh(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

  Widget _buildErrorStateWithRefresh(Object error) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
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
