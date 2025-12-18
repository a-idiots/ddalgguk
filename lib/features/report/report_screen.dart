import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/report/widgets/tabs/alcohol_intake_tab.dart';
import 'package:ddalgguk/features/report/widgets/tabs/recap_tab.dart';
import 'package:ddalgguk/features/report/widgets/tabs/spending_tab.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:go_router/go_router.dart';
import 'package:ddalgguk/core/services/analytics_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Log initial tab view
    AnalyticsService.instance.logViewReportTab('alcohol');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final index = _tabController.index;
      String tabName = 'unknown';
      switch (index) {
        case 0:
          tabName = 'alcohol';
          break;
        case 1:
          tabName = 'spending';
          break;
        case 2:
          tabName = 'recap';
          break;
      }
      AnalyticsService.instance.logViewReportTab(tabName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return currentStatsAsync.when(
          data: (currentStats) {
            return PopScope(
              canPop: widget.onBack == null,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  return;
                }
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Fallback if we can't pop (e.g. deep link entry)
                    context.go('/profile');
                  }
                }
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: TabPageHeader(
                  title: 'Analytics',
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(40),
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 60,
                        right: 60,
                        top: 0,
                        bottom: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(height: 28, text: '알콜섭취량'),
                          Tab(height: 28, text: '소비 금액'),
                          Tab(height: 28, text: '레포트'),
                        ],
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: const [
                    AlcoholIntakeTab(),
                    SpendingTab(),
                    RecapTab(),
                  ],
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
