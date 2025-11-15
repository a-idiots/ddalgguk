import 'package:flutter/material.dart';
import 'package:ddalgguk/features/calendar/calendar_screen.dart';
import 'package:ddalgguk/features/profile/profile_screen.dart';
import 'package:ddalgguk/features/social/social_screen.dart';
import 'package:ddalgguk/features/games/games_screen.dart';
import 'package:ddalgguk/features/settings/settings_screen.dart';
import 'package:ddalgguk/shared/widgets/app_bottom_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2;

  final List<Widget> _screens = const [
    ProfileScreen(),
    SocialScreen(),
    CalendarScreen(),
    GamesScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
