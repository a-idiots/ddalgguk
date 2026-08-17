import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_widget/home_widget.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:ddalgguk/firebase_options.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/core/services/iap_service.dart';
import 'package:ddalgguk/features/profile/data/providers/goal_widget_sync_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/monthly_calendar_widget_sync_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/weekly_widget_sync_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/widget_deeplink_provider.dart';
import 'package:ddalgguk/features/profile/data/services/goal_home_widget_service.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/core/services/notification_manager.dart';
import 'package:ddalgguk/core/services/friend_notification_service.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide Android bottom navigation bar (auto-hides after appearing)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Kakao SDK
  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue without Firebase for now (will be needed later)
  }

  // Initialize Secure Storage Service
  await SecureStorageService.instance.init();

  // Warm up custom drink + uploaded icon caches from SharedPreferences so
  // they're available before the first frame.
  await initializeDrinkHelper();

  // Initialize Notification Service FIRST (before FriendNotificationService)
  try {
    final notificationManager = NotificationManager();
    await notificationManager.initialize();

    // Request notification permissions
    final granted = await notificationManager.requestPermissions();
    debugPrint('Notification permissions granted: $granted');

    // Schedule notifications if permission is granted
    if (granted) {
      // Try to get cached user info for personalized notifications
      final cachedUser = await SecureStorageService.instance.getUserCache();
      await notificationManager.scheduleAllNotifications(
        userName: cachedUser?.name ?? '',
        weeklyDrinkingFrequency: cachedUser?.weeklyDrinkingFrequency,
      );
      debugPrint('Notifications scheduled successfully');
    }
  } catch (e) {
    debugPrint('Notification initialization error: $e');
    // Continue without notifications if initialization fails
  }

  // Initialize Friend Notification Service AFTER notification permissions
  try {
    final friendNotificationService = FriendNotificationService();
    await friendNotificationService.startListening();
    debugPrint('Friend Notification Service initialized successfully');
  } catch (e) {
    debugPrint('Friend Notification Service error: $e');
  }

  // Run the app with Riverpod
  runApp(const ProviderScope(child: DdalggukApp()));
}

class DdalggukApp extends ConsumerStatefulWidget {
  const DdalggukApp({super.key});

  @override
  ConsumerState<DdalggukApp> createState() => _DdalggukAppState();
}

class _DdalggukAppState extends ConsumerState<DdalggukApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initHomeWidgetLinks();

    // 결제 서비스는 앱 시작 시점에 반드시 살아 있어야 한다. purchaseStream을
    // 구독하는 순간 StoreKit의 트랜잭션 옵저버가 시작되므로, 이걸 결제 화면에서만
    // 켜면 앱이 꺼져 있는 동안 완료된 결제·갱신·가족 승인을 놓친다.
    ref.read(iapServiceProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    // 복귀할 때 권한을 다시 맞춘다. 구독이 만료됐거나 환불된 경우, 그리고 밀린
    // 영수증 검증이 있는 경우를 여기서 정리한다. 서버 쪽에 자체 캐시 창이 있어서
    // 매번 스토어를 두드리지는 않는다.
    final iap = ref.read(iapServiceProvider);
    unawaited(iap.retryPendingVerifications());
    unawaited(iap.syncWithStore());
  }

  Future<void> _initHomeWidgetLinks() async {
    await HomeWidget.setAppGroupId(GoalHomeWidgetService.appGroupId);
    // Cold-start: the app was launched by tapping the widget.
    final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleWidgetUri(initial);
    // Warm-start: app resumed from background via widget tap.
    HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) {
      return;
    }
    // ddalgguk://goal → 음주 목표 화면 열기
    if (uri.host == 'goal' || uri.path == '/goal') {
      ref.read(widgetDeepLinkProvider.notifier).state = 'goal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Keep the iOS home-screen widget in sync — fires automatically on any
    // goal / spending / alcohol change, regardless of which screen the user
    // is currently looking at.
    ref.watch(goalWidgetSyncProvider);
    ref.watch(weeklyWidgetSyncProvider);
    ref.watch(monthlyCalendarWidgetSyncProvider);

    return MaterialApp.router(
      title: 'Ddalgguk',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', ''), Locale('en', '')],
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black45,
        ),

        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPink,
          primary: AppColors.primaryPink,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.grey,
        ),
      ),
      routerConfig: router,
    );
  }
}
