import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/auth/data/repositories/auth_repository.dart';

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// StreamProvider for auth state changes
/// Returns the Firebase User when authenticated, null when not authenticated
final authStateProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges();
});

/// Provider for current AppUser
/// Returns AppUser when authenticated, null when not authenticated
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return null;
      }

      // Note: We don't have the provider info here yet
      // This will be enhanced when we implement the full auth flow
      // For now, we'll return null until the auth repository is implemented
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
