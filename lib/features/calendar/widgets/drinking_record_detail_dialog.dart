import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // 영수증 배경 이미지와 콘텐츠
          Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: maxDialogHeight,
            ),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/calendar/receipt.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 여백 (X 버튼 공간)
                const SizedBox(height: 60),
                // 스크롤 가능한 콘텐츠 영역
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 모임명
                        Text(
                          record.meetingName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // 날짜
                        Text(
                          DateFormat('yyyy.MM.dd').format(record.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 캐릭터 이미지 (취함 정도에 따라)
                        _buildCharacterImage(record.drunkLevel),
                        const SizedBox(height: 16),
                        // 혈중 알콜 농도
                        Text(
                          '혈중 알콜 농도',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.drunkLevel * 10}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 점선 구분선
                        _buildDashedDivider(),
                        const SizedBox(height: 24),
                        // 음주량
                        if (record.drinkAmounts.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '음주량',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...record.drinkAmounts.map((drink) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text(
                                    '${_getDrinkTypeName(drink.drinkType)} ${drink.alcoholContent}%',
                                    style: const TextStyle(fontSize: 14),
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
                                        child: const SizedBox(height: 14),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatAmount(drink.amount),
                                    style: const TextStyle(fontSize: 14),
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
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(record.cost)}원',
                              style: const TextStyle(
                                fontSize: 16,
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
                                fontSize: 14,
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
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // 하단 버튼
                if (onEdit != null || onDelete != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (onEdit != null)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onEdit!();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
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
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('삭제'),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // 우측 상단 X 버튼
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 캐릭터 이미지 빌드 (취함 정도에 따라)
  Widget _buildCharacterImage(int drunkLevel) {
    const size = 120.0;
    const eyesScale = 0.35;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            _getBodyImagePath(drunkLevel),
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          Opacity(
            opacity: _getEyesOpacity(drunkLevel),
            child: Image.asset(
              'assets/saku/eyes.png',
              width: size * eyesScale,
              height: size * eyesScale,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  /// 알딸딸 지수에 따른 body 이미지 경로 반환
  String _getBodyImagePath(int drunkLevel) {
    // drunkLevel: 0-10
    // 0-2: body1 (0-20%)
    // 3-4: body2 (30-40%)
    // 5-6: body3 (50-60%)
    // 7-8: body4 (70-80%)
    // 9-10: body5 (90-100%)
    if (drunkLevel <= 2) {
      return 'assets/saku_gradient/body1.png';
    } else if (drunkLevel <= 4) {
      return 'assets/saku_gradient/body2.png';
    } else if (drunkLevel <= 6) {
      return 'assets/saku_gradient/body3.png';
    } else if (drunkLevel <= 8) {
      return 'assets/saku_gradient/body4.png';
    } else {
      return 'assets/saku_gradient/body5.png';
    }
  }

  /// 취함 정도에 따른 눈의 투명도
  double _getEyesOpacity(int drunkLevel) {
    // drunkLevel이 높을수록 눈이 흐려짐
    return 1.0 - (drunkLevel / 10.0).clamp(0.0, 0.8);
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

  /// 술 종류 이름
  String _getDrinkTypeName(int drinkType) {
    switch (drinkType) {
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
        return '기타';
    }
  }

  /// 음주량 포맷팅
  String _formatAmount(double amountInMl) {
    if (amountInMl >= 1000) {
      final bottles = amountInMl / 500;
      if (bottles % 1 == 0) {
        return '${bottles.toInt()}병';
      }
      return '${bottles.toStringAsFixed(1)}병';
    } else if (amountInMl >= 150) {
      final glasses = amountInMl / 150;
      if (glasses % 1 == 0) {
        return '${glasses.toInt()}잔';
      }
      return '${glasses.toStringAsFixed(1)}잔';
    } else {
      return '${amountInMl.toInt()}ml';
    }
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
