import 'package:flutter/material.dart';

/// Custom Hero flight shuttle builder for smooth logo transition
Widget logoFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  // 로고 스타일을 부드럽게 보간
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final size = Tween<double>(begin: 180, end: 100).evaluate(animation);
      final imageSize = Tween<double>(begin: 140, end: 80).evaluate(animation);
      final borderRadius = Tween<double>(
        begin: 90,
        end: 24,
      ).evaluate(animation);

      // 그라디언트는 25~60% 구간에서 서서히 활성화
      final t = animation.value;
      final gradientOpacity = t < 0.25
          ? 0.0
          : t > 0.6
          ? 1.0
          : (t - 0.25) / 0.35;

      final startColor = Color.lerp(
        const Color(0xFFEA6B6B),
        const Color(0xFFFF8080),
        gradientOpacity,
      )!;

      final endColor = Color.lerp(
        const Color(0xFFEA6B6B),
        const Color(0xFFDA4444),
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
            child: Image.asset('assets/logo.png', width: imageSize),
          ),
        ),
      );
    },
  );
}

/// 로그인 화면 진입 시 내부 요소만 단계적으로 등장시키는 래퍼
class AnimatedLoginTransition extends StatefulWidget {
  const AnimatedLoginTransition({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;
  final bool animate;

  @override
  State<AnimatedLoginTransition> createState() =>
      _AnimatedLoginTransitionState();
}

class _AnimatedLoginTransitionState extends State<AnimatedLoginTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topTextFadeOut;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoPosition;
  late Animation<double> _kakaoButtonFade;
  late Animation<double> _googleButtonFade;
  late Animation<double> _appleButtonFade;

  @override
  void initState() {
    super.initState();

    // 라우트 전환(원형 리빌)과 길이를 맞춘다.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Top text fade out: 0~30%
    _topTextFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );

    // Logo scale & position: 33~67%
    _logoScale = Tween<double>(begin: 1.5, end: 0.67).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.67, curve: Curves.easeInOut),
      ),
    );

    _logoPosition =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.6)).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.33, 0.67, curve: Curves.easeInOut),
          ),
        );

    // Buttons fade-in: 70~100% 구간에서 순차 등장 (카카오 → 구글 → 애플)
    _kakaoButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.85, curve: Curves.easeOut),
      ),
    );
    _googleButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 0.95, curve: Curves.easeOut),
      ),
    );
    _appleButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.86, 1.00, curve: Curves.easeOut),
      ),
    );

    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _controller.forward(),
      );
    } else {
      _controller.value = 1.0;
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

    // 배경 리빌은 라우트 전환에서 이미 처리되므로, 여기서는 내부 요소 애니메이션만 제공
    return LoginTransitionAnimations(
      topTextFadeOut: _topTextFadeOut,
      logoScale: _logoScale,
      logoPosition: _logoPosition,
      kakaoButtonFade: _kakaoButtonFade,
      googleButtonFade: _googleButtonFade,
      appleButtonFade: _appleButtonFade,
      child: widget.child,
    );
  }
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
    return context
        .dependOnInheritedWidgetOfExactType<LoginTransitionAnimations>();
  }

  @override
  bool updateShouldNotify(LoginTransitionAnimations oldWidget) => true;
}
