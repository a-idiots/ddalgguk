import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/calendar/dialogs/drink_type_selector.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/models/drink_input_data.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/drink_input_card.dart';
import 'package:ddalgguk/features/calendar/widgets/receipt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 기록 수정 다이얼로그
class EditRecordDialog extends ConsumerStatefulWidget {
  const EditRecordDialog({
    required this.record,
    required this.onRecordUpdated,
    super.key,
  });

  final DrinkingRecord record;
  final VoidCallback onRecordUpdated;

  @override
  ConsumerState<EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends ConsumerState<EditRecordDialog> {
  late final TextEditingController _meetingNameController;
  late final TextEditingController _costController;
  late final TextEditingController _memoController;
  late double _drunkLevel;
  late List<DrinkInputData> _drinkInputs;

  @override
  void initState() {
    super.initState();

    // 기존 데이터로 초기화
    _meetingNameController = TextEditingController(
      text: widget.record.meetingName,
    );
    _costController = TextEditingController(
      text: widget.record.cost > 0 ? widget.record.cost.toString() : '',
    );
    _memoController = TextEditingController(
      text: widget.record.memo['text'] as String? ?? '',
    );
    _drunkLevel = widget.record.drunkLevel.toDouble();

    // 기존 음주량 데이터를 DrinkInputData 리스트로 변환
    _drinkInputs = widget.record.drinkAmounts.isNotEmpty
        ? widget.record.drinkAmounts.map((drink) {
            // ml을 단위에 맞게 변환
            String unit;
            double amount;
            if (drink.amount >= 1000) {
              unit = '병';
              amount = drink.amount / 500;
            } else if (drink.amount >= 150) {
              unit = '잔';
              amount = drink.amount / 150;
            } else {
              unit = 'ml';
              amount = drink.amount;
            }

            return DrinkInputData(
              drinkType: drink.drinkType,
              alcoholController: TextEditingController(
                text: drink.alcoholContent.toString(),
              ),
              amountController: TextEditingController(text: amount.toString()),
              selectedUnit: unit,
            );
          }).toList()
        : [
            DrinkInputData(
              drinkType: 0, // 미정
              alcoholController: TextEditingController(text: '0.0'),
              amountController: TextEditingController(text: '1.0'),
              selectedUnit: '병',
            ),
          ];
  }

  @override
  void dispose() {
    _meetingNameController.dispose();
    _costController.dispose();
    _memoController.dispose();
    for (var input in _drinkInputs) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_meetingNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모임명을 입력해주세요')));
      return;
    }

    // 음주량 입력 유효성 검사 및 변환
    final drinkAmounts = <DrinkAmount>[];
    for (var i = 0; i < _drinkInputs.length; i++) {
      final input = _drinkInputs[i];

      // 술 종류가 미정인지 확인
      if (input.drinkType == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('음주량 ${i + 1}의 술 종류를 선택해주세요')));
        return;
      }

      final alcoholText = input.alcoholController.text.trim();
      final amountText = input.amountController.text.trim();

      if (alcoholText.isEmpty || amountText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음주량 ${i + 1}의 도수와 양을 모두 입력해주세요')),
        );
        return;
      }

      final alcohol = double.tryParse(alcoholText);
      final amount = double.tryParse(amountText);

      if (alcohol == null || amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음주량 ${i + 1}의 도수와 양은 숫자여야 합니다')),
        );
        return;
      }

      if (alcohol < 0 || alcohol > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음주량 ${i + 1}의 도수는 0~100 사이여야 합니다')),
        );
        return;
      }

      if (amount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('음주량 ${i + 1}의 양은 0보다 커야 합니다')));
        return;
      }

      // ml로 변환
      final amountInMl = amount * getUnitMultiplier(input.selectedUnit);

      drinkAmounts.add(
        DrinkAmount(
          drinkType: input.drinkType,
          alcoholContent: alcohol,
          amount: amountInMl,
        ),
      );
    }

    try {
      final updatedRecord = DrinkingRecord(
        id: widget.record.id, // 기존 ID 유지
        date: widget.record.date, // 날짜는 변경하지 않음
        sessionNumber: widget.record.sessionNumber, // 회차 유지
        meetingName: _meetingNameController.text,
        drunkLevel: _drunkLevel.toInt(),
        drinkAmounts: drinkAmounts,
        memo: {'text': _memoController.text},
        cost: _costController.text.isEmpty
            ? 0
            : int.parse(_costController.text),
      );

      final service = DrinkingRecordService();
      await service.updateRecord(updatedRecord);

      widget.onRecordUpdated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 수정되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReceiptDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 여백 (X 버튼 공간)
          const SizedBox(height: 60),
          // 스크롤 가능한 폼 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 모임명과 회차
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('모임명', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 2),
                            Text(
                              '*',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.record.sessionNumber}차',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _meetingNameController,
                    decoration: InputDecoration(
                      hintText: '피넛버터샌드위치',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 알딸딸 지수
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('알딸딸 지수', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 2),
                            Text(
                              '*',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(_drunkLevel * 10).toInt()}%',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Saku character visualization
                  Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            getBodyImagePath((_drunkLevel * 10).toInt()),
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          Image.asset(
                            'assets/saku/eyes.png',
                            width: 80 * 0.35,
                            height: 80 * 0.35,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '0%',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryPink,
                            thumbColor: AppColors.primaryPink,
                            overlayColor: AppColors.primaryPink.withValues(
                              alpha: 0.2,
                            ),
                            inactiveTrackColor: AppColors.primaryPink
                                .withValues(alpha: 0.3),
                          ),
                          child: Slider(
                            value: _drunkLevel,
                            min: 0,
                            max: 10,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                _drunkLevel = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const Text(
                        '100%',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 음주량
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('음주량', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 2),
                            Text(
                              '*',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 28),
                        onPressed: () {
                          setState(() {
                            _drinkInputs.add(
                              DrinkInputData(
                                drinkType: 0, // 미정
                                alcoholController: TextEditingController(
                                  text: '0.0',
                                ),
                                amountController: TextEditingController(
                                  text: '1.0',
                                ),
                                selectedUnit: '병',
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 음주량 리스트
                  ..._drinkInputs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final inputData = entry.value;
                    return DrinkInputCard(
                      inputData: inputData,
                      onTypeChange: (int newType) {
                        setState(() {
                          inputData.drinkType = newType;
                          inputData.alcoholController.text =
                              getDefaultAlcoholContent(newType).toString();
                          inputData.selectedUnit = getDefaultUnit(newType);
                        });
                      },
                      onUnitChange: (String newUnit) {
                        setState(() {
                          inputData.selectedUnit = newUnit;
                        });
                      },
                      onTypeTap: () {
                        DrinkTypeSelector.show(
                          context,
                          currentType: inputData.drinkType,
                          onSelect: (int newType) {
                            setState(() {
                              inputData.drinkType = newType;
                              inputData.alcoholController.text =
                                  getDefaultAlcoholContent(newType).toString();
                              inputData.selectedUnit = getDefaultUnit(newType);
                            });
                          },
                        );
                      },
                      onDelete: _drinkInputs.length > 1
                          ? () {
                              setState(() {
                                _drinkInputs.removeAt(index);
                              });
                            }
                          : null,
                    );
                  }),
                  const SizedBox(height: 24),

                  // 술값 (필수 아님)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '술값(지출 금액)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _costController,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      suffixText: '원',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // 메모 (필수 아님)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('메모', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _memoController,
                    decoration: InputDecoration(
                      hintText: '예: 주사, 숙취, 재미있는 에피소드 등',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 하단 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('수정'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
