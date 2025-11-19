import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/reusable_section.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';

class WeeklySakuSection extends StatelessWidget {
  const WeeklySakuSection({super.key, required this.weeklyStats});

  final WeeklyStats weeklyStats;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: '지난 일주일',
      subtitle: null,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weeklyStats.dailyData.map((dailyData) {
          return _WeeklySakuItem(
            date: dailyData.date,
            drunkLevel: dailyData.drunkLevel,
            hasRecords: dailyData.hasRecords,
          );
        }).toList(),
      ),
    );
  }
}

class _WeeklySakuItem extends StatelessWidget {
  const _WeeklySakuItem({
    required this.date,
    required this.drunkLevel,
    required this.hasRecords,
  });

  final DateTime date;
  final int drunkLevel;
  final bool hasRecords;

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day of week
        Text(
          _getKoreanDayOfWeek(date.weekday),
          style: TextStyle(
            fontSize: 11,
            color: isToday ? const Color(0xFFF27B7B) : Colors.grey,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        // Saku image
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
            border: isToday
                ? Border.all(color: const Color(0xFFF27B7B), width: 2)
                : null,
          ),
          child: ClipOval(
            child: hasRecords
                ? Image.asset(
                    getBodyImagePath(drunkLevel),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/saku/body.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Icon(Icons.check_circle, color: Colors.green[300], size: 24),
          ),
        ),
        const SizedBox(height: 4),
        // Date
        Text(
          DateFormat('d').format(date),
          style: TextStyle(
            fontSize: 11,
            color: isToday ? const Color(0xFFF27B7B) : Colors.grey[600],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getKoreanDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }
}
