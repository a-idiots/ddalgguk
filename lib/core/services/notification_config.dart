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
    this.daysOfWeek,
  });

  final NotificationType type;
  final int hour;
  final int minute;
  final bool repeatDaily;
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday (null means daily)
}

/// Central notification configuration
class NotificationConfig {
  // Notification messages for each type
  static const Map<NotificationType, List<NotificationMessage>> messages = {
    NotificationType.recordAlarm: [
      NotificationMessage(
        title: '오늘 하루도 수고했어요{userSuffix}',
        body: '딸꾹과 함께 오늘의 음주 기록을 남겨볼까요?',
      ),
      NotificationMessage(
        title: '{userPrefix}오늘은 어땠나요?',
        body: '오늘의 음주 기록을 업데이트하고 건강을 챙겨봐요!',
      ),
      NotificationMessage(
        title: '기록할 시간이에요{userSuffix}',
        body: '딸꾹이 기다리고 있어요! 오늘의 음주 기록을 남겨주세요.',
      ),
      NotificationMessage(
        title: '{userPrefix}알림이 도착했어요!',
        body: '오늘 하루 어떠셨나요? 음주 기록으로 건강을 체크해봐요!',
      ),
      NotificationMessage(
        title: '딸꾹이 궁금해해요{userSuffix}',
        body: '오늘은 어떤 하루였나요? 기록으로 남겨보세요!',
      ),
      NotificationMessage(
        title: '{userPrefix}잠깐만요!',
        body: '오늘의 음주 기록을 업데이트하고 건강한 습관을 만들어봐요!',
      ),
      NotificationMessage(
        title: '건강한 음주 습관{userSuffix}',
        body: '딸꾹에 오늘의 기록을 남기고 나만의 패턴을 확인해봐요!',
      ),
      NotificationMessage(
        title: '{userPrefix}오늘도 화이팅!',
        body: '음주 기록으로 나의 건강을 체크하는 시간이에요!',
      ),
      NotificationMessage(
        title: '하루의 마무리{userSuffix}',
        body: '딸꾹과 함께 오늘의 음주 기록을 정리해볼까요?',
      ),
      NotificationMessage(
        title: '{userPrefix}기록이 쌓이고 있어요!',
        body: '꾸준한 기록이 건강한 습관을 만들어요. 오늘도 함께해요!',
      ),
    ],
    NotificationType.socialAlarm: [
      NotificationMessage(
        title: '새로운 친구 신청이 도착했어요!',
        body: '{friendName}님이 친구 신청을 보냈습니다.',
      ),
      NotificationMessage(
        title: '친구 신청이 수락되었어요!',
        body: '{friendName}님과 친구가 되었습니다.',
      ),
      NotificationMessage(
        title: '친구 신청을 확인해보세요!',
        body: '3일이 지난 친구 신청이 있습니다. 우체통을 확인해보세요!',
      ),
    ],
    NotificationType.recapAlarm: [
      NotificationMessage(
        title: '{userPrefix}{month}월 음주 리포트 완성!',
        body: '지금 바로 접속해서 이번 달 알코올 총 섭취량을 확인해보세요.',
      ),
    ],
  };

  // Notification schedules for low frequency drinkers (주 2회 이하)
  static const Map<NotificationType, List<NotificationSchedule>>
  schedulesLowFrequency = {
    NotificationType.recordAlarm: [
      NotificationSchedule(
        type: NotificationType.recordAlarm,
        hour: 9, // 9 AM
        minute: 0,
        repeatDaily: true, // every day
      ),
    ],
  };

  // Notification schedules for high frequency drinkers (주 3회 이상)
  static const Map<NotificationType, List<NotificationSchedule>>
  schedulesHighFrequency = {
    NotificationType.recordAlarm: [
      NotificationSchedule(
        type: NotificationType.recordAlarm,
        hour: 9, // 9 AM
        minute: 0,
        repeatDaily: true, // every day
      ),
    ],
  };

  // Common schedules for all users
  static const Map<NotificationType, List<NotificationSchedule>>
  schedulesCommon = {
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
  /// Randomly selects from available messages
  static NotificationMessage getMessage(
    NotificationType type, {
    String userName = '',
    String? friendName,
    int? month,
    int? seed,
  }) {
    final messageList = messages[type];
    if (messageList == null || messageList.isEmpty) {
      return const NotificationMessage(title: '딸꾹', body: '새로운 알림이 도착했습니다.');
    }

    // Use seed (or current day) to deterministically pick a message
    final index = (seed ?? DateTime.now().day) % messageList.length;
    final message = messageList[index];

    // Build user prefix/suffix based on whether userName is available
    // e.g. "홍길동님, " / ", 홍길동님!" or "" / "!"
    final userPrefix = userName.isNotEmpty ? '$userName님, ' : '';
    final userSuffix = userName.isNotEmpty ? ', $userName님!' : '!';

    var title = message.title
        .replaceAll('{userPrefix}', userPrefix)
        .replaceAll('{userSuffix}', userSuffix);
    var body = message.body
        .replaceAll('{userPrefix}', userPrefix)
        .replaceAll('{userSuffix}', userSuffix);

    // For social alarm, replace friendName placeholder
    if (type == NotificationType.socialAlarm && friendName != null) {
      title = title.replaceAll('{friendName}', friendName);
      body = body.replaceAll('{friendName}', friendName);
    }

    // For recap alarm, replace month placeholder
    if (type == NotificationType.recapAlarm && month != null) {
      title = title.replaceAll('{month}', month.toString());
      body = body.replaceAll('{month}', month.toString());
    }

    return NotificationMessage(title: title, body: body);
  }

  /// Get all schedules for a specific type based on drinking frequency
  /// weeklyDrinkingFrequency: null or <=2 means low frequency (Sunday only)
  /// weeklyDrinkingFrequency: >=3 means high frequency (Friday and Sunday)
  static List<NotificationSchedule> getSchedules(
    NotificationType type, {
    int? weeklyDrinkingFrequency,
  }) {
    // For recordAlarm, return frequency-based schedules
    if (type == NotificationType.recordAlarm) {
      final isHighFrequency =
          weeklyDrinkingFrequency != null && weeklyDrinkingFrequency >= 3;
      final scheduleMap = isHighFrequency
          ? schedulesHighFrequency
          : schedulesLowFrequency;
      return scheduleMap[type] ?? [];
    }

    // For other types, return common schedules
    return schedulesCommon[type] ?? [];
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
