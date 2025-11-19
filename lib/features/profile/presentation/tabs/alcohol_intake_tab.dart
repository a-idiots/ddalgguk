import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';

class AlcoholIntakeTab extends ConsumerWidget {
  const AlcoholIntakeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);

    return weeklyStatsAsync.when(
      data: (weeklyStats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with main stat
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF27B7B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '순수 알코올(에탄올)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF27B7B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${weeklyStats.totalAlcoholMl.toStringAsFixed(1)} ml',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This week',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Bar chart
              const Text(
                '주간 음주량',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calculateMaxY(
                      weeklyStats.dailyData
                          .map((d) => d.drunkLevel.toDouble())
                          .toList(),
                    ),
                    barGroups: _buildBarGroups(weeklyStats.dailyData),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final dayNames = [
                              '월',
                              '화',
                              '수',
                              '목',
                              '금',
                              '토',
                              '일',
                            ];
                            if (value.toInt() < dayNames.length) {
                              return Text(
                                dayNames[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_activity,
                      iconColor: const Color(0xFFF27B7B),
                      title: '총 음주량',
                      value:
                          '${weeklyStats.totalAlcoholMl.toStringAsFixed(0)} ml',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF52A3E3),
                      title: '순수 알코올',
                      value:
                          '${(weeklyStats.totalAlcoholMl * 0.789).toStringAsFixed(0)} g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.calendar_today,
                iconColor: const Color(0xFF52E370),
                title: '금주 일수',
                value: '${weeklyStats.soberDays}일',
                subtitle: '이번 주 ${weeklyStats.soberDays}일 금주 성공',
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading data: $error')),
    );
  }

  double _calculateMaxY(List<double> values) {
    if (values.isEmpty) {
      return 100;
    }
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _buildBarGroups(List<DailySakuData> dailyData) {
    return List.generate(7, (index) {
      if (index < dailyData.length) {
        final drunkLevel = dailyData[index].drunkLevel.toDouble();
        final hasRecords = dailyData[index].hasRecords;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: hasRecords ? drunkLevel : 0,
              color: _getBarColor(dailyData[index].drunkLevel),
              width: 24,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
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
    } else if (level <= 60) {
      return const Color(0xFFFFA552); // Orange
    } else {
      return const Color(0xFFF27B7B); // Red
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}
