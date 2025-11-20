import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SpendingTab extends ConsumerWidget {
  const SpendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Normalize DateTime to prevent infinite rebuilds
    final now = DateTime.now();
    final normalizedDate = DateTime(now.year, now.month);

    final monthlySpendingAsync = ref.watch(
      monthlySpendingProvider(normalizedDate),
    );
    final monthRecordsAsync = ref.watch(monthRecordsProvider(normalizedDate));
    final comparisonAsync = ref.watch(
      monthlySpendingComparisonProvider(normalizedDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Summary Section
          _SpendingSummaryCard(
            month: now.month,
            spendingAsync: monthlySpendingAsync,
            comparisonAsync: comparisonAsync,
          ),
          const SizedBox(height: 32),

          // 2. Record List Section
          _DrinkingRecordList(recordsAsync: monthRecordsAsync),
          const SizedBox(height: 32),

          // 3. Max Spending Section
          _MaxSpendingCard(recordsAsync: monthRecordsAsync),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SpendingSummaryCard extends StatelessWidget {
  const _SpendingSummaryCard({
    required this.month,
    required this.spendingAsync,
    required this.comparisonAsync,
  });

  final int month;
  final AsyncValue<int> spendingAsync;
  final AsyncValue<int> comparisonAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB), // Light pink background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Comparison Text
          comparisonAsync.when(
            data: (diff) {
              final isSaving = diff >= 0;
              final diffAbs = diff.abs();
              if (diffAbs == 0) {
                return Column(
                  children: [
                    const Text(
                      '이번 달은 지난 달과',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '똑같은 금액을 쓰고 있어요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(월 전체 기준)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  const Text(
                    '이번 달은 지난 달보다',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Pretendard',
                      ),
                      children: [
                        TextSpan(
                          text: NumberFormat('#,###').format(diffAbs),
                          style: const TextStyle(color: Color(0xFFF27B7B)),
                        ),
                        const TextSpan(text: '원 '),
                        TextSpan(
                          text: isSaving ? '아끼고' : '더 쓰고',
                          style: const TextStyle(color: Color(0xFFF27B7B)),
                        ),
                        const TextSpan(text: ' 있어요'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(월 전체 기준)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, __) => Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  '비교 정보를 불러올 수 없습니다',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 20),
          // Monthly Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month월 지출 금액',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              spendingAsync.when(
                data: (total) => Text(
                  '${NumberFormat('#,###').format(total)}원',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('Error'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrinkingRecordList extends StatelessWidget {
  const _DrinkingRecordList({required this.recordsAsync});

  final AsyncValue<List<DrinkingRecord>> recordsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '이번 달 음주 기록이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '건강한 한 달을 보내고 계시네요!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Sort by date descending
          final sortedRecords = List<DrinkingRecord>.from(records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: sortedRecords.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return _DrinkingRecordItem(record: sortedRecords[index]);
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                '데이터를 불러올 수 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '로그인 상태를 확인하거나\n잠시 후 다시 시도해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrinkingRecordItem extends StatelessWidget {
  const _DrinkingRecordItem({required this.record});

  final DrinkingRecord record;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Date
        SizedBox(
          width: 40,
          child: Text(
            DateFormat('MM.dd').format(record.date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Character
        SakuCharacter(size: 48, drunkLevel: record.drunkLevel * 10),
        const SizedBox(width: 16),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.meetingName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                '혈중알콜농도 ${record.drunkLevel * 10}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFF27B7B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDrinkAmounts(record.drinkAmounts),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Cost
        Text(
          '${NumberFormat('#,###').format(record.cost)}원',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _formatDrinkAmounts(List<DrinkAmount> amounts) {
    if (amounts.isEmpty) {
      return '';
    }
    return amounts
        .map((a) {
          final typeName = _getDrinkTypeName(a.drinkType);
          final amountStr = _formatAmount(a.amount);
          return '$typeName $amountStr';
        })
        .join(', ');
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
        return '막걸리';
      case 5:
        return '칵테일';
      case 6:
        return '위스키';
      default:
        return '술';
    }
  }

  String _formatAmount(double amount) {
    // Assuming amount is in ml, convert to bottles/glasses if needed
    // Simple logic for now
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}L';
    } else if (amount < 10) {
      return '${amount.toStringAsFixed(1).replaceAll('.0', '')}병';
    }
    return '${amount.toInt()}ml';
  }
}

class _MaxSpendingCard extends StatelessWidget {
  const _MaxSpendingCard({required this.recordsAsync});

  final AsyncValue<List<DrinkingRecord>> recordsAsync;

  @override
  Widget build(BuildContext context) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find the max spending record
        final maxRecord = records.reduce(
          (curr, next) => curr.cost > next.cost ? curr : next,
        );

        // If max cost is 0, don't show this section
        if (maxRecord.cost == 0) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateTime.now().month}월 통장 털린 술자리',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '최대 지출액 (한달 기준)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30), // Extra space for the floating icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE55D5D), Color(0xFFE37B7B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE55D5D).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 60), // Space for the icon
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  maxRecord.meetingName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${NumberFormat('#,###').format(maxRecord.cost)}원',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _DrinkingRecordItem(
                            record: maxRecord,
                          )._formatDrinkAmounts(maxRecord.drinkAmounts),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -20,
                  left: 20,
                  child: SakuCharacter(
                    size: 70,
                    drunkLevel: maxRecord.drunkLevel * 10,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
