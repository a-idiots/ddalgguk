import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/presentation/analytics_screen.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/detail_screen/profile_header.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/detail_screen/weekly_saku_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/detail_screen/achievements_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/detail_screen/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/detail_screen/report_card_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/gradient_background.dart';

import 'package:ddalgguk/core/constants/app_colors.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({
    super.key,
    this.onBack,
    this.onNavigateToAnalytics,
    this.showCharacter = true,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNavigateToAnalytics;
  final bool showCharacter;

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _overscrollDistance = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      // Only handle overscroll at the top (negative overscroll)
      if (notification.overscroll < 0) {
        setState(() {
          _overscrollDistance += notification.overscroll.abs();
        });
      }
    } else if (notification is ScrollEndNotification) {
      // Check if should navigate back
      final screenHeight = MediaQuery.of(context).size.height;
      final threshold = screenHeight * 0.15;

      if (_overscrollDistance > threshold) {
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          // If inside PageView, this might not be needed, but keeping for safety
          // Navigator.of(context).pop();
        }
      }

      setState(() {
        _overscrollDistance = 0;
      });
    } else if (notification is ScrollUpdateNotification) {
      // Reset if user starts scrolling down
      if (notification.scrollDelta != null && notification.scrollDelta! > 0) {
        setState(() {
          _overscrollDistance = 0;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return currentStatsAsync.when(
          data: (currentStats) {
            final theme = AppColors.getTheme(currentStats.thisMonthDrunkDays);

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: ProfileGradientBackground(
                theme: theme,
                reversed: true,
                child: SafeArea(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Header (scrollable, not sticky)
                        SliverToBoxAdapter(
                          child: ProfileHeader(
                            user: user,
                            theme: theme,
                            showCharacter: widget.showCharacter,
                          ),
                        ),
                        // Content
                        SliverList(
                          delegate: SliverChildListDelegate([
                            // Section 2-1: Weekly Saku
                            weeklyStatsAsync.when(
                              data: (weeklyStats) => WeeklySakuSection(
                                weeklyStats: weeklyStats,
                                theme: theme,
                              ),
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stack) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 8),
                            // Section 2-2: Achievements
                            // Section 2-2: Achievements
                            AchievementsSection(theme: theme),
                            const SizedBox(height: 8),
                            // Section 2-3: Alcohol Breakdown
                            AlcoholBreakdownSection(
                              stats: currentStats,
                              theme: theme,
                            ),
                            const SizedBox(height: 8),
                            // Section 2-4: Report Card
                            ReportCardSection(
                              theme: theme,
                              onTap: () {
                                if (widget.onNavigateToAnalytics != null) {
                                  widget.onNavigateToAnalytics!();
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AnalyticsScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 32),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Error loading profile: $error')),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
