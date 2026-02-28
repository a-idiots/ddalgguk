import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/dialogs/goal_edit_sheet.dart';

/// 월 음주 목표 현황 바텀 시트 (유료 사용자용)
class GoalBottomSheet extends ConsumerWidget {
  const GoalBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final now = DateTime.now();
    final monthNum = now.month;
    final monthKey = DateTime(now.year, now.month);

    // 최상위에서 watch해야 변경 시 즉시 반영됨
    final spendingAsync = ref.watch(monthlySpendingProvider(monthKey));
    final alcoholAsync = ref.watch(currentMonthAlcoholBottlesProvider);
    final avgSpendingAsync = ref.watch(prevMonthAvgSpendingProvider);

    return userAsync.when(
      data: (user) {
        final budget = user?.monthlyGoalBudget;
        final alcoholGoal = user?.monthlyGoalAlcohol;

        final currentSpending = spendingAsync.valueOrNull ?? 0;
        final currentAlcohol = alcoholAsync.valueOrNull ?? 0.0;
        final avgSpending = avgSpendingAsync.valueOrNull ?? 30000.0;

        return _GoalBottomSheetContent(
          monthNum: monthNum,
          budget: budget,
          alcoholGoal: alcoholGoal,
          currentSpending: currentSpending,
          currentAlcohol: currentAlcohol,
          avgDrinkSpending: avgSpending,
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GoalBottomSheetContent extends StatelessWidget {
  const _GoalBottomSheetContent({
    required this.monthNum,
    required this.budget,
    required this.alcoholGoal,
    required this.currentSpending,
    required this.currentAlcohol,
    required this.avgDrinkSpending,
  });

  final int monthNum;
  final int? budget;
  final double? alcoholGoal;
  final int currentSpending;
  final double currentAlcohol;
  final double avgDrinkSpending;

  String get _remainingAlcoholText {
    if (alcoholGoal == null) {
      return '';
    }
    final remaining = (alcoholGoal! - currentAlcohol).clamp(0.0, alcoholGoal!);
    return '${_formatBottle(remaining)}병';
  }

  String _formatBottle(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  String _estimatedSessionsInBudget() {
    if (budget == null) {
      return '0회';
    }
    final sessions = (budget! / avgDrinkSpending).floor();
    return '약 $sessions회';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              '음주 목표 설정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            // Budget section
            if (budget != null) ...[
              _GoalProgressSection(
                title: '$monthNum월 예산',
                subtitle: budget! - currentSpending > 0
                    ? '${currencyFmt.format(budget! - currentSpending)}원 남음'
                    : '예산 초과',
                current: currentSpending.toDouble(),
                goal: budget!.toDouble(),
                markerLabel: '${currencyFmt.format(currentSpending)}원',
                barColor: const Color(0xFFF7B6B6),
                legendItems: [
                  _LegendItem(
                    filled: false,
                    label: '$monthNum월 예산',
                    value: '${currencyFmt.format(budget!)}원',
                  ),
                  _LegendItem(
                    filled: true,
                    label: '예산 내 가능 술자리',
                    value: _estimatedSessionsInBudget(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Alcohol section
            if (alcoholGoal != null) ...[
              _GoalProgressSection(
                title: '$monthNum월 목표 음주량',
                subtitle: _remainingAlcoholText.isNotEmpty
                    ? '소주 $_remainingAlcoholText 남음'
                    : null,
                current: currentAlcohol,
                goal: alcoholGoal!,
                markerLabel: '${_formatBottle(currentAlcohol)}병',
                barColor: const Color(0xFFADE4C3),
                legendItems: [
                  _LegendItem(
                    filled: false,
                    label: '$monthNum월 목표 음주량',
                    value: '${_formatBottle(alcoholGoal!)}병',
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),

            // 수정하기 button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _openEditSheet(context, budget, alcoholGoal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '수정하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    int? budget,
    double? alcoholGoal,
  ) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalEditSheet(
        initialBudget: budget,
        initialAlcohol: alcoholGoal,
        monthLabel: '$monthNum월',
      ),
    );
  }
}

class _GoalProgressSection extends StatelessWidget {
  const _GoalProgressSection({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.goal,
    required this.markerLabel,
    required this.barColor,
    required this.legendItems,
  });

  final String title;
  final String? subtitle;
  final double current;
  final double goal;
  final String markerLabel;
  final Color barColor;
  final List<_LegendItem> legendItems;

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          // Progress bar with marker
          _ProgressBar(
            ratio: ratio,
            barColor: barColor,
            markerLabel: markerLabel,
          ),
          const SizedBox(height: 12),
          // Legend
          ...legendItems.map((item) => _LegendRow(item: item)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.ratio,
    required this.barColor,
    required this.markerLabel,
  });

  final double ratio;
  final Color barColor;
  final String markerLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = totalWidth * ratio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // Filled
                Container(
                  width: filledWidth.clamp(0.0, totalWidth),
                  height: 10,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: ratio >= 1.0
                        ? BorderRadius.circular(5)
                        : const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          ),
                  ),
                ),
                // Marker line
                if (ratio > 0 && ratio < 1)
                  Positioned(
                    left: filledWidth - 0.5,
                    top: -2,
                    child: Container(
                      width: 1,
                      height: 14,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Marker label below bar at marker position
            if (ratio > 0)
              SizedBox(
                height: 22,
                child: CustomSingleChildLayout(
                  delegate: _MarkerLabelDelegate(
                    filledWidth: filledWidth,
                    totalWidth: totalWidth,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      markerLabel,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11,
                        color: barColor
                            .withRed((barColor.r * 0.7).round())
                            .withGreen((barColor.g * 0.7).round())
                            .withBlue((barColor.b * 0.7).round()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MarkerLabelDelegate extends SingleChildLayoutDelegate {
  const _MarkerLabelDelegate({
    required this.filledWidth,
    required this.totalWidth,
  });

  final double filledWidth;
  final double totalWidth;

  @override
  Size getSize(BoxConstraints constraints) => constraints.biggest;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: totalWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final idealLeft = filledWidth - childSize.width / 2;
    final left = idealLeft.clamp(0.0, totalWidth - childSize.width);
    return Offset(left, (size.height - childSize.height) / 2);
  }

  @override
  bool shouldRelayout(_MarkerLabelDelegate oldDelegate) =>
      oldDelegate.filledWidth != filledWidth ||
      oldDelegate.totalWidth != totalWidth;
}

class _LegendItem {
  const _LegendItem({
    required this.filled,
    required this.label,
    required this.value,
  });

  final bool filled;
  final String label;
  final String value;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.item});

  final _LegendItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.filled ? Colors.grey[400] : null,
              border: item.filled ? null : Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            item.value,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
