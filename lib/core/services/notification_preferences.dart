import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddalgguk/core/services/notification_config.dart';

/// Service for managing notification preferences
class NotificationPreferences {
  factory NotificationPreferences() => _instance;

  NotificationPreferences._internal();

  static final NotificationPreferences _instance =
      NotificationPreferences._internal();

  static const String _keyPrefix = 'notification_enabled_';

  /// Check if a notification type is enabled
  Future<bool> isNotificationEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + type.name;
    // Default to true (enabled) if not set
    return prefs.getBool(key) ?? true;
  }

  /// Enable or disable a notification type
  Future<void> setNotificationEnabled(
    NotificationType type,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + type.name;
    await prefs.setBool(key, enabled);
  }

  /// Get all notification settings
  Future<Map<NotificationType, bool>> getAllNotificationSettings() async {
    final settings = <NotificationType, bool>{};
    for (final type in NotificationType.values) {
      settings[type] = await isNotificationEnabled(type);
    }
    return settings;
  }

  /// Enable all notifications
  Future<void> enableAllNotifications() async {
    for (final type in NotificationType.values) {
      await setNotificationEnabled(type, true);
    }
  }

  /// Disable all notifications
  Future<void> disableAllNotifications() async {
    for (final type in NotificationType.values) {
      await setNotificationEnabled(type, false);
    }
  }
}
