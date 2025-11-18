import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/presentation/profile_detail_screen.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/gradient_background.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/scroll_indicator.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  double _dragDistance = 0;
  bool _isDragging = false;

  void _handleVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragDistance = 0;
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only track upward drag (negative delta.dy)
      if (details.delta.dy < 0) {
        _dragDistance += details.delta.dy.abs();
      } else {
        // Reset if dragging down
        _dragDistance = (_dragDistance + details.delta.dy).clamp(0.0, double.infinity);
      }
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragDistance > 50) {
      // Navigate to detail screen with slide transition
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileDetailScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }

    setState(() {
      _isDragging = false;
      _dragDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in')),
          );
        }

        return currentStatsAsync.when(
          data: (stats) {
            final drunkLevel = stats.currentDrunkLevel;
            final screenHeight = MediaQuery.of(context).size.height;
            final dragOffset = _isDragging ? -_dragDistance.clamp(0.0, screenHeight * 0.3) : 0.0;

            return Scaffold(
              body: GestureDetector(
                onVerticalDragStart: _handleVerticalDragStart,
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _handleVerticalDragEnd,
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const ProfileDetailScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        final offsetAnimation = animation.drive(tween);
                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, dragOffset, 0),
                  child: ProfileGradientBackground(
                    drunkLevel: drunkLevel,
                    child: SafeArea(
                      child: Stack(
                        children: [
                          // Main content
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(flex: 2),
                                // User info and status at top
                                Column(
                                  children: [
                                    Text(
                                      user.name ?? user.displayName ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '@${user.id ?? 'username'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Drunk level percentage
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$drunkLevel%',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                // Saku character image
                                Image.asset(
                                  getBodyImagePath(drunkLevel),
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback to basic saku if gradient version not found
                                    return Image.asset(
                                      'assets/saku/body.png',
                                      height: 200,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                                const Spacer(flex: 2),
                                // Status message
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    stats.statusMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          // Scroll indicator at bottom
                          const Positioned(
                            bottom: 40,
                            left: 0,
                            right: 0,
                            child: AnimatedScrollIndicator(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => Scaffold(
            body: ProfileGradientBackground(
              drunkLevel: 0,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
          error: (error, stack) => Scaffold(
            body: ProfileGradientBackground(
              drunkLevel: 0,
              child: Center(
                child: Text(
                  'Error loading stats',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
