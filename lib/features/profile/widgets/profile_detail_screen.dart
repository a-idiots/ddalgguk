import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/profile_header.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/weekly_saku_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/achievements_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/widgets/gradient_background.dart';

import 'package:ddalgguk/core/constants/app_colors.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({
    super.key,
    this.onNavigateToAnalytics,
    this.showCharacter = true,
    this.onBackToMain,
    required this.theme,
    required this.drunkLevel,
  });

  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onBackToMain;
  final bool showCharacter;
  final AppTheme theme;
  final int drunkLevel;

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    return currentUserAsync.when(
      skipLoadingOnReload: true,
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return currentStatsAsync.when(
          skipLoadingOnReload: true,
          data: (currentStats) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: ProfileGradientBackground(
                theme: widget.theme,
                reversed: true,
                child: SafeArea(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      return false;
                    },
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          ProfileHeader(
                            user: user,
                            theme: widget.theme,
                            showCharacter: widget.showCharacter,
                            drunkLevel: widget.drunkLevel,
                          ),
                          // Section 2-1: Weekly Saku
                          weeklyStatsAsync.when(
                            skipLoadingOnReload: true,
                            data: (weeklyStats) => WeeklySakuSection(
                              weeklyStats: weeklyStats,
                              theme: widget.theme,
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
                          AchievementsSection(theme: widget.theme),
                          const SizedBox(height: 8),
                          // Section 2-3: Alcohol Breakdown
                          AlcoholBreakdownSection(
                            stats: currentStats,
                            theme: widget.theme,
                            extraComment: true,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
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
