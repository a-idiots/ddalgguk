import 'package:flutter/material.dart';

/// Tail position for speech bubble
enum TailPosition { bottom, right, left, top }

/// Speech bubble widget for Saku character
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.tailPosition = TailPosition.bottom,
    this.fontSize = 14,
    this.maxLines,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final TailPosition tailPosition;
  final double fontSize;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    // Adjust padding based on tail position
    EdgeInsets padding;
    switch (tailPosition) {
      case TailPosition.bottom:
        padding = const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 22,
        );
        break;
      case TailPosition.right:
        padding = const EdgeInsets.only(
          left: 20,
          right: 30,
          top: 12,
          bottom: 12,
        );
        break;
      case TailPosition.left:
        padding = const EdgeInsets.only(
          left: 30,
          right: 20,
          top: 12,
          bottom: 12,
        );
        break;
      case TailPosition.top:
        padding = const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: 12,
        );
        break;
    }

    return CustomPaint(
      painter: _BubblePainter(backgroundColor, tailPosition),
      child: Container(
        padding: padding,
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
  _BubblePainter(this.backgroundColor, this.tailPosition);

  final Color backgroundColor;
  final TailPosition tailPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final tailWidth = 20.0;
    final tailHeight = 10.0;

    // Main bubble rectangle with rounded corners (size adjusted based on tail position)
    RRect rect;
    switch (tailPosition) {
      case TailPosition.bottom:
        rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
          const Radius.circular(20),
        );
        break;
      case TailPosition.right:
        rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width - tailHeight, size.height),
          const Radius.circular(20),
        );
        break;
      case TailPosition.left:
        rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tailHeight, 0, size.width - tailHeight, size.height),
          const Radius.circular(20),
        );
        break;
      case TailPosition.top:
        rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, tailHeight, size.width, size.height - tailHeight),
          const Radius.circular(20),
        );
        break;
    }
    path.addRRect(rect);

    // Triangle tail based on position
    switch (tailPosition) {
      case TailPosition.bottom:
        final tailCenterX = size.width / 2;
        path.moveTo(tailCenterX - tailWidth / 2, size.height - tailHeight);
        path.lineTo(tailCenterX, size.height);
        path.lineTo(tailCenterX + tailWidth / 2, size.height - tailHeight);
        break;
      case TailPosition.right:
        final tailCenterY = size.height / 2;
        path.moveTo(size.width - tailHeight, tailCenterY - tailWidth / 2);
        path.lineTo(size.width, tailCenterY);
        path.lineTo(size.width - tailHeight, tailCenterY + tailWidth / 2);
        break;
      case TailPosition.left:
        final tailCenterY = size.height / 2;
        path.moveTo(tailHeight, tailCenterY - tailWidth / 2);
        path.lineTo(0, tailCenterY);
        path.lineTo(tailHeight, tailCenterY + tailWidth / 2);
        break;
      case TailPosition.top:
        final tailCenterX = size.width / 2;
        path.moveTo(tailCenterX - tailWidth / 2, tailHeight);
        path.lineTo(tailCenterX, 0);
        path.lineTo(tailCenterX + tailWidth / 2, tailHeight);
        break;
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.tailPosition != tailPosition;
  }
}
