import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';

class AlcoholIntakeTab extends ConsumerStatefulWidget {
  const AlcoholIntakeTab({super.key});

  @override
  ConsumerState<AlcoholIntakeTab> createState() => _AlcoholIntakeTabState();
}

class _AlcoholIntakeTabState extends ConsumerState<AlcoholIntakeTab> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  DailySakuData? _selectedData;
  int? _selectedIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                        style: TextStyle(
                          color: Color(0xFFF27B7B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedData != null
                          ? '${_selectedData!.totalAlcoholMl.toInt()}g'
                          : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getWeekLabel(_currentIndex),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Chart Section with PageView
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              reverse: true,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _selectedData = null; // Reset selection on page change
                  _selectedIndex = null;
                });
              },
              itemBuilder: (context, index) {
                // Limit to 4 weeks for now
                if (index > 3) {
                  return null;
                }
                return _WeeklyChartPage(
                  offset: index,
                  selectedIndex: _selectedIndex,
                  onBarTouch: (data, index) {
                    setState(() {
                      _selectedData = data;
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          _buildStatsGrid(ref, _currentIndex),
          const SizedBox(height: 16),

          // Comparison Text
          _buildComparisonText(ref, _currentIndex),
          const SizedBox(height: 16),

          // Drink Type Breakdown
          _buildDrinkTypeBreakdown(ref, _currentIndex),
        ],
      ),
    );
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) {
      return '이번 주';
    }
    if (offset == 1) {
      return '지난 주';
    }
    return '$offset주 전';
  }

  Widget _buildStatsGrid(WidgetRef ref, int offset) {
    final statsAsync = ref.watch(weeklyStatsOffsetProvider(offset));

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

  Widget _buildComparisonText(WidgetRef ref, int offset) {
    // Need current and previous week stats
    final currentStatsAsync = ref.watch(weeklyStatsOffsetProvider(offset));
    final prevStatsAsync = ref.watch(weeklyStatsOffsetProvider(offset + 1));

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

  Widget _buildDrinkTypeBreakdown(WidgetRef ref, int offset) {
    final statsAsync = ref.watch(weeklyStatsOffsetProvider(offset));

    return statsAsync.when(
      data: (stats) {
        final drinkTypes = stats.drinkTypeStats;
        // Sort by amount descending
        drinkTypes.sort((a, b) => b.totalAmountMl.compareTo(a.totalAmountMl));

        // Take top 3 and fill with default if needed
        final displayItems = <DrinkTypeStat>[];
        displayItems.addAll(drinkTypes.take(3));

        // Fill with default empty items if less than 3
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
            : 1.0; // Avoid division by zero

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
                      iconPath: _getDrinkTypeIconPath(
                        displayItems[i].drinkType,
                      ),
                      name: _getDrinkTypeName(displayItems[i].drinkType),
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

  String _getDrinkTypeName(int type) {
    switch (type) {
      case 1:
        return '소주';
      case 2:
        return '맥주';
      case 3:
        return '와인';
      case 4:
        return '칵테일';
      case 5:
        return '막걸리';
      default:
        return '기타';
    }
  }

  String _getDrinkTypeIconPath(int type) {
    switch (type) {
      case 1:
        return 'assets/alcohol_icons/soju.png';
      case 2:
        return 'assets/alcohol_icons/beer.png';
      case 3:
        return 'assets/alcohol_icons/wine.png';
      case 4:
        return 'assets/alcohol_icons/cocktail.png';
      case 5:
        return 'assets/alcohol_icons/makgulli.png';
      default:
        return 'assets/alcohol_icons/undecided.png';
    }
  }
}

class _WeeklyChartPage extends ConsumerWidget {
  const _WeeklyChartPage({
    required this.offset,
    this.onBarTouch,
    this.selectedIndex,
  });

  final int offset;
  final Function(DailySakuData?, int?)? onBarTouch;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsOffsetProvider(offset));

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
                  // Only handle tap events (click/touch release)
                  if (event is FlTapUpEvent) {
                    if (barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      return;
                    }
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < stats.dailyData.length) {
                      // Toggle: if same index clicked, deselect. Otherwise select new
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
                      final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
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
        // Use totalAlcoholMl instead of drunkLevel
        final value = dailyData[index].totalAlcoholMl;
        final isSelected = selectedIndex == index;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: isSelected
                  ? _getBarColor(
                      dailyData[index].drunkLevel,
                    ).withValues(alpha: 1.0)
                  : _getBarColor(
                      dailyData[index].drunkLevel,
                    ).withValues(alpha: 0.6),
              width: 24,
              borderRadius: BorderRadius.circular(4), // Reduced border radius
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY, // Max height background
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
      return const Color(0xFF52E370); // Green
    }
    if (level <= 60) {
      return const Color(0xFFFFD54F); // Yellow
    }
    return const Color(0xFFFF0000); // Red
  }
}

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
        // Rank
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: rank == 1 ? Colors.amber : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(iconPath, width: 20, height: 20),
        ),
        const SizedBox(width: 12),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  color: Colors.grey[400], // Design shows grey bar
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
