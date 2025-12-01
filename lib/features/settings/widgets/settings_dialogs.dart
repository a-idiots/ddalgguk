import 'package:flutter/material.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/speech_bubble.dart';

/// Reusable dialog widget for settings information displays
/// Shows Saku character with a speech bubble containing custom content
class SakuInfoDialog extends StatelessWidget {
  const SakuInfoDialog({
    super.key,
    required this.content,
  });

  /// Content to display inside the speech bubble
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/background/onboarding_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Speech bubble with custom content
                  Center(
                    child: CustomPaint(
                      painter: _BubblePainter(
                        Colors.white,
                        TailPosition.bottom,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                        child: content,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Saku character
                  const Center(
                    child: SakuCharacter(
                      size: 84,
                      drunkLevel: 0,
                    ),
                  ),
                ],
              ),
            ),
            // Close button (X)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
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
    const double tailWidth = 20.0;
    const double tailHeight = 10.0;

    // Main bubble rectangle with rounded corners
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
      const Radius.circular(20),
    );
    path.addRRect(rect);

    // Triangle tail at bottom
    final tailCenterX = size.width / 2;
    path.moveTo(tailCenterX - tailWidth / 2, size.height - tailHeight);
    path.lineTo(tailCenterX, size.height);
    path.lineTo(tailCenterX + tailWidth / 2, size.height - tailHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.tailPosition != tailPosition;
  }
}

/// Shows the app version dialog
void showVersionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => SakuInfoDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '딸꾹',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ver 1.0.0',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows the contact dialog with Instagram DM information
void showContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const SakuInfoDialog(
      content: Text(
        '@ddalgguk으로\n인스타그램 DM',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    ),
  );
}
