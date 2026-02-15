import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/providers/notification_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/screens/main_drink_settings_screen.dart';

/// Edit information screen for user profile settings
class EditInfoScreen extends ConsumerWidget {
  const EditInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '정보 수정',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SettingsSectionDivider(),

          // Personal Information Section
          const SettingsSectionHeader(title: '개인 정보'),
          SettingsListTile(
            title: '성별',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GenderSelectionScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '신체 정보',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PhysicalInfoScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '생년월일',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BirthDateScreen(),
                ),
              );
            },
          ),
          const SettingsSectionDivider(),

          // Drinking Related Section
          const SettingsSectionHeader(title: '음주 관련'),
          SettingsListTile(
            title: '음주 빈도',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DrinkingFrequencyScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '가장 선호하는 주종',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoriteDrinkScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '주량',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlcoholToleranceScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '메인 기록 주종',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MainDrinkSettingsScreen(),
                ),
              );
            },
          ),
          const SettingsSectionDivider(),

          // Usage Purpose Section
          const SettingsSectionHeader(title: '이용 목적'),
          currentUserAsync.when(
            data: (user) => _GoalToggleTile(
              currentGoal: user?.goal ?? true,
              onToggle: (newGoal) async {
                try {
                  final authRepository = ref.read(authRepositoryProvider);
                  final currentUser = user;

                  if (currentUser != null) {
                    await authRepository.saveProfileData(
                      id: currentUser.id ?? '',
                      name: currentUser.name ?? '',
                      goal: newGoal,
                      favoriteDrink: currentUser.favoriteDrink ?? 0,
                      maxAlcohol: currentUser.maxAlcohol ?? 0,
                      weeklyDrinkingFrequency:
                          currentUser.weeklyDrinkingFrequency ?? 0,
                      gender: currentUser.gender,
                      birthDate: currentUser.birthDate,
                      height: currentUser.height,
                      weight: currentUser.weight,
                    );

                    // Refresh user data immediately
                    ref.invalidate(currentUserProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newGoal ? '즐거운 음주로 변경되었습니다' : '건강한 절주로 변경되었습니다',
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('변경 실패: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            loading: () =>
                const _GoalToggleTile(currentGoal: true, onToggle: null),
            error: (_, __) =>
                const _GoalToggleTile(currentGoal: true, onToggle: null),
          ),
        ],
      ),
    );
  }
}

/// Goal toggle tile widget
class _GoalToggleTile extends StatefulWidget {
  const _GoalToggleTile({required this.currentGoal, required this.onToggle});

  final bool currentGoal;
  final Future<void> Function(bool)? onToggle;

  @override
  State<_GoalToggleTile> createState() => _GoalToggleTileState();
}

class _GoalToggleTileState extends State<_GoalToggleTile> {
  late bool _localGoal;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _localGoal = widget.currentGoal;
  }

  @override
  void didUpdateWidget(_GoalToggleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentGoal != oldWidget.currentGoal && !_isUpdating) {
      _localGoal = widget.currentGoal;
    }
  }

  Future<void> _handleToggle() async {
    if (widget.onToggle == null || _isUpdating) {
      return;
    }

    setState(() {
      _localGoal = !_localGoal;
      _isUpdating = true;
    });

    try {
      await widget.onToggle!(_localGoal);
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _localGoal = !_localGoal;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _localGoal ? '즐거운 음주' : '건강한 절주',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
            ),
            GestureDetector(
              onTap: widget.onToggle != null ? _handleToggle : null,
              child: Opacity(
                opacity: widget.onToggle != null && !_isUpdating ? 1.0 : 0.5,
                child: Container(
                  width: 51,
                  height: 31,
                  decoration: BoxDecoration(
                    color: _localGoal ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(15.5),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _localGoal
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 27,
                      height: 27,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gender selection screen
class GenderSelectionScreen extends ConsumerStatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  ConsumerState<GenderSelectionScreen> createState() =>
      _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends ConsumerState<GenderSelectionScreen> {
  String? _selectedGender;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGender();
    });
  }

  // Convert DB value to UI display value
  String? _dbToUi(String? dbValue) {
    switch (dbValue) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      default:
        return null;
    }
  }

  // Convert UI display value to DB value
  String? _uiToDb(String? uiValue) {
    switch (uiValue) {
      case '남성':
        return 'male';
      case '여성':
        return 'female';
      default:
        return null;
    }
  }

  Future<void> _loadGender() async {
    // Invalidate both auth state and current user to ensure fresh data
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        _selectedGender = _dbToUi(currentUser?.gender);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_selectedGender == null) {
      _showSnackBar('성별을 선택해주세요');
      return;
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(gender: _uiToDb(_selectedGender));

      // Refresh user data
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('성별이 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('저장 실패: $e', isError: true);
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
            '성별',
            style: TextStyle(
              fontFamily: 'Inter',
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
          '성별',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GenderButton(
                  label: '남',
                  isSelected: _selectedGender == '남성',
                  onTap: () {
                    setState(() {
                      _selectedGender = '남성';
                    });
                  },
                ),
                const SizedBox(width: 36),
                _GenderButton(
                  label: '여',
                  isSelected: _selectedGender == '여성',
                  onTap: () {
                    setState(() {
                      _selectedGender = '여성';
                    });
                  },
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  Color get mainColor =>
      label == '남' ? const Color(0xFF7A86F5) : const Color(0xFFE35252);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? mainColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: mainColor, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : mainColor,
          ),
        ),
      ),
    );
  }
}

