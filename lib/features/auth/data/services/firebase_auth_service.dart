import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication Service
/// Handles all Firebase Auth operations
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in with credential (for Google, Apple)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign in with custom token (for Kakao)
  Future<UserCredential> signInWithCustomToken(String token) async {
    try {
      return await _firebaseAuth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      debugPrint('Custom token sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign out error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete account error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
    } on FirebaseAuthException catch (e) {
      debugPrint('Get ID token error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Refresh ID token
  Future<String?> refreshIdToken() async {
    return getIdToken(forceRefresh: true);
  }

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Get user photo URL
  String? get userPhotoURL => _firebaseAuth.currentUser?.photoURL;

  /// Get user ID
  String? get userId => _firebaseAuth.currentUser?.uid;
}
