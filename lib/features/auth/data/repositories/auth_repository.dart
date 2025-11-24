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
  }) : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
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
      final userCredential = await _firebaseAuthService.signInWithCredential(
        credential,
      );

      final uid = userCredential.user!.uid;

      // Check if user already exists in Firestore
      debugPrint('=== Sign in with Google - checking Firestore ===');
      final doc = await _usersCollection.doc(uid).get();
      final AppUser appUser;

      if (doc.exists) {
        // Existing user - load from Firestore
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Firestore data: $data');
        appUser = AppUser.fromJson(data);
        debugPrint('Existing user:');
        debugPrint(
          '  - hasCompletedProfileSetup: ${appUser.hasCompletedProfileSetup}',
        );
        debugPrint('  - name: ${appUser.name}');
        debugPrint('  - id: ${appUser.id}');
      } else {
        // New user - create with basic info
        appUser = AppUser.fromFirebaseUser(
          uid: uid,
          photoURL: userCredential.user!.photoURL,
          provider: LoginProvider.google,
        );
        debugPrint(
          'New user created - hasCompletedProfileSetup: ${appUser.hasCompletedProfileSetup}',
        );

        // Save new user to Firestore
        await _saveUserToFirestore(appUser);
      }
      debugPrint('===============================================');

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
      final userCredential = await _firebaseAuthService.signInWithCredential(
        credential,
      );

      final uid = userCredential.user!.uid;

      // Check if user already exists in Firestore
      debugPrint('=== Sign in with Apple - checking Firestore ===');
      final doc = await _usersCollection.doc(uid).get();
      final AppUser appUser;

      if (doc.exists) {
        // Existing user - load from Firestore
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Firestore data: $data');
        appUser = AppUser.fromJson(data);
        debugPrint('Existing user:');
        debugPrint(
          '  - hasCompletedProfileSetup: ${appUser.hasCompletedProfileSetup}',
        );
        debugPrint('  - name: ${appUser.name}');
        debugPrint('  - id: ${appUser.id}');
      } else {
        // New user - create with basic info
        appUser = AppUser.fromFirebaseUser(
          uid: uid,
          photoURL: userCredential.user!.photoURL,
          provider: LoginProvider.apple,
        );
        debugPrint(
          'New user created - hasCompletedProfileSetup: ${appUser.hasCompletedProfileSetup}',
        );

        // Save new user to Firestore
        await _saveUserToFirestore(appUser);
      }
      debugPrint('===============================================');

      // Save token and provider to secure storage
      await _saveAuthData(appUser, LoginProvider.apple);

      return appUser;
    } catch (e) {
      debugPrint('Sign in with Apple error: $e');
      rethrow;
    }
  }

  /// Sign in with Kakao
  /// Exchanges Kakao token for Firebase custom token via Cloud Functions
  Future<AppUser> signInWithKakao() async {
    try {
      // Get Firebase custom token (Kakao token is exchanged internally)
      final firebaseCustomToken = await _kakaoAuthService.signInWithKakao();

      // Sign in to Firebase with custom token
      final userCredential = await _firebaseAuthService.signInWithCustomToken(
        firebaseCustomToken,
      );

      final uid = userCredential.user!.uid;

      // Get Kakao user info for profile data
      final kakaoUser = await _kakaoAuthService.getKakaoUser();

      // Check if user already exists in Firestore
      debugPrint('=== Sign in with Kakao - checking Firestore ===');
      final doc = await _usersCollection.doc(uid).get();
      final AppUser appUser;

      if (doc.exists) {
        // Existing user - load from Firestore
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Firestore data: $data');
        appUser = AppUser.fromJson(data);
        debugPrint('Existing user:');
        debugPrint(
          '  - hasCompletedProfileSetup: ${appUser.hasCompletedProfileSetup}',
        );
        debugPrint('  - name: ${appUser.name}');
        debugPrint('  - id: ${appUser.id}');
      } else {
        // New user - create with basic info from Kakao
        appUser = AppUser.fromFirebaseUser(
          uid: uid,
          photoURL: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          provider: LoginProvider.kakao,
        );
        debugPrint(
          'New user created - hasCompletedProfileSetup: ${appUser.hasCompletedProfileSetup}',
        );

        // Save new user to Firestore
        await _saveUserToFirestore(appUser);
      }
      debugPrint('===============================================');

      // Save token and provider to secure storage
      await _saveAuthData(appUser, LoginProvider.kakao);

      return appUser;
    } catch (e) {
      debugPrint('Sign in with Kakao error: $e');
      rethrow;
    }
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

  /// Get current user (checks cache first, then Firestore)
  Future<AppUser?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuthService.currentUser;
      if (firebaseUser == null) {
        debugPrint('getCurrentUser: No Firebase user');
        return null;
      }

      debugPrint('getCurrentUser: Firebase user exists - ${firebaseUser.uid}');

      // Try to get from cache first
      final cachedUser = await _storageService.getUserCache();
      if (cachedUser != null && cachedUser.uid == firebaseUser.uid) {
        debugPrint(
          'getCurrentUser: Using cached user - hasCompletedProfileSetup: ${cachedUser.hasCompletedProfileSetup}',
        );
        return cachedUser;
      }

      debugPrint('getCurrentUser: No valid cache, fetching from Firestore');

      // If not in cache or cache is stale, get from Firestore
      final doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        debugPrint('getCurrentUser: Document does not exist in Firestore');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      debugPrint('getCurrentUser: Firestore data - $data');

      final user = AppUser.fromJson(data);
      debugPrint(
        'getCurrentUser: Parsed user - hasCompletedProfileSetup: ${user.hasCompletedProfileSetup}',
      );

      // Update cache
      await _storageService.saveUserCache(user);
      debugPrint('getCurrentUser: Cache updated');

      return user;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  /// Save user to Firestore
  Future<void> _saveUserToFirestore(AppUser user) async {
    try {
      await _usersCollection
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
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

      // Save user to cache
      await _storageService.saveUserCache(user);
    } catch (e) {
      debugPrint('Save auth data error: $e');
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({String? name, String? photoURL}) async {
    try {
      final uid = _firebaseAuthService.userId;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
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

  /// Save profile data (onboarding completion)
  Future<void> saveProfileData({
    required String id,
    required String name,
    required bool goal,
    required int favoriteDrink,
    required double maxAlcohol,
    required int weeklyDrinkingFrequency,
  }) async {
    try {
      final firebaseUser = _firebaseAuthService.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not found');
      }

      final uid = firebaseUser.uid;

      // Try to get current user data
      AppUser updatedUser;
      final currentUser = await getCurrentUser();

      if (currentUser != null) {
        // User exists, update with profile data
        updatedUser = currentUser.copyWith(
          id: id,
          name: name,
          goal: goal,
          favoriteDrink: favoriteDrink,
          maxAlcohol: maxAlcohol,
          weeklyDrinkingFrequency: weeklyDrinkingFrequency,
          hasCompletedProfileSetup: true,
        );
      } else {
        // User doesn't exist in Firestore, create new AppUser
        // Try to get last login provider from storage
        final lastProvider = await _storageService.getLastLoginProvider();

        updatedUser =
            AppUser.fromFirebaseUser(
              uid: uid,
              photoURL: firebaseUser.photoURL,
              provider: lastProvider ?? LoginProvider.google,
            ).copyWith(
              id: id,
              name: name,
              goal: goal,
              favoriteDrink: favoriteDrink,
              maxAlcohol: maxAlcohol,
              weeklyDrinkingFrequency: weeklyDrinkingFrequency,
              hasCompletedProfileSetup: true,
            );
      }

      // Save to Firestore
      final jsonData = updatedUser.toJson();
      debugPrint('=== Saving profile data to Firestore ===');
      debugPrint('JSON data: $jsonData');
      debugPrint(
        'hasCompletedProfileSetup: ${jsonData['hasCompletedProfileSetup']}',
      );

      await _usersCollection.doc(uid).set(jsonData, SetOptions(merge: true));

      // Save to cache
      await _storageService.saveUserCache(updatedUser);

      debugPrint('Profile data saved successfully');
      debugPrint('======================================');
    } catch (e) {
      debugPrint('Save profile data error: $e');
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
  Stream<User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  /// Get AppUser stream
  Stream<AppUser?> get appUserChanges {
    return _firebaseAuthService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      // Try to get from cache first
      final cachedUser = await _storageService.getUserCache();
      if (cachedUser != null && cachedUser.uid == firebaseUser.uid) {
        return cachedUser;
      }

      // If not in cache, fetch from Firestore
      var doc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        // Retry once after a short delay to handle race condition during sign up
        // When creating a new user, auth state changes before Firestore write completes
        await Future.delayed(const Duration(milliseconds: 500));
        doc = await _usersCollection.doc(firebaseUser.uid).get();

        if (!doc.exists) {
          return null;
        }
      }

      final data = doc.data() as Map<String, dynamic>;
      final user = AppUser.fromJson(data);

      // Update cache
      await _storageService.saveUserCache(user);

      return user;
    });
  }
}
