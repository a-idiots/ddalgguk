import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemicircularChart extends StatelessWidget {
  const SemicircularChart({
    super.key,
    required this.progress, // 0.0 to 1.0
    required this.centerText,
    required this.activeColor,
    this.size = 200,
  });

  final double progress;
  final String centerText;
  final Color activeColor;
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
            painter: _SemicircularChartPainter(
              progress: progress,
              activeColor: activeColor,
            ),
          ),
          Positioned(
            bottom: 16,
            child: Text(
              centerText,
              style: const TextStyle(
                fontSize: 20,
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
  _SemicircularChartPainter({
    required this.progress,
    required this.activeColor,
  });

  final double progress;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);

    // Use full width but subtract a tiny amount to prevent anti-aliasing clipping at edges
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 50; // Thickness

    final paint = Paint()..style = PaintingStyle.fill;

    // Total segments = 17
    // First and last are 0.5 units. Middle 15 are 1 unit.
    // Total units = 15 + 0.5 + 0.5 = 16 units.
    const int totalSegments = 17;
    const double totalUnits = 16.0;
    const double unitAngle = math.pi / totalUnits;

    // Gap between segments (in radians)
    const double gap = 0.06;
    // Corner radius
    const double cornerRadius = 4.0;

    double currentAngle = math.pi;

    final int activeSegmentsCount = (progress * totalSegments).round();

    for (int i = 0; i < totalSegments; i++) {
      // Determine sweep for this segment
      final bool isEdge = i == 0 || i == totalSegments - 1;
      final double rawSweep = isEdge ? unitAngle / 2 : unitAngle;

      double start = currentAngle;
      double end = currentAngle + rawSweep;

      // Apply gaps
      if (i > 0) {
        start += gap / 2;
      }
      if (i < totalSegments - 1) {
        end -= gap / 2;
      }

      final double sweep = end - start;

      if (i < activeSegmentsCount) {
        paint.color = activeColor;
      } else {
        paint.color = Colors.grey[300]!;
      }

      // Draw rounded sector
      final path = _buildRoundedSectorPath(
        center,
        innerRadius,
        outerRadius,
        start,
        sweep,
        cornerRadius,
      );

      canvas.drawPath(path, paint);

      // Advance current angle
      currentAngle += rawSweep;
    }
  }

  Path _buildRoundedSectorPath(
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    double cornerRadius,
  ) {
    final path = Path();
    final endAngle = startAngle + sweepAngle;

    // Calculate angular offsets for corners
    // For inner corners: sin(dt) = cr / (r + cr)
    final double dtInner = math.asin(
      cornerRadius / (innerRadius + cornerRadius),
    );
    // For outer corners: sin(dt) = cr / (r - cr)
    final double dtOuter = math.asin(
      cornerRadius / (outerRadius - cornerRadius),
    );

    // Check if sweep is too small for the corners
    double effectiveDtInner = dtInner;
    double effectiveDtOuter = dtOuter;

    if (sweepAngle < dtInner * 2) {
      effectiveDtInner = sweepAngle / 2;
    }
    if (sweepAngle < dtOuter * 2) {
      effectiveDtOuter = sweepAngle / 2;
    }

    // Calculate start/end angles for the arcs
    final double thetaInnerStart = startAngle + effectiveDtInner;
    final double thetaInnerEnd = endAngle - effectiveDtInner;
    final double thetaOuterStart = startAngle + effectiveDtOuter;
    final double thetaOuterEnd = endAngle - effectiveDtOuter;

    // Calculate radial distances for the tangent points on the radial lines
    final double dInner = math.sqrt(
      math.pow(innerRadius + cornerRadius, 2) - math.pow(cornerRadius, 2),
    );
    final double dOuter = math.sqrt(
      math.pow(outerRadius - cornerRadius, 2) - math.pow(cornerRadius, 2),
    );

    // 1. Start at Outer Start Line point
    path.moveTo(
      center.dx + dOuter * math.cos(startAngle),
      center.dy + dOuter * math.sin(startAngle),
    );

    // 2. Corner 2 (Outer Start): Arc to Outer Arc
    // We use arcToPoint with radius.
    // The target point is on the outer circle at thetaOuterStart
    path.arcToPoint(
      Offset(
        center.dx + outerRadius * math.cos(thetaOuterStart),
        center.dy + outerRadius * math.sin(thetaOuterStart),
      ),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 3. Outer Arc
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      thetaOuterStart,
      thetaOuterEnd - thetaOuterStart,
      false,
    );

    // 4. Corner 3 (Outer End): Arc to End Line
    path.arcToPoint(
      Offset(
        center.dx + dOuter * math.cos(endAngle),
        center.dy + dOuter * math.sin(endAngle),
      ),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 5. Line to Inner End Line point
    path.lineTo(
      center.dx + dInner * math.cos(endAngle),
      center.dy + dInner * math.sin(endAngle),
    );

    // 6. Corner 4 (Inner End): Arc to Inner Arc
    path.arcToPoint(
      Offset(
        center.dx + innerRadius * math.cos(thetaInnerEnd),
        center.dy + innerRadius * math.sin(thetaInnerEnd),
      ),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 7. Inner Arc (drawn in reverse direction implicitly by order, but arcTo needs positive sweep usually?
    // Actually we want to draw from thetaInnerEnd to thetaInnerStart.
    // Since we are drawing clockwise, the angle decreases? No, angle increases clockwise in Flutter?
    // Flutter coordinates: +x right, +y down. 0 is right. PI/2 is down.
    // We are drawing from PI (left) to 2PI (right).
    // So angle increases clockwise.
    // Outer arc: thetaOuterStart -> thetaOuterEnd (increasing).
    // Inner arc: thetaInnerEnd -> thetaInnerStart (decreasing).
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      thetaInnerEnd,
      thetaInnerStart - thetaInnerEnd,
      false,
    );

    // 8. Corner 1 (Inner Start): Arc to Start Line
    path.arcToPoint(
      Offset(
        center.dx + dInner * math.cos(startAngle),
        center.dy + dInner * math.sin(startAngle),
      ),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SemicircularChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor;
  }
}
