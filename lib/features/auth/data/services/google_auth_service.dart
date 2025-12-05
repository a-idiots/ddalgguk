import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Authentication Service
/// Handles Google Sign-In operations
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId:
                  '575327975025-9d0tkm3ounk9thbsdt651muljo7po2vl.apps.googleusercontent.com',
              serverClientId:
                  '575327975025-06qg084oq1se651uud413ccc96app35f.apps.googleusercontent.com',
            );

  final GoogleSignIn _googleSignIn;

  /// Sign in with Google
  /// Returns AuthCredential to be used with Firebase Auth
  Future<AuthCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in cancelled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return credential;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign out error: $e');
      rethrow;
    }
  }

  /// Disconnect from Google (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google disconnect error: $e');
      rethrow;
    }
  }

  /// Check if user is signed in with Google
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Get current Google user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