/// Physical information screen
class PhysicalInfoScreen extends ConsumerStatefulWidget {
  const PhysicalInfoScreen({super.key});

  @override
  ConsumerState<PhysicalInfoScreen> createState() => _PhysicalInfoScreenState();
}

class _PhysicalInfoScreenState extends ConsumerState<PhysicalInfoScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhysicalInfo();
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPhysicalInfo() async {
    // Invalidate both auth state and current user to ensure fresh data
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        if (currentUser?.height != null) {
          _heightController.text = currentUser!.height!.toInt().toString();
        }
        if (currentUser?.weight != null) {
          _weightController.text = currentUser!.weight!.toInt().toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    if (heightText.isEmpty && weightText.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('키 또는 몸무게를 입력해주세요')));
      return;
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(
        height: heightText.isNotEmpty ? double.tryParse(heightText) : null,
        weight: weightText.isNotEmpty ? double.tryParse(weightText) : null,
      );

      // Refresh user data
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('신체 정보가 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            '신체 정보',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '신체 정보',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _BodyInfoInput(
                      label: '키 (cm)',
                      controller: _heightController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BodyInfoInput(
                      label: '몸무게 (kg)',
                      controller: _weightController,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyInfoInput extends StatelessWidget {
  const _BodyInfoInput({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

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
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        ),
      ],
    );
  }
}

/// Birth date screen
class BirthDateScreen extends ConsumerStatefulWidget {
  const BirthDateScreen({super.key});

  @override
  ConsumerState<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends ConsumerState<BirthDateScreen> {
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBirthDate();
    });
  }

  Future<void> _loadBirthDate() async {
    // Invalidate both auth state and current user to ensure fresh data
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        _selectedDate =
            currentUser?.birthDate ?? DateTime(DateTime.now().year - 19, 1, 1);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일을 선택해주세요')));
      return;
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(birthDate: _selectedDate);

      // Refresh user data
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('생년월일이 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            '생년월일',
            style: TextStyle(
              fontFamily: 'Inter',
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
          '생년월일',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate ?? DateTime(2007, 1, 1),
                minimumDate: DateTime(1900),
                maximumDate: DateTime(DateTime.now().year - 19, 12, 31),
                dateOrder: DatePickerDateOrder.ymd,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

/// Drinking frequency screen
class DrinkingFrequencyScreen extends ConsumerStatefulWidget {
  const DrinkingFrequencyScreen({super.key});

  @override
  ConsumerState<DrinkingFrequencyScreen> createState() =>
      _DrinkingFrequencyScreenState();
}

class _DrinkingFrequencyScreenState
    extends ConsumerState<DrinkingFrequencyScreen> {
  final TextEditingController _frequencyController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFrequency();
    });
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _loadFrequency() async {
    // Invalidate both auth state and current user to ensure fresh data
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        if (currentUser?.weeklyDrinkingFrequency != null) {
          _frequencyController.text = currentUser!.weeklyDrinkingFrequency
              .toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final frequencyText = _frequencyController.text.trim();

    if (frequencyText.isEmpty) {
      setState(() {
        _errorMessage = '음주 빈도를 입력해주세요';
      });
      return;
    }

    final frequency = int.tryParse(frequencyText);
    if (frequency == null || frequency < 0) {
      setState(() {
        _errorMessage = '올바른 숫자를 입력해주세요';
      });
      return;
    }

    // Clamp frequency to maximum 7 and don't save
    if (frequency > 7) {
      _frequencyController.text = '7';
      setState(() {
        _errorMessage = '일주일 음주 빈도는 최대 7회까지 입력 가능합니다';
      });
      return;
    }

    // Valid input, proceed to save
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = await ref.read(currentUserProvider.future);

      if (currentUser != null) {
        await authRepository.saveProfileData(
          id: currentUser.id ?? '',
          name: currentUser.name ?? '',
          goal: currentUser.goal ?? true,
          favoriteDrink: currentUser.favoriteDrink ?? 0,
          maxAlcohol: currentUser.maxAlcohol ?? 0,
          weeklyDrinkingFrequency: frequency,
          gender: currentUser.gender,
          birthDate: currentUser.birthDate,
          height: currentUser.height,
          weight: currentUser.weight,
        );

        // Refresh user data
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);

        // Reschedule notifications with updated drinking frequency
        try {
          await ref.read(rescheduleNotificationsProvider.future);
        } catch (e) {
          debugPrint('Failed to reschedule notifications: $e');
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('음주 빈도가 저장되었습니다')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            '음주 빈도',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '음주 빈도',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SettingsSectionDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '나는 일주일에',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 30,
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              // Keyboard dismissed, validate and clamp value
                              final currentValue = int.tryParse(
                                _frequencyController.text,
                              );
                              if (currentValue != null && currentValue > 7) {
                                _frequencyController.text = '7';
                                setState(() {
                                  _errorMessage = '일주일 음주 빈도는 최대 7회까지 입력 가능합니다';
                                });
                              } else if (currentValue != null &&
                                  currentValue >= 0) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            }
                          },
                          child: TextField(
                            controller: _frequencyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            cursorHeight: 18,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black87,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFFF6B6B),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(
                                left: 3,
                                bottom: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '번 술을 마신다.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 48),
                  Center(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '저장하기',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Favorite drink selection screen
class FavoriteDrinkScreen extends ConsumerStatefulWidget {
  const FavoriteDrinkScreen({super.key});

  @override
  ConsumerState<FavoriteDrinkScreen> createState() =>
      _FavoriteDrinkScreenState();
}

class _FavoriteDrinkScreenState extends ConsumerState<FavoriteDrinkScreen> {
  int? _selectedDrink;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavoriteDrink();
    });
  }

  Future<void> _loadFavoriteDrink() async {
    // Invalidate both auth state and current user to ensure fresh data
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        _selectedDrink = currentUser?.favoriteDrink;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선호하는 주종을 선택해주세요')));
      return;
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = await ref.read(currentUserProvider.future);

      if (currentUser != null) {
        await authRepository.saveProfileData(
          id: currentUser.id ?? '',
          name: currentUser.name ?? '',
          goal: currentUser.goal ?? true,
          favoriteDrink: _selectedDrink!,
          maxAlcohol: currentUser.maxAlcohol ?? 0,
          weeklyDrinkingFrequency: currentUser.weeklyDrinkingFrequency ?? 0,
          gender: currentUser.gender,
          birthDate: currentUser.birthDate,
          height: currentUser.height,
          weight: currentUser.weight,
        );

        // Refresh user data
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('선호하는 주종이 저장되었습니다')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            '가장 선호하는 주종',
            style: TextStyle(
              fontFamily: 'Inter',
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
          '가장 선호하는 주종',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SettingsSectionDivider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildDrinkSelectionCards(),
                const SizedBox(height: 48),
                Center(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkSelectionCards() {
    Widget buildDrinkCard(int drinkId) {
      final drink = drinks.firstWhere((drink) => drink.id == drinkId);
      final isSelected = _selectedDrink == drinkId;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDrink = drinkId;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFB3B3)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(drink.imagePath, width: 40, height: 40),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '당신의 최애 술은?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // First row: 3 items
          Row(
            children: [
              buildDrinkCard(1),
              const SizedBox(width: 12),
              buildDrinkCard(2),
              const SizedBox(width: 12),
              buildDrinkCard(3),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: 2 items
          Row(
            children: [
              buildDrinkCard(4),
              const SizedBox(width: 12),
              buildDrinkCard(5),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Empty space for alignment
            ],
          ),
        ],
      ),
    );
  }
}

/// Alcohol tolerance screen
class AlcoholToleranceScreen extends ConsumerStatefulWidget {
  const AlcoholToleranceScreen({super.key});

  @override
  ConsumerState<AlcoholToleranceScreen> createState() =>
      _AlcoholToleranceScreenState();
}

class _AlcoholToleranceScreenState
    extends ConsumerState<AlcoholToleranceScreen> {
  int? _sliderIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaxAlcohol();
    });
  }

  Future<void> _loadMaxAlcohol() async {
    // Invalidate both auth state and current user to ensure fresh data
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        if (currentUser?.maxAlcohol != null) {
          _sliderIndex = _alcoholToSliderIndex(currentUser!.maxAlcohol!);
        }
        _isLoading = false;
      });
    }
  }

  // Convert slider index to actual alcohol amount
  double _sliderIndexToAlcohol(int index) {
    if (index <= 7) {
      // 0-1병: 7등분
      return index / 7.0;
    } else if (index <= 13) {
      // 1-4병: 0.5병씩
      return 1.0 + (index - 7) * 0.5;
    } else {
      // 4병+
      return 4.0 + (index - 13);
    }
  }

  // Convert alcohol amount to slider index
  int _alcoholToSliderIndex(double alcohol) {
    if (alcohol <= 1.0) {
      return (alcohol * 7).round();
    } else if (alcohol <= 4.0) {
      return 7 + ((alcohol - 1.0) / 0.5).round();
    } else {
      return 13 + (alcohol - 4.0).round();
    }
  }

  double get _maxAlcohol =>
      _sliderIndex != null ? _sliderIndexToAlcohol(_sliderIndex!) : 0.0;

  String _getAlcoholDisplayText() {
    final alcohol = _maxAlcohol;
    if (alcohol >= 1) {
      if ((alcohol * 10) % 10 != 0) {
        return '$alcohol병';
      } else {
        return '${alcohol.toInt()}병';
      }
    } else {
      return '${(alcohol * 7).toInt()}잔';
    }
  }

  Future<void> _handleSave() async {
    if (_sliderIndex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주량을 선택해주세요')));
      return;
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = await ref.read(currentUserProvider.future);

      if (currentUser != null) {
        await authRepository.saveProfileData(
          id: currentUser.id ?? '',
          name: currentUser.name ?? '',
          goal: currentUser.goal ?? true,
          favoriteDrink: currentUser.favoriteDrink ?? 0,
          maxAlcohol: _maxAlcohol,
          weeklyDrinkingFrequency: currentUser.weeklyDrinkingFrequency ?? 0,
          gender: currentUser.gender,
          birthDate: currentUser.birthDate,
          height: currentUser.height,
          weight: currentUser.weight,
        );

        // Refresh user data
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('주량이 저장되었습니다')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            '주량',
            style: TextStyle(
              fontFamily: 'Inter',
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
          '주량',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SettingsSectionDivider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text(
                  '소주 주량을 입력해주세요.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                _buildAlcoholSlider(),
                const SizedBox(height: 12),
                const Text(
                  '음주 백과💡 소주 1병은 약 7잔이다.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 48),
                Center(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlcoholSlider() {
    return Column(
      children: [
        _NonLinearSlider(
          sliderIndex: _sliderIndex ?? 0,
          onChanged: (index) {
            setState(() {
              _sliderIndex = index;
            });
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0병',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                _getAlcoholDisplayText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                '7병',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NonLinearSlider extends StatelessWidget {
  const _NonLinearSlider({required this.sliderIndex, required this.onChanged});

  final int sliderIndex;
  final ValueChanged<int> onChanged;

  // Calculate visual position (0.0 to 1.0) for each index
  double _getVisualPosition(int index) {
    if (index <= 7) {
      // 0-1병: 7등분 -> 30% of track (0.0 to 0.3)
      return 0.3 * (index / 7.0);
    } else if (index <= 13) {
      // 1-4병: 6단계 -> 50% of track (0.3 to 0.8)
      return 0.3 + 0.5 * ((index - 7) / 6.0);
    } else {
      // 4병+: 3단계 -> 20% of track (0.8 to 1.0)
      return 0.8 + 0.2 * ((index - 13) / 3.0);
    }
  }

  // Find nearest index from visual position
  int _findNearestIndex(double position) {
    int nearestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i <= 16; i++) {
      final indexPosition = _getVisualPosition(i);
      final distance = (position - indexPosition).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  @override
  Widget build(BuildContext context) {
    final visualPosition = _getVisualPosition(sliderIndex);

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = details.localPosition.dx;
        final width = box.size.width;
        final position = (localPosition / width).clamp(0.0, 1.0);
        final newIndex = _findNearestIndex(position);
        if (newIndex != sliderIndex) {
          onChanged(newIndex);
        }
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = details.localPosition.dx;
        final width = box.size.width;
        final position = (localPosition / width).clamp(0.0, 1.0);
        final newIndex = _findNearestIndex(position);
        onChanged(newIndex);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Thumb의 반지름
            const thumbRadius = 10.0;
            // 실제 사용 가능한 트랙 너비 (padding 제외)
            final trackWidth = constraints.maxWidth;
            // Thumb의 중심 위치 (thumbRadius ~ trackWidth - thumbRadius 범위)
            final thumbCenterPosition =
                thumbRadius + (trackWidth - 2 * thumbRadius) * visualPosition;

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Track
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Active track (thumb의 중심까지 채움)
                Positioned(
                  left: 0,
                  right: null,
                  top: 18,
                  child: Container(
                    width: thumbCenterPosition,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Thumb (중심이 thumbCenterPosition에 오도록)
                Positioned(
                  left: thumbCenterPosition - thumbRadius,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
