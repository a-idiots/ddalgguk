import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 친구 요청 우편함 화면
class PostboxScreen extends ConsumerWidget {
  const PostboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final sentRequestsAsync = ref.watch(sentFriendRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CommonPageHeader(title: '친구 신청'),
        body: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(height: 26, text: '받은 신청'),
                    Tab(height: 26, text: '보낸 신청'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  requestsAsync.when(
                    data: (requests) {
                      if (requests.isEmpty) {
                        return _buildEmptyStateWithRefresh(ref);
                      }
                      return _buildRequestsListWithRefresh(requests, ref);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    ),
                    error: (error, stack) =>
                        _buildErrorStateWithRefresh(ref, error),
                  ),
                  sentRequestsAsync.when(
                    data: (requests) {
                      if (requests.isEmpty) {
                        return _buildSentEmptyStateWithRefresh(ref);
                      }
                      return _buildSentRequestsListWithRefresh(requests, ref);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    ),
                    error: (error, stack) =>
                        _buildSentErrorStateWithRefresh(ref, error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(friendRequestsProvider);
    await ref.read(friendRequestsProvider.future);
  }

  Future<void> _onRefreshSent(WidgetRef ref) async {
    ref.invalidate(sentFriendRequestsProvider);
    await ref.read(sentFriendRequestsProvider.future);
  }

  Widget _buildEmptyStateWithRefresh(WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 600,
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
                  '받은 친구 요청이 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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

  Widget _buildSentEmptyStateWithRefresh(WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _onRefreshSent(ref),
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 600,
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
                  '보낸 친구 신청이 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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

  Widget _buildRequestsListWithRefresh(
    List<FriendRequest> requests,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryPink,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = requests[index];
          return _FriendRequestCard(request: request, ref: ref);
        },
      ),
    );
  }

  Widget _buildSentRequestsListWithRefresh(
    List<FriendRequest> requests,
    WidgetRef ref,
  ) {
    return RefreshIndicator(
      onRefresh: () => _onRefreshSent(ref),
      color: AppColors.primaryPink,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = requests[index];
          return _SentFriendRequestCard(request: request, ref: ref);
        },
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

  Widget _buildSentErrorStateWithRefresh(WidgetRef ref, Object error) {
    return RefreshIndicator(
      onRefresh: () => _onRefreshSent(ref),
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

/// 보낸 친구 요청 카드
class _SentFriendRequestCard extends StatefulWidget {
  const _SentFriendRequestCard({required this.request, required this.ref});

  final FriendRequest request;
  final WidgetRef ref;

  @override
  State<_SentFriendRequestCard> createState() => _SentFriendRequestCardState();
}

class _SentFriendRequestCardState extends State<_SentFriendRequestCard> {
  bool _isProcessing = false;

  Widget _buildProfileAvatar(int? profilePhoto, {double size = 48}) {
    final photo = profilePhoto ?? 0;

    if (photo <= 10) {
      return SakuCharacter(size: size, drunkLevel: photo * 10);
    }

    const alcoholIcons = [
      'assets/imgs/alcohol_icons/soju.png',
      'assets/imgs/alcohol_icons/beer.png',
      'assets/imgs/alcohol_icons/cocktail.png',
      'assets/imgs/alcohol_icons/wine.png',
      'assets/imgs/alcohol_icons/makgulli.png',
    ];
    final iconIndex = photo - 11;

    if (iconIndex >= 0 && iconIndex < alcoholIcons.length) {
      return Center(
        child: Image.asset(
          alcoholIcons[iconIndex],
          width: size * 0.9,
          height: size * 0.9,
          fit: BoxFit.contain,
        ),
      );
    }

    return SakuCharacter(size: size);
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.request.toUserName ?? widget.request.toUserId}님께 보낸 친구 신청을\n취소하시겠어요?',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '유지하기',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('계속하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final friendService = widget.ref.read(friendServiceProvider);
      await friendService.cancelSentFriendRequest(
        requestId: widget.request.id,
        toUserId: widget.request.toUserId,
      );
      widget.ref.invalidate(sentFriendRequestsProvider);
      widget.ref.invalidate(friendRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구 신청을 취소했습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('취소 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final formattedDate = dateFormat.format(widget.request.createdAt);
    final isPending = widget.request.status == FriendRequestStatus.pending;
    final statusLabel = widget.request.status == FriendRequestStatus.pending
        ? '대기중'
        : widget.request.status == FriendRequestStatus.accepted
        ? '수락됨'
        : '취소됨';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _buildProfileAvatar(
                  widget.request.toUserProfilePhoto,
                  size: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.toUserName ?? widget.request.toUserId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.request.message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _cancelRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('취소하기'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 친구 요청 카드
class _FriendRequestCard extends StatefulWidget {
  const _FriendRequestCard({required this.request, required this.ref});

  final FriendRequest request;
  final WidgetRef ref;

  @override
  State<_FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends State<_FriendRequestCard> {
  bool _isProcessing = false;

  Widget _buildProfileAvatar(int? profilePhoto, {double size = 48}) {
    final photo = profilePhoto ?? 0;

    if (photo <= 10) {
      return SakuCharacter(size: size, drunkLevel: photo * 10);
    }

    const alcoholIcons = [
      'assets/imgs/alcohol_icons/soju.png',
      'assets/imgs/alcohol_icons/beer.png',
      'assets/imgs/alcohol_icons/cocktail.png',
      'assets/imgs/alcohol_icons/wine.png',
      'assets/imgs/alcohol_icons/makgulli.png',
    ];
    final iconIndex = photo - 11;

    if (iconIndex >= 0 && iconIndex < alcoholIcons.length) {
      return Center(
        child: Image.asset(
          alcoholIcons[iconIndex],
          width: size * 0.9,
          height: size * 0.9,
          fit: BoxFit.contain,
        ),
      );
    }

    return SakuCharacter(size: size);
  }

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);

    try {
      final friendService = widget.ref.read(friendServiceProvider);
      await friendService.acceptFriendRequest(widget.request);

      // 친구 목록과 요청 목록 갱신
      widget.ref.invalidate(friendsProvider);
      widget.ref.invalidate(friendRequestsProvider);
      widget.ref.invalidate(sentFriendRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구 요청을 수락했습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _declineRequest() async {
    setState(() => _isProcessing = true);

    try {
      final friendService = widget.ref.read(friendServiceProvider);
      await friendService.declineFriendRequest(widget.request.id);

      // 요청 목록 갱신
      widget.ref.invalidate(friendRequestsProvider);
      widget.ref.invalidate(sentFriendRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구 요청을 거절했습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final formattedDate = dateFormat.format(widget.request.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 프로필 이미지 또는 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _buildProfileAvatar(
                  widget.request.fromUserProfilePhoto,
                  size: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.fromUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.request.message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _declineRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _acceptRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('수락'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
