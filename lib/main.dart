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
import 'package:sentry_flutter/sentry_flutter.dart';

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
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://05bb15ae811c9fdd9c4c66ced66bef9e@o4511399383400448.ingest.us.sentry.io/4511399384580096';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const ProviderScope(child: DdalggukApp()))),
  );
  // TODO: Remove this line after sending the first sample event to sentry.
  await Sentry.captureException(StateError('This is a sample exception.'));
}

class DdalggukApp extends ConsumerStatefulWidget {
  const DdalggukApp({super.key});

  @override
  ConsumerState<DdalggukApp> createState() => _DdalggukAppState();
}

class _DdalggukAppState extends ConsumerState<DdalggukApp> {
  @override
  void initState() {
    super.initState();
    _initHomeWidgetLinks();
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
