import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/dialogs/goal_edit_sheet.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '음주 목표'),
            Tab(text: '달성 현황'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalTab(),
          const _AchievementTab(),
        ],
      ),
    );
  }
}

// ── 음주 목표 탭 ─────────────────────────────────────────────

class _GoalTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final now = DateTime.now();
    final monthNum = now.month;
    final monthKey = DateTime(now.year, now.month);

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

        return _GoalTabContent(
          monthNum: monthNum,
          budget: budget,
          alcoholGoal: alcoholGoal,
          currentSpending: currentSpending,
          currentAlcohol: currentAlcohol,
          avgDrinkSpending: avgSpending,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GoalTabContent extends StatelessWidget {
  const _GoalTabContent({
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

  String _formatCurrency(int amount) =>
      '${NumberFormat('#,###').format(amount)}원';

  String _formatBottle(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final budgetOver = budget != null && currentSpending > budget!;
    final alcoholOver =
        alcoholGoal != null && currentAlcohol > alcoholGoal!;

    // 예산 계산
    final budgetRemaining =
        budget != null ? (budget! - currentSpending) : 0;
    final budgetOverAmount =
        budget != null ? (currentSpending - budget!).clamp(0, currentSpending) : 0;
    final sessionsLeft = budget != null
        ? (budgetRemaining / avgDrinkSpending)
            .floor()
            .clamp(0, double.maxFinite.toInt())
        : 0;

    // 음주량 계산 (1/10단위 정수 연산)
    final goalTenths =
        alcoholGoal != null ? (alcoholGoal! * 10).round() : 0;
    final currentTenths = (currentAlcohol * 10).round();
    final diffTenths = goalTenths - currentTenths; // 양수 = 남음, 음수 = 초과

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 예산 섹션 ──
                if (budget != null) ...[
                  _GoalSection(
                    title: '$monthNum월 예산',
                    summaryText: budgetOver
                        ? '${_formatCurrency(budgetOverAmount)} 초과'
                        : '${_formatCurrency(budgetRemaining)} 남음',
                    summaryIsOver: budgetOver,
                    ratio: budget! > 0
                        ? (currentSpending / budget!).clamp(0.0, 1.0)
                        : 0.0,
                    markerLabel: _formatCurrency(currentSpending),
                    barColor: const Color(0xFFF7B6B6),
                    isOverGoal: budgetOver,
                    legendItems: [
                      _LegendItem(
                        filled: false,
                        label: '$monthNum월 예산',
                        value: _formatCurrency(budget!),
                      ),
                      _LegendItem(
                        filled: true,
                        label: '예산 내 가능 술자리',
                        value: '$sessionsLeft회',
                      ),
                      _LegendItem(
                        filled: true,
                        label: '총 지출 금액',
                        value: _formatCurrency(currentSpending),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // ── 음주량 섹션 ──
                if (alcoholGoal != null) ...[
                  _GoalSection(
                    title: '$monthNum월 목표 음주량',
                    summaryText: alcoholOver
                        ? '${_formatBottle((-diffTenths) / 10.0)}병 초과'
                        : '${_formatBottle(diffTenths / 10.0)}병 남음',
                    summaryIsOver: alcoholOver,
                    ratio: alcoholGoal! > 0
                        ? (currentAlcohol / alcoholGoal!).clamp(0.0, 1.0)
                        : 0.0,
                    markerLabel: '${_formatBottle(currentAlcohol)}병',
                    barColor: const Color(0xFFADE4C3),
                    isOverGoal: alcoholOver,
                    legendItems: [
                      _LegendItem(
                        filled: false,
                        label: '$monthNum월 목표 음주량',
                        value: '${_formatBottle(alcoholGoal!)}병',
                      ),
                      _LegendItem(
                        filled: true,
                        label: '총 음주량',
                        value: '${_formatBottle(currentAlcohol)}병',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── 수정하기 버튼 ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _openEditSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '수정하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final monthNum = DateTime.now().month;
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

// ── 섹션 위젯 ─────────────────────────────────────────────────

class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.title,
    required this.summaryText,
    required this.summaryIsOver,
    required this.ratio,
    required this.markerLabel,
    required this.barColor,
    required this.isOverGoal,
    required this.legendItems,
  });

  final String title;
  final String summaryText;
  final bool summaryIsOver;
  final double ratio;
  final String markerLabel;
  final Color barColor;
  final bool isOverGoal;
  final List<_LegendItem> legendItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          summaryText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: summaryIsOver ? Colors.red[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _ProgressBar(
          ratio: ratio,
          barColor: isOverGoal ? Colors.red[400]! : barColor,
          markerLabel: markerLabel,
          showMarker: !isOverGoal,
        ),
        const SizedBox(height: 12),
        ...legendItems.map((item) => _LegendRow(item: item)),
      ],
    );
  }
}

// ── 프로그레스 바 ─────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.ratio,
    required this.barColor,
    required this.markerLabel,
    this.showMarker = true,
  });

  final double ratio;
  final Color barColor;
  final String markerLabel;
  final bool showMarker;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = totalWidth * ratio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
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
                if (showMarker && ratio > 0 && ratio < 1)
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
            if (showMarker && ratio > 0) ...[
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
  bool shouldRelayout(_MarkerLabelDelegate old) =>
      old.filledWidth != filledWidth || old.totalWidth != totalWidth;
}

// ── 범례 ────────────────────────────────────────────────────

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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.filled ? Colors.grey[400] : null,
              border: item.filled
                  ? null
                  : Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// ── 달성 현황 탭 (미구현) ──────────────────────────────────────

class _AchievementTab extends StatelessWidget {
  const _AchievementTab();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
