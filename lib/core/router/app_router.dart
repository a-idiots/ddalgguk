import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';
import 'package:ddalgguk/features/auth/splash_screen.dart';
import 'package:ddalgguk/features/auth/login_screen.dart';
import 'package:ddalgguk/features/auth/onboarding/onboarding_profile_screen.dart';
import 'package:ddalgguk/core/navigation/main_navigation.dart';

/// Route names
class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String profileSetup = '/auth/onboarding';
  static const String home = '/';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final currentLocation = state.matchedLocation;
      debugPrint('=== Router Redirect: $currentLocation ===');

      // Wait for auth state to load - prevent redirect loop during loading
      final isLoading = authState.maybeWhen(
        loading: () => true,
        orElse: () => false,
      );

      if (isLoading) {
        debugPrint('Router: Auth state is loading, no redirect');
        return null;
      }

      // Check if user is authenticated with Firebase
      final isAuthenticated = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      debugPrint('Router: isAuthenticated = $isAuthenticated');

      final isOnSplashPage = currentLocation == Routes.splash;
      final isOnLoginPage = currentLocation == Routes.login;
      final isOnProfileSetupPage = currentLocation == Routes.profileSetup;

      // Redirect logic
      // 0. If authenticated and on splash page, skip to home/onboarding
      if (isAuthenticated && isOnSplashPage) {
        debugPrint('Router: Skipping splash (already authenticated)');
        return Routes.home; // Will be further redirected by logic below if needed
      }

      // 1. If not authenticated and not on splash or login, go to splash
      if (!isAuthenticated && !isOnLoginPage && !isOnSplashPage) {
        debugPrint('Router: Redirecting to splash (not authenticated)');
        return Routes.splash;
      }

      // Check if profile setup is completed (only if authenticated)
      bool hasCompletedProfileSetup = false;
      if (isAuthenticated) {
        debugPrint('Router: Checking profile setup');
        // Try to get from cache first for better performance
        final cachedUser = await SecureStorageService.instance.getUserCache();

        if (cachedUser != null) {
          hasCompletedProfileSetup = cachedUser.hasCompletedProfileSetup;
          debugPrint(
            'Router: Using cache - hasCompletedProfileSetup: $hasCompletedProfileSetup',
          );
        } else {
          debugPrint('Router: No cache, fetching from Firestore');
          // If no cache, try to get from Firestore
          // This ensures we always have the latest data after login
          try {
            final authRepository = ref.read(authRepositoryProvider);
            final currentUser = await authRepository.getCurrentUser();
            hasCompletedProfileSetup =
                currentUser?.hasCompletedProfileSetup ?? false;
            debugPrint(
              'Router: From Firestore - hasCompletedProfileSetup: $hasCompletedProfileSetup',
            );
          } catch (e) {
            debugPrint('Router: Error fetching user - $e');
            // If error, assume profile setup is not complete
            hasCompletedProfileSetup = false;
          }
        }
      }

      // 2. If authenticated but not completed profile setup, go to profile setup
      if (isAuthenticated &&
          !hasCompletedProfileSetup &&
          !isOnProfileSetupPage) {
        debugPrint('Router: Redirecting to profile setup (not completed)');
        return Routes.profileSetup;
      }

      // 3. If authenticated, completed profile, and on login page, go to home
      if (isAuthenticated && hasCompletedProfileSetup && isOnLoginPage) {
        debugPrint('Router: Redirecting to home from login (completed profile)');
        return Routes.home;
      }

      // 4. If authenticated, completed profile, and on profile setup page, go to home
      if (isAuthenticated && hasCompletedProfileSetup && isOnProfileSetupPage) {
        debugPrint('Router: Redirecting to home from profile setup (completed profile)');
        return Routes.home;
      }

      // No redirect needed
      debugPrint('Router: No redirect needed');
      debugPrint('======================================');
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      ref.read(firebaseAuthProvider).authStateChanges(),
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(animate: true),
            transitionDuration: const Duration(milliseconds: 1200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return HeroControllerScope(
                controller: HeroController(
                  // Custom create flight callback to synchronize with circular reveal
                  createRectTween: (begin, end) {
                    return MaterialRectArcTween(begin: begin, end: end);
                  },
                ),
                child: _CircularRevealTransition(
                  animation: animation,
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: Routes.profileSetup,
        name: 'profileSetup',
        builder: (context, state) => const OnboardingProfileScreen(),
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const MainNavigation(),
      ),
    ],
  );
});

/// Helper class to make GoRouter refresh when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Circular reveal transition for splash to login screen
class _CircularRevealTransition extends StatelessWidget {
  const _CircularRevealTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    // Center on login screen's Hero (logo) position
    // Logo is at: SafeArea top + 180px padding + 50px (half of 100px logo height)
    final center = Offset(size.width / 2, topPadding + 180 + 50);

    // Calculate max radius to cover entire screen from center point
    final maxRadius = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
      math.pow(math.max(center.dy, size.height - center.dy), 2),
    );

    // Circular reveal animation: 200-800ms (0.16 - 0.67 of total 1200ms)
    final revealAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.16, 0.67, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: revealAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // White background (login screen)
            child!,
            // Pink background with circular shrink (outside to inside)
            ClipPath(
              clipper: _CircularRevealClipper(
                fraction: 1 - revealAnimation.value, // Reverse the animation
                center: center,
                minRadius: 0,
                maxRadius: maxRadius,
              ),
              child: Container(
                color: const Color(0xFFEA6B6B),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Custom clipper for circular reveal effect
class _CircularRevealClipper extends CustomClipper<Path> {
  const _CircularRevealClipper({
    required this.fraction,
    required this.center,
    required this.minRadius,
    required this.maxRadius,
  });

  final double fraction;
  final Offset center;
  final double minRadius;
  final double maxRadius;

  @override
  Path getClip(Size size) {
    final radius = minRadius + (maxRadius - minRadius) * fraction;
    final path = Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );
    return path;
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction ||
        oldClipper.center != center ||
        oldClipper.minRadius != minRadius ||
        oldClipper.maxRadius != maxRadius;
  }
}
