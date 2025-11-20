import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/features/profile/widgets/reusable_section.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/core/constants/app_colors.dart';

class WeeklySakuSection extends ConsumerStatefulWidget {
  const WeeklySakuSection({
    super.key,
    required this.weeklyStats, // Initial stats (offset 0)
    required this.theme,
  });

  final WeeklyStats weeklyStats;
  final AppTheme theme;

  @override
  ConsumerState<WeeklySakuSection> createState() => _WeeklySakuSectionState();
}

class _WeeklySakuSectionState extends ConsumerState<WeeklySakuSection> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  static const int _totalWeeks = 4;

  @override
  void initState() {
    super.initState();
    // Start at the last page (current week)
    _currentPageIndex = _totalWeeks - 1;
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getOffsetFromPageIndex(int pageIndex) {
    // pageIndex 3 -> offset 0
    // pageIndex 2 -> offset 1
    // pageIndex 0 -> offset 3
    return (_totalWeeks - 1) - pageIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate date range for the current visible week
    final offset = _getOffsetFromPageIndex(_currentPageIndex);

    // We need the stats for the current offset to get the date range
    // Since we might not have the async data yet for title update during swipe,
    // we can calculate dates manually.
    final now = DateTime.now();
    final endDate = now.subtract(Duration(days: 7 * offset));
    final startDate = endDate.subtract(const Duration(days: 6));

    final dateRangeText =
        '${DateFormat('MM.dd.').format(startDate)} ~ ${DateFormat('MM.dd.').format(endDate)}';

    return ProfileSection(
      title: '지난 일주일',
      titleOutside: true,
      subtitle: Align(
        alignment: Alignment.bottomLeft, // or bottomCenter / bottomRight
        child: Text(
          dateRangeText,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      content: SizedBox(
        height: 30, // Adjust height for SakuCharacter
        child: PageView.builder(
          controller: _pageController,
          itemCount: _totalWeeks,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final itemOffset = _getOffsetFromPageIndex(index);

            // Use the passed weeklyStats for offset 0 to avoid flicker/reload if possible,
            // but for consistency we can just watch the provider for all.
            // However, widget.weeklyStats is already available.

            if (itemOffset == 0) {
              return _buildWeekRow(widget.weeklyStats);
            }

            final statsAsync = ref.watch(weeklyStatsOffsetProvider(itemOffset));

            return statsAsync.when(
              data: (stats) => _buildWeekRow(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading data')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekRow(WeeklyStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.dailyData.map((dailyData) {
        return SizedBox(
          width: 40,
          height: 40,
          child: dailyData.hasRecords
              ? SakuCharacter(size: 40, drunkLevel: dailyData.drunkLevel)
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                ),
        );
      }).toList(),
    );
  }
}
