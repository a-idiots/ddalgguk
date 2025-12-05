import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

/// Saku character widget with eye tracking capability
/// The eyes follow the cursor position in the input field
class SakuCharacter extends StatefulWidget {
  const SakuCharacter({
    super.key,
    this.cursorOffset,
    this.size = 200,
    this.drunkLevel = 0,
    this.status = 0,
  });

  /// Cursor offset in the input field (null when not focused)
  final Offset? cursorOffset;

  /// Size of the character
  final double size;

  /// Drunk level (0-100) for gradient body images
  /// 0 = sober, 100 = very drunk
  final int drunkLevel;

  /// Status of the character
  /// 0 = normal (default)
  /// 1 = future date (no eyes)
  /// -1 = empty date (with eyes)
  final int status;

  @override
  State<SakuCharacter> createState() => _SakuCharacterState();
}

class _SakuCharacterState extends State<SakuCharacter>
    with TickerProviderStateMixin {
  late AnimationController _eyeController;
  late AnimationController _sizeController;
  late Animation<double> _sizeAnimation;
  Offset _currentEyePosition = Offset.zero;
  Offset _targetEyePosition = Offset.zero;
  double _animatedSize = 200;

  @override
  void initState() {
    super.initState();
    _animatedSize = widget.size;

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

    _sizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _sizeAnimation =
        Tween<double>(begin: widget.size, end: widget.size).animate(
      CurvedAnimation(parent: _sizeController, curve: Curves.easeInOut),
    );

    _sizeAnimation.addListener(() {
      setState(() {
        _animatedSize = _sizeAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(SakuCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cursorOffset != oldWidget.cursorOffset) {
      _updateEyePosition();
    }
    if (widget.size != oldWidget.size) {
      _updateSize(oldWidget.size);
    }
  }

  void _updateSize(double oldSize) {
    _sizeAnimation = Tween<double>(begin: oldSize, end: widget.size).animate(
      CurvedAnimation(parent: _sizeController, curve: Curves.easeInOut),
    );

    _sizeController.reset();
    _sizeController.forward();
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
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get body image path based on status or drunk level
    String bodyImagePath;
    bool showEyes = true;

    if (widget.status == 1) {
      bodyImagePath = 'assets/calendar/future_date.png';
      showEyes = false;
    } else if (widget.status == -1) {
      bodyImagePath = 'assets/calendar/empty_date.png';
      showEyes = true;
    } else {
      bodyImagePath = getBodyImagePath(widget.drunkLevel);
      showEyes = true;
    }

    return SizedBox(
      width: _animatedSize,
      height: _animatedSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body (with gradient based on drunk level)
          Image.asset(
            bodyImagePath,
            width: _animatedSize,
            height: _animatedSize,
            fit: BoxFit.contain,
          ),
          // Eyes with tracking
          if (showEyes)
            Transform.translate(
              offset: _currentEyePosition,
              child: Image.asset(
                'assets/saku/eyes.png',
                width: _animatedSize * 0.3, // Eyes are smaller relative to body
                height: _animatedSize * 0.3,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}
