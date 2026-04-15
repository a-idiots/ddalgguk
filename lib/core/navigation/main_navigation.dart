import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/calendar/calendar_screen.dart';
import 'package:ddalgguk/features/profile/profile_screen.dart';
import 'package:ddalgguk/features/social/social_screen.dart';
import 'package:ddalgguk/features/report/report_screen.dart';
import 'package:ddalgguk/features/settings/settings_screen.dart';
import 'package:ddalgguk/shared/widgets/app_bottom_nav_bar.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/data/providers/widget_deeplink_provider.dart';
import 'package:ddalgguk/features/profile/screens/goal_detail_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 2;

  final List<Widget> _screens = const [
    ProfileScreen(),
    SocialScreen(),
    CalendarScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleGoalDeepLink() {
    // Switch to profile tab then push the goal detail screen on top.
    setState(() {
      _currentIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GoalDetailScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle pending widget deep-links (e.g. tap on home-screen goal widget).
    ref.listen<String?>(widgetDeepLinkProvider, (_, next) {
      if (next == 'goal') {
        // Reset first so the same tap doesn't fire twice on rebuild.
        ref.read(widgetDeepLinkProvider.notifier).state = null;
        _handleGoalDeepLink();
      }
    });

    // Calculate background color for navigation bar
    Color? navBackgroundColor;
    if (_currentIndex == 0) {
      final bottomColor = ref.watch(profileBottomColorProvider);
      navBackgroundColor = bottomColor;
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: navBackgroundColor,
      ),
    );
  }
}
