import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/auth/splash_screen.dart';
import 'package:ddalgguk/features/auth/login_screen.dart';
import 'package:ddalgguk/features/onboarding/onboarding_profile_screen.dart';
import 'package:ddalgguk/core/navigation/main_navigation.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';

/// Route names
class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String profileSetup = '/auth/onboarding';
  static const String home = '/';
}

/// 스플래시 최소 표시 시간 (필요시 400~800ms 내에서 조절)
const Duration kSplashMinDisplay = Duration(milliseconds: 900);

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  // ❌ Do NOT watch authStateProvider here. It causes the entire GoRouter to rebuild
  // on every auth change, resetting the navigation stack and showing the splash screen.
  // final authState = ref.watch(authStateProvider);

  // 라우터 생성 시점을 기록 → 스플래시 최소 표시 시간 계산에 사용
  final routerBootTime = DateTime.now();

  // redirect 재평가를 트리거할 수 있는 리스너
  final notifier = _RouterNotifier();

  // Auth state 변경 감지 (로딩, 데이터, 에러 등 모든 상태 변화 시 알림)
  ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, __) {
    notifier.notify();
  });

  // 비인증 최초 진입 시 스플래시를 잠깐이라도 보여주기 위한 타이머
  final timer = Timer(kSplashMinDisplay, () {
    notifier.notify();
  });

  ref.onDispose(() {
    timer.cancel();
    notifier.dispose();
  });

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final current = state.matchedLocation;

      // 0) auth provider가 아직 로딩이면 그대로 두고 그려지게 함
      // 0) Get current auth state using ref.read (since we are not watching anymore)
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      if (isLoading) {
        return null;
      }

      // 1) 인증 여부 및 사용자 정보
      // Always get fresh data from cache to catch updates
      final appUser = authState.valueOrNull;
      final isAuthed = appUser != null;

      // 1.5) If authenticated but profile setup seems incomplete, force check cache
      // This handles the case where Firestore was updated but stream didn't emit
      // and prevents redirect loops (Home -> Profile -> Home -> ...)
      if (isAuthed && !appUser.hasCompletedProfileSetup) {
        final authRepo = ref.read(authRepositoryProvider);
        final cachedUser = await authRepo.getCurrentUser();

        // If cache has newer info (completed setup), invalidate provider to propagate changes
        if (cachedUser != null && cachedUser.hasCompletedProfileSetup) {
          // Force refresh of authStateProvider to update UI with fresh data
          ref.invalidate(authStateProvider);
          // Return null to wait for the provider to update and trigger redirect again
          return null;
        }
      }

      // 2) 현재 스플래시라면 분기
      if (current == Routes.splash) {
        // ✅ 인증 여부와 관계없이 스플래시 최소 표시 시간 보장
        final now = DateTime.now();
        final bootElapsed = now.difference(routerBootTime);
        // 로그아웃으로 인해 스플래시로 왔다면 로그아웃 시간 기준 체크
        final logoutElapsed = notifier.logoutTime != null
            ? now.difference(notifier.logoutTime!)
            : const Duration(days: 999);

        final shouldWait =
            bootElapsed < kSplashMinDisplay ||
            logoutElapsed < kSplashMinDisplay;

        if (shouldWait) {
          // 아직은 스플래시에 머문다
          return null;
        }

        if (!isAuthed) {
          // 표시 시간이 지났으면 로그인으로 이동
          return Routes.login;
        } else {
          // ✅ 인증됐다면 애니메이션 없이 바로 목적지
          final done = appUser.hasCompletedProfileSetup;
          return done ? Routes.home : Routes.profileSetup;
        }
      }

      // 3) 스플래시 외 경로
      if (!isAuthed) {
        // 로그아웃 발생 시 (비인증 상태인데 로그인/스플래시 화면이 아님)
        // 스플래시 화면을 거쳐서 로그인으로 이동하도록 함
        if (current != Routes.login) {
          notifier.logoutTime = DateTime.now();
          // 스플래시 표시 시간 후 리프레시 트리거
          Timer(kSplashMinDisplay, () => notifier.notify());
          return Routes.splash;
        }
        return null; // 이미 로그인 화면이면 유지
      }

      // 인증된 상태 → 프로필 설정 여부로 분기
      final done = appUser.hasCompletedProfileSetup;
      if (done) {
        return current == Routes.home ? null : Routes.home;
      } else {
        return current == Routes.profileSetup ? null : Routes.profileSetup;
      }
    },
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 스플래시 → 로그인: 원형 리빌 전환(플랫폼 공통)
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(animate: true),
            transitionDuration: const Duration(milliseconds: 1200),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return HeroControllerScope(
                    controller: HeroController(
                      createRectTween: (begin, end) =>
                          MaterialRectArcTween(begin: begin, end: end),
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
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingProfileScreen(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Slide from Right to Left
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),

      // 메인은 애니메이션 없이 즉시 진입
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const MainNavigation(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Slide from Right to Left
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),
    ],
  );
});

/// Simple ChangeNotifier for Router refresh
class _RouterNotifier extends ChangeNotifier {
  DateTime? logoutTime;
  void notify() => notifyListeners();
}

/// Circular reveal transition for splash → login
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
    final center = Offset(size.width / 2, size.height * 0.35);

    // 화면 전체를 덮는 최대 반경
    final maxRadius = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
          math.pow(math.max(center.dy, size.height - center.dy), 2),
    );

    // 1200ms 중 200~800ms 구간에서 리빌
    final reveal = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.16, 0.67, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            ClipPath(
              clipper: _CircularRevealClipper(
                fraction: 1 - reveal.value,
                center: center,
                minRadius: 0,
                maxRadius: maxRadius,
              ),
              child: Container(color: const Color(0xFFEA6B6B)),
            ),
          ],
        );
      },
    );
  }
}

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
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircularRevealClipper old) {
    return old.fraction != fraction ||
        old.center != center ||
        old.minRadius != minRadius ||
        old.maxRadius != maxRadius;
  }
}
