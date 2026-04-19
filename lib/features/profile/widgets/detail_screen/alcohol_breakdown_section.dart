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
    required this.extraComment,
  });

  final ProfileStats stats;
  final AppTheme theme;
  final bool extraComment;

  @override
  Widget build(BuildContext context) {
    final breakdown = stats.breakdown;
    final today = DateFormat('MM.dd.').format(DateTime.now());

    return ProfileSection(
      title: '혈중 알콜 분해 현황',
      subtitle: SectionSubtitle(text: today),
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Semicircular chart
            SemicircularChart(
              progress: stats.timeToSober <= 0
                  ? breakdown.progressPercentage / 100
                  : 1 - breakdown.progressPercentage / 100,
              topLabel: stats.timeToSober <= 0
                  ? '완전 분해 완료'
                  : '완전 분해까지 ${_getTimeText(stats.timeToSober)}',
              bottomLabel: '${breakdown.alcoholRemaining.toStringAsFixed(3)}%',
              activeColor: theme.primaryColor,
              size: 280,
            ),
            const SizedBox(height: 24),

            // Message box
            if (extraComment)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.black54,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '실제 법정에서 사용하는 위드마크 공식을 이용해 계산한 혈중 알콜 농도에요. 키, 체중, 성별 등을 반영해 매 시간 업데이트됩니다.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
