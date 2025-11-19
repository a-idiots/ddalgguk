import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/calendar/calendar_screen.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';

class SpendingTab extends ConsumerWidget {
  const SpendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthlySpendingAsync = ref.watch(monthlySpendingProvider(now));
    final monthRecordsAsync = ref.watch(monthRecordsProvider(now));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly spending header
          monthlySpendingAsync.when(
            data: (totalSpending) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이번 달은 지난 달보다',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF27B7B),
                        ),
                        children: [
                          TextSpan(
                            text: NumberFormat('#,###').format(totalSpending),
                          ),
                          const TextSpan(
                            text: '원',
                            style: TextStyle(fontSize: 20),
                          ),
                          const TextSpan(
                            text: ' 더 마셨어요',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(총 견적 기준)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          // Monthly total
          monthlySpendingAsync.when(
            data: (totalSpending) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${now.month}월 지출 금액',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(totalSpending)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF27B7B),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          // Recent transactions
          const Text(
            '리스트',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          monthRecordsAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      '이번 달 음주 기록이 없습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              // Sort by date descending
              final sortedRecords = List<DrinkingRecord>.from(records)
                ..sort((a, b) => b.date.compareTo(a.date));

              return Column(
                children: sortedRecords.take(10).map((DrinkingRecord record) {
                  return _TransactionItem(
                    date: record.date,
                    title: record.meetingName.isNotEmpty
                        ? record.meetingName
                        : '음주 기록',
                    drunkLevel: record.drunkLevel,
                    cost: record.cost,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.date,
    required this.title,
    required this.drunkLevel,
    required this.cost,
  });

  final DateTime date;
  final String title;
  final int drunkLevel;
  final int cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('HH:mm').format(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('M/d').format(date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Drunk level indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getDrunkLevelColor(drunkLevel).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$drunkLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getDrunkLevelColor(drunkLevel),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '취음정도 ${drunkLevel * 10}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Cost
          Text(
            '${NumberFormat('#,###').format(cost)}원',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF27B7B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDrunkLevelColor(int level) {
    if (level <= 3) {
      return const Color(0xFF52E370);
    } else if (level <= 6) {
      return const Color(0xFFFFA552);
    } else {
      return const Color(0xFFF27B7B);
    }
  }
}
