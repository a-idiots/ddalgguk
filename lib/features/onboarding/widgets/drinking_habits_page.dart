import 'package:flutter/material.dart';

/// Page for setting max alcohol capacity
class DrinkingHabitsPage extends StatefulWidget {
  const DrinkingHabitsPage({
    super.key,
    required this.onComplete,
    this.initialMaxAlcohol,
  });

  final void Function({required double maxAlcohol}) onComplete;
  final double? initialMaxAlcohol;

  @override
  State<DrinkingHabitsPage> createState() => _DrinkingHabitsPageState();
}

class _DrinkingHabitsPageState extends State<DrinkingHabitsPage> {
  int? _sliderIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialMaxAlcohol != null) {
      _sliderIndex = _alcoholToSliderIndex(widget.initialMaxAlcohol!);
    } else {
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

  bool get _isFormComplete => _sliderIndex != null;

  void _handleComplete() {
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

    widget.onComplete(maxAlcohol: _maxAlcohol);
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
            '당신의 주량이 궁금해요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
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
            // 실제 사�� 가능한 트랙 너비 (padding 제외)
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
