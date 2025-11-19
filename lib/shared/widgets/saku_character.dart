import 'package:flutter/material.dart';

/// Saku character widget with eye tracking capability
/// The eyes follow the cursor position in the input field
class SakuCharacter extends StatefulWidget {
  const SakuCharacter({super.key, this.cursorOffset, this.size = 200});

  /// Cursor offset in the input field (null when not focused)
  final Offset? cursorOffset;

  /// Size of the character
  final double size;

  @override
  State<SakuCharacter> createState() => _SakuCharacterState();
}

class _SakuCharacterState extends State<SakuCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _eyeController;
  Offset _currentEyePosition = Offset.zero;
  Offset _targetEyePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _eyeController.addListener(() {
      setState(() {
        _currentEyePosition = Offset.lerp(
          _currentEyePosition,
          _targetEyePosition,
          _eyeController.value,
        )!;
      });
    });
  }

  @override
  void didUpdateWidget(SakuCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cursorOffset != oldWidget.cursorOffset) {
      _updateEyePosition();
    }
  }

  void _updateEyePosition() {
    if (widget.cursorOffset == null) {
      // Reset to center when not focused
      _targetEyePosition = Offset.zero;
    } else {
      // Calculate eye direction based on cursor position
      // The cursor offset is relative to the screen
      // We need to calculate the angle from the character to the cursor
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final characterPosition = renderBox.localToGlobal(Offset.zero);
        final characterCenter = Offset(
          characterPosition.dx + widget.size / 2,
          characterPosition.dy + widget.size / 2,
        );

        // Calculate direction vector
        final direction = widget.cursorOffset! - characterCenter;
        final distance = direction.distance;

        if (distance > 0) {
          // Normalize and limit movement range
          const maxEyeMovement = 8.0; // Maximum pixel movement for eyes
          final normalizedDirection = direction / distance;
          _targetEyePosition = Offset(
            normalizedDirection.dx * maxEyeMovement,
            normalizedDirection.dy * maxEyeMovement,
          );
        }
      }
    }

    _eyeController.reset();
    _eyeController.forward();
  }

  @override
  void dispose() {
    _eyeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body
          Image.asset(
            'assets/saku/body.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
          // Eyes with tracking
          Transform.translate(
            offset: _currentEyePosition,
            child: Image.asset(
              'assets/saku/eyes.png',
              width: widget.size * 0.3, // Eyes are smaller relative to body
              height: widget.size * 0.3,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
