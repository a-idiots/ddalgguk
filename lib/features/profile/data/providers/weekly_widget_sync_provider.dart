import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/data/services/weekly_home_widget_service.dart';

/// Keeps the iOS home-screen weekly widget in sync with the current
/// week's drinking stats.
///
/// Side-effect-only provider: must stay alive (watched by a consumer)
/// so that any change to weekly stats re-pushes data to the widget.
///
/// Mounted at app root in [DdalggukApp].
final weeklyWidgetSyncProvider = Provider<void>((ref) {
  final weeklyAsync = ref.watch(weeklyStatsProvider);

  final weeklyStats = weeklyAsync.valueOrNull;
  if (weeklyStats == null) {
    return;
  }

  WeeklyHomeWidgetService.update(weeklyStats: weeklyStats);
});
