import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/drink_type_selector.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/drink_input_data.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/drink_input_card.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/circular_slider.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 기록 추가 다이얼로그
class AddRecordDialog extends ConsumerStatefulWidget {
  const AddRecordDialog({
    required this.selectedDate,
    required this.sessionNumber,
    required this.onRecordAdded,
    super.key,
  });

  final DateTime selectedDate;
  final int sessionNumber;
  final VoidCallback onRecordAdded;

  @override
  ConsumerState<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends ConsumerState<AddRecordDialog> {
  late final TextEditingController _meetingNameController;
  late final TextEditingController _costController;
  late final TextEditingController _memoController;
  double _drunkLevel = 0.0;
  late List<DrinkInputData> _drinkInputs;

  @override
  void initState() {
    super.initState();
    _meetingNameController = TextEditingController();
    _costController = TextEditingController();
    _memoController = TextEditingController();
    _drinkInputs = [
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
      final record = DrinkingRecord(
        id: '', // Firestore에서 자동 생성
        date: widget.selectedDate,
        sessionNumber: 0, // 서비스에서 자동 계산
        meetingName: _meetingNameController.text,
        drunkLevel: _drunkLevel.toInt(),
        yearMonth: DateFormat(
          'yyyy-MM',
        ).format(widget.selectedDate), // Added yearMonth
        drinkAmount: drinkAmounts, // Renamed from drinkAmounts
        memo: {'text': _memoController.text},
        cost: _costController.text.isEmpty
            ? 0
            : int.parse(_costController.text),
      );

      final service = ref.read(drinkingRecordServiceProvider);
      await service.createRecord(record);

      // 소셜 탭의 프로필 카드 업데이트를 위해 friendsProvider 새로고침
      ref.invalidate(friendsProvider);

      widget.onRecordAdded();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 추가되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('기록 추가 실패: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 실패: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 스크롤 가능한 폼 영역
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 모임명
                Row(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('모임명', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                        SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${widget.sessionNumber}차',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _meetingNameController,
                  decoration: InputDecoration(
                    hintText: '모임명을 입력해주세요.',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
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
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('알딸딸 지수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                        SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${(_drunkLevel * 10).toInt()}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 둥근 슬라이더와 캐릭터를 겹쳐서 표시
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 둥근 슬라이더
                        CircularSlider(
                          value: _drunkLevel * 10,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          size: 240,
                          trackWidth: 8,
                          inactiveColor: Colors.grey[300]!,
                          activeColor: const Color(0xFFFA75A5),
                          thumbColor: const Color(0xFFFA75A5),
                          thumbRadius: 12,
                          onChanged: (value) {
                            setState(() {
                              _drunkLevel = value / 10;
                            });
                          },
                        ),
                        // 가운데 캐릭터
                        SakuCharacter(
                          size: 120,
                          drunkLevel: (_drunkLevel * 10).toInt(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 음주량
                Row(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('음주량', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                        SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                      ],
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
                const Text(
                  '술값(지출 금액)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _costController,
                  decoration: InputDecoration(
                    hintText: '지출 금액 (선택)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    suffixText: '원',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // 메모 (필수 아님)
                const Text('메모', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                TextField(
                  controller: _memoController,
                  decoration: InputDecoration(
                    hintText: '오늘 모임의 기록을 남겨보세요. (선택)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                // 하단 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('추가'),
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
}
