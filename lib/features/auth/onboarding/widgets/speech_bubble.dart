import 'package:flutter/material.dart';

/// Speech bubble widget for Saku character
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.fontSize = 14,
    this.maxLines,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(backgroundColor),
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 22, // 12 + 10 (tail height) to center text in main bubble
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
        ),
      ),
    );
  }
}

/// Custom painter for speech bubble with tail
class _BubblePainter extends CustomPainter {
  _BubblePainter(this.backgroundColor);

  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();

    // Main bubble rectangle with rounded corners
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 10),
      const Radius.circular(20),
    );
    path.addRRect(rect);

    // Triangle tail at the bottom center
    final tailWidth = 20.0;
    final tailHeight = 10.0;
    final tailCenterX = size.width / 2;

    path.moveTo(tailCenterX - tailWidth / 2, size.height - tailHeight);
    path.lineTo(tailCenterX, size.height);
    path.lineTo(tailCenterX + tailWidth / 2, size.height - tailHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor;
  }
}
