import 'dart:async';

import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
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
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isSearching = false;
  String? _foundUserName;
  String? _foundUserId;
  List<AppUser> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    // @ 기호로 시작
    _userIdController.text = '@';
    _userIdController.selection = TextSelection.fromPosition(
      const TextPosition(offset: 1),
    );

    // 텍스트 변경 리스너
    _userIdController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _userIdController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _userIdController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() => _showSuggestions = false);
    }
  }

  void _onTextChanged() {
    final text = _userIdController.text;

    // @ 기호가 없으면 추가
    if (!text.startsWith('@')) {
      _userIdController.text = '@$text';
      _userIdController.selection = TextSelection.fromPosition(
        TextPosition(offset: _userIdController.text.length),
      );
      return;
    }

    // @ 기호만 있거나 커서가 @ 앞에 있으면 삭제 방지
    if (text == '@' || _userIdController.selection.baseOffset == 0) {
      _userIdController.selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }

    // 검색어 추출 (@ 제외)
    final searchQuery = text.substring(1);

    // debounce로 검색 요청 최적화
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    if (searchQuery.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsersByPrefix(searchQuery);
    });
  }

  Future<void> _searchUsersByPrefix(String prefix) async {
    if (prefix.isEmpty) {
      return;
    }

    setState(() => _isSearching = true);

    try {
      final friendService = ref.read(friendServiceProvider);
      final users = await friendService.searchUsersByIdPrefix(prefix, limit: 10);

      if (mounted) {
        setState(() {
          _suggestions = users;
          _showSuggestions = users.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSuggestion(AppUser user) {
    setState(() {
      _userIdController.text = '@${user.id ?? ''}';
      _foundUserName = user.name ?? user.displayName ?? 'Unknown';
      _foundUserId = user.uid;
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  Future<void> _searchUser() async {
    // @ 제거하고 ID 추출
    String userId = _userIdController.text.trim();
    if (userId.startsWith('@')) {
      userId = userId.substring(1);
    }

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
          _showSuggestions = false;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userIdController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: '@ 사용자 ID',
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
                  // 자동완성 제안 리스트
                  if (_showSuggestions && _suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final user = _suggestions[index];
                          return ListTile(
                            dense: true,
                            onTap: () => _selectSuggestion(user),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryPink.withValues(alpha: 0.2),
                              child: Text(
                                (user.id ?? '@')[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ),
                            title: Text(
                              '@${user.id ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: user.name != null
                                ? Text(
                                    user.name!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
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
