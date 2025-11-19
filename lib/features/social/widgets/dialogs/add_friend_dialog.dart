import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/features/social/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 친구 추가 다이얼로그
class AddFriendDialog extends ConsumerStatefulWidget {
  const AddFriendDialog({super.key});

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  final _userIdController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  String? _foundUserName;
  String? _foundUserId;

  @override
  void dispose() {
    _userIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사용자 ID를 입력해주세요')));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final friendService = ref.read(friendServiceProvider);
      final user = await friendService.searchUserById(userId);

      if (user != null) {
        setState(() {
          _foundUserName = user.name ?? user.displayName ?? 'Unknown';
          _foundUserId = user.uid;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다')));
        }
        setState(() {
          _foundUserName = null;
          _foundUserId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Exception 메시지만 추출
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _sendRequest() async {
    if (_foundUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 사용자를 검색해주세요')));
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('요청 메시지를 입력해주세요')));
      return;
    }

    if (message.length > FriendRequest.maxMessageLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '메시지는 최대 ${FriendRequest.maxMessageLength}자까지 입력 가능합니다',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final friendService = ref.read(friendServiceProvider);
      await friendService.sendFriendRequest(
        toUserId: _foundUserId!,
        toUserName: _foundUserName!,
        message: message,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈습니다')));
      }
    } catch (e) {
      if (mounted) {
        // Exception 메시지만 추출
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '친구 추가',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              // 사용자 ID 검색
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        hintText: '사용자 ID 입력',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('검색'),
                  ),
                ],
              ),
              // 검색 결과
              if (_foundUserName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        '사용자를 찾았습니다: $_foundUserName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 요청 메시지
                TextField(
                  controller: _messageController,
                  maxLength: FriendRequest.maxMessageLength,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '친구 요청 메시지를 입력하세요',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  if (_foundUserName != null)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('요청 보내기'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
