import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/features/profile/domain/models/profile_stats.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/reusable_section.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/semicircular_chart.dart';

class AlcoholBreakdownSection extends StatelessWidget {
  const AlcoholBreakdownSection({
    super.key,
    required this.stats,
  });

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final breakdown = stats.breakdown;
    final today = DateFormat('M월 d일').format(DateTime.now());

    return ProfileSection(
      title: '혈중 알콜 분해 현황',
      subtitle: SectionSubtitle(text: today),
      content: Column(
        children: [
          // Semicircular chart
          SemicircularChart(
            progress: breakdown.progressPercentage / 100,
            centerText: _getTimeText(stats.timeToSober),
            size: 280,
          ),
          const SizedBox(height: 24),
          // Message box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Message icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFFF27B7B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Message text
                Expanded(
                  child: Text(
                    stats.statusMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
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
      return '0시간';
    } else if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes분';
    } else {
      return '${hours.toStringAsFixed(1)}시간';
    }
  }
}
