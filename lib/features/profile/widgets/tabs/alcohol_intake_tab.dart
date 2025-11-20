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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '순수 알코올(에탄올)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart Section with PageView
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              reverse: true, // Page 0 is rightmost (This week)
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                // Limit to 4 weeks for now
                if (index > 3) {
                  return null;
                }
                return _WeeklyChartPage(offset: index);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          _buildStatsGrid(ref, _currentIndex),
          const SizedBox(height: 24),

          // Comparison Text
          _buildComparisonText(ref, _currentIndex),
          const SizedBox(height: 32),

          // Drink Type Breakdown
          _buildDrinkTypeBreakdown(ref, _currentIndex),
        ],
      ),
    );
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) {
      return 'This week';
    }
    if (offset == 1) {
      return 'Last week';
    }
    return '$offset weeks ago';
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
                value: '${(stats.totalAlcoholMl * 0.789).toInt()}',
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
    // Mock data for breakdown
    final drinkTypes = [
      {
        'name': '소주',
        'amount': 8310,
        'max': 10000,
        'color': Colors.green,
        'icon': Icons.local_drink,
      },
      {
        'name': '맥주',
        'amount': 1001,
        'max': 10000,
        'color': Colors.amber,
        'icon': Icons.sports_bar,
      },
      {
        'name': '와인',
        'amount': 830,
        'max': 10000,
        'color': Colors.red,
        'icon': Icons.wine_bar,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주종별 섭취량 TOP 3',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < drinkTypes.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _DrinkTypeRow(
                  rank: i + 1,
                  icon: drinkTypes[i]['icon'] as IconData,
                  color: drinkTypes[i]['color'] as Color,
                  name: drinkTypes[i]['name'] as String,
                  amount: drinkTypes[i]['amount'] as int,
                  maxAmount: drinkTypes[i]['max'] as int,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyChartPage extends ConsumerWidget {
  const _WeeklyChartPage({required this.offset});

  final int offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsOffsetProvider(offset));

    return statsAsync.when(
      data: (stats) {
        final maxVal = _calculateMaxY(
          stats.dailyData.map((d) => d.drunkLevel.toDouble()).toList(),
        );

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              barGroups: _buildBarGroups(stats.dailyData),
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
                      if (value % 100 == 0) {
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
      return 400;
    }
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max > 400 ? max * 1.2 : 400).toDouble();
  }

  List<BarChartGroupData> _buildBarGroups(List<DailySakuData> dailyData) {
    return List.generate(7, (index) {
      if (index < dailyData.length) {
        // Use a multiplier to make bars taller for visualization if needed
        // Assuming drunkLevel is 0-100, but chart shows up to 400.
        // Maybe mapping drunkLevel to ml? Or just using drunkLevel as is?
        // The design shows bars going up to 400. Let's assume drunkLevel is scaled or we use ml if available.
        // DailySakuData has drunkLevel (int). Let's use it directly for now, scaled up x4 for visual match with 400 scale
        final value = dailyData[index].drunkLevel.toDouble() * 4;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: _getBarColor(dailyData[index].drunkLevel),
              width: 24,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(12),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 400, // Max height background
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
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
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
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
    required this.icon,
    required this.color,
    required this.name,
    required this.amount,
    required this.maxAmount,
  });

  final int rank;
  final IconData icon;
  final Color color;
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
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
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
