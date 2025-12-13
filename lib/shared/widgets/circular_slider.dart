import 'dart:math';
import 'package:flutter/material.dart';

/// 둥근 슬라이더 위젯
class CircularSlider extends StatefulWidget {
  const CircularSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions = 20,
    this.size = 200,
    this.trackWidth = 20,
    this.inactiveColor = const Color(0xFFFEE5DA),
    this.activeColor = const Color(0xFFFA75A5),
    this.thumbColor = const Color(0xFFFA75A5),
    this.thumbRadius = 12,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;
  final double size;
  final double trackWidth;
  final Color inactiveColor;
  final Color activeColor;
  final Color thumbColor;
  final double thumbRadius;

  @override
  State<CircularSlider> createState() => _CircularSliderState();
}

class _CircularSliderState extends State<CircularSlider> {
  bool _isDragging = false;

  double _normalizeValue(double value) {
    return (value - widget.min) / (widget.max - widget.min);
  }

  double _denormalizeValue(double normalizedValue) {
    final value = normalizedValue * (widget.max - widget.min) + widget.min;
    if (widget.divisions > 0) {
      final step = (widget.max - widget.min) / widget.divisions;
      return (value / step).round() * step;
    }
    return value;
  }

  void _handlePanStart(Offset localPosition) {
    // 새로운 드래그 시작 - 점프 체크 없이 바로 값 설정
    _isDragging = false;
    _handlePanUpdate(localPosition);
    _isDragging = true;
  }

  void _handlePanUpdate(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // 각도 계산 (0도 = 위쪽, 시계 반대방향)
    var angle = atan2(-dx, -dy);

    // 0 ~ 2π 범위로 정규화
    if (angle < 0) {
      angle += 2 * pi;
    }

    // 각도를 0~1 범위의 값으로 변환
    final normalizedValue = angle / (2 * pi);

    // 실제 값으로 변환
    final newValue = _denormalizeValue(normalizedValue);

    // 0%↔100% 점프 방지 (드래그 중일 때만)
    final currentValue = widget.value;
    if (_isDragging && currentValue >= 80 && newValue <= 20) {
      // 100% 근처에서 0% 근처로 점프하려는 경우 100%로 고정
      widget.onChanged(widget.max);
      return;
    }
    if (_isDragging && currentValue <= 20 && newValue >= 80) {
      // 0% 근처에서 100% 근처로 점프하려는 경우 0%로 고정
      widget.onChanged(widget.min);
      return;
    }

    // 범위 체크
    final clampedValue = newValue.clamp(widget.min, widget.max);

    if (clampedValue != widget.value) {
      widget.onChanged(clampedValue);
    }
  }

  void _handlePanEnd() {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _handlePanStart(details.localPosition),
      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
      onPanEnd: (details) => _handlePanEnd(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _CircularSliderPainter(
            value: _normalizeValue(widget.value),
            trackWidth: widget.trackWidth,
            inactiveColor: widget.inactiveColor,
            activeColor: widget.activeColor,
            thumbColor: widget.thumbColor,
            thumbRadius: widget.thumbRadius,
          ),
        ),
      ),
    );
  }
}

class _CircularSliderPainter extends CustomPainter {
  _CircularSliderPainter({
    required this.value,
    required this.trackWidth,
    required this.inactiveColor,
    required this.activeColor,
    required this.thumbColor,
    required this.thumbRadius,
  });

  final double value;
  final double trackWidth;
  final Color inactiveColor;
  final Color activeColor;
  final Color thumbColor;
  final double thumbRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - trackWidth) / 2;

    // 비활성 트랙 그리기 (전체 원)
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, inactivePaint);

    // 활성 트랙 그리기 (0도에서 현재 값까지, 시계 반대방향, 그라데이션)
    if (value > 0) {
      final sweepAngle = value * 2 * pi;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // 시계 반대방향 그라데이션
      // 12시 방향부터 핸들 위치까지 그라데이션
      final gradientPaint = Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFFEE5DA), // 12시 방향 시작 색상
            Color(0xFFFA75A5), // 핸들 위치 색상
            Color(0xFFFEE5DA), // 다시 12시로 돌아오는 색상
          ],
          stops: [0.0, 1.0 - value, 1.0], // 12시->핸들->12시
          // 12시 방향에서 시작
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -pi / 2, // 시작 각도 (위쪽 = -90도)
        -sweepAngle, // 시계 반대방향
        false,
        gradientPaint,
      );
    }

    // 핸들(썸) 그리기 (시계 반대방향)
    final sweepAngle = value * 2 * pi;
    final thumbAngle = -pi / 2 - sweepAngle;
    final thumbX = center.dx + radius * cos(thumbAngle);
    final thumbY = center.dy + radius * sin(thumbAngle);
    final thumbCenter = Offset(thumbX, thumbY);

    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(_CircularSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.trackWidth != trackWidth ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.thumbRadius != thumbRadius;
  }
}
