import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/auth/domain/models/monthly_goal.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (context) => Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(color: Colors.black),
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 36),
                    tabs: const [
                      Tab(text: '음주 목표', height: 36),
                      Tab(text: '달성 현황', height: 36),
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
                    indicator: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
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

// ── 달성 현황 탭 ──────────────────────────────────────────────

class _AchievementTab extends ConsumerStatefulWidget {
  const _AchievementTab();

  @override
  ConsumerState<_AchievementTab> createState() => _AchievementTabState();
}

class _AchievementTabState extends ConsumerState<_AchievementTab> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final allGoals = userAsync.valueOrNull?.monthlyGoals ?? {};
    final now = DateTime.now();

    // Filter to months in the selected year that have a goal set
    final monthsWithGoals = List.generate(
      _year == now.year ? now.month : 12,
      (i) => i + 1,
    ).where((m) {
      final key = '$_year-${m.toString().padLeft(2, '0')}';
      return allGoals.containsKey(key);
    }).toList();

    return Column(
      children: [
        // Year navigation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left, size: 24),
                color: Colors.black,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                '$_year년',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _year < now.year
                    ? () => setState(() => _year++)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: _year < now.year ? Colors.black : Colors.grey[300],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (monthsWithGoals.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/imgs/goal_assets/goal_badge/goal_none.png',
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '설정하신 목표가 없어요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: monthsWithGoals.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF2F2F2),
              ),
              itemBuilder: (context, index) {
                final month = monthsWithGoals[index];
                final key = '$_year-${month.toString().padLeft(2, '0')}';
                final goal = allGoals[key]!;
                return _MonthRow(
                  month: month,
                  monthKey: DateTime(_year, month),
                  goal: goal,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MonthRow extends ConsumerWidget {
  const _MonthRow({
    required this.month,
    required this.monthKey,
    required this.goal,
  });

  final int month;
  final DateTime monthKey;
  final MonthlyGoal goal;

  String _badgeAsset(double spending, double alcohol) {
    final hasBudget = goal.budget != null;
    final hasAlcohol = goal.alcohol != null;
    final budgetMet = !hasBudget || spending <= goal.budget!;
    final alcoholMet = !hasAlcohol || alcohol <= goal.alcohol!;
    if (hasBudget && hasAlcohol) {
      if (budgetMet && alcoholMet) {
        return 'assets/imgs/goal_assets/goal_badge/goal_success.png';
      }
      if (budgetMet || alcoholMet) {
        return 'assets/imgs/goal_assets/goal_badge/goal_partly.png';
      }
      return 'assets/imgs/goal_assets/goal_badge/goal_fail.png';
    }
    final onlyMet = hasBudget ? budgetMet : alcoholMet;
    return onlyMet
        ? 'assets/imgs/goal_assets/goal_badge/goal_success.png'
        : 'assets/imgs/goal_assets/goal_badge/goal_fail.png';
  }

  String _formatBottle(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(monthlySpendingProvider(monthKey));
    final alcoholAsync = ref.watch(monthlyAlcoholBottlesProvider(monthKey));

    final spending = spendingAsync.valueOrNull?.toDouble() ?? 0.0;
    final alcohol = alcoholAsync.valueOrNull ?? 0.0;

    final budget = goal.budget;
    final alcoholGoal = goal.alcohol;

    final budgetOver = budget != null && spending > budget;
    final alcoholOver = alcoholGoal != null && alcohol > alcoholGoal;

    final budgetRatio = budget != null && budget > 0
        ? (spending / budget).clamp(0.0, 1.0)
        : 0.0;
    final alcoholRatio = alcoholGoal != null && alcoholGoal > 0
        ? (alcohol / alcoholGoal).clamp(0.0, 1.0)
        : 0.0;

    final currencyFmt = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(_badgeAsset(spending, alcohol), width: 32, height: 32),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              '$month월',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (budget != null) ...[
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${currencyFmt.format(spending.toInt())}원',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: budgetOver ? Colors.red[400] : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' /${currencyFmt.format(budget)}원',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MiniBar(ratio: budgetRatio, isOver: budgetOver),
                  if (alcoholGoal != null) const SizedBox(height: 10),
                ],
                if (alcoholGoal != null) ...[
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_formatBottle(alcohol)}병',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                alcoholOver ? Colors.red[400] : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' /${_formatBottle(alcoholGoal)}병',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MiniBar(ratio: alcoholRatio, isOver: alcoholOver),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.ratio, required this.isOver});

  final double ratio;
  final bool isOver;

  static const _green = Color(0xFF6DCC99);
  static const _red = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final barColor = isOver ? _red : _green;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = (totalWidth * ratio).clamp(0.0, totalWidth);
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: filledWidth,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: ratio >= 1.0
                    ? BorderRadius.circular(3)
                    : const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
