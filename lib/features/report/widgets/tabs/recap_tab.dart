import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/profile/domain/models/weekly_stats.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/speech_bubble.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

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
    // Normalize DateTime to prevent infinite rebuilds
    final now = DateTime.now();
    final normalizedDate = DateTime(now.year, now.month);

    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final monthRecordsAsync = ref.watch(monthRecordsProvider(normalizedDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Capture Area
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              color: const Color(
                0xFFFFEBEB,
              ).withValues(alpha: 0.3), // Light pink bg
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // Character
                  currentStatsAsync.when(
                    data: (stats) {
                      // Calculate average drunk level (0-100)
                      // Assuming thisMonthDrunkDays represents some metric, cap it at 10
                      final avgDrunkLevel = (stats.thisMonthDrunkDays * 10)
                          .clamp(0, 100);

                      return Column(
                        children: [
                          SakuCharacter(size: 180, drunkLevel: avgDrunkLevel),
                          const SizedBox(height: 24),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              children: [
                                const TextSpan(text: '평균적으로 술자리에서 '),
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
                  const SizedBox(height: 24),

                  // Stats Pills
                  currentStatsAsync.when(
                    data: (stats) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatPill(
                            label: '만취 1번', // Mock
                            color: const Color(0xFFE55D5D),
                          ),
                          _StatPill(
                            label: '평균 2.5병', // Mock
                            color: const Color(0xFFE55D5D),
                          ),
                          _StatPill(
                            label: '연속 3일 음주', // Mock
                            color: const Color(0xFFE55D5D),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 40),

                  // Grid Layout
                  _buildGridSection(monthRecordsAsync, weeklyStatsAsync),
                  const SizedBox(height: 40),

                  // One-line Review
                  const SpeechBubble(
                    text: '간이 회복되지 않았는데 또 술을 마셨어요',
                    tailPosition: TailPosition.top,
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '11월 한줄평',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            const SizedBox(width: 16),
            // Total Volume (Right)
            Expanded(flex: 4, child: _buildTotalVolumeCard(weeklyStatsAsync)),
          ],
        ),
        const SizedBox(height: 24),
        // Row 2: Badge & Most Drunk
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Badge (Left)
            Expanded(flex: 4, child: _buildBadgeCard()),
            const SizedBox(width: 16),
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
            const Text(
              '지갑에 빵꾸 뚫린 날',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              '11월 술값 지출 부문 1위',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB4B4), // Pink
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SakuCharacter(
                    size: 50,
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
                          '${NumberFormat('#,###').format(maxRecord.cost)}원',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '무슨 일이 있으셨나요?',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
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
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _StarburstPainter(
                  color: const Color(0xFF88D8B0),
                ), // Green
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '총',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    NumberFormat('#,###').format(stats.totalAlcoholMl),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'ml 음주',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

  Widget _buildBadgeCard() {
    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: _SpikyCirclePainter(
              color: const Color(0xFFFF4081),
            ), // Hot Pink
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '나랑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '술마시려면',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '목요일 밤',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '주로 목, 금 저녁 음주',
                style: TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
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
            const Text(
              '가장 얼큰했던 술자리',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              '11월 가장 취한 부문 1위',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE55D5D), // Red
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SakuCharacter(
                    size: 50,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  _StarburstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.7;
    final path = Path();

    const spikes = 12;
    final angleStep = (math.pi * 2) / spikes;

    for (int i = 0; i < spikes; i++) {
      final angle = i * angleStep;
      final nextAngle = (i + 1) * angleStep;
      final midAngle = (angle + nextAngle) / 2;

      final p1 = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final p2 = Offset(
        center.dx + math.cos(midAngle) * innerRadius,
        center.dy + math.sin(midAngle) * innerRadius,
      );

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpikyCirclePainter extends CustomPainter {
  _SpikyCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.85;
    final path = Path();

    const spikes = 20;
    final angleStep = (math.pi * 2) / spikes;

    for (int i = 0; i < spikes; i++) {
      final angle = i * angleStep;
      final nextAngle = (i + 1) * angleStep;
      final midAngle = (angle + nextAngle) / 2;

      final p1 = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final p2 = Offset(
        center.dx + math.cos(midAngle) * innerRadius,
        center.dy + math.sin(midAngle) * innerRadius,
      );

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(
        center.dx + math.cos(midAngle) * (innerRadius * 0.9),
        center.dy + math.sin(midAngle) * (innerRadius * 0.9),
        p2.dx,
        p2.dy,
      );
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
