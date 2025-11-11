import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:ddalgguk/firebase_options.dart';

import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // Note: You need to add google-services.json (Android) and GoogleService-Info.plist (iOS)
  // and run `flutterfire configure` to generate firebase_options.dart
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

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: DdalggukApp(),
    ),
  );
}

class DdalggukApp extends ConsumerWidget {
  const DdalggukApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ddalgguk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
