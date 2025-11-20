import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';
import 'package:ddalgguk/features/auth/splash_screen.dart';
import 'package:ddalgguk/features/auth/login_screen.dart';
import 'package:ddalgguk/features/auth/widgets/onboarding/onboarding_profile_screen.dart';
import 'package:ddalgguk/core/navigation/main_navigation.dart';

/// Route names
class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String profileSetup = '/auth/onboarding';
  static const String home = '/';
}

/// 스플래시 최소 표시 시간 (필요시 400~800ms 내에서 조절)
const Duration kSplashMinDisplay = Duration(milliseconds: 600);

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // 라우터 생성 시점을 기록 → 스플래시 최소 표시 시간 계산에 사용
  final routerBootTime = DateTime.now();

  // 인증된 경우에만 프로필 설정 완료 여부 확인
  Future<bool> hasCompletedProfileSetup() async {
    try {
      final cachedUser = await SecureStorageService.instance.getUserCache();
      if (cachedUser != null) {
        return cachedUser.hasCompletedProfileSetup;
      }

      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = await authRepository.getCurrentUser();
      return currentUser?.hasCompletedProfileSetup ?? false;
    } catch (_) {
      return false; // 오류시 미완료로 간주
    }
  }

  // redirect 재평가를 트리거할 수 있는 리스너(아래 클래스 참고)
  final refresh = GoRouterRefreshStream(
    ref.read(firebaseAuthProvider).authStateChanges(),
    // 비인증 최초 진입 시 스플래시를 잠깐이라도 보여주기 위해
    initialKickDelay: kSplashMinDisplay,
  );

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,

    redirect: (context, state) async {
      final current = state.matchedLocation;

      // 0) auth provider가 아직 로딩이면 그대로 두고 그려지게 함
      final isLoading = authState.maybeWhen(
        loading: () => true,
        orElse: () => false,
      );
      if (isLoading) {
        return null;
      }

      // 1) 인증 여부
      final isAuthed = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      // 2) 현재 스플래시라면 분기
      if (current == Routes.splash) {
        if (!isAuthed) {
          // ✅ 비인증이면 스플래시 최소 표시 시간 보장
          final elapsed = DateTime.now().difference(routerBootTime);
          if (elapsed < kSplashMinDisplay) {
            // 아직은 스플래시에 머문다(안드로이드에서도 확실히 한 프레임 이상 노출)
            return null;
          }
          // 표시 시간이 지났으면 로그인으로 이동(아래 /login 전환 애니메이션 적용)
          return Routes.login;
        } else {
          // ✅ 인증됐다면 애니메이션 없이 바로 목적지
          final done = await hasCompletedProfileSetup();
          return done ? Routes.home : Routes.profileSetup;
        }
      }

      // 3) 스플래시 외 경로
      if (!isAuthed) {
        // 비인증 상태에서는 /login에만 머문다
        return current == Routes.login ? null : Routes.login;
      }

      // 인증된 상태 → 프로필 설정 여부로 분기
      final done = await hasCompletedProfileSetup();
      if (done) {
        return current == Routes.home ? null : Routes.home;
      } else {
        return current == Routes.profileSetup ? null : Routes.profileSetup;
      }
    },

    refreshListenable: refresh,

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
        builder: (context, state) => const OnboardingProfileScreen(),
      ),

      // 메인은 애니메이션 없이 즉시 진입
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MainNavigation()),
      ),
    ],
  );
});

/// Helper class to make GoRouter refresh when things change
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream, {Duration? initialKickDelay}) {
    // 인증 상태 변경 시 즉시 리프레시
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );

    // 최초 한 번, 스플래시 최소 표시 시간 이후 리프레시(비인증 진입용)
    if (initialKickDelay != null) {
      _kickTimer = Timer(initialKickDelay, () => notifyListeners());
    }
  }

  late final StreamSubscription<dynamic> _subscription;
  Timer? _kickTimer;

  @override
  void dispose() {
    _subscription.cancel();
    _kickTimer?.cancel();
    super.dispose();
  }
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
