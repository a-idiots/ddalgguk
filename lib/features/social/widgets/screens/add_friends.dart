import 'dart:async';

import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:ddalgguk/features/social/domain/models/friend_request.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 친구 추가 화면 (페이지)
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _userIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isSearching = false;
  String? _foundUserName;
  String? _foundUserId;
  AppUser? _foundUser;
  List<AppUser> _suggestions = [];
  bool _skipNextSearch = false;
  bool _hasConfirmedSelection = false;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _userIdController.text = '@';
    _userIdController.selection = TextSelection.fromPosition(
      const TextPosition(offset: 1),
    );
    _messageController.text = '우리 친구해요!';

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
    _hasConfirmedSelection = false;
    final text = _userIdController.text;

    if (!text.startsWith('@')) {
      _userIdController.text = '@$text';
      _userIdController.selection = TextSelection.fromPosition(
        TextPosition(offset: _userIdController.text.length),
      );
      return;
    }

    if (text == '@' || _userIdController.selection.baseOffset == 0) {
      _userIdController.selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }

    final searchQuery = text.substring(1);

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
      if (_hasConfirmedSelection || !_focusNode.hasFocus) {
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
        if (_hasConfirmedSelection || !_focusNode.hasFocus) {
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
    _hasConfirmedSelection = true;
    setState(() {
      _userIdController.text = '@${user.id ?? ''}';
      _foundUserName = user.name ?? 'Unknown';
      _foundUserId = user.uid;
      _foundUser = user;
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  Future<void> _searchUser() async {
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
        _hasConfirmedSelection = true;
        setState(() {
          _foundUser = user;
          _foundUserName = user.name ?? 'Unknown';
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
          _foundUser = null;
          _hasConfirmedSelection = false;
        });
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
              // 사용자 ID 검색
              SizedBox(
                height: 44,
                child: TextField(
                  controller: _userIdController,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _isSearching ? null : _searchUser(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '@ 사용자 ID',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      onPressed: _isSearching ? null : _searchUser,
                      icon: Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              // 검색 결과
              if (_foundUserName != null && _foundUser != null) ...[
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
                      _buildProfileAvatar(_foundUser!, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUserName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${_foundUser!.id ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 요청 메시지
                TextField(
                  controller: _messageController,
                  maxLength: FriendRequest.maxMessageLength,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
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
              if (_foundUserName != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
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
