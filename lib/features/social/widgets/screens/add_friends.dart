import 'dart:async';

import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 선택된 친구 신청 대상 (메시지 컨트롤러 포함)
class _SelectedUser {
  _SelectedUser({required this.user})
    : messageController = TextEditingController();

  final AppUser user;
  final TextEditingController messageController;

  void dispose() => messageController.dispose();
}

/// 친구 추가 화면 (페이지)
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _userIdController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  List<AppUser> _suggestions = [];
  final List<_SelectedUser> _selectedUsers = [];
  final Set<String> _sendingUids = {};
  bool _skipNextSearch = false;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _userIdController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _userIdController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _userIdController.dispose();
    _focusNode.dispose();
    for (final s in _selectedUsers) {
      s.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
    }
  }

  void _onTextChanged() {
    if (_skipNextSearch) {
      _skipNextSearch = false;
      return;
    }
    final searchQuery = _userIdController.text;

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
      if (!_focusNode.hasFocus) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }

      final friendService = ref.read(friendServiceProvider);
      final users = await friendService.searchUsersByIdPrefix(
        prefix,
        limit: 10,
      );

      if (mounted) {
        if (!_focusNode.hasFocus) {
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
          });
          return;
        }

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
    _debounce?.cancel();
    _skipNextSearch = true;
    _addUser(user);
    setState(() {
      _userIdController.clear();
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  Future<void> _searchUser() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
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
        _addUser(user);
        setState(() {
          _userIdController.clear();
          _showSuggestions = false;
        });
        _focusNode.unfocus();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다')));
        }
      }
    } catch (e) {
      if (mounted) {
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

  void _addUser(AppUser user) {
    if (_selectedUsers.any((s) => s.user.uid == user.uid)) {
      return;
    }
    setState(() => _selectedUsers.add(_SelectedUser(user: user)));
  }

  void _removeUser(_SelectedUser selected) {
    setState(() => _selectedUsers.remove(selected));
    selected.dispose();
  }

  Future<void> _sendRequest(_SelectedUser selected) async {
    final message = selected.messageController.text.trim().isEmpty
        ? '우리 친구해요!'
        : selected.messageController.text.trim();

    if (message.length > FriendRequest.maxMessageLength) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '메시지는 최대 ${FriendRequest.maxMessageLength}자까지 입력 가능합니다',
          ),
        ),
      );
      return;
    }

    setState(() => _sendingUids.add(selected.user.uid));

    try {
      final friendService = ref.read(friendServiceProvider);
      await friendService.sendFriendRequest(
        toUserId: selected.user.uid,
        toUserName: selected.user.name ?? '',
        message: message,
      );

      if (mounted) {
        setState(() {
          _selectedUsers.remove(selected);
          _sendingUids.remove(selected.user.uid);
        });
        selected.dispose();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈습니다')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingUids.remove(selected.user.uid));
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Widget _buildProfileAvatar(AppUser user, {double size = 32}) {
    final photoIndex = user.profilePhoto;

    const alcoholIcons = [
      'assets/imgs/alcohol_icons/soju.png',
      'assets/imgs/alcohol_icons/beer.png',
      'assets/imgs/alcohol_icons/cocktail.png',
      'assets/imgs/alcohol_icons/wine.png',
      'assets/imgs/alcohol_icons/makgulli.png',
    ];

    Widget avatar;
    if (photoIndex <= 10) {
      avatar = SakuCharacter(size: size, drunkLevel: photoIndex * 10);
    } else {
      final iconIndex = photoIndex - 11;
      if (iconIndex >= 0 && iconIndex < alcoholIcons.length) {
        avatar = Image.asset(alcoholIcons[iconIndex], fit: BoxFit.contain);
      } else {
        avatar = Icon(Icons.person, size: size * 0.7, color: Colors.grey[600]);
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: avatar),
    );
  }

  Widget _buildSelectedUserCard(_SelectedUser selected) {
    final isSending = _sendingUids.contains(selected.user.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 유저 정보 행
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
            child: Row(
              children: [
                _buildProfileAvatar(selected.user, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.user.name ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '@${selected.user.id ?? ''}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // 친구 신청 보내기 (종이비행기) + 제거 버튼
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isSending ? null : () => _sendRequest(selected),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryPink,
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: Colors.grey[500],
                                size: 22,
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeUser(selected),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 메시지 입력
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: selected.messageController,
              maxLength: FriendRequest.maxMessageLength,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '메시지 보내기',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonPageHeader(title: '친구 추가'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사용자 ID 검색창
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _userIdController,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _isSearching ? null : _searchUser(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '검색',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
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
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final user = _suggestions[index];
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -3,
                        ),
                        onTap: () => _selectSuggestion(user),
                        leading: _buildProfileAvatar(user, size: 30),
                        title: Text(
                          '@${user.id ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        subtitle: user.name != null
                            ? Text(
                                user.name!,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.25,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
              // 선택된 유저 카드 목록
              if (_selectedUsers.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final selected in _selectedUsers)
                  _buildSelectedUserCard(selected),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
