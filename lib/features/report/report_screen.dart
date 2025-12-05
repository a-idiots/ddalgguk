import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/report/widgets/tabs/alcohol_intake_tab.dart';
import 'package:ddalgguk/features/report/widgets/tabs/recap_tab.dart';
import 'package:ddalgguk/features/report/widgets/tabs/spending_tab.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:go_router/go_router.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
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
              child: DefaultTabController(
                length: 3,
                child: Scaffold(
                  backgroundColor: Colors.white,
                  appBar: TabPageHeader(
                    title: 'Analytics',
                    fontSize: 24,
                    centerTitle: false,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(30),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TabBar(
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
                            Tab(height: 24, text: '알콜섭취량'),
                            Tab(height: 24, text: '소비 금액'),
                            Tab(height: 24, text: '레포트'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  body: const TabBarView(
                    children: [AlcoholIntakeTab(), SpendingTab(), RecapTab()],
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
