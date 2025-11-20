import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/widgets/info_input_page.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/widgets/goal_setting_page.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/widgets/page_indicator.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';

/// Main onboarding profile screen with PageView
class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = false;

  // Form data
  String? _name;
  String? _id;
  bool? _goal;
  List<int>? _favoriteDrinks;
  double? _maxAlcohol;

  static const String _pageIndexKey = 'onboarding_profile_page_index';
  static const String _nameKey = 'onboarding_profile_name';
  static const String _idKey = 'onboarding_profile_id';

  @override
  void initState() {
    super.initState();
    // Initialize PageController immediately to avoid LateInitializationError
    _pageController = PageController(initialPage: 0);
    _loadSavedState();
  }

  /// Load saved state from SharedPreferences
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt(_pageIndexKey) ?? 0;
    final savedName = prefs.getString(_nameKey);
    final savedId = prefs.getString(_idKey);

    if (mounted) {
      setState(() {
        _currentPage = savedPage;
        _name = savedName;
        _id = savedId;
      });

      // Jump to saved page if not on first page
      if (savedPage > 0) {
        _pageController.jumpToPage(savedPage);
      }
    }
  }

  /// Save current state to SharedPreferences
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageIndexKey, _currentPage);
    if (_name != null) {
      await prefs.setString(_nameKey, _name!);
    }
    if (_id != null) {
      await prefs.setString(_idKey, _id!);
    }
  }

  /// Clear saved state
  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pageIndexKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_idKey);
  }

  void _handleNameSubmit(String name) {
    setState(() {
      _name = name;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _saveState();
  }

  void _handleIdSubmit(String id) {
    // Hide keyboard before moving to page 3
    FocusScope.of(context).unfocus();

    setState(() {
      _id = id;
    });
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _saveState();
  }

  Future<void> _handleComplete({
    required bool goal,
    required List<int> favoriteDrinks,
    required double maxAlcohol,
  }) async {
    if (_name == null || _id == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _goal = goal;
      _favoriteDrinks = favoriteDrinks;
      _maxAlcohol = maxAlcohol;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);

      // Save profile data
      await authRepository.saveProfileData(
        id: _id!,
        name: _name!,
        goal: goal,
        favoriteDrink: favoriteDrinks,
        maxAlcohol: maxAlcohol,
      );

      // Clear saved state
      await _clearSavedState();

      // Navigate to home
      if (mounted) {
        context.go(Routes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    debugPrint(
      'DEBUG: _handleBack called, _currentPage = $_currentPage, _isLoading = $_isLoading',
    );

    if (_isLoading) {
      debugPrint('DEBUG: Cannot go back while loading');
      return;
    }

    if (_currentPage > 0) {
      debugPrint(
        'DEBUG: Going back from page $_currentPage to ${_currentPage - 1}',
      );
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _saveState();
    } else {
      debugPrint('DEBUG: Already on first page, cannot go back');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 100;

    final isWhiteBg =
        (_pageController.hasClients
            ? (_pageController.page ?? _currentPage.toDouble())
            : _currentPage.toDouble()) >=
        1.5;

    final backIconColor = isWhiteBg ? Colors.black87 : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Detect keyboard manually via MediaQuery
      body: Stack(
        children: [
          // 🔥 페이지 스크롤에 맞춰 ‘배경’이 함께 이동하는 레이어
          Positioned.fill(
            child: _AnimatedOnboardingBackground(
              controller: _pageController,
              // 초기에는 controller.page가 null일 수 있으니 폴백 전달
              fallbackPage: _currentPage,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // Page content
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    // Page 1: Name input
                    InfoInputPage(
                      title: '당신의 이름을 알려주세요!',
                      speechBubbleText: '안녕 나는 사쿠!\n나는 너의 간의 정령이야',
                      hintText: '행복한술고래',
                      onNext: _handleNameSubmit,
                      validator: _validateName,
                      initialValue: _name,
                      inputType: InfoInputType.name,
                    ),
                    // Page 2: ID input
                    InfoInputPage(
                      title: '당신의 아이디를 알려주세요!',
                      speechBubbleText: '안녕 $_name!\n앞으로 잘 부탁해 :)',
                      hintText: 'username',
                      onNext: _handleIdSubmit,
                      validator: _validateId,
                      initialValue: _id,
                      inputType: InfoInputType.id,
                    ),
                    // Page 3: Goal setting
                    GoalSettingPage(
                      onComplete: _handleComplete,
                      initialGoal: _goal,
                      initialFavoriteDrinks: _favoriteDrinks,
                      initialMaxAlcohol: _maxAlcohol,
                    ),
                  ],
                ),
                // Page indicator - Hidden when keyboard is visible or on page 3
                if (!isKeyboardVisible && _currentPage != 2)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Center(
                      child: PageIndicator(
                        currentPage: _currentPage,
                        pageCount: 3,
                      ),
                    ),
                  ),
                // Back button (only show on pages 2 and 3)
                if (_currentPage > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _handleBack();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: backIconColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Validate name: only Korean, English, and numbers (no special characters)
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }

    // Only allow Korean (Hangul), English letters, and numbers
    final regex = RegExp(r'^[가-힣a-zA-Z0-9]+$');
    if (!regex.hasMatch(value)) {
      return '한글, 영어, 숫자만 사용 가능합니다';
    }

    if (value.length < 2) {
      return '이름은 2글자 이상이어야 합니다';
    }

    if (value.length > 20) {
      return '이름은 20글자 이하여야 합니다';
    }

    return null;
  }

  /// Validate ID: Instagram rules (letters, numbers, periods, underscores)
  String? _validateId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '아이디를 입력해주세요';
    }

    // Remove @ if present
    final id = value.startsWith('@') ? value.substring(1) : value;

    // Instagram username rules:
    // - 3-30 characters
    // - Letters, numbers, periods, and underscores only
    // - Cannot start or end with a period
    // - Cannot have consecutive periods
    if (id.length < 3) {
      return '아이디는 3글자 이상이어야 합니다';
    }

    if (id.length > 30) {
      return '아이디는 30글자 이하여야 합니다';
    }

    final regex = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!regex.hasMatch(id)) {
      return '영어, 숫자, 마침표, 밑줄만 사용 가능합니다';
    }

    if (id.startsWith('.') || id.endsWith('.')) {
      return '아이디는 마침표로 시작하거나 끝날 수 없습니다';
    }

    if (id.contains('..')) {
      return '연속된 마침표는 사용할 수 없습니다';
    }

    return null;
  }
}

class _AnimatedOnboardingBackground extends StatelessWidget {
  const _AnimatedOnboardingBackground({
    required this.controller,
    required this.fallbackPage,
  });

  final PageController controller;
  final int fallbackPage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // 0,1,2 페이지 사이의 실시간 위치값 (ex. 1.0 -> 1.35 -> 2.0)
            final page = controller.hasClients
                ? (controller.page ?? fallbackPage.toDouble())
                : fallbackPage.toDouble();

            // 기본(0~1페이지) 배경: 그라데이션
            const gradientBg = DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFA3A3), Color(0xFFE35252)],
                  stops: [0.0, 0.85],
                ),
              ),
            );

            // 2페이지(세 번째) 배경: 오른쪽에서 슬라이드 인 되는 화이트
            // page = 1.0  -> dx = width (오른쪽 바깥)
            // page = 2.0  -> dx = 0     (완전히 자리 잡음)
            final dx = ((2 - page).clamp(0.0, 1.0)) * width;

            return Stack(
              fit: StackFit.expand,
              children: [
                gradientBg,
                Transform.translate(
                  offset: Offset(dx, 0),
                  child: const ColoredBox(color: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
