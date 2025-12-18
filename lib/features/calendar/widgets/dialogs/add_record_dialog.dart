import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/drink_input_data.dart';
import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/new_drink_input_card.dart';
import 'package:ddalgguk/features/calendar/widgets/completed_drink_card.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/circular_slider.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ddalgguk/core/services/analytics_service.dart';

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

  // 현재 입력 중인 데이터
  late DrinkInputData _currentInput;

  // 완료된 기록들
  final List<CompletedDrinkRecord> _completedRecords = [];

  // 성공적으로 추가되었는지 여부 (취소 로그 방지용)
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _meetingNameController = TextEditingController();
    _costController = TextEditingController();
    _memoController = TextEditingController();
    _currentInput = _createNewInput();
    AnalyticsService.instance.logDrinkRecordStart();
  }

  @override
  void dispose() {
    _meetingNameController.dispose();
    _costController.dispose();
    _memoController.dispose();
    _currentInput.dispose();
    if (!_isSuccess) {
      AnalyticsService.instance.logDrinkRecordCancel();
    }
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

  void _handleAdd(BuildContext localContext) {
    final alcoholText = _currentInput.alcoholController.text.trim();
    final amountText = _currentInput.amountController.text.trim();

    // 술 종류 확인
    if (_currentInput.drinkType == 0) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
      ).showSnackBar(const SnackBar(content: Text('술 종류를 선택해주세요')));
      return;
    }

    // 입력값 확인
    if (alcoholText.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
      ).showSnackBar(const SnackBar(content: Text('도수와 양을 모두 입력해주세요')));
      return;
    }

    final alcohol = double.tryParse(alcoholText);
    final amount = double.tryParse(amountText);

    if (alcohol == null || amount == null) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
      ).showSnackBar(const SnackBar(content: Text('도수와 양은 숫자여야 합니다')));
      return;
    }

    if (alcohol < 0 || alcohol > 100) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
      ).showSnackBar(const SnackBar(content: Text('도수는 0~100 사이여야 합니다')));
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
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

  Future<void> _handleSubmit(BuildContext localContext) async {
    if (_meetingNameController.text.isEmpty) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
      ).showSnackBar(const SnackBar(content: Text('모임명을 입력해주세요')));
      return;
    }

    // 완료된 기록이 없으면 에러
    if (_completedRecords.isEmpty) {
      ScaffoldMessenger.of(localContext).clearSnackBars();
      ScaffoldMessenger.of(
        localContext,
      ).showSnackBar(const SnackBar(content: Text('최소 한 개의 음주량을 추가해주세요')));
      return;
    }

    // 완료된 기록들을 DrinkAmount로 변환
    final drinkAmounts = <DrinkAmount>[];
    for (var record in _completedRecords) {
      // ml로 변환
      final amountInMl =
          record.amount * getUnitMultiplier(record.drinkType, record.unit);

      drinkAmounts.add(
        DrinkAmount(
          drinkType: record.drinkType,
          alcoholContent: record.alcoholContent,
          amount: amountInMl,
        ),
      );
    }

    // Capture Navigator and ScaffoldMessenger before async gap
    final navigator = Navigator.of(localContext);
    final scaffoldMessenger = ScaffoldMessenger.of(localContext);

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

      // 데이터 변경 알림
      ref.read(drinkingRecordsLastUpdatedProvider.notifier).state =
          DateTime.now();

      // 소셜 탭의 프로필 카드 업데이트를 위해 friendsProvider 새로고침
      ref.invalidate(friendsProvider);

      widget.onRecordAdded();

      _isSuccess = true;
      await AnalyticsService.instance.logDrinkRecordComplete(type: 'drink');

      if (mounted) {
        navigator.pop();
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('기록이 추가되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('기록 추가 실패: $e');

      if (mounted) {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
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
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                    ),
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
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[400]!,
                                ),
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
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red,
                                ),
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
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 완료된 기록 리스트
                          ..._completedRecords.map((record) {
                            return CompletedDrinkCard(
                              record: record,
                              onDelete: () {
                                setState(() {
                                  _completedRecords.remove(record);
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
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
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[400]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
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
                          TextField(
                            controller: _memoController,
                            decoration: InputDecoration(
                              hintText: '오늘 모임의 기록을 남겨보세요. (선택)',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[400]!,
                                ),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
