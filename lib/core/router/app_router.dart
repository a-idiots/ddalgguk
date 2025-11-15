import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';
import 'package:ddalgguk/features/auth/login_screen.dart';
import 'package:ddalgguk/features/auth/onboarding/onboarding_profile_screen.dart';
import 'package:ddalgguk/core/navigation/main_navigation.dart';

/// Route names
class Routes {
  static const String login = '/login';
  static const String profileSetup = '/auth/onboarding';
  static const String home = '/';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.home,
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

      final isOnLoginPage = currentLocation == Routes.login;
      final isOnProfileSetupPage = currentLocation == Routes.profileSetup;

      // Redirect logic
      // 1. If not authenticated, go to login
      if (!isAuthenticated && !isOnLoginPage) {
        debugPrint('Router: Redirecting to login (not authenticated)');
        return Routes.login;
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
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
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
