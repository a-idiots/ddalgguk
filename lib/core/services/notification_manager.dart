import 'package:ddalgguk/core/services/notification_config.dart';
import 'package:ddalgguk/core/services/notification_service.dart';
import 'package:ddalgguk/core/services/notification_preferences.dart';

/// Notification manager for scheduling and managing notifications
class NotificationManager {
  factory NotificationManager() => _instance;

  NotificationManager._internal();

  static final NotificationManager _instance = NotificationManager._internal();

  final NotificationService _service = NotificationService();
  final NotificationPreferences _preferences = NotificationPreferences();

  /// Initialize notification manager
  Future<void> initialize() async {
    await _service.initialize();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return _service.requestPermissions();
  }

  /// Schedule all enabled notifications
  Future<void> scheduleAllNotifications({String userName = '사용자'}) async {
    // Get all enabled notification types
    final enabledTypes = NotificationConfig.getEnabledTypes();

    for (final type in enabledTypes) {
      await scheduleNotificationsForType(type, userName: userName);
    }
  }

  /// Schedule notifications for a specific type
  Future<void> scheduleNotificationsForType(
    NotificationType type, {
    String userName = '사용자',
  }) async {
    // Check if this notification type is enabled
    final isEnabled = await _preferences.isNotificationEnabled(type);
    if (!isEnabled) {
      // If disabled, cancel any existing notifications
      await cancelNotificationsForType(type);
      return;
    }

    // Get schedules for this type
    final schedules = NotificationConfig.getSchedules(type);

    // Schedule each notification
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      final notificationId = NotificationConfig.getNotificationId(type, i);

      // For recap alarm, we need to determine the next month
      int? month;
      bool isMonthlyLastDay = false;

      if (type == NotificationType.recapAlarm) {
        final now = DateTime.now();
        // Calculate which month's recap this will be for
        // The notification shows on the last day, so it's for the current month
        month = now.month;
        isMonthlyLastDay = true;

        // If today is past the last day schedule, it's for next month
        final lastDayThisMonth = DateTime(now.year, now.month + 1, 0);
        final scheduledTimeToday = DateTime(
          now.year,
          now.month,
          lastDayThisMonth.day,
          schedule.hour,
          schedule.minute,
        );

        if (now.isAfter(scheduledTimeToday)) {
          month = now.month == 12 ? 1 : now.month + 1;
        }
      }

      // Get message for this type
      final message = NotificationConfig.getMessage(
        type,
        userName: userName,
        month: month,
      );

      await _service.scheduleNotification(
        id: notificationId,
        title: message.title,
        body: message.body,
        type: type,
        hour: schedule.hour,
        minute: schedule.minute,
        repeatDaily: schedule.repeatDaily,
        isMonthlyLastDay: isMonthlyLastDay,
      );
    }
  }

  /// Toggle notification for a specific type
  Future<void> toggleNotification(
    NotificationType type, {
    required bool enabled,
    String userName = '사용자',
  }) async {
    // Save preference
    await _preferences.setNotificationEnabled(type, enabled);

    if (enabled) {
      // Schedule notification
      await scheduleNotificationsForType(type, userName: userName);
    } else {
      // Cancel notification
      await cancelNotificationsForType(type);
    }
  }

  /// Check if a notification type is enabled in preferences
  Future<bool> isNotificationEnabled(NotificationType type) async {
    return _preferences.isNotificationEnabled(type);
  }

  /// Cancel notifications for a specific type
  Future<void> cancelNotificationsForType(NotificationType type) async {
    final schedules = NotificationConfig.getSchedules(type);

    for (var i = 0; i < schedules.length; i++) {
      final notificationId = NotificationConfig.getNotificationId(type, i);
      await _service.cancelNotification(notificationId);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _service.cancelAllNotifications();
  }

  /// Get pending notifications
  Future<int> getPendingNotificationCount() async {
    final pending = await _service.getPendingNotifications();
    return pending.length;
  }

  /// Show immediate notification for testing
  Future<void> showTestNotification({
    NotificationType type = NotificationType.recordAlarm,
    String userName = '사용자',
  }) async {
    final message = NotificationConfig.getMessage(type, userName: userName);
    final notificationId = NotificationConfig.getNotificationId(type, 0);

    await _service.showNotification(
      id: notificationId,
      title: message.title,
      body: message.body,
      type: type,
    );
  }

  /// Show delayed notification for testing (useful for iOS)
  Future<void> showDelayedTestNotification({
    NotificationType type = NotificationType.recordAlarm,
    String userName = '사용자',
    int delaySeconds = 5,
  }) async {
    final message = NotificationConfig.getMessage(type, userName: userName);
    final notificationId = NotificationConfig.getNotificationId(type, 999);

    await _service.showDelayedNotification(
      id: notificationId,
      title: message.title,
      body: message.body,
      type: type,
      delaySeconds: delaySeconds,
    );
  }

  /// Reschedule all notifications (useful after updating user name)
  Future<void> rescheduleAllNotifications({String userName = '사용자'}) async {
    await cancelAllNotifications();
    await scheduleAllNotifications(userName: userName);
  }

  /// Check if a specific notification type is scheduled
  Future<bool> isNotificationTypeScheduled(NotificationType type) async {
    final pending = await _service.getPendingNotifications();
    final schedules = NotificationConfig.getSchedules(type);

    for (var i = 0; i < schedules.length; i++) {
      final notificationId = NotificationConfig.getNotificationId(type, i);
      final isScheduled = pending.any((p) => p.id == notificationId);
      if (!isScheduled) {
        return false;
      }
    }

    return schedules.isNotEmpty;
  }
}
