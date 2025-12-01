import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';

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
    _loadGender();
  }

  Future<void> _loadGender() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        _selectedGender = currentUser?.gender;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGender() async {
    if (_selectedGender == null) {
      return;
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(gender: _selectedGender);

      // Refresh user data
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('성별이 저장되었습니다')));
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
      body: Column(
        children: [
          const SettingsSectionDivider(),
          RadioGroup<String?>(
            groupValue: _selectedGender,
            onChanged: (value) async {
              setState(() {
                _selectedGender = value;
              });
              await _saveGender();
            },
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    '남성',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16),
                  ),
                  leading: Radio<String>(value: '남성'),
                  onTap: () async {
                    setState(() {
                      _selectedGender = '남성';
                    });
                    await _saveGender();
                  },
                ),
                ListTile(
                  title: const Text(
                    '여성',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16),
                  ),
                  leading: Radio<String>(value: '여성'),
                  onTap: () async {
                    setState(() {
                      _selectedGender = '여성';
                    });
                    await _saveGender();
                  },
                ),
              ],
            ),
          ),
        ],
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
    _loadPhysicalInfo();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPhysicalInfo() async {
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
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop();
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
      body: Column(
        children: [
          const SettingsSectionDivider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '키',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 16),
                    ),
                    const SizedBox(width: 120),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '입력',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'cm',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      '몸무게',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 16),
                    ),
                    const SizedBox(width: 88),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '입력',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'kg',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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
}

/// Birth date screen
class BirthDateScreen extends ConsumerStatefulWidget {
  const BirthDateScreen({super.key});

  @override
  ConsumerState<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends ConsumerState<BirthDateScreen> {
  int? _year;
  int? _month;
  int? _day;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBirthDate();
  }

  Future<void> _loadBirthDate() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted && currentUser?.birthDate != null) {
      setState(() {
        _year = currentUser!.birthDate!.year;
        _month = currentUser.birthDate!.month;
        _day = currentUser.birthDate!.day;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<int> _getYears() {
    final currentYear = DateTime.now().year;
    return List.generate(100, (index) => currentYear - index);
  }

  List<int> _getMonths() {
    return List.generate(12, (index) => index + 1);
  }

  List<int> _getDays() {
    if (_year == null || _month == null) {
      return List.generate(31, (index) => index + 1);
    }
    final daysInMonth = DateTime(_year!, _month! + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

  Future<void> _handleSave() async {
    if (_year == null || _month == null || _day == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 선택해주세요')));
      return;
    }

    try {
      final birthDate = DateTime(_year!, _month!, _day!);
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(birthDate: birthDate);

      // Refresh user data
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('생년월일이 저장되었습니다')));
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionDivider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  '연도',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _year,
                      hint: const Text(
                        '선택',
                        style: TextStyle(fontFamily: 'Inter'),
                      ),
                      isExpanded: true,
                      items: _getYears().map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(
                            '$year년',
                            style: const TextStyle(fontFamily: 'Inter'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _year = value;
                          if (_day != null && _month != null) {
                            final daysInMonth = DateTime(
                              _year!,
                              _month! + 1,
                              0,
                            ).day;
                            if (_day! > daysInMonth) {
                              _day = daysInMonth;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '월',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _month,
                      hint: const Text(
                        '선택',
                        style: TextStyle(fontFamily: 'Inter'),
                      ),
                      isExpanded: true,
                      items: _getMonths().map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                            '$month월',
                            style: const TextStyle(fontFamily: 'Inter'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _month = value;
                          if (_day != null && _year != null && _month != null) {
                            final daysInMonth = DateTime(
                              _year!,
                              _month! + 1,
                              0,
                            ).day;
                            if (_day! > daysInMonth) {
                              _day = daysInMonth;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '일',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _day,
                      hint: const Text(
                        '선택',
                        style: TextStyle(fontFamily: 'Inter'),
                      ),
                      isExpanded: true,
                      items: _getDays().map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(
                            '$day일',
                            style: const TextStyle(fontFamily: 'Inter'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _day = value;
                        });
                      },
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

  @override
  void initState() {
    super.initState();
    _loadFrequency();
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _loadFrequency() async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음주 빈도를 입력해주세요')));
      return;
    }

    final frequency = int.tryParse(frequencyText);
    if (frequency == null || frequency < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 숫자를 입력해주세요')));
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
          maxAlcohol: currentUser.maxAlcohol ?? 0,
          weeklyDrinkingFrequency: frequency,
          gender: currentUser.gender,
          birthDate: currentUser.birthDate,
          height: currentUser.height,
          weight: currentUser.weight,
        );

        // Refresh user data
        ref.invalidate(currentUserProvider);

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
      body: Column(
        children: [
          const SettingsSectionDivider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '나는 술을 일주일에',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _frequencyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '번 마신다',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
    _loadFavoriteDrink();
  }

  Future<void> _loadFavoriteDrink() async {
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
    final drinks = [
      {'img': 'assets/alcohol_icons/soju.png', 'name': '소주', 'id': 0},
      {'img': 'assets/alcohol_icons/beer.png', 'name': '맥주', 'id': 1},
      {'img': 'assets/alcohol_icons/cocktail.png', 'name': '칵테일', 'id': 2},
      {'img': 'assets/alcohol_icons/wine.png', 'name': '와인', 'id': 3},
      {'img': 'assets/alcohol_icons/makgulli.png', 'name': '막걸리', 'id': 4},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '당신의 최애 술은?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: drinks.map((drink) {
              final drinkId = drink['id'] as int;
              final isSelected = _selectedDrink == drinkId;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            drink['img'] as String,
                            width: 42,
                            height: 42,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drink['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
    _loadMaxAlcohol();
  }

  Future<void> _loadMaxAlcohol() async {
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
