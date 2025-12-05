import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RecapTab extends ConsumerStatefulWidget {
  const RecapTab({super.key});

  @override
  ConsumerState<RecapTab> createState() => _RecapTabState();
}

class _RecapTabState extends ConsumerState<RecapTab> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndSave() async {
    try {
      final RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(
        pngBytes,
        name: 'ddalgguk_recap_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지가 갤러리에 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalize DateTime to prevent infinite rebuilds
    final now = DateTime.now();
    final normalizedDate = DateTime(now.year, now.month);

    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final monthRecordsAsync = ref.watch(monthRecordsProvider(normalizedDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      child: Column(
        children: [
          // Capture Area
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              color: const Color(
                0xFFFFEBEB,
              ).withValues(alpha: 1), // Light pink bg
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Header
                  currentUserAsync.when(
                    data: (user) {
                      if (user == null) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Text(
                            '${user.name ?? 'User'}의 ${now.month}월 음주 Recap',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Character
                  monthRecordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final avgDrunkLevel = records.isEmpty
                          ? 0
                          : (records
                                      .map((r) => r.drunkLevel)
                                      .reduce((a, b) => a + b) /
                                  records.length *
                                  10)
                              .round();

                      return Column(
                        children: [
                          SakuCharacter(size: 120, drunkLevel: avgDrunkLevel),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              children: [
                                const TextSpan(text: '보통 술자리에서 '),
                                TextSpan(
                                  text: '$avgDrunkLevel%의 취기',
                                  style: const TextStyle(
                                    color: Color(0xFFE55D5D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: '를 유지해요'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),

                  // Stats Pills
                  monthRecordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // Calculate stats
                      try {
                        final drunkCount =
                            records.where((r) => r.drunkLevel >= 7).length;

                        double totalBottles = 0;
                        for (var r in records) {
                          if (r.drinkAmount.isEmpty) {
                            continue;
                          }
                          for (var d in r.drinkAmount) {
                            totalBottles += (d.amount / 500.0).clamp(0, 1000);
                          }
                        }
                        final avgBottles = records.isEmpty
                            ? 0.0
                            : (totalBottles / records.length).clamp(0, 100);

                        // Consecutive days
                        final sortedDates = records
                            .map(
                              (r) => DateTime(
                                r.date.year,
                                r.date.month,
                                r.date.day,
                              ),
                            )
                            .toSet()
                            .toList()
                          ..sort();

                        int maxConsecutive = sortedDates.isEmpty ? 0 : 1;
                        if (sortedDates.length > 1) {
                          int currentConsecutive = 1;
                          for (int i = 0; i < sortedDates.length - 1; i++) {
                            final diff = sortedDates[i + 1]
                                .difference(sortedDates[i])
                                .inDays;
                            if (diff == 1) {
                              currentConsecutive++;
                              if (currentConsecutive > maxConsecutive) {
                                maxConsecutive = currentConsecutive;
                              }
                            } else {
                              currentConsecutive = 1;
                            }
                          }
                        }

                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatPill(
                              label: '만취 $drunkCount번',
                              color: const Color(0xFFE55D5D),
                            ),
                            _StatPill(
                              label: '평균 ${avgBottles.toStringAsFixed(1)}병',
                              color: const Color(0xFFE55D5D),
                            ),
                            _StatPill(
                              label: '연속 $maxConsecutive일 음주',
                              color: const Color(0xFFE55D5D),
                            ),
                          ],
                        );
                      } catch (e) {
                        return const SizedBox.shrink();
                      }
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // Grid Layout
                  _buildGridSection(monthRecordsAsync, weeklyStatsAsync),
                  const SizedBox(height: 16),

                  // One-line Review
                  SizedBox(
                    height: 80,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              height: 80,
                              child: RepaintBoundary(
                                child: Image.asset(
                                  'assets/recap/bubble.png',
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned.fill(
                              bottom: 18,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    '11월 한줄평',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '간이 회복되지 않았는데 또 술을 마셨어요',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _captureAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('다운로드'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Share logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('스토리 공유'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridSection(
    AsyncValue<List<DrinkingRecord>> recordsAsync,
    AsyncValue<WeeklyStats> weeklyStatsAsync,
  ) {
    return Column(
      children: [
        // Row 1: Hole in Wallet & Total Volume
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hole in Wallet (Left)
            Expanded(flex: 5, child: _buildHoleInWalletCard(recordsAsync)),
            const SizedBox(width: 8),
            // Total Volume (Right)
            Expanded(flex: 4, child: _buildTotalVolumeCard(weeklyStatsAsync)),
          ],
        ),
        // Row 2: Badge & Most Drunk
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Badge (Left)
            Expanded(flex: 4, child: _buildBadgeCard(recordsAsync)),
            const SizedBox(width: 8),
            // Most Drunk (Right)
            Expanded(flex: 5, child: _buildMostDrunkCard(recordsAsync)),
          ],
        ),
      ],
    );
  }

  Widget _buildHoleInWalletCard(AsyncValue<List<DrinkingRecord>> recordsAsync) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const SizedBox.shrink();
        }
        final maxRecord = records.reduce(
          (curr, next) => curr.cost > next.cost ? curr : next,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '지갑에 빵꾸 뚫린 날',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '11월 술값 지출 부문 1위',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB4B4), // Pink
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SakuCharacter(
                    size: 40,
                    drunkLevel: maxRecord.drunkLevel * 10,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maxRecord.meetingName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${NumberFormat('#,###').format(maxRecord.cost)}원',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          '무슨 일이 있으셨나요?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTotalVolumeCard(AsyncValue<WeeklyStats> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        return SizedBox(
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: RepaintBoundary(
                  child: Image.asset(
                    'assets/recap/star_1.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF88D8B0),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '총',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      NumberFormat('#,###').format(stats.totalAlcoholMl),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'ml 음주',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadgeCard(AsyncValue<List<DrinkingRecord>> recordsAsync) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const SizedBox.shrink();
        }

        // 1. Calculate frequency and total volume per weekday
        final weekdayFrequency = <int, int>{};
        final weekdayVolume = <int, double>{};
        final processedDates = <String>{}; // To track unique dates (yyyy-MM-dd)

        for (var record in records) {
          final dateKey =
              '${record.date.year}-${record.date.month}-${record.date.day}';
          final weekday = record.date.weekday;

          // Count frequency only if this date hasn't been processed for frequency yet
          // Actually, since records might be multiple per day, we should just count unique dates per weekday.
          // But simpler: just check if we've seen this dateKey.
          if (!processedDates.contains(dateKey)) {
            weekdayFrequency[weekday] = (weekdayFrequency[weekday] ?? 0) + 1;
            processedDates.add(dateKey);
          }

          double volume = 0;
          for (var drink in record.drinkAmount) {
            volume += drink.amount;
          }
          weekdayVolume[weekday] = (weekdayVolume[weekday] ?? 0) + volume;
        }

        // 2. Find the weekday(s) with max frequency
        int maxFreq = 0;
        if (weekdayFrequency.isNotEmpty) {
          maxFreq = weekdayFrequency.values.reduce((a, b) => a > b ? a : b);
        }

        final maxFreqWeekdays = weekdayFrequency.entries
            .where((entry) => entry.value == maxFreq)
            .map((entry) => entry.key)
            .toList();

        debugPrint('maxFreqWeekdays: $weekdayFrequency');

        // 3. Resolve ties by max volume
        int bestWeekday = 1; // Default to Monday if something goes wrong
        if (maxFreqWeekdays.isNotEmpty) {
          if (maxFreqWeekdays.length == 1) {
            bestWeekday = maxFreqWeekdays.first;
          } else {
            // Sort by volume descending
            maxFreqWeekdays.sort((a, b) {
              final volA = weekdayVolume[a] ?? 0;
              final volB = weekdayVolume[b] ?? 0;
              return volB.compareTo(volA);
            });
            bestWeekday = maxFreqWeekdays.first;
          }
        }

        // Map weekday int to String
        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final weekdayName = weekdays[bestWeekday - 1];

        return SizedBox(
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: RepaintBoundary(
                  child: Image.asset(
                    'assets/recap/star_2.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4081),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '나랑',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '술마시려면',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$weekdayName요일 밤',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMostDrunkCard(AsyncValue<List<DrinkingRecord>> recordsAsync) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const SizedBox.shrink();
        }
        final maxRecord = records.reduce(
          (curr, next) => curr.drunkLevel > next.drunkLevel ? curr : next,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '가장 얼큰했던 술자리',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '11월 가장 취한 부문 1위',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE55D5D), // Red
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SakuCharacter(
                    size: 35,
                    drunkLevel: maxRecord.drunkLevel * 10,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maxRecord.meetingName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '알딸딸 지수 ${maxRecord.drunkLevel * 10}%',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Reduced padding (80% of original 16/12)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
