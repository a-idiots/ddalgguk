/// Storage keys used throughout the application
class StorageKeys {
  // Prevent instantiation
  StorageKeys._();

  // Secure Storage Keys (encrypted)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String firebaseIdToken = 'firebase_id_token';
  static const String userId = 'user_id';
  static const String userCache = 'user_cache';

  // SharedPreferences Keys (unencrypted)
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
  static const String lastLoginProvider = 'last_login_provider';
  static const String badgeStats = 'badge_stats'; // Local stats JSON
  static const String mainDrinkIds = 'main_drink_ids'; // List<int>
  static const String customDrinks =
      'custom_drinks'; // List<Map<String, dynamic>>
}

/// Login provider types
enum LoginProvider {
  google('google'),
  apple('apple'),
  kakao('kakao');

  const LoginProvider(this.value);
  final String value;

  static LoginProvider? fromString(String? value) {
    if (value == null) {
      return null;
    }
    return LoginProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => LoginProvider.google,
    );
  }
}
