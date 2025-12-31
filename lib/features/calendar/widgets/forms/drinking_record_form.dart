import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/drink_input_data.dart';
import 'package:ddalgguk/features/calendar/widgets/completed_drink_card.dart';
import 'package:ddalgguk/features/calendar/widgets/new_drink_input_card.dart';

import 'package:ddalgguk/shared/widgets/circular_slider.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';

class DrinkingRecordForm extends StatefulWidget {
  const DrinkingRecordForm({
    required this.sessionNumber,
    required this.submitButtonText,
    required this.onSubmit,
    this.initialMeetingName = '',
    this.initialCost = '',
    this.initialMemo = '',
    this.initialDrunkLevel = 0.0,
    this.initialRecords = const [],
    super.key,
  });

  final int sessionNumber;
  final String submitButtonText;
  final String initialMeetingName;
  final String initialCost;
  final String initialMemo;
  final double initialDrunkLevel;
  final List<CompletedDrinkRecord> initialRecords;
  final Future<void> Function({
    required String meetingName,
    required double drunkLevel,
    required List<CompletedDrinkRecord> records,
    required int cost,
    required String memo,
  })
  onSubmit;

  @override
  State<DrinkingRecordForm> createState() => _DrinkingRecordFormState();
}

class _DrinkingRecordFormState extends State<DrinkingRecordForm> {
  late final TextEditingController _meetingNameController;
  late final TextEditingController _costController;
  late final TextEditingController _memoController;
  late double _drunkLevel;

  // 현재 입력 중인 데이터
  late DrinkInputData _currentInput;

  // 완료된 기록들
  late final List<CompletedDrinkRecord> _completedRecords;

  @override
  void initState() {
    super.initState();
    _meetingNameController = TextEditingController(
      text: widget.initialMeetingName,
    );
    _costController = TextEditingController(text: widget.initialCost);
    _memoController = TextEditingController(text: widget.initialMemo);
    _drunkLevel = widget.initialDrunkLevel;

    // 리스트는 변경 가능해야 하므로 복사해서 사용
    _completedRecords = List.from(widget.initialRecords);

    _currentInput = _createNewInput();
  }

  @override
  void dispose() {
    _meetingNameController.dispose();
    _costController.dispose();
    _memoController.dispose();
    _currentInput.dispose();
    super.dispose();
  }

  DrinkInputData _createNewInput() {
    return DrinkInputData(
      drinkType: 0, // 미정
      alcoholController: TextEditingController(),
      amountController: TextEditingController(),
      selectedUnit: 'ml',
    );
  }

  void _handleAdd(BuildContext context) {
    final alcoholText = _currentInput.alcoholController.text.trim();
    final amountText = _currentInput.amountController.text.trim();

    // 술 종류 확인
    if (_currentInput.drinkType == 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('술 종류를 선택해주세요')));
      return;
    }

    // 입력값 확인
    if (alcoholText.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('도수와 양을 모두 입력해주세요')));
      return;
    }

    final alcohol = double.tryParse(alcoholText);
    final amount = double.tryParse(amountText);

    if (alcohol == null || amount == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('도수와 양은 숫자여야 합니다')));
      return;
    }

    if (alcohol < 0 || alcohol > 100) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('도수는 0~100 사이여야 합니다')));
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('양은 0보다 커야 합니다')));
      return;
    }

    // 완료된 기록에 추가
    setState(() {
      _completedRecords.add(
        CompletedDrinkRecord(
          drinkType: _currentInput.drinkType,
          alcoholContent: alcohol,
          amount: amount,
          unit: _currentInput.selectedUnit,
        ),
      );

      // 현재 입력 초기화
      _currentInput.dispose();
      _currentInput = _createNewInput();
    });
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final meetingName = _meetingNameController.text.trim();

    if (meetingName.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모임명을 입력해주세요')));
      return;
    }

    // 완료된 기록이 없으면 에러
    if (_completedRecords.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 한 개의 음주량을 추가해주세요')));
      return;
    }

    final cost = _costController.text.isEmpty
        ? 0
        : int.tryParse(_costController.text) ?? 0;
    final memo = _memoController.text;

    // 부모에게 데이터 전달
    await widget.onSubmit(
      meetingName: meetingName,
      drunkLevel: _drunkLevel,
      records: _completedRecords,
      cost: cost,
      memo: memo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
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
                          Text(
                            '모임명',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
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
                      SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                            trackWidth: 16,
                            inactiveColor: Colors.grey[300]!,
                            activeColor: const Color(0xFFFA75A5),
                            thumbColor: const Color(0xFFFA75A5),
                            thumbRadius: 14,
                            onChanged: (value) {
                              setState(() {
                                _drunkLevel = value / 10;
                              });
                            },
                          ),
                          // 가운데 컨텐츠
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 사쿠 캐릭터
                              SakuCharacter(
                                size: 80,
                                drunkLevel: (_drunkLevel * 10).toInt(),
                              ),
                              const SizedBox(height: 8),
                              // 퍼센트 표시
                              Text(
                                '${(_drunkLevel * 10).toInt()}%',
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
                      SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 완료된 기록 리스트
                  ..._completedRecords.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
                    return CompletedDrinkCard(
                      record: record,
                      onDelete: () {
                        setState(() {
                          _completedRecords.removeAt(index);
                        });
                      },
                    );
                  }),

                  // 현재 입력창
                  NewDrinkInputCard(
                    key: ValueKey(_currentInput.hashCode),
                    inputData: _currentInput,
                    onAdd: () => _handleAdd(context),
                  ),
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
                  const Text(
                    '메모',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
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
                          onPressed: () => _handleSubmit(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(widget.submitButtonText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
