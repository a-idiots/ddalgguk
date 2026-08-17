import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/data/services/goal_home_widget_service.dart';

/// Keeps the iOS home-screen widget's App Group container in sync with the
/// current user's monthly goal + month-to-date progress.
///
/// This is a side-effect-only provider: its return value is unused. It just
/// needs to stay **alive** (watched by at least one consumer) so that every
/// change to the underlying providers (user goal, month records, etc.)
/// re-runs this builder and pushes a fresh snapshot to the widget.
///
/// Mounted once at app root in [DdalggukApp].
final goalWidgetSyncProvider = Provider<void>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final proAsync = ref.watch(proProvider);
  final now = DateTime.now();
  final monthNum = now.month;
  final monthKey = DateTime(now.year, now.month);

  final spendingAsync = ref.watch(monthlySpendingProvider(monthKey));
  final alcoholAsync = ref.watch(currentMonthAlcoholBottlesProvider);

  final user = userAsync.valueOrNull;
  final isPro = proAsync.valueOrNull ?? false;
  final budget = user?.monthlyGoalBudget;
  final alcoholGoal = user?.monthlyGoalAlcohol;
  final hasGoal = isPro && (budget != null || alcoholGoal != null);

  final currentSpending = spendingAsync.valueOrNull ?? 0;
  final currentAlcohol = alcoholAsync.valueOrNull ?? 0.0;

  GoalHomeWidgetService.update(
    hasGoal: hasGoal,
    monthNum: monthNum,
    budget: hasGoal ? budget : null,
    alcoholGoal: hasGoal ? alcoholGoal : null,
    currentSpending: currentSpending,
    currentAlcohol: currentAlcohol,
  );
});
