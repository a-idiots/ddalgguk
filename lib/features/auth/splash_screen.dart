import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/app_state_provider.dart';

/// Splash screen that displays the app branding before transitioning to login or home
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-transition to login or home after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startTransition();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 120),

              // Top text: "더 즐겁게, 더 건강하게 —"
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  '더 즐겁게,\n더 건강하게 —',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFFEA6B6B),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // Center logo
              Image.asset('assets/logo/v1_1_logo.png', width: 180, height: 180),

              const SizedBox(height: 60),

              // Subtitle: "나만의 HIP한 알콜 트래커"
              const Text(
                '나만의 HIP한 알콜 트래커',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFEA6B6B),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 16),

              // App name: "딸꾹"
              const Text(
                'DDALGGUK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  color: Color(0xFFEA6B6B),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const Spacer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _startTransition() {
    // Mark splash animation as completed
    // Router's redirect logic will handle navigation
    ref.read(appStateProvider.notifier).setSplashAnimationCompleted();
  }
}
