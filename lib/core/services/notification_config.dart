/// Notification types enum
enum NotificationType { recordAlarm, socialAlarm, recapAlarm }

/// Notification message configuration
class NotificationMessage {
  const NotificationMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// Notification schedule configuration
class NotificationSchedule {
  const NotificationSchedule({
    required this.type,
    required this.hour,
    required this.minute,
    this.repeatDaily = true,
  });

  final NotificationType type;
  final int hour;
  final int minute;
  final bool repeatDaily;
}

/// Central notification configuration
class NotificationConfig {
  // Notification messages for each type
  static const Map<NotificationType, List<NotificationMessage>> messages = {
    NotificationType.recordAlarm: [
      NotificationMessage(
        title: '한잔하기 딱 좋은 날이에요, {userName}님!',
        body: '지금바로 딸꾹에 접속해서 음주 기록을 업데이트 해주세요!',
      ),
    ],
    NotificationType.socialAlarm: [
      // 나중에 추가될 소셜 알림 메시지
    ],
    NotificationType.recapAlarm: [
      NotificationMessage(
        title: '{userName}님의 {month}월 음주 리포트 완성!',
        body: '지금 바로 접속해서 이번 달 알코올 총 섭취량을 확인해보세요.',
      ),
    ],
  };

  // Notification schedules for each type
  static const Map<NotificationType, List<NotificationSchedule>> schedules = {
    NotificationType.recordAlarm: [
      NotificationSchedule(
        type: NotificationType.recordAlarm,
        hour: 21, // 9 PM
        minute: 0,
        repeatDaily: true,
      ),
    ],
    NotificationType.socialAlarm: [
      // 나중에 추가될 소셜 알림 스케줄
    ],
    NotificationType.recapAlarm: [
      NotificationSchedule(
        type: NotificationType.recapAlarm,
        hour: 10, // 10 AM
        minute: 0,
        repeatDaily: false, // 매월 마지막날에만
      ),
    ],
  };

  /// Get notification message for a specific type
  /// Returns the first message if multiple are defined
  static NotificationMessage getMessage(
    NotificationType type, {
    String userName = '사용자',
    int? month,
  }) {
    final messageList = messages[type];
    if (messageList == null || messageList.isEmpty) {
      return const NotificationMessage(title: '딸꾹', body: '새로운 알림이 도착했습니다.');
    }

    final message = messageList.first;
    var title = message.title.replaceAll('{userName}', userName);
    var body = message.body.replaceAll('{userName}', userName);

    // For recap alarm, replace month placeholder
    if (type == NotificationType.recapAlarm && month != null) {
      title = title.replaceAll('{month}', month.toString());
      body = body.replaceAll('{month}', month.toString());
    }

    return NotificationMessage(title: title, body: body);
  }

  /// Get all schedules for a specific type
  static List<NotificationSchedule> getSchedules(NotificationType type) {
    return schedules[type] ?? [];
  }

  /// Get all enabled notification types
  static List<NotificationType> getEnabledTypes() {
    return [NotificationType.recordAlarm, NotificationType.recapAlarm];
  }

  /// Get notification ID for a specific type and schedule index
  static int getNotificationId(NotificationType type, int scheduleIndex) {
    // Generate unique ID based on type and index
    // recordAlarm: 1000-1099
    // socialAlarm: 2000-2099
    // recapAlarm: 3000-3099
    switch (type) {
      case NotificationType.recordAlarm:
        return 1000 + scheduleIndex;
      case NotificationType.socialAlarm:
        return 2000 + scheduleIndex;
      case NotificationType.recapAlarm:
        return 3000 + scheduleIndex;
    }
  }

  /// Get notification channel ID for a specific type
  static String getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.recordAlarm:
        return 'record_alarm_channel';
      case NotificationType.socialAlarm:
        return 'social_alarm_channel';
      case NotificationType.recapAlarm:
        return 'recap_alarm_channel';
    }
  }

  /// Get notification channel name for a specific type
  static String getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.recordAlarm:
        return '음주 기록 알림';
      case NotificationType.socialAlarm:
        return '소셜 알림';
      case NotificationType.recapAlarm:
        return 'Recap 알림';
    }
  }

  /// Get notification channel description for a specific type
  static String getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.recordAlarm:
        return '음주 기록을 업데이트하도록 알려드립니다';
      case NotificationType.socialAlarm:
        return '친구들의 소식을 알려드립니다';
      case NotificationType.recapAlarm:
        return '월간 음주 리포트를 알려드립니다';
    }
  }
}
