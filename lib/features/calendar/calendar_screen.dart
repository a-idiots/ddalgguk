import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/add_record_dialog.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/edit_record_dialog.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/drinking_record_detail_dialog.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
        offset: const Offset(-3, 0), // 기록 추가 버튼 우측 패딩
        child: FloatingActionButton(
          onPressed: () => _showAddRecordDialog(context),
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 캘린더 영역 - 고정 높이로 표시
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Center(
                  child: Transform.scale(
                    scale: 0.9,
                    child: FractionallySizedBox(
                      widthFactor: 1.05,
                      child: TableCalendar<DrinkingRecord>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
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
                            final isOutsideMonth =
                                date.month != focusedDay.month;
                            final isToday = isSameDay(DateTime.now(), date);
                            return _buildDayCell(
                              date,
                              isOutsideMonth: isOutsideMonth,
                              isToday: isToday,
                            );
                          },
                          todayBuilder: (context, date, focusedDay) {
                            final isOutsideMonth =
                                date.month != focusedDay.month;
                            return _buildDayCell(
                              date,
                              isOutsideMonth: isOutsideMonth,
                              isToday: true,
                            );
                          },
                          selectedBuilder: (context, date, focusedDay) {
                            final isOutsideMonth =
                                date.month != focusedDay.month;
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
                            final isOutsideMonth =
                                date.month != focusedDay.month;
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
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // 음주 기록 리스트 - 스크롤 가능
              _buildRecordsList(),
            ],
          ),
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

    // 기록 유무 및 평균 취함 정도 확인
    final records = _getRecordsForDay(date);
    final hasRecord = records.isNotEmpty;
    final avgDrunkLevel = hasRecord
        ? (records.map((r) => r.drunkLevel).reduce((a, b) => a + b) /
                  records.length)
              .round()
        : 0;

    const sakuSize = 44.0;

    return Center(
      child: SizedBox(
        width: 56,
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 선택된 날짜 배경 (위쪽 여백 추가)
            if (isSelected)
              Positioned(
                top: 8,
                bottom: -4,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
            // 기록이 있을 때만 사쿠 캐릭터를 위에 겹침
            if (hasRecord)
              Opacity(
                opacity: isOutsideMonth ? 0.35 : 1,
                child: SakuCharacter(
                  size: sakuSize,
                  drunkLevel: avgDrunkLevel * 10,
                ),
              ),
            Positioned(
              bottom: 0,
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('날짜를 선택하세요')),
      );
    }

    final records = _getRecordsForDay(_selectedDay!);

    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_bar, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                DateFormat('yyyy년 M월 d일').format(_selectedDay!),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '음주 기록이 없습니다',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _confirmAndAddNoDrinkRecord(_selectedDay!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('금주 기록 추가하기'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            SakuCharacter(size: sakuSize, drunkLevel: record.drunkLevel * 10),
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
                        child: Row(
                          children: [
                            Text(
                              '${getDrinkTypeName(drink.drinkType)} ${drink.alcoholContent}%',
                              style: const TextStyle(fontSize: 13),
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
                                  child: const SizedBox(height: 13),
                                ),
                              ),
                            ),
                            Text(
                              formatDrinkAmount(drink.amount),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
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
            // 우측: 회차
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ],
        ),
      ),
    );
  }

  /// 금주 기록 추가 확인 및 추가
  Future<void> _confirmAndAddNoDrinkRecord(DateTime date) async {
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

    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('금주 기록 추가'),
        content: Text(
          '${DateFormat('yyyy년 M월 d일').format(date)}에\n금주 기록을 추가하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final record = DrinkingRecord(
        id: '', // Firestore에서 자동 생성
        date: date,
        sessionNumber: 0, // 서비스에서 자동 계산
        meetingName: '금주',
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
            content: Text('금주 기록이 추가되었습니다!'),
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
      builder: (context) => DrinkingRecordDetailDialog(
        record: record,
        onEdit: () => _showEditRecordDialog(context, record),
        onDelete: () => _deleteRecord(record.id),
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

        // 삭제하기 전에 해당 기록의 정보를 가져옴
        final recordToDelete = await service.getRecord(recordId);
        if (recordToDelete == null) {
          throw Exception('기록을 찾을 수 없습니다');
        }

        final deletedDate = recordToDelete.date;
        final deletedSessionNumber = recordToDelete.sessionNumber;

        // 기록 삭제
        await service.deleteRecord(recordId);

        // 같은 날짜의 남은 기록들을 가져옴
        final remainingRecords = await service.getRecordsByDate(deletedDate);

        // 삭제된 차수보다 큰 차수를 가진 기록들의 차수를 1씩 감소
        for (final record in remainingRecords) {
          if (record.sessionNumber > deletedSessionNumber) {
            final updatedRecord = record.copyWith(
              sessionNumber: record.sessionNumber - 1,
            );
            await service.updateRecord(updatedRecord);
          }
        }

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
