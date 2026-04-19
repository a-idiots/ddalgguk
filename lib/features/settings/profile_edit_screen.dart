import 'dart:typed_data';

import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/providers/profile_photo_providers.dart';
import 'package:ddalgguk/features/settings/widgets/save_button.dart';
import 'package:ddalgguk/shared/widgets/profile_avatar.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

/// 프로필 편집 화면
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();

  int _selectedProfilePhoto = 0;
  String? _userId;
  String? _userUid;
  bool _isLoading = true;
  bool _isSaving = false;

  /// 갤러리에서 고른 사진의 바이트 (미리보기용, 아직 업로드 전)
  Uint8List? _pendingPhotoBytes;

  /// 갤러리에서 고른 XFile (저장 시 업로드)
  XFile? _pendingPhotoFile;

  // 주종 아이콘 목록 (11~19)
  static const _alcoholIcons = [
    'assets/imgs/alcohol_icons/soju.png',
    'assets/imgs/alcohol_icons/beer.png',
    'assets/imgs/alcohol_icons/cocktail.png',
    'assets/imgs/alcohol_icons/wine.png',
    'assets/imgs/alcohol_icons/makgulli.png',
    'assets/imgs/alcohol_icons/whiskey.png',
    'assets/imgs/alcohol_icons/highball.png',
    'assets/imgs/alcohol_icons/sake.png',
    'assets/imgs/alcohol_icons/vodka.png',
  ];

  static const _alcoholIconNames = [
    '소주',
    '맥주',
    '칵테일',
    '와인',
    '막걸리',
    '위스키',
    '하이볼',
    '사케',
    '보드카',
  ];

  // 기본 프로필 SVG (uid 해시 → 4색 중 하나)
  static const _basicProfileColors = ['F2BFBF', 'CFA8A8', 'F59696', 'FFBCBC'];
  static const _basicProfileSvgTemplate =
      '<svg width="33" height="33" viewBox="0 0 33 33" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<path d="M33 16.5C33 7.3873 25.6127 0 16.5 0C7.3873 0 0 7.3873 0 16.5'
      'C0 25.6127 7.3873 33 16.5 33C25.6127 33 33 25.6127 33 16.5Z" '
      'fill="#BGCOLOR"/>'
      '<path fill-rule="evenodd" clip-rule="evenodd" '
      'd="M6.69338 26.7419C8.91745 23.6612 12.539 21.6562 16.6289 21.6562'
      'C20.6537 21.6562 24.2249 23.5978 26.4572 26.5954C23.8968 29.121 '
      '20.3805 30.6797 16.5 30.6797C12.6951 30.6797 9.24016 29.181 '
      '6.69338 26.7419ZM22.1719 13.2773C22.1719 16.481 19.6902 19.0781 '
      '16.6289 19.0781C13.5676 19.0781 11.0859 16.481 11.0859 13.2773'
      'C11.0859 10.0737 13.5676 7.47656 16.6289 7.47656C19.6902 7.47656 '
      '22.1719 10.0737 22.1719 13.2773Z" fill="white"/></svg>';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);

    if (mounted && currentUser != null) {
      setState(() {
        _nameController.text = currentUser.name ?? '';
        _selectedProfilePhoto = currentUser.profilePhoto;
        _userId = currentUser.id;
        _userUid = currentUser.uid;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ── 프로필 미리보기 ──────────────────────────────────────────────────────

  Widget _buildProfilePreview() {
    const double previewSize = 120;

    // 갤러리에서 새로 고른 사진 (아직 업로드 전)
    if (_pendingPhotoBytes != null) {
      return ClipOval(
        child: Image.memory(
          _pendingPhotoBytes!,
          width: previewSize,
          height: previewSize,
          fit: BoxFit.cover,
        ),
      );
    }

    // 0: 기본 프로필 SVG 미리보기
    if (_selectedProfilePhoto == 0) {
      final uid = _userUid ?? '';
      final hash = uid.codeUnits.fold(0, (acc, c) => acc + c);
      final color = _basicProfileColors[hash % _basicProfileColors.length];
      final svg = _basicProfileSvgTemplate.replaceFirst('BGCOLOR', color);
      return ClipOval(
        child: SvgPicture.string(
          svg,
          width: previewSize,
          height: previewSize,
          fit: BoxFit.cover,
        ),
      );
    }

    // -1 / 1-10 / 11-19 → ProfileAvatar 위젯 통합 처리
    return ProfileAvatar(
      profilePhoto: _selectedProfilePhoto,
      uid: _userUid ?? '',
      size: previewSize,
    );
  }

  // ── 1단계: 프로필 편집 옵션 선택 (3가지) ────────────────────────────────

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.photo_library_outlined,
                label: '직접 업로드하기',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              _buildOptionTile(
                icon: Icons.emoji_food_beverage_outlined,
                label: '딸꾹 아이콘에서 선택하기',
                onTap: () {
                  Navigator.pop(ctx);
                  _showProfilePhotoSelector();
                },
              ),
              _buildOptionTile(
                icon: Icons.person_outline,
                label: '기본 프로필 이용하기',
                onTap: () {
                  setState(() {
                    _selectedProfilePhoto = 0;
                    _pendingPhotoBytes = null;
                    _pendingPhotoFile = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // ── 갤러리 선택 ─────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pendingPhotoBytes = bytes;
        _pendingPhotoFile = file;
        _selectedProfilePhoto = -1;
      });
    }
  }

  // ── 2단계: 딸꾹 아이콘 선택 ─────────────────────────────────────────────

  void _showProfilePhotoSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '프로필 사진 선택',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사쿠 섹션 (index 1~10)
                        _sectionLabel('사쿠'),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: 10,
                          itemBuilder: (context, idx) {
                            final photoIndex = idx + 1; // 1~10
                            final isSelected =
                                _selectedProfilePhoto == photoIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProfilePhoto = photoIndex;
                                  _pendingPhotoBytes = null;
                                  _pendingPhotoFile = null;
                                });
                                setModalState(() {});
                                Navigator.pop(ctx);
                              },
                              child: _iconCell(
                                isSelected: isSelected,
                                child: SakuCharacter(
                                  size: 60,
                                  drunkLevel: photoIndex * 10,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // 주종 섹션 (index 11~19)
                        _sectionLabel('주종'),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: _alcoholIcons.length,
                          itemBuilder: (context, idx) {
                            final photoIndex = 11 + idx;
                            final isSelected =
                                _selectedProfilePhoto == photoIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProfilePhoto = photoIndex;
                                  _pendingPhotoBytes = null;
                                  _pendingPhotoFile = null;
                                });
                                setModalState(() {});
                                Navigator.pop(ctx);
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _iconCell(
                                      isSelected: isSelected,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Image.asset(
                                          _alcoholIcons[idx],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _alcoholIconNames[idx],
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _iconCell({required bool isSelected, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFF0A9A9) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0A9A9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  // ── 저장 ────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final uid = _userUid;

      // 커스텀 사진 업로드 (갤러리에서 선택한 경우)
      if (_selectedProfilePhoto == -1 &&
          _pendingPhotoFile != null &&
          uid != null) {
        final service = ref.read(profilePhotoServiceProvider);
        await service.uploadPhotoFromFile(uid, _pendingPhotoFile!);
      }

      await ref
          .read(authRepositoryProvider)
          .updateUserProfile(name: name, profilePhoto: _selectedProfilePhoto);

      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);

      // 커스텀 사진 캐시 무효화
      if (_selectedProfilePhoto == -1 && uid != null) {
        ref.invalidate(profilePhotoBase64Provider(uid));
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('저장 실패: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // ── 빌드 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '프로필 편집',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '프로필 편집',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SettingsSectionDivider(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // 프로필 사진 (탭 → 옵션 다이얼로그)
                    GestureDetector(
                      onTap: _showProfileOptions,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildProfilePreview(),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 아이디 (읽기 전용)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '아이디',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '@${_userId ?? ''}',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 닉네임 입력
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '닉네임',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '닉네임을 입력하세요',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    SaveButton(onPressed: _isSaving ? null : _handleSave),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
