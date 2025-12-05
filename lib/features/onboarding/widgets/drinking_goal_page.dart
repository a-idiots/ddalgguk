import 'package:flutter/material.dart';

/// Page for setting drinking goal and frequency
class DrinkingGoalPage extends StatefulWidget {
  const DrinkingGoalPage({
    super.key,
    required this.onNext,
    this.initialGoal,
    this.initialWeeklyDrinkingFrequency,
  });

  final void Function({
    required bool goal,
    required int weeklyDrinkingFrequency,
  })
  onNext;

  final bool? initialGoal;
  final int? initialWeeklyDrinkingFrequency;

  @override
  State<DrinkingGoalPage> createState() => _DrinkingGoalPageState();
}

class _DrinkingGoalPageState extends State<DrinkingGoalPage>
    with SingleTickerProviderStateMixin {
  bool? _selectedGoal;
  int? _weeklyDrinkingFrequency;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _frequencyController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal;
    _weeklyDrinkingFrequency = widget.initialWeeklyDrinkingFrequency;
    _frequencyController = TextEditingController(
      text: widget.initialWeeklyDrinkingFrequency?.toString() ?? '',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    if (_selectedGoal != null) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFormComplete =>
      _selectedGoal != null && _weeklyDrinkingFrequency != null;

  void _handleNext() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('목표를 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_weeklyDrinkingFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일주일 음주 빈도를 입력해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onNext(
      goal: _selectedGoal!,
      weeklyDrinkingFrequency: _weeklyDrinkingFrequency!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 120),
            const Text(
              '만나서 반가워요!\n당신의 목표는 무엇인가요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            _buildSimpleGoalOptions(),
            const SizedBox(height: 60),
            // Weekly drinking frequency input
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Row(
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
                                _weeklyDrinkingFrequency = 7;
                                _errorMessage = '일주일 음주 빈도는 최대 7회까지 입력 가능합니다';
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
                            contentPadding: EdgeInsets.only(left: 3, bottom: 1),
                          ),
                          onChanged: (value) {
                            final frequency = int.tryParse(value);
                            setState(() {
                              _weeklyDrinkingFrequency = frequency;
                            });
                          },
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
              ),
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormComplete ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '다음',
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

  Widget _buildSimpleGoalOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGoalButton('건강한 절주', false),
        const SizedBox(width: 30),
        _buildGoalButton('즐거운 음주', true),
      ],
    );
  }

  Widget _buildGoalButton(String label, bool value) {
    final isSelected = _selectedGoal == value;
    return GestureDetector(
      onTap: () {
        if (_selectedGoal == null) {
          _animationController.forward();
        }
        setState(() {
          _selectedGoal = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.black54,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.black54,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
