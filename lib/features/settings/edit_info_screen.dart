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
              // TODO: Navigate to drinking frequency selection
            },
          ),
          SettingsListTile(
            title: '가장 선호하는 주종',
            onTap: () {
              // TODO: Navigate to favorite drink selection
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
  ConsumerState<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
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

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성별이 저장되었습니다')),
        );
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
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                    ),
                  ),
                  leading: Radio<String>(
                    value: '남성',
                  ),
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
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                    ),
                  ),
                  leading: Radio<String>(
                    value: '여성',
                  ),
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
  int? _height;
  int? _weight;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhysicalInfo();
  }

  Future<void> _loadPhysicalInfo() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (mounted) {
      setState(() {
        _height = currentUser?.height?.toInt();
        _weight = currentUser?.weight?.toInt();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectHeight() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => _HeightPickerDialog(initialHeight: _height),
    );
    if (selected != null) {
      setState(() {
        _height = selected;
      });
    }
  }

  Future<void> _selectWeight() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => _WeightPickerDialog(initialWeight: _weight),
    );
    if (selected != null) {
      setState(() {
        _weight = selected;
      });
    }
  }

  Future<void> _handleSave() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(
        height: _height?.toDouble(),
        weight: _weight?.toDouble(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신체 정보가 저장되었습니다')),
        );
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
          ListTile(
            title: const Text(
              '키',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
              ),
            ),
            trailing: Text(
              _height != null ? '$_height cm' : '선택',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            onTap: _selectHeight,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text(
              '몸무게',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
              ),
            ),
            trailing: Text(
              _weight != null ? '$_weight kg' : '선택',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            onTap: _selectWeight,
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
    );
  }
}

/// Height picker dialog
class _HeightPickerDialog extends StatefulWidget {
  const _HeightPickerDialog({this.initialHeight});

  final int? initialHeight;

  @override
  State<_HeightPickerDialog> createState() => _HeightPickerDialogState();
}

class _HeightPickerDialogState extends State<_HeightPickerDialog> {
  late int _selectedHeight;

  @override
  void initState() {
    super.initState();
    _selectedHeight = widget.initialHeight ?? 170;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('키 선택', style: TextStyle(fontFamily: 'Inter')),
      content: SizedBox(
        height: 300,
        width: 300,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedHeight = 100 + index;
            });
          },
          controller: FixedExtentScrollController(
            initialItem: _selectedHeight - 100,
          ),
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final height = 100 + index;
              return Center(
                child: Text(
                  '$height cm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: height == _selectedHeight ? 24 : 18,
                    fontWeight: height == _selectedHeight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
            childCount: 121, // 100-220cm
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(fontFamily: 'Inter')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedHeight),
          child: const Text('확인', style: TextStyle(fontFamily: 'Inter')),
        ),
      ],
    );
  }
}

/// Weight picker dialog
class _WeightPickerDialog extends StatefulWidget {
  const _WeightPickerDialog({this.initialWeight});

  final int? initialWeight;

  @override
  State<_WeightPickerDialog> createState() => _WeightPickerDialogState();
}

class _WeightPickerDialogState extends State<_WeightPickerDialog> {
  late int _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.initialWeight ?? 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('몸무게 선택', style: TextStyle(fontFamily: 'Inter')),
      content: SizedBox(
        height: 300,
        width: 300,
        child: ListWheelScrollView.useDelegate(
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedWeight = 30 + index;
            });
          },
          controller: FixedExtentScrollController(
            initialItem: _selectedWeight - 30,
          ),
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final weight = 30 + index;
              return Center(
                child: Text(
                  '$weight kg',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: weight == _selectedWeight ? 24 : 18,
                    fontWeight: weight == _selectedWeight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
            childCount: 121, // 30-150kg
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(fontFamily: 'Inter')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedWeight),
          child: const Text('확인', style: TextStyle(fontFamily: 'Inter')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해주세요')),
      );
      return;
    }

    try {
      final birthDate = DateTime(_year!, _month!, _day!);
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUserInfo(birthDate: birthDate);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생년월일이 저장되었습니다')),
        );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsSectionDivider(),
            const SizedBox(height: 24),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _year,
                  hint: const Text('선택', style: TextStyle(fontFamily: 'Inter')),
                  isExpanded: true,
                  items: _getYears().map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text('$year년', style: const TextStyle(fontFamily: 'Inter')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _year = value;
                      if (_day != null && _month != null) {
                        final daysInMonth = DateTime(_year!, _month! + 1, 0).day;
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
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _month,
                  hint: const Text('선택', style: TextStyle(fontFamily: 'Inter')),
                  isExpanded: true,
                  items: _getMonths().map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text('$month월', style: const TextStyle(fontFamily: 'Inter')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _month = value;
                      if (_day != null && _year != null && _month != null) {
                        final daysInMonth = DateTime(_year!, _month! + 1, 0).day;
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
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _day,
                  hint: const Text('선택', style: TextStyle(fontFamily: 'Inter')),
                  isExpanded: true,
                  items: _getDays().map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text('$day일', style: const TextStyle(fontFamily: 'Inter')),
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
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
    );
  }
}
