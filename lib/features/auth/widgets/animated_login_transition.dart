import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom Hero flight shuttle builder for smooth logo transition
Widget logoFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  // Smoothly transition between the two logo styles
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      // Interpolate size
      final size = Tween<double>(begin: 180, end: 100).evaluate(animation);
      final imageSize = Tween<double>(begin: 140, end: 80).evaluate(animation);
      final borderRadius =
          Tween<double>(begin: 90, end: 24).evaluate(animation);

      // Gradient transition (25-60% of animation)
      // This ensures it's fully visible BEFORE circular reveal completes at 67%
      final gradientOpacity = animation.value < 0.25
          ? 0.0
          : animation.value > 0.6
              ? 1.0
              : (animation.value - 0.25) / 0.35; // Maps 0.25-0.6 to 0.0-1.0

      // Gradient colors transition from splash background to final gradient
      final startColor = Color.lerp(
        Color(0xFFEA6B6B), // Match splash background (circle invisible at start)
        Color(0xFFFF8080), // Gradient start color
        gradientOpacity,
      )!;

      final endColor = Color.lerp(
        Color(0xFFEA6B6B), // Match splash background (circle invisible at start)
        Color(0xFFDA4444), // Gradient end color
        gradientOpacity,
      )!;

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: Tween<double>(begin: 20, end: 10).evaluate(animation),
              offset: Offset(
                0,
                Tween<double>(begin: 8, end: 4).evaluate(animation),
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Image.asset(
              'assets/logo.png',
              width: imageSize,
            ),
          ),
        ),
      );
    },
  );
}

/// Custom clipper for iris/circular reveal effect
class CircularRevealClipper extends CustomClipper<Path> {
  CircularRevealClipper({
    required this.progress,
    required this.center,
  });

  final double progress;
  final Offset center;

  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate the maximum radius needed to cover the entire screen
    final maxRadius = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2)
    );

    // Current radius based on progress
    final radius = maxRadius * progress;

    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}

/// Wrapper widget that animates the login screen entrance
class AnimatedLoginTransition extends StatefulWidget {
  const AnimatedLoginTransition({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;
  final bool animate;

  @override
  State<AnimatedLoginTransition> createState() => _AnimatedLoginTransitionState();
}

class _AnimatedLoginTransitionState extends State<AnimatedLoginTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topTextFadeOut;
  late Animation<double> _irisReveal;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoPosition;
  late Animation<double> _kakaoButtonFade;
  late Animation<double> _googleButtonFade;
  late Animation<double> _appleButtonFade;

  @override
  void initState() {
    super.initState();

    // Main animation controller (1200ms total)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Top text fade out: 0-400ms
    _topTextFadeOut = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOut),
      ),
    );

    // Iris reveal effect: 200-800ms
    _irisReveal = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.67, curve: Curves.easeInOut),
      ),
    );

    // Logo scale: 400-800ms
    _logoScale = Tween<double>(
      begin: 1.5,
      end: 0.67,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.67, curve: Curves.easeInOut),
      ),
    );

    // Logo position: 400-800ms (from center to top)
    _logoPosition = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.6),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.67, curve: Curves.easeInOut),
      ),
    );

    // Staggered button fade ins: 800-1200ms
    _kakaoButtonFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.83, 1.0, curve: Curves.easeOut),
      ),
    );

    _googleButtonFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.92, 1.09, curve: Curves.easeOut),
      ),
    );

    _appleButtonFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(1.0, 1.17, curve: Curves.easeOut),
      ),
    );

    // Start animation if enabled
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.forward();
      });
    } else {
      _controller.value = 1.0; // Skip animation
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Pink background (will be revealed through iris effect)
            Container(
              color: const Color(0xFFEA6B6B),
            ),

            // White background with iris reveal
            ClipPath(
              clipper: CircularRevealClipper(
                progress: _irisReveal.value,
                center: Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height * 0.35,
                ),
              ),
              child: Container(
                color: Colors.white,
              ),
            ),

            // Provide animations to descendants via InheritedWidget
            LoginTransitionAnimations(
              topTextFadeOut: _topTextFadeOut,
              logoScale: _logoScale,
              logoPosition: _logoPosition,
              kakaoButtonFade: _kakaoButtonFade,
              googleButtonFade: _googleButtonFade,
              appleButtonFade: _appleButtonFade,
              child: child!,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }

  // Getters for animations (to be used by child widgets)
  Animation<double> get topTextFadeOut => _topTextFadeOut;
  Animation<double> get logoScale => _logoScale;
  Animation<Offset> get logoPosition => _logoPosition;
  Animation<double> get kakaoButtonFade => _kakaoButtonFade;
  Animation<double> get googleButtonFade => _googleButtonFade;
  Animation<double> get appleButtonFade => _appleButtonFade;
}

/// Helper widget to access animations from ancestor
class LoginTransitionAnimations extends InheritedWidget {
  const LoginTransitionAnimations({
    super.key,
    required this.topTextFadeOut,
    required this.logoScale,
    required this.logoPosition,
    required this.kakaoButtonFade,
    required this.googleButtonFade,
    required this.appleButtonFade,
    required super.child,
  });

  final Animation<double> topTextFadeOut;
  final Animation<double> logoScale;
  final Animation<Offset> logoPosition;
  final Animation<double> kakaoButtonFade;
  final Animation<double> googleButtonFade;
  final Animation<double> appleButtonFade;

  static LoginTransitionAnimations? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LoginTransitionAnimations>();
  }

  @override
  bool updateShouldNotify(LoginTransitionAnimations oldWidget) => true;
}
