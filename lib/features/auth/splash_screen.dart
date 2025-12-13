import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/auth/widgets/animated_login_transition.dart';
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
      backgroundColor: const Color(0xFFEA6B6B), // Pink background
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
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // Center logo
              Hero(
                tag: 'app_logo',
                flightShuttleBuilder: logoFlightShuttleBuilder,
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(90),
                    child: Center(
                      child: Image.asset('assets/imgs/logo.png', width: 140),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Subtitle: "나만의 HIP한 알콜 트래커"
              const Text(
                '나만의 HIP한 알콜 트래커',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 16),

              // App name: "딸꾹"
              const Text(
                '딸꾹',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
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
