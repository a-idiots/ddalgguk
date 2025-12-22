import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';

class UnifiedProfileSetupPage extends StatefulWidget {
  const UnifiedProfileSetupPage({
    super.key,
    required this.userName,
    required this.selectedGender,
    required this.onGenderSelected,
    required this.selectedDate,
    required this.onDateSelected,
    required this.height,
    required this.weight,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onComplete,
    required this.onBack,
  });

  final String? userName;
  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final double? height;
  final double? weight;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  @override
  State<UnifiedProfileSetupPage> createState() =>
      _UnifiedProfileSetupPageState();
}

class _UnifiedProfileSetupPageState extends State<UnifiedProfileSetupPage> {
  int _currentStep =
      0; // 0: Intro, 1: Gender, 2: BirthDate, 3: BodyInfo, 4: Outro
  int _introStep = 0; // 0: First title, 1: Second title
  bool _showOutroButton = false;

  @override
  void initState() {
    super.initState();
    _startIntroAnimation();
  }

  void _startIntroAnimation() {
    // Show first title for 2 seconds, then switch to second title
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _currentStep == 0) {
        setState(() {
          _introStep = 1;
        });
        // Show second title for 2 seconds, then advance to next step
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _currentStep == 0) {
            _nextStep();
          }
        });
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        // If entering Outro (step 4), delay button appearance
        if (_currentStep == 4) {
          _showOutroButton = false;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _currentStep == 4) {
              setState(() {
                _showOutroButton = true;
              });
            }
          });
        }
      });
    } else {
      widget.onComplete();
    }
  }

  String _getTitle() {
    switch (_currentStep) {
      case 0:
        return _introStep == 0
            ? '안녕 나는 사쿠!\n너의 간의 정령이야!'
            : '맞춤형 관리를 위해서\n너의 정보가 필요해!';
      case 1:
        return '먼저 성별을 선택해줘!';
      case 2:
        return '나이도 선택해줘!';
      case 3:
        return '알콜 분해 속도는\n키와 몸무게에 따라서도 달라져!';
      case 4:
        return '좋아 준비 완료!\n${widget.userName ?? '친구'}, 앞으로 잘 부탁해!';
      default:
        return '';
    }
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case 0: // Intro
        return const SizedBox();
      case 1: // Gender
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GenderButton(
              label: '남',
              isSelected: widget.selectedGender == 'male',
              onTap: () => widget.onGenderSelected('male'),
            ),
            const SizedBox(width: 36),
            _GenderButton(
              label: '여',
              isSelected: widget.selectedGender == 'female',
              onTap: () => widget.onGenderSelected('female'),
            ),
          ],
        );
      case 2: // BirthDate
        return SizedBox(
          height: 200,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime:
                widget.selectedDate ?? DateTime(DateTime.now().year - 19),
            minimumDate: DateTime(1900),
            maximumDate: DateTime(DateTime.now().year - 19, 12, 31),
            dateOrder: DatePickerDateOrder.ymd,
            onDateTimeChanged: widget.onDateSelected,
          ),
        );
      case 3: // BodyInfo
        return Row(
          children: [
            Expanded(
              child: _BodyInfoInput(
                label: '키 (cm)',
                onChanged: widget.onHeightChanged,
                initialValue: widget.height?.toString(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BodyInfoInput(
                label: '몸무게 (kg)',
                onChanged: widget.onWeightChanged,
                initialValue: widget.weight?.toString(),
              ),
            ),
          ],
        );
      case 4: // Outro
        return const SizedBox();
      default:
        return const SizedBox();
    }
  }

  bool _isNextEnabled() {
    switch (_currentStep) {
      case 0: // Intro
        return false; // Auto-advance
      case 1: // Gender
        return widget.selectedGender != null;
      case 2: // BirthDate
        return widget.selectedDate != null;
      case 3: // BodyInfo
        return widget.height != null && widget.weight != null;
      case 4: // Outro
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Button visibility logic:
    // Intro (0): Hidden (Auto-advance)
    // Gender (1), BirthDate (2), BodyInfo (3): Visible
    // Outro (4): Visible after delay
    final showButton =
        (_currentStep >= 1 && _currentStep <= 3) ||
        (_currentStep == 4 && _showOutroButton);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        color: Colors.transparent, // Hit test for tap
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 120),
            SizedBox(
              height:
                  50, // Fixed height for 2 lines of text (fontSize 15 * height 1.4 * 2 lines + padding)
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                layoutBuilder:
                    (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Check if this is the entering child or exiting child
                  final isEntering =
                      child.key ==
                      ValueKey<String>('${_currentStep}_$_introStep');

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: isEntering
                          ? const Offset(0, 0.6)
                          : const Offset(0, -0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  _getTitle(),
                  key: ValueKey<String>('${_currentStep}_$_introStep'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                    color: Color(0xFF7E7E7E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const SakuCharacter(
              size: 160,
              status: -2,
              cursorOffset: Offset(0, -10),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                layoutBuilder:
                    (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final isEntering = child.key == ValueKey<int>(_currentStep);

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: isEntering
                          ? const Offset(0, 0.4)
                          : const Offset(0, -0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildContent(),
                ),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: showButton && _isNextEnabled() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStep == 4 ? '시작하기' : '다음',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  Color get mainColor => label == '남' ? Color(0xFF7A86F5) : Color(0xFFE35252);

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

class _BodyInfoInput extends StatelessWidget {
  const _BodyInfoInput({
    required this.label,
    required this.onChanged,
    this.initialValue,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;

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
        ),
      ],
    );
  }
}
