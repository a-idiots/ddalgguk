import 'package:ddalgguk/core/services/notification_config.dart';
import 'package:ddalgguk/core/services/notification_service.dart';

/// Notification manager for scheduling and managing notifications
class NotificationManager {
  factory NotificationManager() => _instance;

  NotificationManager._internal();

  static final NotificationManager _instance = NotificationManager._internal();

  final NotificationService _service = NotificationService();

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
    // Get schedules for this type
    final schedules = NotificationConfig.getSchedules(type);

    // Get message for this type
    final message = NotificationConfig.getMessage(type, userName: userName);

    // Schedule each notification
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      final notificationId = NotificationConfig.getNotificationId(type, i);

      await _service.scheduleNotification(
        id: notificationId,
        title: message.title,
        body: message.body,
        type: type,
        hour: schedule.hour,
        minute: schedule.minute,
        repeatDaily: schedule.repeatDaily,
      );
    }
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
