import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

/// Pushes the current monthly goal + progress data to the iOS home-screen
/// widget via a shared App Group container.
///
/// The iOS widget extension (bundle id: `com.aidiot.ddalgguk.GoalWidget`)
/// reads the same keys from `UserDefaults(suiteName: appGroupId)`.
class GoalHomeWidgetService {
  GoalHomeWidgetService._();

  static const String appGroupId = 'group.com.aidiot.ddalgguk';
  static const String iosWidgetName = 'DdalggukGoalWidget';

  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);
    _initialized = true;
  }

  /// Writes the goal state and triggers a widget reload.
  ///
  /// All numeric values use the same definitions as the profile
  /// [MonthlyGoalSection]: [budget] in won, [alcoholGoal] in 소주병
  /// (1병 = 360ml), [currentSpending] in won, [currentAlcohol] in 소주병.
  static Future<void> update({
    required bool hasGoal,
    required int monthNum,
    int? budget,
    double? alcoholGoal,
    required int currentSpending,
    required double currentAlcohol,
  }) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _ensureInit();
      await Future.wait([
        HomeWidget.saveWidgetData<bool>('has_goal', hasGoal),
        HomeWidget.saveWidgetData<int>('month_num', monthNum),
        HomeWidget.saveWidgetData<int>('goal_budget', budget ?? 0),
        HomeWidget.saveWidgetData<bool>('has_budget', budget != null),
        HomeWidget.saveWidgetData<double>(
          'goal_alcohol',
          alcoholGoal ?? 0.0,
        ),
        HomeWidget.saveWidgetData<bool>('has_alcohol', alcoholGoal != null),
        HomeWidget.saveWidgetData<int>('current_spending', currentSpending),
        HomeWidget.saveWidgetData<double>('current_alcohol', currentAlcohol),
        HomeWidget.saveWidgetData<int>(
          'updated_at',
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ]);
      await HomeWidget.updateWidget(iOSName: iosWidgetName);
    } catch (_) {
      // Best-effort: never let widget sync break the app.
    }
  }
}
