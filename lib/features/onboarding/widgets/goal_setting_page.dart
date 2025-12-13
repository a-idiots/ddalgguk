import 'package:flutter/material.dart';
import 'package:ddalgguk/features/onboarding/widgets/page_indicator.dart';

/// Goal setting page for profile setup (Page 3)
class GoalSettingPage extends StatefulWidget {
  const GoalSettingPage({
    super.key,
    required this.onComplete,
    this.initialGoal,
    this.initialFavoriteDrink,
    this.initialMaxAlcohol,
    this.initialWeeklyDrinkingFrequency,
  });

  final void Function({
    required bool goal,
    required int favoriteDrink,
    required double maxAlcohol,
    required int weeklyDrinkingFrequency,
  })
  onComplete;

  final bool? initialGoal;
  final int? initialFavoriteDrink;
  final double? initialMaxAlcohol;
  final int? initialWeeklyDrinkingFrequency;

  @override
  State<GoalSettingPage> createState() => _GoalSettingPageState();
}

class _GoalSettingPageState extends State<GoalSettingPage> {
  bool? _selectedGoal;
  int? _selectedDrink;
  int? _sliderIndex; // null until both goal and drink are selected
  int? _weeklyDrinkingFrequency;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal;
    if (widget.initialFavoriteDrink != null) {
      _selectedDrink = widget.initialFavoriteDrink;
    }
    if (widget.initialMaxAlcohol != null) {
      _sliderIndex = _alcoholToSliderIndex(widget.initialMaxAlcohol!);
    }
    if (widget.initialWeeklyDrinkingFrequency != null) {
      _weeklyDrinkingFrequency = widget.initialWeeklyDrinkingFrequency;
    }
    // Initialize slider index if both goal and drink are already selected
    if (_selectedGoal != null &&
        _selectedDrink != null &&
        _sliderIndex == null) {
      _sliderIndex = 8; // Default to 1.5 bottles
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

  bool get _isFormComplete =>
      _selectedGoal != null &&
      _selectedDrink != null &&
      _sliderIndex != null &&
      _weeklyDrinkingFrequency != null;

  void _handleComplete() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('목표를 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선호하는 주류를 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_sliderIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('주량을 입력해주세요'),
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

    widget.onComplete(
      goal: _selectedGoal!,
      favoriteDrink: _selectedDrink!,
      maxAlcohol: _maxAlcohol,
      weeklyDrinkingFrequency: _weeklyDrinkingFrequency!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 키보드 내림
        FocusScope.of(context).unfocus();
      },
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Goal setting section
              const Text(
                '당신의 목표는 무엇인가요?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              _buildSimpleGoalOptions(),
              const SizedBox(height: 12),
              // Divider
              const Divider(color: Colors.black26, thickness: 0.5),
              const SizedBox(height: 12),
              _buildDrinkSelectionCards(),
              const SizedBox(height: 24),
              // Slider section - only visible when both goal and drink are selected
              Visibility(
                visible: _selectedGoal != null && _selectedDrink != null,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Column(
                  children: [
                    const Text(
                      '소주 주량을 입력해주세요.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildAlcoholSlider(),
                    const SizedBox(height: 12),
                    const Text(
                      '음주 백과💡 소주 1병은 약 7잔이다.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Weekly drinking frequency input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '나는 일주일에',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          final frequency = int.tryParse(value);
                          setState(() {
                            _weeklyDrinkingFrequency = frequency;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '번 술을 마신다',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Page indicator
              const PageIndicator(currentPage: 2, pageCount: 3),
              const SizedBox(height: 32),
              // Complete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormComplete ? _handleComplete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '입력 완료',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

  Widget _buildSimpleGoalOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSimpleRadio('건강한 절주', false),
        const SizedBox(width: 40),
        _buildSimpleRadio('즐거운 음주', true),
      ],
    );
  }

  Widget _buildSimpleRadio(String label, bool value) {
    final isSelected = _selectedGoal == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = value;
        });
      },
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 2),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFF6B6B)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkSelectionCards() {
    final drinks = [
      {'img': 'assets/imgs/alcohol_icons/soju.png', 'name': '소주', 'id': 0},
      {'img': 'assets/imgs/alcohol_icons/beer.png', 'name': '맥주', 'id': 1},
      {'img': 'assets/imgs/alcohol_icons/cocktail.png', 'name': '칵테일', 'id': 2},
      {'img': 'assets/imgs/alcohol_icons/wine.png', 'name': '와인', 'id': 3},
      {'img': 'assets/imgs/alcohol_icons/makgulli.png', 'name': '막걸리', 'id': 4},
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
