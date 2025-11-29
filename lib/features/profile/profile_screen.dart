import 'dart:ui';

import 'package:ddalgguk/features/profile/widgets/profile_main_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/profile/widgets/profile_detail_screen.dart';
import 'package:ddalgguk/features/report/screens/report_screen.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final PageController _pageController = PageController();
  final GlobalKey _mainCharacterKey = GlobalKey();

  // Animation state
  double _currentPage = 0.0;
  bool _isAnalyticsVisible = false;

  // Layout state
  Offset? _mainCharacterPosition;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);

    // Calculate initial position after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMainCharacterPosition();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0.0;
    });
  }

  void _updateMainCharacterPosition() {
    final renderBox =
        _mainCharacterKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      // Adjust for SafeArea if needed, but localToGlobal gives screen coordinates
      // We need coordinates relative to the Stack (which is usually full screen here)
      setState(() {
        _mainCharacterPosition = position;
      });
    }
  }

  void _handleNavigateToAnalytics() {
    setState(() {
      _isAnalyticsVisible = true;
    });
  }

  void _handleBackFromAnalytics() {
    setState(() {
      _isAnalyticsVisible = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMainCharacterPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyticsVisible) {
      return ReportScreen(onBack: _handleBackFromAnalytics);
    }

    final currentStatsAsync = ref.watch(currentProfileStatsProvider);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Target position (Detail Screen)
    // Top: SafeArea + 16
    // Right: 28 -> Left: Width - 28 - 60
    final targetTop = padding.top + 16;
    final targetLeft = screenSize.width - 28 - 60;
    const targetSize = 60.0;

    // Start position (Main Screen)
    // Use calculated position or fallback to center
    // Fallback: Center vertically approx (45% down), Center horizontally
    final startTop = _mainCharacterPosition?.dy ?? (screenSize.height * 0.45);
    final startLeft = _mainCharacterPosition?.dx ?? (screenSize.width / 2 - 75);
    const startSize = 150.0;

    // Interpolate
    // We want the animation to happen as we scroll from page 0 to 1
    // _currentPage goes from 0.0 to 1.0
    final progress = _currentPage.clamp(0.0, 1.0);

    final currentTop = lerpDouble(startTop, targetTop, progress)!;
    final currentLeft = lerpDouble(startLeft, targetLeft, progress)!;
    final currentSize = lerpDouble(startSize, targetSize, progress)!;

    // Visibility logic
    // Show floating character when:
    // 1. We are scrolling (progress > 0 && progress < 1)
    // 2. OR we haven't calculated the main position yet (fallback)
    // 3. Actually, for smoothness, let's ALWAYS show floating character
    //    and hide the static ones in the pages.
    //    BUT, the static ones are part of the page layout (scrolling content).
    //    So, when settled at 0, show Main static. When settled at 1, show Detail static.
    //    When moving, show Floating.

    final showMainStatic = progress <= 0.01;
    final showDetailStatic = progress >= 0.99;
    final showFloating = !showMainStatic && !showDetailStatic;

    return Scaffold(
      body: Stack(
        children: [
          // PageView for vertical navigation
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(), // Or BouncingScrollPhysics
            children: [
              // Page 0: Main View
              ProfileMainView(
                showCharacter: showMainStatic,
                characterKey: _mainCharacterKey,
                opacity: (1.0 - progress).clamp(0.0, 1.0),
              ),
              // Page 1: Detail View
              ProfileDetailScreen(
                onBack: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                onNavigateToAnalytics: _handleNavigateToAnalytics,
                showCharacter: showDetailStatic,
              ),
            ],
          ),

          // Floating Character
          if (showFloating)
            Positioned(
              top: currentTop,
              left: currentLeft,
              width: currentSize,
              height: currentSize,
              child: IgnorePointer(
                child: currentStatsAsync.when(
                  data: (stats) => SakuCharacter(
                    size: currentSize,
                    drunkLevel: stats.todayDrunkLevel,
                  ),
                  loading: () => SakuCharacter(size: currentSize),
                  error: (_, __) => SakuCharacter(size: currentSize),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
