import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/dialogs/goal_bottom_sheet.dart';
import 'package:ddalgguk/features/profile/widgets/dialogs/goal_edit_sheet.dart';

class MonthlyGoalSection extends ConsumerWidget {
  const MonthlyGoalSection({super.key, required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final proAsync = ref.watch(proProvider);
    final now = DateTime.now();
    final monthNum = now.month;
    final monthKey = DateTime(now.year, now.month);

    // 현재 월 데이터 (목표 있을 때만 사용)
    final spendingAsync = ref.watch(monthlySpendingProvider(monthKey));
    final alcoholAsync = ref.watch(currentMonthAlcoholBottlesProvider);
    final avgSpendingAsync = ref.watch(prevMonthAvgSpendingProvider);

    return userAsync.when(
      skipLoadingOnReload: true,
      data: (user) {
        final budget = user?.monthlyGoalBudget;
        final alcoholGoal = user?.monthlyGoalAlcohol;
        final hasGoal = budget != null || alcoholGoal != null;
        final isPro = proAsync.valueOrNull ?? false;

        final currentSpending = spendingAsync.valueOrNull ?? 0;
        final currentAlcohol = alcoholAsync.valueOrNull ?? 0.0;
        final avgSpending = avgSpendingAsync.valueOrNull ?? 30000.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 목표가 설정된 경우에만 요약 텍스트 표시
            if (hasGoal) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _GoalSummaryText(
                  budget: budget,
                  alcoholGoal: alcoholGoal,
                  currentSpending: currentSpending,
                  currentAlcohol: currentAlcohol,
                  avgDrinkSpending: avgSpending,
                ),
              ),
            ],
            // 카드
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$monthNum월달 음주 잔고',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 22),
                          color: Colors.grey[500],
                          onPressed: () => _onEditTapped(
                            context,
                            ref,
                            isPro,
                            budget,
                            alcoholGoal,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  if (!hasGoal)
                    _EmptyGoalContent()
                  else
                    _GoalProgressContent(
                      monthNum: monthNum,
                      budget: budget,
                      alcoholGoal: alcoholGoal,
                      currentSpending: currentSpending,
                      currentAlcohol: currentAlcohol,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _onEditTapped(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
    int? budget,
    double? alcoholGoal,
  ) {
    if (!isPro) {
      _showProDialog(context);
      return;
    }

    final hasGoal = budget != null || alcoholGoal != null;
    if (hasGoal) {
      // 이미 목표가 설정됨 → 현황 바텀시트 표시
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GoalBottomSheet(),
      );
    } else {
      // 목표 미설정 → 바로 입력 시트 표시
      final monthNum = DateTime.now().month;
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GoalEditSheet(monthLabel: '$monthNum월'),
      );
    }
  }

  void _showProDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'DDALGGUK PRO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('음주 목표 설정은 PRO 기능이에요.\n구독 또는 1회 결제로 이용할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: Color(0xFFF0A9A9))),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Text(
          '아직 설정한 목표가 없습니다.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }
}

class _GoalSummaryText extends StatelessWidget {
  const _GoalSummaryText({
    required this.budget,
    required this.alcoholGoal,
    required this.currentSpending,
    required this.currentAlcohol,
    required this.avgDrinkSpending,
  });

  final int? budget;
  final double? alcoholGoal;
  final int currentSpending;
  final double currentAlcohol;
  final double avgDrinkSpending;

  String _formatBottle(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];

    if (budget != null) {
      final remaining = (budget! - currentSpending).clamp(0, budget!);
      final sessions = (remaining / avgDrinkSpending).floor();
      spans.addAll([
        const TextSpan(text: '술자리 '),
        TextSpan(
          text: '$sessions번',
          style: const TextStyle(
            color: Color(0xFFF27B7B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ]);
    }

    if (alcoholGoal != null) {
      final remaining = (alcoholGoal! - currentAlcohol).clamp(
        0.0,
        alcoholGoal!,
      );
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(text: ' / '));
      }
      spans.addAll([
        const TextSpan(text: '소주 '),
        TextSpan(
          text: '${_formatBottle(remaining)}병',
          style: const TextStyle(
            color: Color(0xFFF27B7B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ]);
    }

    spans.add(const TextSpan(text: '\n남았습니다.'));

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        children: spans,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _GoalProgressContent extends StatelessWidget {
  const _GoalProgressContent({
    required this.monthNum,
    required this.budget,
    required this.alcoholGoal,
    required this.currentSpending,
    required this.currentAlcohol,
  });

  final int monthNum;
  final int? budget;
  final double? alcoholGoal;
  final int currentSpending;
  final double currentAlcohol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (budget != null) ...[
            _BarRow(
              label: '지출액',
              ratio: budget! > 0
                  ? (currentSpending / budget!).clamp(0.0, 1.0)
                  : 0.0,
              markerLabel: _formatCurrency(currentSpending),
              barColor: const Color(0xFFF7B6B6),
            ),
            const SizedBox(height: 20),
          ],
          if (alcoholGoal != null) ...[
            _BarRow(
              label: '음주량',
              ratio: alcoholGoal! > 0
                  ? (currentAlcohol / alcoholGoal!).clamp(0.0, 1.0)
                  : 0.0,
              markerLabel: '${_formatBottle(currentAlcohol)}병',
              barColor: const Color(0xFFADE4C3),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${NumberFormat('#,###').format(amount)}원';
  }

  String _formatBottle(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.ratio,
    required this.markerLabel,
    required this.barColor,
  });

  final String label;
  final double ratio;
  final String markerLabel;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final filledWidth = totalWidth * ratio;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background bar
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Filled bar
                    Container(
                      width: filledWidth.clamp(0.0, totalWidth),
                      height: 10,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.only(
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
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                ),
                if (ratio > 0) ...[
                  const SizedBox(height: 6),
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
              ],
            );
          },
        ),
      ],
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
