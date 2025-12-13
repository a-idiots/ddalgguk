import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/calendar/calendar_screen.dart';
import 'package:ddalgguk/features/profile/profile_screen.dart';
import 'package:ddalgguk/features/social/social_screen.dart';
import 'package:ddalgguk/features/report/report_screen.dart';
import 'package:ddalgguk/features/settings/settings_screen.dart';
import 'package:ddalgguk/shared/widgets/app_bottom_nav_bar.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';

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

  @override
  Widget build(BuildContext context) {
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
