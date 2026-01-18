import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:ddalgguk/core/services/notification_config.dart';

/// Notification service for managing local notifications
class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🔔 Requesting notification permissions...');

    // Request Android permissions (Android 13+)
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('📱 Android permission granted: $granted');
      if (granted != true) {
        return false;
      }
    }

    // Request iOS permissions
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🍎 iOS permission granted: $granted');
      if (granted != true) {
        return false;
      }
    }

    return true;
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    required int hour,
    required int minute,
    bool repeatDaily = true,
    bool isMonthlyLastDay = false,
    List<int>? daysOfWeek,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate;

    if (isMonthlyLastDay) {
      // Schedule for the last day of current month
      scheduledDate = _getLastDayOfMonth(now.year, now.month, hour, minute);

      // If the scheduled time has passed this month, schedule for next month
      if (scheduledDate.isBefore(now)) {
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        scheduledDate = _getLastDayOfMonth(nextYear, nextMonth, hour, minute);
      }
    } else if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
      // Schedule for specific days of the week
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time has passed today, start from tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Find the next occurrence of a target day
      while (!daysOfWeek.contains(scheduledDate.weekday)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    } else {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    final androidDetails = AndroidNotificationDetails(
      NotificationConfig.getChannelId(type),
      NotificationConfig.getChannelName(type),
      channelDescription: NotificationConfig.getChannelDescription(type),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (repeatDaily) {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
      // For weekly notifications on specific days
      // Schedule multiple notifications, one for each day of the week
      for (var i = 0; i < daysOfWeek.length; i++) {
        final targetDay = daysOfWeek[i];
        var dayScheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // If the scheduled time has passed today, start from tomorrow
        if (dayScheduledDate.isBefore(now)) {
          dayScheduledDate = dayScheduledDate.add(const Duration(days: 1));
        }

        // Find the next occurrence of this specific day
        while (dayScheduledDate.weekday != targetDay) {
          dayScheduledDate = dayScheduledDate.add(const Duration(days: 1));
        }

        // Use unique ID for each day (id + day offset)
        final dayNotificationId = id + i;

        await _notificationsPlugin.zonedSchedule(
          dayNotificationId,
          title,
          body,
          dayScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

        debugPrint(
          '📅 Scheduled weekly notification for ${_getDayName(targetDay)}: $dayScheduledDate',
        );
      }
      return; // Exit early since we scheduled all notifications
    } else if (isMonthlyLastDay) {
      // For monthly notifications, we need to reschedule after each trigger
      // This is a one-time notification that should be rescheduled monthly
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('📅 Scheduled recap notification for: $scheduledDate');
    } else {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Get the last day of a specific month
  tz.TZDateTime _getLastDayOfMonth(int year, int month, int hour, int minute) {
    // Get the first day of next month, then subtract 1 day
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final firstDayOfNextMonth = tz.TZDateTime(tz.local, nextYear, nextMonth, 1);
    final lastDayOfMonth = firstDayOfNextMonth.subtract(
      const Duration(days: 1),
    );

    // Set the time
    return tz.TZDateTime(
      tz.local,
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day,
      hour,
      minute,
    );
  }

  /// Get day name for debugging
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _notificationsPlugin.pendingNotificationRequests();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap here
    // You can add navigation logic based on the notification payload
    // Example: Navigate to specific screen based on notification type
  }

  /// Show immediate notification (for testing)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🔔 Showing notification: id=$id, title=$title, body=$body');

    // Check iOS permissions
    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🍎 iOS notification permission status: $granted');
    }

    final androidDetails = AndroidNotificationDetails(
      NotificationConfig.getChannelId(type),
      NotificationConfig.getChannelName(type),
      channelDescription: NotificationConfig.getChannelDescription(type),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(id, title, body, notificationDetails);
      debugPrint('✅ Notification API called successfully');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
      rethrow;
    }
  }

  /// Schedule notification after delay (for testing)
  Future<void> showDelayedNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    required int delaySeconds,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint(
      '🔔 Scheduling notification in $delaySeconds seconds: id=$id, title=$title',
    );

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: delaySeconds));

    final androidDetails = AndroidNotificationDetails(
      NotificationConfig.getChannelId(type),
      NotificationConfig.getChannelName(type),
      channelDescription: NotificationConfig.getChannelDescription(type),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✅ Notification scheduled successfully for $scheduledDate');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      rethrow;
    }
  }
}
