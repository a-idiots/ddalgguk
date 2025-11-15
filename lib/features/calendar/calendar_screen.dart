import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/data/services/drinking_record_service.dart';
import 'package:ddalgguk/features/calendar/dialogs/add_record_dialog.dart';
import 'package:ddalgguk/features/calendar/dialogs/edit_record_dialog.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/drinking_record_detail_dialog.dart';
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
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
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
                    // enabledDayPredicate를 제거하여 모든 날짜 선택 가능하도록 변경
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
                      disabledBuilder: (context, date, focusedDay) {
                        // 미래 날짜도 동일하게 표시 (단, 선택 불가)
                        final isOutsideMonth = date.month != focusedDay.month;
                        return _buildDayCell(
                          date,
                          isOutsideMonth: isOutsideMonth,
                          isToday: false,
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

    // 기록 유무 및 최대 취함 정도 확인
    final records = _getRecordsForDay(date);
    final hasRecord = records.isNotEmpty;
    final maxDrunkLevel = hasRecord
        ? records.map((r) => r.drunkLevel).reduce((a, b) => a > b ? a : b)
        : 0;

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
                      getBodyImagePath(maxDrunkLevel),
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
        return _buildRecordCard(record, index);
      },
    );
  }

  /// 기록 카드 빌드
  Widget _buildRecordCard(DrinkingRecord record, int index) {
    const sakuSize = 60.0;
    const eyesScale = 0.35;

    return GestureDetector(
      onTap: () => _showRecordDetail(context, record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 사쿠 캐릭터
            SizedBox(
              width: sakuSize,
              height: sakuSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    getBodyImagePath(record.drunkLevel),
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
            const SizedBox(width: 16),
            // 중앙: 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 모임명
                  Text(
                    record.meetingName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 혈중 알콜 농도
                  Text(
                    '혈중알콜농도 ${record.drunkLevel * 10}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 음주량
                  if (record.drinkAmounts.isNotEmpty) ...[
                    ...record.drinkAmounts.map((drink) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${getDrinkTypeName(drink.drinkType)} ${drink.alcoholContent}% ${formatDrinkAmount(drink.amount)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                  ],
                  // 지출 금액
                  Text(
                    '${NumberFormat('#,###').format(record.cost)}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // 우측: 회차 및 액션 버튼
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${record.sessionNumber}차',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditRecordDialog(context, record),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteRecord(record.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 무음주 기록 추가
  Future<void> _addNoDrinkRecord(DateTime date) async {
    // 미래 날짜 체크
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (normalizedDate.isAfter(normalizedToday)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미래의 기록은 미리 추가할 수 없습니다'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

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
          const SnackBar(
            content: Text('무음주 기록이 추가되었습니다!'),
            duration: Duration(seconds: 2),
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
    final selectedDate = _selectedDay ?? DateTime.now();

    // 미래 날짜 체크
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedSelectedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (normalizedSelectedDate.isAfter(normalizedToday)) {
      // 미래 날짜인 경우 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('미래의 기록은 미리 추가할 수 없습니다'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final records = _getRecordsForDay(selectedDate);
    final sessionNumber = records.length + 1;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => AddRecordDialog(
        selectedDate: selectedDate,
        sessionNumber: sessionNumber,
        onRecordAdded: () {
          // 캘린더 새로고침을 위해 provider invalidate
          ref.invalidate(monthRecordsProvider(_focusedDay));
        },
      ),
    );
  }

  /// 기록 수정 다이얼로그
  void _showEditRecordDialog(BuildContext context, DrinkingRecord record) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => EditRecordDialog(
        record: record,
        onRecordUpdated: () {
          // 캘린더 새로고침을 위해 provider invalidate
          ref.invalidate(monthRecordsProvider(_focusedDay));
        },
      ),
    );
  }

  /// 기록 상세 보기
  void _showRecordDetail(BuildContext context, DrinkingRecord record) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => DrinkingRecordDetailDialog(record: record),
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
