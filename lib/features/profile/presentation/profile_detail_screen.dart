import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/presentation/analytics_screen.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/profile_header.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/weekly_saku_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/achievements_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/report_card_section.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check scroll position to determine if header should be expanded
    final isExpanded = _scrollController.hasClients && _scrollController.offset < 50;
    if (_isHeaderExpanded != isExpanded) {
      setState(() {
        _isHeaderExpanded = isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in'));
          }

          return currentStatsAsync.when(
            data: (currentStats) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Sticky Header
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    expandedHeight: 100,
                    collapsedHeight: 70,
                    flexibleSpace: ProfileHeader(
                      user: user,
                      drunkLevel: currentStats.currentDrunkLevel,
                      isExpanded: _isHeaderExpanded,
                    ),
                    automaticallyImplyLeading: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Content
                  SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      // Section 2-1: Weekly Saku
                      weeklyStatsAsync.when(
                        data: (weeklyStats) => WeeklySakuSection(
                          weeklyStats: weeklyStats,
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
                      achievementsAsync.when(
                        data: (achievements) => AchievementsSection(
                          achievements: achievements,
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
                      // Section 2-3: Alcohol Breakdown
                      AlcoholBreakdownSection(
                        stats: currentStats,
                      ),
                      const SizedBox(height: 8),
                      // Section 2-4: Report Card
                      ReportCardSection(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading profile: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
