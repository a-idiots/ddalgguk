import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/features/auth/data/services/firebase_auth_service.dart';
import 'package:ddalgguk/features/auth/data/services/google_auth_service.dart';
import 'package:ddalgguk/features/auth/data/services/apple_auth_service.dart';
import 'package:ddalgguk/features/auth/data/services/kakao_auth_service.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/shared/services/secure_storage_service.dart';

/// Authentication Repository
/// Central hub for all authentication operations
class AuthRepository {
  AuthRepository({
    FirebaseAuthService? firebaseAuthService,
    GoogleAuthService? googleAuthService,
    AppleAuthService? appleAuthService,
    KakaoAuthService? kakaoAuthService,
    FirebaseFirestore? firestore,
    SecureStorageService? storageService,
  })  : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
        _googleAuthService = googleAuthService ?? GoogleAuthService(),
        _appleAuthService = appleAuthService ?? AppleAuthService(),
        _kakaoAuthService = kakaoAuthService ?? KakaoAuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? SecureStorageService.instance;

  final FirebaseAuthService _firebaseAuthService;
  final GoogleAuthService _googleAuthService;
  final AppleAuthService _appleAuthService;
  final KakaoAuthService _kakaoAuthService;
  final FirebaseFirestore _firestore;
  final SecureStorageService _storageService;

  // Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Sign in with Google
  Future<AppUser> signInWithGoogle() async {
    try {
      // Get Google credential
      final credential = await _googleAuthService.signInWithGoogle();

      // Sign in to Firebase
      final userCredential =
          await _firebaseAuthService.signInWithCredential(credential);

      // Create AppUser
      final appUser = AppUser.fromFirebaseUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        displayName: userCredential.user!.displayName,
        photoURL: userCredential.user!.photoURL,
        provider: LoginProvider.google,
      );

      // Save to Firestore
      await _saveUserToFirestore(appUser);

      // Save token and provider to secure storage
      await _saveAuthData(appUser, LoginProvider.google);

      return appUser;
    } catch (e) {
      debugPrint('Sign in with Google error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<AppUser> signInWithApple() async {
    try {
      // Get Apple credential
      final credential = await _appleAuthService.signInWithApple();

      // Sign in to Firebase
      final userCredential =
          await _firebaseAuthService.signInWithCredential(credential);

      // Create AppUser
      final appUser = AppUser.fromFirebaseUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        displayName: userCredential.user!.displayName,
        photoURL: userCredential.user!.photoURL,
        provider: LoginProvider.apple,
      );

      // Save to Firestore
      await _saveUserToFirestore(appUser);

      // Save token and provider to secure storage
      await _saveAuthData(appUser, LoginProvider.apple);

      return appUser;
    } catch (e) {
      debugPrint('Sign in with Apple error: $e');
      rethrow;
    }
  }

  /// Sign in with Kakao
  /// NOTE: This is a skeleton implementation
  /// Requires backend server to exchange Kakao token for Firebase custom token
  Future<AppUser> signInWithKakao() async {
    throw UnimplementedError(
      'Kakao login requires a backend server to exchange tokens. '
      'Please implement the backend endpoint first. '
      'See kakao_auth_service.dart for details.',
    );

    // TODO: Implement after setting up backend
    // try {
    //   // Get Kakao access token
    //   final kakaoAccessToken = await _kakaoAuthService.signInWithKakao();
    //
    //   // Exchange for Firebase custom token (requires backend)
    //   // final firebaseCustomToken = await _exchangeKakaoTokenForFirebaseToken(kakaoAccessToken);
    //
    //   // Sign in to Firebase with custom token
    //   // final userCredential = await _firebaseAuthService.signInWithCustomToken(firebaseCustomToken);
    //
    //   // Create AppUser
    //   // final appUser = AppUser.fromFirebaseUser(...);
    //
    //   // Save to Firestore
    //   // await _saveUserToFirestore(appUser);
    //
    //   // Save token and provider to secure storage
    //   // await _saveAuthData(appUser, LoginProvider.kakao);
    //
    //   // return appUser;
    // } catch (e) {
    //   debugPrint('Sign in with Kakao error: $e');
    //   rethrow;
    // }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Get the last login provider
      final lastProvider = await _storageService.getLastLoginProvider();

      // Sign out from the provider
      switch (lastProvider) {
        case LoginProvider.google:
          await _googleAuthService.signOut();
        case LoginProvider.apple:
          // Apple doesn't have a separate sign out
          break;
        case LoginProvider.kakao:
          await _kakaoAuthService.signOut();
        case null:
          break;
      }

      // Sign out from Firebase
      await _firebaseAuthService.signOut();

      // Clear secure storage
      await _storageService.deleteAllSecureData();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Get current user from Firestore
  Future<AppUser?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuthService.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        return null;
      }

      return AppUser.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  /// Save user to Firestore
  Future<void> _saveUserToFirestore(AppUser user) async {
    try {
      await _usersCollection.doc(user.uid).set(
            user.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Save user to Firestore error: $e');
      rethrow;
    }
  }

  /// Save authentication data to secure storage
  Future<void> _saveAuthData(AppUser user, LoginProvider provider) async {
    try {
      // Get Firebase ID token
      final idToken = await _firebaseAuthService.getIdToken();
      if (idToken != null) {
        await _storageService.saveFirebaseIdToken(idToken);
      }

      // Save user ID
      await _storageService.saveUserId(user.uid);

      // Save last login provider
      await _storageService.saveLastLoginProvider(provider);
    } catch (e) {
      debugPrint('Save auth data error: $e');
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final uid = _firebaseAuthService.userId;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (photoURL != null) {
        updates['photoURL'] = photoURL;
      }

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
      }
    } catch (e) {
      debugPrint('Update user profile error: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final uid = _firebaseAuthService.userId;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Delete from Firestore
      await _usersCollection.doc(uid).delete();

      // Delete Firebase Auth account
      await _firebaseAuthService.deleteAccount();

      // Clear secure storage
      await _storageService.deleteAllSecureData();
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuthService.isSignedIn;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges =>
      _firebaseAuthService.authStateChanges;
}
