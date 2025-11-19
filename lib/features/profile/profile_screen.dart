import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';

import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/presentation/profile_detail_screen.dart';
import 'package:ddalgguk/features/profile/presentation/analytics_screen.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/gradient_background.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/scroll_indicator.dart';

import 'package:ddalgguk/shared/widgets/saku_character.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileView { main, detail, analytics }

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _ProfileView _currentView = _ProfileView.main;
  double _dragDistance = 0;
  bool _isDragging = false;

  void _handleVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragDistance = 0;
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      return;
    }

    setState(() {
      // Only track upward drag (negative delta.dy)
      if (details.delta.dy < 0) {
        _dragDistance += details.delta.dy.abs();
      } else {
        _dragDistance = (_dragDistance - details.delta.dy).clamp(
          0.0,
          double.infinity,
        );
      }
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) {
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final threshold = screenHeight * 0.2;
    final velocity = details.velocity.pixelsPerSecond.dy;

    // Check if should navigate to detail screen
    final shouldNavigate = _dragDistance > threshold || velocity < -500;

    if (shouldNavigate) {
      setState(() {
        _currentView = _ProfileView.detail;
      });
    }

    setState(() {
      _isDragging = false;
      _dragDistance = 0;
    });
  }

  void _handleBackToMain() {
    setState(() {
      _currentView = _ProfileView.main;
    });
  }

  void _handleNavigateToAnalytics() {
    setState(() {
      _currentView = _ProfileView.analytics;
    });
  }

  void _handleBackToDetail() {
    setState(() {
      _currentView = _ProfileView.detail;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show different views based on current state
    switch (_currentView) {
      case _ProfileView.detail:
        return ProfileDetailScreen(
          onBack: _handleBackToMain,
          onNavigateToAnalytics: _handleNavigateToAnalytics,
        );
      case _ProfileView.analytics:
        return AnalyticsScreen(onBack: _handleBackToDetail);
      case _ProfileView.main:
        break;
    }

    // Main profile view
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return currentStatsAsync.when(
          data: (stats) {
            final thisMonthDrunkDays = stats.thisMonthDrunkDays;
            final theme = AppColors.getTheme(thisMonthDrunkDays);

            return GestureDetector(
              onVerticalDragStart: _handleVerticalDragStart,
              onVerticalDragUpdate: _handleVerticalDragUpdate,
              onVerticalDragEnd: _handleVerticalDragEnd,
              child: ProfileGradientBackground(
                theme: theme,
                child: SafeArea(
                  child: Stack(
                    children: [
                      // Main content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 1),
                            // User info and status at top
                            Column(
                              children: [
                                Text(
                                  user.name ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(text: '이번 달 '),
                                      if (thisMonthDrunkDays == 0) ...[
                                        TextSpan(
                                          text: '$thisMonthDrunkDays일째',
                                          style: TextStyle(
                                            color: theme.secondaryColor,
                                          ),
                                        ),
                                        const TextSpan(text: ' 금주 중이네요!'),
                                      ] else ...[
                                        TextSpan(
                                          text: '$thisMonthDrunkDays번째',
                                          style: TextStyle(
                                            color: theme.secondaryColor,
                                          ),
                                        ),
                                        const TextSpan(text: ' 음주네요!'),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(flex: 1),
                            // Saku character image
                            SakuCharacter(size: 150),

                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                      // Scroll indicator at bottom
                      const Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: AnimatedScrollIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => ProfileGradientBackground(
            theme: AppColors.getTheme(0),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (error, stack) => ProfileGradientBackground(
            theme: AppColors.getTheme(0),
            child: Center(
              child: Text(
                'Error loading stats',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
