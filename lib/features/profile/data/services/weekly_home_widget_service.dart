import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';

/// Pushes the current weekly stats data to the iOS home-screen
/// widget via a shared App Group container.
///
/// The iOS widget extension reads the same keys from
/// `UserDefaults(suiteName: appGroupId)`.
class WeeklyHomeWidgetService {
  WeeklyHomeWidgetService._();

  static const String appGroupId = 'group.com.aidiot.ddalgguk';
  static const String iosWidgetName = 'DdalggukWeeklyWidget';

  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
    _initialized = true;
  }

  /// Writes the weekly stats and triggers a widget reload.
  static Future<void> update({required WeeklyStats weeklyStats}) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _ensureInit();

      final dateRange =
          '${DateFormat('MM.dd.').format(weeklyStats.startDate)} ~ '
          '${DateFormat('MM.dd.').format(weeklyStats.endDate)}';

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final futures = <Future<bool?>>[
        HomeWidget.saveWidgetData<String>('weekly_date_range', dateRange),
        HomeWidget.saveWidgetData<int>(
          'weekly_sober_days',
          weeklyStats.soberDays,
        ),
        HomeWidget.saveWidgetData<int>(
          'weekly_drinking_days',
          weeklyStats.totalSessions,
        ),
      ];

      for (int i = 0; i < weeklyStats.dailyData.length && i < 7; i++) {
        final day = weeklyStats.dailyData[i];
        final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
        final isFuture = dayDate.isAfter(today);

        futures.addAll([
          HomeWidget.saveWidgetData<int>(
            'weekly_day_${i}_drunk_level',
            day.drunkLevel,
          ),
          HomeWidget.saveWidgetData<bool>(
            'weekly_day_${i}_has_records',
            day.hasRecords,
          ),
          HomeWidget.saveWidgetData<bool>(
            'weekly_day_${i}_is_future',
            isFuture,
          ),
        ]);
      }

      await Future.wait(futures);
      await HomeWidget.updateWidget(iOSName: iosWidgetName);
    } catch (_) {
      // Best-effort: never let widget sync break the app.
    }
  }
}
