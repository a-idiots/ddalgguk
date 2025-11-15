import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Provider for DrinkingRecordService
final drinkingRecordServiceProvider = Provider<DrinkingRecordService>((ref) {
  return DrinkingRecordService();
});

// Provider for selected month's records
final monthRecordsProvider =
    StreamProvider.family<List<DrinkingRecord>, DateTime>((ref, date) {
      final service = ref.watch(drinkingRecordServiceProvider);
      return service.streamRecordsByMonth(date.year, date.month);
    });

/// 음주량 입력 데이터를 관리하는 헬퍼 클래스
class _DrinkInputData {
  _DrinkInputData({
    required this.drinkType,
    required this.alcoholController,
    required this.amountController,
    required this.selectedUnit,
  });

  int drinkType;
  final TextEditingController alcoholController;
  final TextEditingController amountController;
  String selectedUnit;

  void dispose() {
    alcoholController.dispose();
    amountController.dispose();
  }
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<DrinkingRecord>> _recordsMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// 날짜를 키로 사용하기 위해 시간 정보를 제거
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 특정 날짜의 음주 기록 가져오기
  List<DrinkingRecord> _getRecordsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return _recordsMap[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(monthRecordsProvider(_focusedDay));

    // 월별 기록이 변경되면 맵 업데이트
    recordsAsync.whenData((records) {
      final newMap = <DateTime, List<DrinkingRecord>>{};
      for (final record in records) {
        final normalizedDate = _normalizeDate(record.date);
        if (!newMap.containsKey(normalizedDate)) {
          newMap[normalizedDate] = [];
        }
        newMap[normalizedDate]!.add(record);
      }
      if (mounted) {
        setState(() {
          _recordsMap = newMap;
        });
      }
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Transform.translate(
        offset: const Offset(16, 0),
        child: FloatingActionButton(
          onPressed: () => _showAddRecordDialog(context),
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 캘린더 영역 - 고정 높이로 표시
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.95,
                  child: TableCalendar<DrinkingRecord>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 72,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 1,
                      outsideDaysVisible: false,
                      markerDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      todayDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    eventLoader: _getRecordsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, focusedDay) {
                        final isOutsideMonth = date.month != focusedDay.month;
                        final isToday = isSameDay(DateTime.now(), date);
                        return _buildDayCell(
                          date,
                          isOutsideMonth: isOutsideMonth,
                          isToday: isToday,
                        );
                      },
                      todayBuilder: (context, date, focusedDay) {
                        final isOutsideMonth = date.month != focusedDay.month;
                        return _buildDayCell(
                          date,
                          isOutsideMonth: isOutsideMonth,
                          isToday: true,
                        );
                      },
                      selectedBuilder: (context, date, focusedDay) {
                        final isOutsideMonth = date.month != focusedDay.month;
                        final isToday = isSameDay(DateTime.now(), date);
                        return _buildDayCell(
                          date,
                          isOutsideMonth: isOutsideMonth,
                          isToday: isToday,
                          isSelected: true,
                        );
                      },
                      outsideBuilder: (context, date, focusedDay) =>
                          const SizedBox.shrink(),
                      markerBuilder: (context, date, records) {
                        // markerBuilder는 사용하지 않음 (이미 _buildDayCell에서 처리)
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // 음주 기록 리스트 - 나머지 공간을 차지하며 스크롤 가능
            Expanded(child: _buildRecordsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
    bool isOutsideMonth = false,
  }) {
    if (isOutsideMonth) {
      return const SizedBox.shrink();
    }
    final textColor = isOutsideMonth
        ? Colors.grey
        : isToday
        ? Colors.red
        : Colors.black87;

    // 기록 유무 확인
    final hasRecord = _getRecordsForDay(date).isNotEmpty;

    const sakuSize = 44.0;
    const eyesScale = 0.35;

    return Center(
      child: SizedBox(
        width: 48,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 기본 플레이스홀더 (항상 표시)
            Opacity(
              opacity: isOutsideMonth ? 0.25 : 0.5,
              child: Image.asset(
                'assets/calendar/empty_date.png',
                width: sakuSize,
                height: sakuSize,
                fit: BoxFit.contain,
              ),
            ),
            // 기록이 있을 때만 사쿠 이미지를 위에 겹침
            if (hasRecord)
              Opacity(
                opacity: isOutsideMonth ? 0.35 : 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/saku_gradient/body1.png',
                      width: sakuSize,
                      height: sakuSize,
                      fit: BoxFit.contain,
                    ),
                    Image.asset(
                      'assets/saku/eyes.png',
                      width: sakuSize * eyesScale,
                      height: sakuSize * eyesScale,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: -6,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 선택된 날짜의 기록 목록 표시
  Widget _buildRecordsList() {
    if (_selectedDay == null) {
      return const Center(child: Text('날짜를 선택하세요'));
    }

    final records = _getRecordsForDay(_selectedDay!);

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_bar, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy년 M월 d일').format(_selectedDay!),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '음주 기록이 없습니다',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addNoDrinkRecord(_selectedDay!),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('술을 한방울도 안마셨어요!'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text('${record.sessionNumber}차')),
            title: Text(
              record.meetingName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('취함 정도: ${record.drunkLevel}/10'),
                Text('술값: ${NumberFormat('#,###').format(record.cost)}원'),
                if (record.drinkAmounts.isNotEmpty)
                  Text(
                    '음주량: ${record.drinkAmounts.length}종류',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditRecordDialog(context, record),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteRecord(record.id),
                ),
              ],
            ),
            onTap: () => _showRecordDetail(context, record),
          ),
        );
      },
    );
  }

  /// 무음주 기록 추가
  Future<void> _addNoDrinkRecord(DateTime date) async {
    try {
      final record = DrinkingRecord(
        id: '', // Firestore에서 자동 생성
        date: date,
        sessionNumber: 0, // 서비스에서 자동 계산
        meetingName: '무음주',
        drunkLevel: 0,
        drinkAmounts: [],
        memo: {'text': '술을 한방울도 안마셨어요!'},
        cost: 0,
      );

      final service = ref.read(drinkingRecordServiceProvider);
      await service.createRecord(record);

      // 캘린더 새로고침을 위해 provider invalidate
      ref.invalidate(monthRecordsProvider(_focusedDay));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('무음주 기록이 추가되었습니다!'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기록 추가 실패: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 기록 추가 다이얼로그
  void _showAddRecordDialog(BuildContext context) {
    final meetingNameController = TextEditingController();
    final costController = TextEditingController();
    final memoController = TextEditingController();
    double drunkLevel = 5.0;
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    // 음주량 입력 데이터 (컨트롤러와 메타데이터만 관리)
    final drinkInputs = <_DrinkInputData>[
      _DrinkInputData(
        drinkType: 2, // 맥주
        alcoholController: TextEditingController(text: '5.0'),
        amountController: TextEditingController(text: '1.0'),
        selectedUnit: '병',
      ),
    ];
    bool showDetailFields = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final screenHeight = MediaQuery.of(context).size.height;
          final maxDialogHeight = screenHeight * 0.85;

          // 선택된 날짜의 기록 개수를 가져와서 회차 결정 (날짜 변경 시마다 업데이트)
          final records = _getRecordsForDay(selectedDate);
          final sessionNumber = records.length + 1;

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
                                    child: const Text(
                                      '모임명',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${sessionNumber}차',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: meetingNameController,
                                decoration: const InputDecoration(
                                  hintText: '피넛버터샌드위치',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
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
                                    child: const Text(
                                      '알딸딸 지수',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(drunkLevel * 10).toInt()}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    '0%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: drunkLevel,
                                      min: 0,
                                      max: 10,
                                      divisions: 20,
                                      onChanged: (value) {
                                        setState(() {
                                          drunkLevel = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const Text(
                                    '100%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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
                                    child: const Text(
                                      '음주량',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        drinkInputs.add(
                                          _DrinkInputData(
                                            drinkType: 2, // 기본 맥주
                                            alcoholController:
                                                TextEditingController(
                                                  text: '5.0',
                                                ),
                                            amountController:
                                                TextEditingController(
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
                              ...drinkInputs.asMap().entries.map((entry) {
                                final index = entry.key;
                                final inputData = entry.value;
                                return _buildDrinkInputCard(
                                  inputData: inputData,
                                  onTypeChange: (int newType) {
                                    setState(() {
                                      inputData.drinkType = newType;
                                      inputData.alcoholController.text =
                                          _getDefaultAlcoholContent(
                                            newType,
                                          ).toString();
                                      inputData.selectedUnit = _getDefaultUnit(
                                        newType,
                                      );
                                    });
                                  },
                                  onUnitChange: (String newUnit) {
                                    setState(() {
                                      inputData.selectedUnit = newUnit;
                                    });
                                  },
                                  onDelete: drinkInputs.length > 1
                                      ? () {
                                          setState(() {
                                            drinkInputs.removeAt(index);
                                          });
                                        }
                                      : null,
                                );
                              }),
                              const SizedBox(height: 16),

                              // 상세 기록하기 버튼
                              TextButton.icon(
                                icon: Icon(
                                  showDetailFields ? Icons.remove : Icons.add,
                                  size: 16,
                                ),
                                label: const Text(
                                  '상세 기록하기',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  setState(() {
                                    showDetailFields = !showDetailFields;
                                  });
                                },
                              ),

                              // 메모와 술값 (상세 기록)
                              if (showDetailFields) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: memoController,
                                  decoration: const InputDecoration(
                                    labelText: '메모',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: costController,
                                  decoration: const InputDecoration(
                                    labelText: '술값(지출 금액)',
                                    suffixText: '원',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
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
                              onPressed: () async {
                                if (meetingNameController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('모임명을 입력해주세요'),
                                    ),
                                  );
                                  return;
                                }

                                // 음주량 입력 유효성 검사 및 변환
                                final drinkAmounts = <DrinkAmount>[];
                                for (var i = 0; i < drinkInputs.length; i++) {
                                  final input = drinkInputs[i];
                                  final alcoholText = input
                                      .alcoholController
                                      .text
                                      .trim();
                                  final amountText = input.amountController.text
                                      .trim();

                                  if (alcoholText.isEmpty ||
                                      amountText.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '음주량 ${i + 1}의 도수와 양을 모두 입력해주세요',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final alcohol = double.tryParse(alcoholText);
                                  final amount = double.tryParse(amountText);

                                  if (alcohol == null || amount == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '음주량 ${i + 1}의 도수와 양은 숫자여야 합니다',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (alcohol < 0 || alcohol > 100) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '음주량 ${i + 1}의 도수는 0~100 사이여야 합니다',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '음주량 ${i + 1}의 양은 0보다 커야 합니다',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ml로 변환
                                  final amountInMl =
                                      amount *
                                      _getUnitMultiplier(input.selectedUnit);

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
                                    date: selectedDate,
                                    sessionNumber: 0, // 서비스에서 자동 계산
                                    meetingName: meetingNameController.text,
                                    drunkLevel: drunkLevel.toInt(),
                                    drinkAmounts: drinkAmounts,
                                    memo: {'text': memoController.text},
                                    cost: costController.text.isEmpty
                                        ? 0
                                        : int.parse(costController.text),
                                  );

                                  debugPrint('=== 기록 추가 시작 ===');
                                  debugPrint('모임명: ${record.meetingName}');
                                  debugPrint('날짜: ${record.date}');
                                  debugPrint(
                                    '음주량 개수: ${record.drinkAmounts.length}',
                                  );

                                  final service = ref.read(
                                    drinkingRecordServiceProvider,
                                  );
                                  final recordId = await service.createRecord(
                                    record,
                                  );

                                  debugPrint('기록 ID: $recordId');
                                  debugPrint('=== 기록 추가 완료 ===');

                                  // 캘린더 새로고침을 위해 provider invalidate
                                  ref.invalidate(monthRecordsProvider(_focusedDay));

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '기록이 추가되었습니다 (ID: $recordId)',
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e, stackTrace) {
                                  debugPrint('=== 기록 추가 실패 ===');
                                  debugPrint('에러: $e');
                                  debugPrint('스택트레이스: $stackTrace');

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('추가 실패: $e'),
                                        duration: const Duration(seconds: 5),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('추가'),
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
        },
      ),
    );
  }

  /// 술 종류 버튼 빌더
  Widget _buildDrinkTypeButton(
    int drinkType,
    String label,
    int selectedType,
    Function(int) onSelect,
  ) {
    final isSelected = drinkType == selectedType;
    return GestureDetector(
      onTap: () {
        onSelect(drinkType);
        Navigator.pop(context); // 선택 후 말풍선 닫기
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(child: _getDrinkIcon(drinkType)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 술 종류에 따른 아이콘 반환
  Widget _getDrinkIcon(int drinkType) {
    switch (drinkType) {
      case 1: // 소주
        return const Icon(Icons.liquor, size: 22);
      case 2: // 맥주
        return const Icon(Icons.sports_bar, size: 22);
      case 3: // 와인
        return const Icon(Icons.wine_bar, size: 22);
      case 4: // 막걸리
        return const Icon(Icons.local_bar, size: 22);
      case 5: // 칵테일
        return const Icon(Icons.local_bar, size: 22);
      case 6: // 위스키
        return const Icon(Icons.liquor, size: 22);
      default:
        return const Icon(Icons.local_bar, size: 22);
    }
  }

  /// 주종별 기본 도수
  double _getDefaultAlcoholContent(int drinkType) {
    switch (drinkType) {
      case 1: // 소주
        return 16.5;
      case 2: // 맥주
        return 5.0;
      case 3: // 와인
        return 12.0;
      case 4: // 막걸리
        return 4.0;
      case 5: // 칵테일
        return 0.0;
      case 6: // 위스키
        return 0.0;
      default:
        return 0.0;
    }
  }

  /// 주종별 기본 단위
  String _getDefaultUnit(int drinkType) {
    switch (drinkType) {
      case 1: // 소주
        return '병';
      case 2: // 맥주
        return '병';
      case 3: // 와인
        return '잔';
      case 4: // 막걸리
        return '병';
      case 5: // 칵테일
        return '잔';
      case 6: // 위스키
        return '잔';
      default:
        return '병';
    }
  }

  /// 단위별 ml 변환
  double _getUnitMultiplier(String unit) {
    switch (unit) {
      case '병':
        return 500.0;
      case '잔':
        return 150.0;
      case 'ml':
        return 1.0;
      default:
        return 500.0;
    }
  }

  /// 주종 이름
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

  /// 음주량 입력 카드 빌더 (텍스트 입력 방식)
  Widget _buildDrinkInputCard({
    required _DrinkInputData inputData,
    required Function(int) onTypeChange,
    required Function(String) onUnitChange,
    Function()? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 상단: 아이콘, 도수, 양
          Row(
            children: [
              // 술 종류 아이콘 (탭하면 선택 가능)
              GestureDetector(
                onTap: () {
                  _showDrinkTypeSelector(
                    context,
                    currentType: inputData.drinkType,
                    onSelect: onTypeChange,
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: _getDrinkIcon(inputData.drinkType)),
                ),
              ),
              const SizedBox(width: 8),
              // 도수 입력
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '도수',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: inputData.alcoholController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Text('%', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 양 입력 with 단위 선택
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '양',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: inputData.amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 2),
                      PopupMenuButton<String>(
                        initialValue: inputData.selectedUnit,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              inputData.selectedUnit,
                              style: const TextStyle(fontSize: 11),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                        onSelected: onUnitChange,
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: '병',
                                child: Text('병'),
                              ),
                              const PopupMenuItem<String>(
                                value: '잔',
                                child: Text('잔'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'ml',
                                child: Text('ml'),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 하단: 주종 이름과 삭제 버튼 (선택적)
          if (onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDrinkTypeName(inputData.drinkType),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 술 종류 선택기 (하단 말풍선 형태)
  void _showDrinkTypeSelector(
    BuildContext context, {
    required int currentType,
    required Function(int) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '술 종류 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // 좌우 스크롤 가능한 아이콘 리스트
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildDrinkTypeButton(1, '소주', currentType, onSelect),
                  const SizedBox(width: 16),
                  _buildDrinkTypeButton(2, '맥주', currentType, onSelect),
                  const SizedBox(width: 16),
                  _buildDrinkTypeButton(3, '와인', currentType, onSelect),
                  const SizedBox(width: 16),
                  _buildDrinkTypeButton(4, '막걸리', currentType, onSelect),
                  const SizedBox(width: 16),
                  _buildDrinkTypeButton(5, '칵테일', currentType, onSelect),
                  const SizedBox(width: 16),
                  _buildDrinkTypeButton(6, '위스키', currentType, onSelect),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      // 말풍선 닫힐 때 추가 동작 필요시 여기에
    });
  }

  /// 기록 수정 다이얼로그
  void _showEditRecordDialog(BuildContext context, DrinkingRecord record) {
    // TODO: 실제 수정 폼 구현
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('음주 기록 수정'),
        content: const Text('음주 기록 수정 기능은 곧 구현됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 기록 상세 보기
  void _showRecordDetail(BuildContext context, DrinkingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${record.meetingName} - ${record.sessionNumber}차'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('날짜: ${DateFormat('yyyy-MM-dd').format(record.date)}'),
              const SizedBox(height: 8),
              Text('취함 정도: ${record.drunkLevel}/10'),
              const SizedBox(height: 8),
              Text('술값: ${NumberFormat('#,###').format(record.cost)}원'),
              const SizedBox(height: 8),
              const Text('음주량:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...record.drinkAmounts.map(
                (drink) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    '종류 ${drink.drinkType}: ${drink.amount}ml (${drink.alcoholContent}%)',
                  ),
                ),
              ),
              if (record.memo.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '메모:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(record.memo.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 기록 삭제
  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(drinkingRecordServiceProvider);
        await service.deleteRecord(recordId);

        // 캘린더 새로고침을 위해 provider invalidate
        ref.invalidate(monthRecordsProvider(_focusedDay));

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('기록이 삭제되었습니다')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }
}
