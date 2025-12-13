import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
// import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart'; // Apparently unused or exported elsewhere? Keeping if needed, but error said unused. I'll remove it.
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
    // Normalize DateTime
    final now = DateTime.now();
    final normalizedDate = DateTime(now.year, now.month);

    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final monthRecordsAsync = ref.watch(monthRecordsProvider(normalizedDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          // Capture Area
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              color: Colors.white, // White bg
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Header
                  currentUserAsync.when(
                    data: (user) {
                      if (user == null) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Text(
                            user.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${now.month}월 음주 Recap',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // 2. Soju Glass (Total Volume)
                  weeklyStatsAsync.when(
                    data: (stats) {
                      return _SojuGlassWidget(
                        totalMl: stats.totalAlcoholMl.toInt(),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 40),

                  // 3. Stats Grid
                  monthRecordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _buildStatsGrid(records);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // 4. Hole in Wallet
                  monthRecordsAsync.when(
                    data: (records) => _buildHoleInWalletSection(records),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // 5. Most Drunk
                  monthRecordsAsync.when(
                    data: (records) => _buildMostDrunkSection(records),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Separator
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DottedLinePainter(),
                  ),
                  const SizedBox(height: 24),

                  // 6. One-line Review
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '11월 한줄평',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '11월 가장 취한 부문 1위',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '간이 회복되지 않았는데 또 술을 마셨어요',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily:
                          'Pretendard', // Assuming default font supports this look
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                      side: const BorderSide(color: Colors.grey),
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
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
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

  Widget _buildStatsGrid(List<DrinkingRecord> records) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate stats
    final drunkCount = records.where((r) => r.drunkLevel >= 7).length;

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

    final avgDrunkLevel = records.isEmpty
        ? 0
        : (records.map((r) => r.drunkLevel).reduce((a, b) => a + b) /
                  records.length *
                  10)
              .round();

    // Consecutive days
    final sortedDates =
        records
            .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
            .toSet()
            .toList()
          ..sort();

    int maxConsecutive = sortedDates.isEmpty ? 0 : 1;
    if (sortedDates.length > 1) {
      int currentConsecutive = 1;
      for (int i = 0; i < sortedDates.length - 1; i++) {
        final diff = sortedDates[i + 1].difference(sortedDates[i]).inDays;
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(value: '$avgDrunkLevel%', label: '술자리 평균 취기'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '${drunkCount}번', label: '만취'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${avgBottles.toStringAsFixed(1)}병',
                label: '평균 음주량',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '${maxConsecutive}일', label: '연속 음주'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoleInWalletSection(List<DrinkingRecord> records) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxRecord = records.reduce(
      (curr, next) => curr.cost > next.cost ? curr : next,
    );

    return Column(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DottedLinePainter(),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '지갑에 빵꾸 뚫린 날',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '11월 술값 지출 부문 1위',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              maxRecord.meetingName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Text(
              '${NumberFormat('#,###').format(maxRecord.cost)}원',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMostDrunkSection(List<DrinkingRecord> records) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxRecord = records.reduce(
      (curr, next) => curr.drunkLevel > next.drunkLevel ? curr : next,
    );

    return Column(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DottedLinePainter(),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '가장 얼큰했던 술자리',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '11월 가장 취한 부문 1위',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              maxRecord.meetingName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Text(
              '${maxRecord.drunkLevel * 10}%',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SojuGlassWidget extends StatelessWidget {
  const _SojuGlassWidget({required this.totalMl});

  final int totalMl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(180, 220), painter: _SojuGlassPainter()),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '총 음주량',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat('#,###').format(totalMl),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'mL',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SojuGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    // Glass shape (Trapezoid approx)
    final double topWidth = size.width;
    final double height = size.height;

    path.moveTo(0, 0); // Top Left

    // Top curve (Wavy)
    path.cubicTo(
      topWidth * 0.25,
      height * 0.1, // Control point 1
      topWidth * 0.75,
      -height * 0.05, // Control point 2
      topWidth,
      0, // Top Right
    );

    path.lineTo(topWidth * 0.85, height); // Bottom Right
    path.lineTo(topWidth * 0.15, height); // Bottom Left
    path.close();

    // Draw main black body
    canvas.drawPath(path, paint);

    // Draw outline
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer glass line separated
    // Let's do a separate simple outline path
    final outlinePath = Path();
    outlinePath.moveTo(-5, 0);
    outlinePath.lineTo(topWidth * 0.15 - 5, height + 5);
    outlinePath.lineTo(topWidth * 0.85 + 5, height + 5);
    outlinePath.lineTo(topWidth + 5, 0);

    canvas.drawPath(outlinePath, borderPaint..strokeWidth = 1.5);

    // Draw bubbles
    final bubblePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      6,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.5),
      8,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      7,
      bubblePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
