import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/presentation/analytics_screen.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/detail_screen/profile_header.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/weekly_saku_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/achievements_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/alcohol_breakdown_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/report_card_section.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({
    super.key,
    this.onBack,
    this.onNavigateToAnalytics,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNavigateToAnalytics;

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderExpanded = true;
  double _overscrollDistance = 0;

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
    final isExpanded = _scrollController.hasClients && _scrollController.offset < 50;
    if (_isHeaderExpanded != isExpanded) {
      setState(() {
        _isHeaderExpanded = isExpanded;
      });
    }
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
          Navigator.of(context).pop();
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
    final achievementsAsync = ref.watch(achievementsProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in')),
          );
        }

        return currentStatsAsync.when(
          data: (currentStats) {
            return Scaffold(
              backgroundColor: Colors.grey[50],
              body: SafeArea(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                          drunkLevel: currentStats.thisMonthDrunkDays,
                          isExpanded: _isHeaderExpanded,
                        ),
                        automaticallyImplyLeading: false,
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
                              if (widget.onNavigateToAnalytics != null) {
                                widget.onNavigateToAnalytics!();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AnalyticsScreen(),
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
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Text('Error loading profile: $error'),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
