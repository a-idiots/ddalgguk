import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// Kakao Authentication Service
/// Handles Kakao Sign-In operations and exchanges Kakao tokens for Firebase custom tokens
class KakaoAuthService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
  /// Sign in with Kakao
  /// Returns Firebase custom token after exchanging Kakao access token
  Future<String> signInWithKakao() async {
    try {
      // Step 1: Get Kakao access token
      final String kakaoAccessToken = await _getKakaoAccessToken();

      // Step 2: Exchange Kakao token for Firebase custom token
      final String firebaseCustomToken = await _exchangeKakaoTokenForFirebaseToken(kakaoAccessToken);

      return firebaseCustomToken;
    } catch (e) {
      debugPrint('Kakao sign in error: $e');
      rethrow;
    }
  }

  /// Get Kakao access token by logging in with KakaoTalk or Kakao Account
  Future<String> _getKakaoAccessToken() async {
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

    // Get Kakao user info for logging
    final User user = await UserApi.instance.me();
    debugPrint('Kakao login successful:');
    debugPrint('User ID: ${user.id}');
    debugPrint('Email: ${user.kakaoAccount?.email}');
    debugPrint('Nickname: ${user.kakaoAccount?.profile?.nickname}');

    return token.accessToken;
  }

  /// Exchange Kakao access token for Firebase custom token via Cloud Functions
  Future<String> _exchangeKakaoTokenForFirebaseToken(String kakaoAccessToken) async {
    try {
      // Call Firebase Cloud Function to exchange tokens
      final HttpsCallable callable = _functions.httpsCallable('kakaoAuth');
      final result = await callable.call<Map<String, dynamic>>({
        'kakaoAccessToken': kakaoAccessToken,
      });

      // Extract custom token from response
      final String? customToken = result.data['customToken'] as String?;

      if (customToken == null) {
        throw Exception('Failed to get Firebase custom token from Cloud Functions');
      }

      return customToken;
    } catch (e) {
      debugPrint('Token exchange error: $e');
      throw Exception('Failed to exchange Kakao token for Firebase token: $e');
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
