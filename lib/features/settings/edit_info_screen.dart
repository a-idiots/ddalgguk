import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';

/// Edit information screen for user profile settings
class EditInfoScreen extends StatelessWidget {
  const EditInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              // TODO: Navigate to alcohol tolerance selection
            },
          ),
          const SettingsSectionDivider(),

          // Usage Purpose Section
          const SettingsSectionHeader(title: '이용 목적'),
          SettingsListTile(
            title: '즐거운 음주',
            onTap: () {
              // TODO: Navigate to usage purpose selection
            },
          ),
        ],
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
