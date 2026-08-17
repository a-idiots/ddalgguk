import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';

/// Pushes the current month's calendar data to the iOS home-screen
/// widget via a shared App Group container.
class MonthlyCalendarWidgetService {
  MonthlyCalendarWidgetService._();

  static const String appGroupId = 'group.com.aidiot.ddalgguk';
  static const String iosWidgetName = 'DdalggukMonthlyCalendarWidget';

  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
    _initialized = true;
  }

  /// Writes the monthly calendar data and triggers a widget reload.
  ///
  /// [year] and [month] identify the calendar month.
  /// [records] is the full list of drinking records for that month.
  static Future<void> update({
    required int year,
    required int month,
    required List<DrinkingRecord> records,
  }) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _ensureInit();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Group records by day
      final recordsByDay = <int, List<DrinkingRecord>>{};
      for (final record in records) {
        final day = record.date.day;
        recordsByDay.putIfAbsent(day, () => []).add(record);
      }

      // Count stats
      int drinkingDays = 0;
      int soberDays = 0;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      // Determine elapsed days (up to today)
      final isCurrentMonth = year == today.year && month == today.month;
      final isFutureMonth = DateTime(year, month).isAfter(today);
      final elapsedDays = isFutureMonth
          ? 0
          : (isCurrentMonth ? today.day : daysInMonth);

      final futures = <Future<bool?>>[];

      futures.addAll([
        HomeWidget.saveWidgetData<int>('cal_year', year),
        HomeWidget.saveWidgetData<int>('cal_month', month),
        HomeWidget.saveWidgetData<int>('cal_days_in_month', daysInMonth),
      ]);

      // First day of month weekday (1=Monday, 7=Sunday)
      final firstWeekday = DateTime(year, month, 1).weekday;
      futures.add(
        HomeWidget.saveWidgetData<int>('cal_first_weekday', firstWeekday),
      );

      for (int d = 1; d <= daysInMonth; d++) {
        final dayRecords = recordsByDay[d] ?? [];
        final date = DateTime(year, month, d);
        final isFuture = date.isAfter(today);

        // 0 = no record (past), 1 = drinking, 2 = sober, 3 = future
        int status;
        if (isFuture) {
          status = 3;
        } else if (dayRecords.isEmpty) {
          status = 0;
        } else {
          final allSober = dayRecords.every(
            (r) => r.drunkLevel == 0 && r.meetingName == '금주',
          );
          if (allSober) {
            status = 2;
            soberDays++;
          } else {
            status = 1;
            drinkingDays++;
          }
        }

        // Average drunk level for the day (0-100 scale, matching drunkLevel * 10)
        int drunkLevel = 0;
        if (dayRecords.isNotEmpty) {
          final avg =
              dayRecords.map((r) => r.drunkLevel).reduce((a, b) => a + b) /
              dayRecords.length;
          drunkLevel = (avg.round() * 10).clamp(0, 100);
        }

        futures.addAll([
          HomeWidget.saveWidgetData<int>('cal_day_${d}_status', status),
          HomeWidget.saveWidgetData<int>(
            'cal_day_${d}_drunk_level',
            drunkLevel,
          ),
        ]);
      }

      final noRecordDays = (elapsedDays - drinkingDays - soberDays).clamp(
        0,
        999,
      );

      futures.addAll([
        HomeWidget.saveWidgetData<int>('cal_drinking_days', drinkingDays),
        HomeWidget.saveWidgetData<int>('cal_sober_days', soberDays),
        HomeWidget.saveWidgetData<int>('cal_no_record_days', noRecordDays),
      ]);

      await Future.wait(futures);
      await HomeWidget.updateWidget(iOSName: iosWidgetName);
    } catch (_) {
      // Best-effort: never let widget sync break the app.
    }
  }
}
