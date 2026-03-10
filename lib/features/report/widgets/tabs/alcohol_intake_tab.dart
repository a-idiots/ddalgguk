import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';

class AlcoholIntakeTab extends ConsumerStatefulWidget {
  const AlcoholIntakeTab({super.key});

  @override
  ConsumerState<AlcoholIntakeTab> createState() => _AlcoholIntakeTabState();
}

class _AlcoholIntakeTabState extends ConsumerState<AlcoholIntakeTab> {
  DailySakuData? _selectedData;
  int? _selectedIndex;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedWeekMonday = _thisWeekMonday();

  static DateTime _thisWeekMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Returns all Mondays within [year]/[month] that are ≤ today's Monday.
  List<DateTime> _weeksInMonth(int year, int month) {
    final todayMonday = _thisWeekMonday();
    final List<DateTime> weeks = [];
    final firstOfMonth = DateTime(year, month, 1);
    // Days until the first Monday on or after the 1st
    final daysUntilMonday = (8 - firstOfMonth.weekday) % 7;
    DateTime current = firstOfMonth.add(Duration(days: daysUntilMonday));
    while (current.month == month) {
      if (!current.isAfter(todayMonday)) {
        weeks.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 7));
    }
    return weeks;
  }

  void _prevMonth() {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final weeks = _weeksInMonth(newMonth.year, newMonth.month);
    setState(() {
      _selectedMonth = newMonth;
      _selectedWeekMonday = weeks.isNotEmpty ? weeks.last : _thisWeekMonday();
      _selectedData = null;
      _selectedIndex = null;
    });
  }

  void _nextMonth() {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final now = DateTime.now();
    final isCurrentMonth =
        newMonth.year == now.year && newMonth.month == now.month;
    setState(() {
      _selectedMonth = newMonth;
      _selectedWeekMonday = isCurrentMonth
          ? _thisWeekMonday()
          : _weeksInMonth(newMonth.year, newMonth.month).first;
      _selectedData = null;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final weeks = _weeksInMonth(_selectedMonth.year, _selectedMonth.month);
    final weekIndex = weeks.indexOf(_selectedWeekMonday);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: const Icon(Icons.chevron_left, size: 24),
              ),
              Text(
                '${_selectedMonth.year}년 ${_selectedMonth.month}월',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: isCurrentMonth ? null : _nextMonth,
                child: Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: isCurrentMonth ? Colors.grey[400] : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Week dropdown
          Align(
            alignment: Alignment.centerRight,
            child: _WeekDropdown(
              weeks: weeks,
              selectedIndex: weekIndex,
              onSelected: (index) {
                setState(() {
                  _selectedWeekMonday = weeks[index];
                  _selectedData = null;
                  _selectedIndex = null;
                });
              },
            ),
          ),
          const SizedBox(height: 4),

          // Selected bar alcohol display
          AnimatedOpacity(
            opacity: _selectedData != null ? 1.0 : 0.0,
            duration: _selectedData != null
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            curve: Curves.easeInOut,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '순수 알코올',
                    style: TextStyle(color: Color(0xFFF27B7B), fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedData != null
                      ? '${_selectedData!.totalAlcoholMl.toInt()}g'
                      : '',
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Chart
          SizedBox(
            height: 200,
            child: _WeeklyChartPage(
              monday: _selectedWeekMonday,
              selectedIndex: _selectedIndex,
              onBarTouch: (data, index) {
                setState(() {
                  _selectedData = data;
                  _selectedIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          _buildStatsGrid(_selectedWeekMonday),
          const SizedBox(height: 16),

          _buildComparisonText(_selectedWeekMonday),
          const SizedBox(height: 16),

          _buildDrinkTypeBreakdown(_selectedWeekMonday),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DateTime monday) {
    final statsAsync = ref.watch(weeklyStatsByMondayProvider(monday));

    return statsAsync.when(
      data: (stats) {
        return Row(
          children: [
            Expanded(
              child: _StatBox(
                icon: Icons.local_drink,
                color: Colors.red,
                label: '총 음주량',
                value: '${stats.totalAlcoholMl.toInt()}',
                unit: 'ml',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                icon: Icons.water_drop,
                color: Colors.red,
                label: '순수 알코올',
                value: '${stats.totalPureAlcoholMl.toInt()}',
                unit: 'g',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                icon: Icons.wine_bar,
                color: Colors.red,
                label: '주 평균 음주량',
                value: '${(stats.totalAlcoholMl / 7).toInt()}',
                unit: 'ml',
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildComparisonText(DateTime monday) {
    final prevMonday = monday.subtract(const Duration(days: 7));
    final currentStatsAsync = ref.watch(weeklyStatsByMondayProvider(monday));
    final prevStatsAsync = ref.watch(weeklyStatsByMondayProvider(prevMonday));

    if (currentStatsAsync.isLoading || prevStatsAsync.isLoading) {
      return const SizedBox.shrink();
    }
    if (currentStatsAsync.hasError || prevStatsAsync.hasError) {
      return const SizedBox.shrink();
    }

    final currentStats = currentStatsAsync.value!;
    final prevStats = prevStatsAsync.value!;
    final diff = currentStats.totalAlcoholMl - prevStats.totalAlcoholMl;
    final isMore = diff > 0;
    final diffAbs = diff.abs().toInt();

    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: [
            const TextSpan(text: '이번 주는 지난 주보다 '),
            TextSpan(
              text: '${diffAbs}ml',
              style: const TextStyle(color: Colors.red),
            ),
            TextSpan(text: isMore ? ' 더 마시고 있어요!' : ' 덜 마셨어요!'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkTypeBreakdown(DateTime monday) {
    final statsAsync = ref.watch(weeklyStatsByMondayProvider(monday));

    return statsAsync.when(
      data: (stats) {
        final drinkTypes = stats.drinkTypeStats;
        drinkTypes.sort((a, b) => b.totalAmountMl.compareTo(a.totalAmountMl));

        final displayItems = <DrinkTypeStat>[];
        displayItems.addAll(drinkTypes.take(3));
        while (displayItems.length < 3) {
          displayItems.add(
            const DrinkTypeStat(
              drinkType: 0,
              totalAmountMl: 0,
              maxAmountMl: 0,
              pureAlcoholMl: 0,
            ),
          );
        }

        final maxAmount =
            displayItems.isNotEmpty && displayItems.first.totalAmountMl > 0
                ? displayItems.first.totalAmountMl
                : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주종별 섭취량 TOP 3',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  for (int i = 0; i < displayItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _DrinkTypeRow(
                      rank: i + 1,
                      iconPath: getDrinkIconPath(displayItems[i].drinkType),
                      name: getDrinkTypeName(displayItems[i].drinkType),
                      amount: displayItems[i].totalAmountMl.toInt(),
                      maxAmount: maxAmount.toInt(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Week Dropdown ─────────────────────────────────────────────

class _WeekDropdown extends StatefulWidget {
  const _WeekDropdown({
    required this.weeks,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DateTime> weeks;
  final int selectedIndex;
  final void Function(int index) onSelected;

  @override
  State<_WeekDropdown> createState() => _WeekDropdownState();
}

class _WeekDropdownState extends State<_WeekDropdown> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlay;

  void _showMenu() {
    if (_overlay != null) {
      return;
    }

    final renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final pos = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    _overlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        onTap: _removeMenu,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned(
              right: screenSize.width - (pos.dx + size.width),
              top: pos.dy + size.height + 8,
              width: 120,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.weeks.asMap().entries.map((entry) {
                        final i = entry.key;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (i > 0)
                              Divider(height: 1, color: Colors.grey[200]),
                            InkWell(
                              onTap: () {
                                _removeMenu();
                                widget.onSelected(i);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    '${i + 1}주차',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _removeMenu() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weeks.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('데이터 없음', style: TextStyle(fontSize: 12)),
      );
    }

    final label = widget.selectedIndex >= 0
        ? '${widget.selectedIndex + 1}주차'
        : '${widget.weeks.length}주차';

    return GestureDetector(
      key: _key,
      onTap: _showMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Chart Page ────────────────────────────────────────────────

class _WeeklyChartPage extends ConsumerWidget {
  const _WeeklyChartPage({
    required this.monday,
    this.onBarTouch,
    this.selectedIndex,
  });

  final DateTime monday;
  final Function(DailySakuData?, int?)? onBarTouch;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsByMondayProvider(monday));

    return statsAsync.when(
      data: (stats) {
        final maxVal = _calculateMaxY(
          stats.dailyData.map((d) => d.totalAlcoholMl).toList(),
        );

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              barTouchData: BarTouchData(
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent) {
                    if (barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      return;
                    }
                    final index =
                        barTouchResponse.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < stats.dailyData.length) {
                      if (selectedIndex == index) {
                        onBarTouch?.call(null, null);
                      } else {
                        onBarTouch?.call(stats.dailyData[index], index);
                      }
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
                ),
              ),
              barGroups: _buildBarGroups(stats.dailyData, maxVal),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: maxVal,
                    color: Colors.grey[200],
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: HorizontalLineLabel(show: false),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
                      if (value.toInt() < dayNames.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dayNames[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 100 == 0 || value == maxVal) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 100,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200],
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  double _calculateMaxY(List<double> values) {
    if (values.isEmpty) {
      return 100;
    }
    final max = values.reduce((a, b) => a > b ? a : b);
    final target = max + 50;
    return (target / 50).ceil() * 50.0;
  }

  List<BarChartGroupData> _buildBarGroups(
    List<DailySakuData> dailyData,
    double maxY,
  ) {
    return List.generate(7, (index) {
      if (index < dailyData.length) {
        final value = dailyData[index].totalAlcoholMl;
        final isSelected = selectedIndex == index;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: isSelected
                  ? _getBarColor(dailyData[index].drunkLevel)
                      .withValues(alpha: 1.0)
                  : _getBarColor(dailyData[index].drunkLevel)
                      .withValues(alpha: 0.6),
              width: 24,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: Colors.transparent,
              ),
            ),
          ],
        );
      }
      return BarChartGroupData(x: index, barRods: []);
    });
  }

  Color _getBarColor(int level) {
    if (level <= 30) {
      return const Color(0xFFFF0000);
    }
    if (level <= 60) {
      return const Color(0xFFFFD54F);
    }
    return const Color(0xFF52E370);
  }
}

// ── Stat Box ──────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drink Type Row ────────────────────────────────────────────

class _DrinkTypeRow extends StatelessWidget {
  const _DrinkTypeRow({
    required this.rank,
    required this.iconPath,
    required this.name,
    required this.amount,
    required this.maxAmount,
  });

  final int rank;
  final String iconPath;
  final String name;
  final int amount;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 16,
              color: rank == 1 ? Colors.amber : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(iconPath, width: 20, height: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name),
                  Text(
                    '${amount}ml',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: amount / maxAmount,
                  backgroundColor: Colors.grey[200],
                  color: Colors.grey[400],
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
