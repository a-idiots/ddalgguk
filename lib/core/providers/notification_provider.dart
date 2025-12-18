import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/services/notification_manager.dart';
import 'package:ddalgguk/core/services/notification_config.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';

/// Provider for notification manager
final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager();
});

/// Provider for notification initialization status
final notificationInitializedProvider = StateProvider<bool>((ref) => false);

/// Provider for initializing notifications
final initializeNotificationsProvider = FutureProvider<void>((ref) async {
  final manager = ref.read(notificationManagerProvider);
  final currentUser = await ref.read(currentUserProvider.future);

  // Initialize notification service
  await manager.initialize();

  // Request permissions
  final granted = await manager.requestPermissions();

  if (granted) {
    // Schedule notifications with user name
    final userName = currentUser?.name ?? '사용자';
    await manager.scheduleAllNotifications(userName: userName);

    // Mark as initialized
    ref.read(notificationInitializedProvider.notifier).state = true;
  }
});

/// Provider for rescheduling notifications when user name changes
final rescheduleNotificationsProvider = FutureProvider.family<void, String>((
  ref,
  userName,
) async {
  final manager = ref.read(notificationManagerProvider);
  await manager.rescheduleAllNotifications(userName: userName);
});

/// Provider for showing test notification
final showTestNotificationProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final manager = ref.read(notificationManagerProvider);
    final currentUser = await ref.read(currentUserProvider.future);
    final userName = currentUser?.name ?? '사용자';

    await manager.showTestNotification(
      type: NotificationType.recordAlarm,
      userName: userName,
    );
  };
});

/// Provider for showing delayed test notification (useful for iOS)
final showDelayedTestNotificationProvider =
    Provider<Future<void> Function({int delaySeconds})>((ref) {
      return ({int delaySeconds = 5}) async {
        final manager = ref.read(notificationManagerProvider);
        final currentUser = await ref.read(currentUserProvider.future);
        final userName = currentUser?.name ?? '사용자';

        await manager.showDelayedTestNotification(
          type: NotificationType.recordAlarm,
          userName: userName,
          delaySeconds: delaySeconds,
        );
      };
    });

/// Provider for getting pending notification count
final pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  final manager = ref.read(notificationManagerProvider);
  return manager.getPendingNotificationCount();
});

/// Provider for canceling all notifications
final cancelAllNotificationsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final manager = ref.read(notificationManagerProvider);
    await manager.cancelAllNotifications();
    ref.read(notificationInitializedProvider.notifier).state = false;
  };
});

/// Provider for checking if a notification type is scheduled
final isNotificationTypeScheduledProvider =
    FutureProvider.family<bool, NotificationType>((ref, type) async {
      final manager = ref.read(notificationManagerProvider);
      return manager.isNotificationTypeScheduled(type);
    });

/// Provider for checking if a notification type is enabled
final isNotificationEnabledProvider =
    FutureProvider.family<bool, NotificationType>((ref, type) async {
      final manager = ref.read(notificationManagerProvider);
      return manager.isNotificationEnabled(type);
    });

/// Provider for toggling notification
final toggleNotificationProvider =
    Provider<Future<void> Function(NotificationType, bool)>((ref) {
      return (NotificationType type, bool enabled) async {
        final manager = ref.read(notificationManagerProvider);
        final currentUser = await ref.read(currentUserProvider.future);
        final userName = currentUser?.name ?? '사용자';

        await manager.toggleNotification(
          type,
          enabled: enabled,
          userName: userName,
        );

        // Invalidate relevant providers
        ref.invalidate(isNotificationEnabledProvider(type));
        ref.invalidate(isNotificationTypeScheduledProvider(type));
        ref.invalidate(pendingNotificationCountProvider);
      };
    });
