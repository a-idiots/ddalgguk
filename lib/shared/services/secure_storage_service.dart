import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/features/auth/domain/models/app_user.dart';

/// Service for secure storage operations
/// Uses flutter_secure_storage for sensitive data (encrypted)
/// Uses shared_preferences for non-sensitive data
class SecureStorageService {
  // Singleton pattern
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ====================
  // Secure Storage (Encrypted)
  // ====================

  /// Save Firebase ID token securely
  Future<void> saveFirebaseIdToken(String token) async {
    await _secureStorage.write(key: StorageKeys.firebaseIdToken, value: token);
  }

  /// Get Firebase ID token
  Future<String?> getFirebaseIdToken() async {
    return _secureStorage.read(key: StorageKeys.firebaseIdToken);
  }

  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: StorageKeys.accessToken);
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: StorageKeys.refreshToken);
  }

  /// Save user ID securely
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: StorageKeys.userId, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return _secureStorage.read(key: StorageKeys.userId);
  }

  /// Save user cache (entire AppUser object as JSON)
  Future<void> saveUserCache(AppUser user) async {
    final json = user.toJson();
    final jsonString = jsonEncode(json);
    await _secureStorage.write(key: StorageKeys.userCache, value: jsonString);
  }

  /// Get user cache
  Future<AppUser?> getUserCache() async {
    try {
      final jsonString = await _secureStorage.read(key: StorageKeys.userCache);
      if (jsonString == null) {
        return null;
      }
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final user = AppUser.fromJson(jsonMap);
      return user;
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  /// Clear user cache
  Future<void> clearUserCache() async {
    await _secureStorage.delete(key: StorageKeys.userCache);
  }

  /// Delete all secure data (logout)
  Future<void> deleteAllSecureData() async {
    await _secureStorage.deleteAll();
  }

  // ====================
  // SharedPreferences (Unencrypted)
  // ====================

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted(bool value) async {
    await _ensurePrefsInitialized();
    await _prefs!.setBool(StorageKeys.hasCompletedOnboarding, value);
  }

  /// Check if onboarding is completed
  Future<bool> hasCompletedOnboarding() async {
    await _ensurePrefsInitialized();
    return _prefs!.getBool(StorageKeys.hasCompletedOnboarding) ?? false;
  }

  /// Save last login provider
  Future<void> saveLastLoginProvider(LoginProvider provider) async {
    await _ensurePrefsInitialized();
    await _prefs!.setString(StorageKeys.lastLoginProvider, provider.value);
  }

  /// Get last login provider
  Future<LoginProvider?> getLastLoginProvider() async {
    await _ensurePrefsInitialized();
    final value = _prefs!.getString(StorageKeys.lastLoginProvider);
    return LoginProvider.fromString(value);
  }

  /// Clear all SharedPreferences data
  Future<void> clearPreferences() async {
    await _ensurePrefsInitialized();
    await _prefs!.clear();
  }

  /// Clear all storage (secure + preferences)
  Future<void> clearAll() async {
    await deleteAllSecureData();
    await clearPreferences();
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensurePrefsInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}
