import 'package:flutter/material.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';

/// Page for setting drinking habits (favorite drink and max alcohol)
class DrinkingHabitsPage extends StatefulWidget {
  const DrinkingHabitsPage({
    super.key,
    required this.onComplete,
    this.initialFavoriteDrink,
    this.initialMaxAlcohol,
  });

  final void Function({required int favoriteDrink, required double maxAlcohol})
  onComplete;

  final int? initialFavoriteDrink;
  final double? initialMaxAlcohol;

  @override
  State<DrinkingHabitsPage> createState() => _DrinkingHabitsPageState();
}

class _DrinkingHabitsPageState extends State<DrinkingHabitsPage>
    with SingleTickerProviderStateMixin {
  int? _selectedDrink;
  int? _sliderIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialFavoriteDrink != null) {
      _selectedDrink = widget.initialFavoriteDrink;
    }
    if (widget.initialMaxAlcohol != null) {
      _sliderIndex = _alcoholToSliderIndex(widget.initialMaxAlcohol!);
    }
    // Initialize slider index if drink is already selected
    if (_selectedDrink != null && _sliderIndex == null) {
      _sliderIndex = 8; // Default to 1.5 bottles
    }

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

    if (_selectedDrink != null) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  bool get _isFormComplete => _selectedDrink != null && _sliderIndex != null;

  void _handleComplete() {
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선호하는 주류를 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_sliderIndex == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('주량을 입력해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onComplete(favoriteDrink: _selectedDrink!, maxAlcohol: _maxAlcohol);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 120),
          const Text(
            '당신의 음주 습관이 궁금해요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
          _buildDrinkSelectionCards(),
          const SizedBox(height: 25),
          // Slider section with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
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
                  const SizedBox(height: 16),
                  _buildAlcoholSlider(),
                  const SizedBox(height: 12),
                  const Text(
                    '음주 백과💡 소주 1병은 약 7잔이다.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isFormComplete ? _handleComplete : null,
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
                '입력 완료',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
            final wasNull = _selectedDrink == null;
            setState(() {
              _selectedDrink = drinkId;
              _sliderIndex ??= 0;
            });
            if (wasNull) {
              _animationController.forward();
            }
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
              buildDrinkCard(6),
            ],
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
                '7병+',
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
