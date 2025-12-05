import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/features/onboarding/widgets/info_input_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/drinking_goal_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/drinking_habits_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/page_indicator.dart';
import 'package:ddalgguk/features/onboarding/widgets/intro_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/gender_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/birth_date_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/body_info_page.dart';
import 'package:ddalgguk/features/onboarding/widgets/outro_page.dart';
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

  void _handleDrinkingGoalSubmit({
    required bool goal,
    required int weeklyDrinkingFrequency,
  }) {
    setState(() {
      _goal = goal;
      _weeklyDrinkingFrequency = weeklyDrinkingFrequency;
    });
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _saveState();
  }

  void _handleDrinkingHabitsSubmit({
    required int favoriteDrink,
    required double maxAlcohol,
  }) {
    setState(() {
      _favoriteDrink = favoriteDrink;
      _maxAlcohol = maxAlcohol;
    });
    _pageController.animateToPage(
      4,
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

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Detect keyboard manually via MediaQuery
      body: Stack(
        children: [
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
                      title: 'Your Name',
                      hintText: '행복한술고래',
                      onNext: _handleNameSubmit,
                      validator: _validateName,
                      initialValue: _name,
                      inputType: InfoInputType.name,
                    ),
                    // Page 2: ID input
                    InfoInputPage(
                      title: 'ID',
                      hintText: 'username',
                      onNext: _handleIdSubmit,
                      validator: _validateId,
                      initialValue: _id,
                      inputType: InfoInputType.id,
                    ),
                    // Page 2: Drinking Goal
                    DrinkingGoalPage(
                      onNext: _handleDrinkingGoalSubmit,
                      initialGoal: _goal,
                      initialWeeklyDrinkingFrequency: _weeklyDrinkingFrequency,
                    ),
                    // Page 3: Drinking Habits
                    DrinkingHabitsPage(
                      onComplete: _handleDrinkingHabitsSubmit,
                      initialFavoriteDrink: _favoriteDrink,
                      initialMaxAlcohol: _maxAlcohol,
                    ),
                    // Page 3: Intro
                    IntroPage(
                      onNext: () {
                        _pageController.animateToPage(
                          5,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    // Page 4: Gender
                    GenderPage(
                      selectedGender: _gender,
                      onGenderSelected: (gender) {
                        setState(() {
                          _gender = gender;
                        });
                      },
                      onNext: _gender != null
                          ? () {
                              _pageController.animateToPage(
                                6,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                    // Page 5: BirthDate
                    BirthDatePage(
                      selectedDate: _birthDate,
                      onDateSelected: (date) {
                        setState(() {
                          _birthDate = date;
                        });
                      },
                      onNext: _birthDate != null
                          ? () {
                              _pageController.animateToPage(
                                7,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                    // Page 6: BodyInfo
                    BodyInfoPage(
                      height: _height,
                      weight: _weight,
                      onHeightChanged: (value) {
                        setState(() {
                          _height = double.tryParse(value);
                        });
                      },
                      onWeightChanged: (value) {
                        setState(() {
                          _weight = double.tryParse(value);
                        });
                      },
                      onNext: (_height != null && _weight != null)
                          ? () {
                              _pageController.animateToPage(
                                8,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                    // Page 7: Outro
                    OutroPage(
                      onStart: () {
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
                    ),
                  ],
                ),
                // Page indicator - Hidden when keyboard is visible or on page 3
                if (!isKeyboardVisible && _currentPage <= 3)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: Center(
                      child: PageIndicator(
                        currentPage: _currentPage,
                        pageCount: 4,
                      ),
                    ),
                  ),
                if (_currentPage > 0 && _currentPage < 4)
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
                            color: Colors.black,
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
