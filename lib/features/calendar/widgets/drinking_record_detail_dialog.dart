import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/circular_slider.dart';
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
    // 기록을 CompletedDrinkRecord로 변환
    final completedRecords = record.drinkAmount.map((drink) {
      // ml을 단위에 맞게 변환
      String unit;
      double amount;

      // 주종별 병 용량 기준으로 1병 이상인지 확인
      final bottleMultiplier = getUnitMultiplier(drink.drinkType, '병');
      final glassMultiplier = getUnitMultiplier(drink.drinkType, '잔');

      if (drink.amount >= bottleMultiplier) {
        unit = '병';
        amount = drink.amount / bottleMultiplier;
      } else if (drink.amount >= glassMultiplier) {
        unit = '잔';
        amount = drink.amount / glassMultiplier;
      } else {
        unit = 'ml';
        amount = drink.amount;
      }

      return CompletedDrinkRecord(
        drinkType: drink.drinkType,
        alcoholContent: drink.alcoholContent,
        amount: amount,
        unit: unit,
      );
    }).toList();

    return Stack(
      children: [
        Column(
          children: [
            // 제목 (중앙 정렬)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // 스크롤 가능한 콘텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 알딸딸 지수
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '알딸딸 지수',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 둥근 슬라이더와 캐릭터 (조작 불가)
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 둥근 슬라이더 (핸들 숨김)
                            CircularSlider(
                              value: record.drunkLevel.toDouble() * 10,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              size: 240,
                              trackWidth: 16,
                              inactiveColor: Colors.grey[300]!,
                              activeColor: const Color(0xFFFA75A5),
                              thumbColor: Colors.transparent, // 핸들 숨김
                              thumbRadius: 0, // 핸들 크기 0
                              onChanged: (_) {}, // 조작 불가 (빈 함수)
                            ),
                            // 가운데 컨텐츠
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 사쿠 캐릭터
                                SakuCharacter(
                                  size: 80,
                                  drunkLevel: record.drunkLevel * 10,
                                ),
                                const SizedBox(height: 8),
                                // 퍼센트 표시
                                Text(
                                  '${record.drunkLevel * 10}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 음주량
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '음주량',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 완료된 기록 리스트 (삭제 버튼 없이)
                    ...completedRecords.map((record) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // 아이콘
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: getDrinkIcon(record.drinkType),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 정보 텍스트
                            Expanded(
                              child: Text(
                                '${getDrinkTypeName(record.drinkType)} · ${record.alcoholContent}% · ${record.amount}${record.unit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // 술값 (필수 아님)
                    const Text(
                      '술값(지출 금액)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '${NumberFormat('#,###').format(record.cost)}원',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 메모 (필수 아님)
                    const Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        record.memo['text'] as String? ?? '',
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 우상단 메뉴 버튼
        if (onEdit != null || onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              color: Colors.grey[200],
              surfaceTintColor: Colors.transparent,
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) {
                  Navigator.pop(context);
                  onEdit!();
                } else if (value == 'delete' && onDelete != null) {
                  Navigator.pop(context);
                  onDelete!();
                }
              },
              itemBuilder: (BuildContext context) => [
                if (onEdit != null)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
