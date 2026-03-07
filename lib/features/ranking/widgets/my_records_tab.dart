import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/ranking/data/providers/my_records_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 소셜 탭 → "나의 기록" 서브탭
///
/// 연도별 월간 기록을 그리드로 표시하고,
/// 월 카드를 탭하면 해당 달의 주차별 팝업이 열린다.
class MyRecordsTab extends ConsumerWidget {
  const MyRecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(myRecordsYearProvider);
    final recordsAsync = ref.watch(myYearlyRecordsProvider(year));
    final now = DateTime.now();

    return Column(
      children: [
        _YearSelector(year: year, maxYear: now.year),
        Expanded(
          child: recordsAsync.when(
            data: (records) => _MonthGrid(records: records),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            ),
            error: (e, _) => Center(
              child: Text(
                '불러오기 실패: $e',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 연도 선택 위젯
// ---------------------------------------------------------------------------

class _YearSelector extends ConsumerWidget {
  const _YearSelector({required this.year, required this.maxYear});

  final int year;
  final int maxYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              final next = year - 1;
              ref.read(myRecordsYearProvider.notifier).state = next;
              ref.invalidate(myYearlyRecordsProvider(next));
            },
            icon: const Icon(Icons.chevron_left, size: 28),
          ),
          Text(
            '$year년',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: year < maxYear
                ? () {
                    final next = year + 1;
                    ref.read(myRecordsYearProvider.notifier).state = next;
                    ref.invalidate(myYearlyRecordsProvider(next));
                  }
                : null,
            icon: Icon(
              Icons.chevron_right,
              size: 28,
              color: year < maxYear ? Colors.black : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 월 그리드
// ---------------------------------------------------------------------------

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.records});

  final List<MonthRecord> records;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) => _MonthCard(record: records[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// 월 카드
// ---------------------------------------------------------------------------

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.record});

  final MonthRecord record;

  @override
  Widget build(BuildContext context) {
    final isFuture = record.isFuture;
    final isCurrent = record.isCurrent;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 월 레이블 pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isFuture ? Colors.grey.shade300 : Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${record.month}월',
            style: TextStyle(
              color: isFuture ? Colors.grey.shade500 : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 기록 없음 / 미래: 기호 하나만 크게
        if (isFuture || record.amount == null)
          Text(
            isFuture ? '?' : '-',
            style: TextStyle(
              color: isFuture ? Colors.grey.shade400 : Colors.black38,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          )
        else ...[
          // 등수
          _rankWidget(),
          const SizedBox(height: 4),
          // 그램수
          _gramsWidget(),
        ],
      ],
    );

    // 이번 달: 얕은 elevation 카드
    if (isCurrent) {
      content = Material(
        elevation: 4,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: content,
        ),
      );
    }

    if (isFuture) {
      return content;
    }

    return GestureDetector(
      onTap: () => _showWeeklyPopup(context),
      child: content,
    );
  }

  // amount != null 인 경우에만 호출됨
  Widget _rankWidget() {
    if (record.amount == 0) {
      return const Text(
        'WOW!',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (record.rank != null) {
      return Text(
        '${record.rank}등',
        style: const TextStyle(color: Colors.black54, fontSize: 16),
      );
    }
    return const Text(
      '-',
      style: TextStyle(color: Colors.black38, fontSize: 16),
    );
  }

  // amount != null 인 경우에만 호출됨
  Widget _gramsWidget() {
    final grams = record.displayGrams!;
    return Text(
      '${grams.toStringAsFixed(0)}g',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  void _showWeeklyPopup(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _WeeklyPopup(year: record.year, month: record.month),
    );
  }
}

// ---------------------------------------------------------------------------
// 주차별 팝업
// ---------------------------------------------------------------------------

class _WeeklyPopup extends ConsumerWidget {
  const _WeeklyPopup({required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync =
        ref.watch(myMonthWeeklyRecordsProvider((year, month)));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 닫기 버튼 (우측 상단)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            // 월 레이블 pill (단독 행, 중앙 정렬)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$month월',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 주차 그리드
            recordsAsync.when(
              data: (records) => _WeekGrid(records: records),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: AppColors.primaryPink,
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '불러오기 실패: $e',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 주차 그리드
// ---------------------------------------------------------------------------

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.records});

  final List<WeekRecord> records;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: records.length,
      itemBuilder: (_, i) => _WeekCard(record: records[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// 주차 카드
// ---------------------------------------------------------------------------

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.record});

  final WeekRecord record;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 주차 레이블 pill (항상 회색)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${record.weekOfMonth}주',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 미래 / 기록 없음: 기호 하나만 크게 (월별 카드와 동일한 스타일)
        if (record.isFuture)
          Text(
            '?',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (record.amount == null)
          const Text(
            '-',
            style: TextStyle(
              color: Colors.black38,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (record.amount == 0)
          const Text(
            'WOW!',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          )
        else ...[
          _rankWidget(),
          _gramsWidget(),
        ],
      ],
    );
  }

  Widget _rankWidget() {
    if (record.rank != null) {
      return Text(
        '${record.rank}등',
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      );
    }
    return const Text(
      '-',
      style: TextStyle(color: Colors.black38, fontSize: 13),
    );
  }

  Widget _gramsWidget() {
    final grams = record.displayGrams!;
    return Text(
      '${grams.toStringAsFixed(0)}g',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }
}
