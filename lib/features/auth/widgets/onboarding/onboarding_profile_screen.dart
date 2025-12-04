import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/widgets/info_input_page.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/widgets/goal_setting_page.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/widgets/page_indicator.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';

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
  int? _favoriteDrink;
  double? _maxAlcohol;
  int? _weeklyDrinkingFrequency;
  String? _gender;
  DateTime? _birthDate;
  double? _height;
  double? _weight;

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
    required int favoriteDrink,
    required double maxAlcohol,
    required int weeklyDrinkingFrequency,
  }) async {
    if (_name == null || _id == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _goal = goal;
      _favoriteDrink = favoriteDrink;
      _maxAlcohol = maxAlcohol;
      _weeklyDrinkingFrequency = weeklyDrinkingFrequency;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);

      // Save profile data
      await authRepository.saveProfileData(
        id: _id!,
        name: _name!,
        goal: goal,
        favoriteDrink: favoriteDrink,
        maxAlcohol: maxAlcohol,
        weeklyDrinkingFrequency: weeklyDrinkingFrequency,
        gender: _gender,
        birthDate: _birthDate,
        height: _height,
        weight: _weight,
      );

      // Clear saved state
      await _clearSavedState();

      // Navigate to home
      // The router will check cache and see hasCompletedProfileSetup: true
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

  void _handleGoalSubmit({
    required bool goal,
    required int favoriteDrink,
    required double maxAlcohol,
    required int weeklyDrinkingFrequency,
  }) {
    setState(() {
      _goal = goal;
      _favoriteDrink = favoriteDrink;
      _maxAlcohol = maxAlcohol;
      _weeklyDrinkingFrequency = weeklyDrinkingFrequency;
    });
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _saveState();
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
                      onComplete:
                          ({
                            required goal,
                            required favoriteDrink,
                            required maxAlcohol,
                            required weeklyDrinkingFrequency,
                          }) => _handleGoalSubmit(
                            goal: goal,
                            favoriteDrink: favoriteDrink,
                            maxAlcohol: maxAlcohol,
                            weeklyDrinkingFrequency: weeklyDrinkingFrequency,
                          ),
                      initialGoal: _goal,
                      initialFavoriteDrink: _favoriteDrink,
                      initialMaxAlcohol: _maxAlcohol,
                      initialWeeklyDrinkingFrequency: _weeklyDrinkingFrequency,
                    ),
                    // Page 3: Intro
                    _buildIntroPage(),
                    // Page 4: Gender
                    _buildGenderPage(),
                    // Page 5: BirthDate
                    _buildBirthDatePage(),
                    // Page 6: BodyInfo
                    _buildBodyInfoPage(),
                    // Page 7: Outro
                    _buildOutroPage(),
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

  Widget _buildIntroPage() {
    return _CommonOnboardingPage(
      title: '당신의 건강한 음주 생활을 위해\n몇 가지 정보가 필요해요!',
      content: const SizedBox.shrink(),
      onNext: () {
        _pageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      buttonText: '다음',
    );
  }

  Widget _buildGenderPage() {
    return _CommonOnboardingPage(
      title: '성별을 알려주세요',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GenderButton(
            label: '남성',
            isSelected: _gender == 'male',
            onTap: () {
              setState(() {
                _gender = 'male';
              });
            },
          ),
          const SizedBox(width: 16),
          _GenderButton(
            label: '여성',
            isSelected: _gender == 'female',
            onTap: () {
              setState(() {
                _gender = 'female';
              });
            },
          ),
        ],
      ),
      onNext: _gender != null
          ? () {
              _pageController.animateToPage(
                5,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          : null,
      buttonText: '다음',
    );
  }

  Widget _buildBirthDatePage() {
    // Simple date picker implementation
    return _CommonOnboardingPage(
      title: '생년월일을 알려주세요',
      content: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _birthDate = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _birthDate != null
                    ? '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일'
                    : '날짜 선택',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      onNext: _birthDate != null
          ? () {
              _pageController.animateToPage(
                6,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          : null,
      buttonText: '다음',
    );
  }

  Widget _buildBodyInfoPage() {
    return _CommonOnboardingPage(
      title: '키와 몸무게를 알려주세요',
      content: Column(
        children: [
          _BodyInfoInput(
            label: '키 (cm)',
            onChanged: (value) {
              setState(() {
                _height = double.tryParse(value);
              });
            },
            initialValue: _height?.toString(),
          ),
          const SizedBox(height: 16),
          _BodyInfoInput(
            label: '몸무게 (kg)',
            onChanged: (value) {
              setState(() {
                _weight = double.tryParse(value);
              });
            },
            initialValue: _weight?.toString(),
          ),
        ],
      ),
      onNext: (_height != null && _weight != null)
          ? () {
              _pageController.animateToPage(
                7,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          : null,
      buttonText: '다음',
    );
  }

  Widget _buildOutroPage() {
    return _CommonOnboardingPage(
      title: '준비가 완료되었어요!\n이제 시작해볼까요?',
      content: const SizedBox.shrink(),
      onNext: () {
        if (_goal != null &&
            _favoriteDrink != null &&
            _maxAlcohol != null &&
            _weeklyDrinkingFrequency != null &&
            _gender != null &&
            _birthDate != null &&
            _height != null &&
            _weight != null) {
          _handleComplete(
            goal: _goal!,
            favoriteDrink: _favoriteDrink!,
            maxAlcohol: _maxAlcohol!,
            weeklyDrinkingFrequency: _weeklyDrinkingFrequency!,
          );
        }
      },
      buttonText: '시작하기',
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

class _CommonOnboardingPage extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onNext;
  final String buttonText;

  const _CommonOnboardingPage({
    required this.title,
    required this.content,
    this.onNext,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 키보드 내림
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const SakuCharacter(size: 120), // Default size
            const SizedBox(height: 40),
            Expanded(child: content),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onNext != null
                      ? Colors.black
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _BodyInfoInput extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;

  const _BodyInfoInput({
    required this.label,
    required this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
