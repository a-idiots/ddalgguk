import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/providers/app_state_provider.dart';
import 'package:ddalgguk/features/auth/widgets/google_login_button.dart';
import 'package:ddalgguk/features/auth/widgets/apple_login_button.dart';
import 'package:ddalgguk/features/auth/widgets/kakao_login_button.dart';
import 'package:ddalgguk/features/auth/widgets/animated_login_transition.dart';

/// Login Screen with social login options
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.animate = true});

  final bool animate;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _kakaoButtonFade;
  late Animation<double> _googleButtonFade;
  late Animation<double> _appleButtonFade;

  @override
  void initState() {
    super.initState();

    // Button fade-in animation controller (400ms duration, starting at 800ms)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Staggered fade-in animations for buttons
    _kakaoButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _googleButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
      ),
    );

    _appleButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation after circular reveal completes (800ms)
    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      // If no animation, show buttons immediately
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithGoogle();

      if (mounted) {
        // Set flag to indicate user just logged in
        // Router redirect will handle navigation
        ref.read(appStateProvider.notifier).setJustLoggedIn(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google 로그인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithApple();

      if (mounted) {
        // Set flag to indicate user just logged in
        // Router redirect will handle navigation
        ref.read(appStateProvider.notifier).setJustLoggedIn(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple 로그인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleKakaoLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithKakao();

      if (mounted) {
        // Set flag to indicate user just logged in
        // Router redirect will handle navigation
        ref.read(appStateProvider.notifier).setJustLoggedIn(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('UnimplementedError')
                  ? '카카오 로그인은 백엔드 서버 구축 후 사용할 수 있습니다'
                  : '카카오 로그인 실패: $e',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 상단 영역 - 로고, 타이틀, 서브타이틀
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 180),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 앱 로고
                    Hero(
                      tag: 'app_logo',
                      flightShuttleBuilder: logoFlightShuttleBuilder,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF8080), Color(0xFFDA4444)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Image.asset('assets/logo.png', width: 80),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 메인 타이틀
                    const Text(
                      '딸꾹 DDALKKUK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEA6B6B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 서브타이틀
                    Text(
                      '나만의 HIP한 알콜 트래커',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 영역 - 로그인 버튼들
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kakao Login Button
                    _buildAnimatedButton(
                      animation: _kakaoButtonFade,
                      child: KakaoLoginButton(
                        onPressed: _handleKakaoLogin,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Google Login Button
                    _buildAnimatedButton(
                      animation: _googleButtonFade,
                      child: GoogleLoginButton(
                        onPressed: _handleGoogleLogin,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Apple Login Button
                    _buildAnimatedButton(
                      animation: _appleButtonFade,
                      child: AppleLoginButton(
                        onPressed: _handleAppleLogin,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 96),

                    // Terms and Privacy Policy
                    Text(
                      '로그인하면 서비스 이용약관 및\n개인정보 처리방침에 동의하게 됩니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
