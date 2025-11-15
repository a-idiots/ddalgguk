import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// Kakao Authentication Service
/// Handles Kakao Sign-In operations
///
/// IMPORTANT: Kakao login with Firebase requires a backend server
/// to generate custom Firebase tokens. This is a skeleton implementation.
///
/// To complete the implementation, you need:
/// 1. Set up Firebase Cloud Functions or your own backend server
/// 2. Create an endpoint that accepts Kakao access token
/// 3. Verify the token with Kakao API
/// 4. Generate a Firebase custom token
/// 5. Return the custom token to the app
///
/// Alternative approaches:
/// - Use Firebase Anonymous Auth + link to Kakao ID in Firestore
/// - Use a third-party authentication service
class KakaoAuthService {
  /// Sign in with Kakao
  /// Returns Kakao access token that needs to be exchanged for Firebase custom token
  Future<String> signInWithKakao() async {
    try {
      // Check if KakaoTalk is installed
      final bool isInstalled = await isKakaoTalkInstalled();

      OAuthToken token;
      if (isInstalled) {
        // Login with KakaoTalk app
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          debugPrint('KakaoTalk login failed, trying web login: $error');
          // If KakaoTalk login fails, try web login
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // Login with Kakao Account (web)
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // Get Kakao user info
      final User user = await UserApi.instance.me();
      debugPrint('Kakao login successful:');
      debugPrint('User ID: ${user.id}');
      debugPrint('Email: ${user.kakaoAccount?.email}');
      debugPrint('Nickname: ${user.kakaoAccount?.profile?.nickname}');

      // TODO: Send token.accessToken to your backend server
      // to exchange it for a Firebase custom token
      //
      // Example:
      // final response = await http.post(
      //   Uri.parse('YOUR_BACKEND_URL/auth/kakao'),
      //   body: {'kakaoAccessToken': token.accessToken},
      // );
      // final firebaseCustomToken = response.body['customToken'];
      // return firebaseCustomToken;

      // For now, return the Kakao access token
      // This CANNOT be used directly with Firebase Auth
      return token.accessToken;
    } catch (e) {
      debugPrint('Kakao sign in error: $e');
      rethrow;
    }
  }

  /// Get Kakao user information
  Future<User> getKakaoUser() async {
    try {
      return await UserApi.instance.me();
    } catch (e) {
      debugPrint('Get Kakao user error: $e');
      rethrow;
    }
  }

  /// Sign out from Kakao
  Future<void> signOut() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      debugPrint('Kakao sign out error: $e');
      rethrow;
    }
  }

  /// Unlink Kakao account (revoke access)
  Future<void> unlink() async {
    try {
      await UserApi.instance.unlink();
    } catch (e) {
      debugPrint('Kakao unlink error: $e');
      rethrow;
    }
  }

  /// Check if access token exists
  Future<bool> hasToken() async {
    try {
      await UserApi.instance.accessTokenInfo();
      return true;
    } catch (e) {
      return false;
    }
  }
}
