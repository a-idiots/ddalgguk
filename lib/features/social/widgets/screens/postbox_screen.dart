import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';

/// 친구 요청 우편함 화면
class PostboxScreen extends ConsumerWidget {
  const PostboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonPageHeader(title: '친구 신청'),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyStateWithRefresh(ref);
          }
          return _buildRequestsListWithRefresh(requests, ref);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
        error: (error, stack) => _buildErrorStateWithRefresh(ref, error),
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(friendRequestsProvider);
    await ref.read(friendRequestsProvider.future);
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
                  'assets/socials/empty_postbox.png',
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

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);

    try {
      final friendService = widget.ref.read(friendServiceProvider);
      await friendService.acceptFriendRequest(widget.request);

      // 친구 목록과 요청 목록 갱신
      widget.ref.invalidate(friendsProvider);
      widget.ref.invalidate(friendRequestsProvider);

      if (mounted) {
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

      if (mounted) {
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
              CircleAvatar(
                radius: 24,
                backgroundImage: widget.request.fromUserPhoto != null
                    ? NetworkImage(widget.request.fromUserPhoto!)
                    : null,
                child: widget.request.fromUserPhoto == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
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
