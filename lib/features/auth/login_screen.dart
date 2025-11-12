import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/features/auth/widgets/google_login_button.dart';
import 'package:ddalgguk/features/auth/widgets/apple_login_button.dart';
import 'package:ddalgguk/features/auth/widgets/kakao_login_button.dart';

/// Login Screen with social login options
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isKakaoLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithGoogle();

      if (mounted) {
        // Navigation will be handled automatically by go_router redirect
        context.go(Routes.home);
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
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isAppleLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithApple();

      if (mounted) {
        // Navigation will be handled automatically by go_router redirect
        context.go(Routes.home);
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
          _isAppleLoading = false;
        });
      }
    }
  }

  Future<void> _handleKakaoLogin() async {
    setState(() {
      _isKakaoLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithKakao();

      if (mounted) {
        // Navigation will be handled automatically by go_router redirect
        context.go(Routes.home);
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
          _isKakaoLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Icon
              const Icon(
                Icons.local_drink,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),

              // App Title
              const Text(
                '딸꾹!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                '음주 관리를 시작해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 64),

              // Google Login Button
              GoogleLoginButton(
                onPressed: _handleGoogleLogin,
                isLoading: _isGoogleLoading,
              ),
              const SizedBox(height: 16),

              // Apple Login Button
              AppleLoginButton(
                onPressed: _handleAppleLogin,
                isLoading: _isAppleLoading,
              ),
              const SizedBox(height: 16),

              // Kakao Login Button
              KakaoLoginButton(
                onPressed: _handleKakaoLogin,
                isLoading: _isKakaoLoading,
              ),
              const SizedBox(height: 32),

              // Terms and Privacy Policy
              Text(
                '로그인하면 서비스 이용약관 및\n개인정보 처리방침에 동의하게 됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
