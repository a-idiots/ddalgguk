import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';

/// 음주 기록 상세 다이얼로그
class DrinkingRecordDetailDialog extends StatelessWidget {
  const DrinkingRecordDetailDialog({
    required this.record,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final DrinkingRecord record;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Text(
                record.meetingName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('yyyy.MM.dd').format(record.date),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 스크롤 가능한 콘텐츠 영역
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 캐릭터 이미지 (취함 정도에 따라)
                _buildCharacterImage(record.drunkLevel),
                const SizedBox(height: 24),
                // 혈중 알콜 농도
                Text(
                  '혈중 알콜 농도',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.drunkLevel * 10}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // 점선 구분선
                _buildDashedDivider(),
                const SizedBox(height: 24),
                // 음주량
                if (record.drinkAmount.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '음주량',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...record.drinkAmount.map((drink) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(
                            '${getDrinkTypeName(drink.drinkType)} ${drink.alcoholContent}%',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: CustomPaint(
                                painter: _DottedLinePainter(
                                  color: Colors.grey[300]!,
                                ),
                                child: const SizedBox(height: 15),
                              ),
                            ),
                          ),
                          Text(
                            formatDrinkAmount(drink.amount),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildDashedDivider(),
                  const SizedBox(height: 24),
                ],
                // 지출
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '지출',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(record.cost)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDashedDivider(),
                const SizedBox(height: 24),
                // 취중 메모
                if (record.memo['text'] != null &&
                    (record.memo['text'] as String).isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '취중 메모',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      record.memo['text'] as String,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // 하단 버튼
                if (onEdit != null || onDelete != null)
                  Row(
                    children: [
                      if (onEdit != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit!();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('수정'),
                          ),
                        ),
                      if (onEdit != null && onDelete != null)
                        const SizedBox(width: 12),
                      if (onDelete != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete!();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('삭제'),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 캐릭터 이미지 빌드 (취함 정도에 따라)
  Widget _buildCharacterImage(int drunkLevel) {
    const size = 120.0;

    return SakuCharacter(size: size, drunkLevel: drunkLevel * 10);
  }

  /// 점선 구분선
  Widget _buildDashedDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            height: 1,
            color: index % 2 == 0 ? Colors.grey[300] : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// 점선을 그리는 CustomPainter
class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dotRadius = 1.5;
    const dotSpacing = 4.0;
    final y = size.height / 2;

    for (double x = 0; x < size.width; x += dotSpacing) {
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) => false;
}
