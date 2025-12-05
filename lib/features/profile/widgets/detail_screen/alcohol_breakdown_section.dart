import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/widgets/reusable_section.dart';
import 'package:ddalgguk/features/profile/widgets/detail_screen/alcohol_break_chart/semicircular_chart.dart';

import 'package:ddalgguk/core/constants/app_colors.dart';

class AlcoholBreakdownSection extends StatelessWidget {
  const AlcoholBreakdownSection({
    super.key,
    required this.stats,
    required this.theme,
  });

  final ProfileStats stats;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final breakdown = stats.breakdown;
    final today = DateFormat('MM.dd.').format(DateTime.now());

    return ProfileSection(
      title: '혈중 알콜 분해 현황',
      subtitle: SectionSubtitle(text: today),
      content: Column(
        children: [
          // Semicircular chart
          SemicircularChart(
            progress: breakdown.progressPercentage / 100,
            topLabel: stats.timeToSober <= 0
                ? '완전 분해 완료'
                : '완전 분해까지 ${_getTimeText(stats.timeToSober)}',
            bottomLabel: '${breakdown.alcoholRemaining.toStringAsFixed(3)}%',
            activeColor: theme.primaryColor,
            size: 280,
          ),
          const SizedBox(height: 24),
          // Message box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent, // No background
              borderRadius: BorderRadius.circular(30), // More rounded
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                // Message icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.secondaryColor, // Theme color background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .sentiment_very_satisfied_rounded, // Changed icon to match image roughly
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Message text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '간 회복은 훨씬 오래 걸려요!',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                      Text(
                        '72시간 이상 금주하면 간 효소 정상화에 도움이 돼요.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeText(double hours) {
    if (hours <= 0) {
      return '간 회복 완료';
    } else if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes분';
    } else {
      return '${hours.toStringAsFixed(1)}시간';
    }
  }
}
