import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemicircularChart extends StatelessWidget {
  const SemicircularChart({
    super.key,
    required this.progress, // 0.0 to 1.0
    required this.centerText,
    this.size = 200,
  });

  final double progress;
  final String centerText;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6, // Semicircular height
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size * 0.6),
            painter: _SemicircularChartPainter(progress: progress),
          ),
          Positioned(
            bottom: 10,
            child: Text(
              centerText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemicircularChartPainter extends CustomPainter {
  _SemicircularChartPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    // Draw background arc (gray)
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from -x axis (180 degrees)
      math.pi, // Sweep 180 degrees (semicircle)
      false,
      backgroundPaint,
    );

    // Draw progress arc (red to green based on progress)
    final progressColor = _getProgressColor(progress);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from -x axis (180 degrees)
      math.pi * progress, // Sweep based on progress
      false,
      progressPaint,
    );

    // Draw segments (optional tick marks)
    _drawSegments(canvas, center, radius);
  }

  void _drawSegments(Canvas canvas, Offset center, double radius) {
    final segmentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw 12 segments (every 15 degrees)
    for (int i = 0; i <= 12; i++) {
      final angle = math.pi + (math.pi / 12 * i);
      final innerRadius = radius - 8;
      final outerRadius = radius + 8;

      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, segmentPaint);
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      // Low progress: Red
      return const Color(0xFFE35252);
    } else if (progress < 0.7) {
      // Medium progress: Orange/Yellow
      return const Color(0xFFFFA552);
    } else {
      // High progress: Green
      return const Color(0xFF52E370);
    }
  }

  @override
  bool shouldRepaint(covariant _SemicircularChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
