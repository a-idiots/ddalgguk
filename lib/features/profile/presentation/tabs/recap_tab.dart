import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/calendar/calendar_screen.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';

class RecapTab extends ConsumerStatefulWidget {
  const RecapTab({super.key});

  @override
  ConsumerState<RecapTab> createState() => _RecapTabState();
}

class _RecapTabState extends ConsumerState<RecapTab> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndSave() async {
    try {
      final RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
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
    final now = DateTime.now();
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final monthRecordsAsync = ref.watch(monthRecordsProvider(now));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Capture Area
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              color: Colors.white, // White background for capture
              padding: const EdgeInsets.all(16),
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
                          SakuCharacter(size: 100),
                          const SizedBox(height: 16),
                          Text(
                            user.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${now.month}월 음주 Recap',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Stats Pills
                  currentStatsAsync.when(
                    data: (stats) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _StatPill(
                            label: '평균 취기',
                            value: '${stats.thisMonthDrunkDays * 10}%',
                            color: const Color(0xFFF27B7B),
                          ),
                          _StatPill(
                            label: '블랙아웃',
                            value: '0회', // Mock data
                            color: Colors.black,
                          ),
                          _StatPill(
                            label: '평균 주량',
                            value: '2.5병', // Mock data
                            color: const Color(0xFFFFA552),
                          ),
                          _StatPill(
                            label: '연속 음주',
                            value: '3일', // Mock data
                            color: const Color(0xFF52A3E3),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // Grid Layout
                  _buildGridSection(monthRecordsAsync, weeklyStatsAsync),
                  const SizedBox(height: 32),

                  // One-line Review
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '한줄평',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '건이 되돌려지지 않는데도 술을 마셔요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _captureAndSave,
                  icon: const Icon(Icons.download),
                  label: const Text('이미지 저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = (width - 16) / 2;

        return Column(
          children: [
            Row(
              children: [
                // Top Left: Max Spending
                SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: _buildMaxSpendingCard(recordsAsync),
                ),
                const SizedBox(width: 16),
                // Top Right: Total Volume
                SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: _buildTotalVolumeCard(weeklyStatsAsync),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Bottom Left: Most Drunk
                SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: _buildMostDrunkCard(recordsAsync),
                ),
                const SizedBox(width: 16),
                // Bottom Right: Frequent Day
                SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: _buildFrequentDayCard(weeklyStatsAsync),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaxSpendingCard(AsyncValue<List<DrinkingRecord>> recordsAsync) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) return _EmptyCard(label: '지갑 털린 날');
        final maxRecord = records.reduce(
          (curr, next) => curr.cost > next.cost ? curr : next,
        );
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.attach_money, color: Colors.amber, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '지갑 털린 날',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    maxRecord.meetingName.isNotEmpty
                        ? maxRecord.meetingName
                        : '모임',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildTotalVolumeCard(AsyncValue<WeeklyStats> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/images/star_bg.png'), // Placeholder
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '총 마신 양',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(stats.totalAlcoholMl / 1000).toStringAsFixed(1)}L',
                    style: const TextStyle(
                      fontSize: 20,
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
        if (records.isEmpty) return _EmptyCard(label: '가장 취한 날');
        final maxRecord = records.reduce(
          (curr, next) => curr.drunkLevel > next.drunkLevel ? curr : next,
        );
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE4EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.local_bar, color: Colors.pink, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '가장 취한 날',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '취기 ${maxRecord.drunkLevel * 10}%',
                    style: const TextStyle(
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

  Widget _buildFrequentDayCard(AsyncValue<WeeklyStats> statsAsync) {
    // Mock logic for frequent day as it's not in WeeklyStats
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.calendar_today, color: Colors.purple, size: 32),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '자주 마시는 요일',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                '금요일',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          '$label\n기록 없음',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
