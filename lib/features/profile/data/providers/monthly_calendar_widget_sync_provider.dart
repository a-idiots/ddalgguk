import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/profile/data/services/monthly_calendar_widget_service.dart';

/// Keeps the iOS home-screen monthly calendar widget in sync.
///
/// Side-effect-only provider: must stay alive (watched by a consumer)
/// so that any change to monthly records re-pushes data to the widget.
///
/// Mounted at app root in [DdalggukApp].
final monthlyCalendarWidgetSyncProvider = Provider<void>((ref) {
  final now = DateTime.now();
  final monthKey = DateTime(now.year, now.month);

  final recordsAsync = ref.watch(monthRecordsProvider(monthKey));

  final records = recordsAsync.valueOrNull;
  if (records == null) {
    return;
  }

  MonthlyCalendarWidgetService.update(
    year: now.year,
    month: now.month,
    records: records,
  );
});
