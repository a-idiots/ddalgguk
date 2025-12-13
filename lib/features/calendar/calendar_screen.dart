import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/add_record_dialog.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/edit_record_dialog.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/drinking_record_detail_dialog.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/bottom_handle_dialogue.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

  void _updateRecordsMap(List<DrinkingRecord> records) {
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
    // Provider를 구독하기 위해 watch 필요
    ref.watch(monthRecordsProvider(_focusedDay));

    // 월별 기록 변경 감지
    ref.listen(monthRecordsProvider(_focusedDay), (previous, next) {
      next.whenData((records) {
        _updateRecordsMap(records);
      });
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Transform.translate(
        offset: const Offset(14, 0), // 오른쪽 20% 가리기
        child: SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            onPressed: () => _showAddRecordDialog(context),
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 32),
          ),
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
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[300],
                indent: 0,
                endIndent: 0,
              ),
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

    // 미래 날짜 체크
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isFutureDate = normalizedDate.isAfter(normalizedToday);

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
                isFutureDate
                    ? 'assets/imgs/calendar/future_date.png'
                    : 'assets/imgs/calendar/empty_date.png',
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
              Text(
                DateFormat('yyyy년 M월 d일').format(_selectedDay!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '음주 기록이 없습니다',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _confirmAndAddNoDrinkRecord(_selectedDay!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
                child: const Text(
                  '+ 금주 기록 추가하기',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
            indent: 0,
            endIndent: 0,
          ),
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordCard(record, index);
          },
        ),
        // 하단 구분선
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[300],
          indent: 0,
          endIndent: 0,
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  /// 기록 카드 빌드
  Widget _buildRecordCard(DrinkingRecord record, int index) {
    const sakuSize = 50.0;

    return Slidable(
      key: Key(record.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.45, //여기가 수정 및 삭제 가로세로 비율 조정 변수
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              _showEditRecordDialog(context, record);
            },
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            autoClose: true,
            flex: 1,
            child: const Text(
              '수정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              _deleteRecord(record.id);
            },
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
            autoClose: true,
            flex: 1,
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showRecordDetail(context, record),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 사쿠 캐릭터
              SakuCharacter(
                size: sakuSize,
                drunkLevel: record.drunkLevel * 10,
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 혈중 알콜 농도
                    Text(
                      '혈중알콜농도 ${record.drunkLevel * 10}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 음주량
                    if (record.drinkAmount.isNotEmpty) ...[
                      ...record.drinkAmount.map((drink) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Builder(
                            builder: (context) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              // 카드 왼쪽 padding (16) + 사쿠 (50) + 간격 (16) = 82
                              return SizedBox(
                                width: screenWidth - 50,
                                child: Row(
                                  children: [
                                    Text(
                                      '${getDrinkTypeName(drink.drinkType)} ${drink.alcoholContent}%',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      ' ················································· ',
                                      style: const TextStyle(fontSize: 12,
                                      color: AppColors.grey),
                                    ),
                                    Text(
                                      formatDrinkAmount(drink.amount),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 2),
                    ],
                    // 지출 금액
                    Text(
                      '${NumberFormat('#,###').format(record.cost)}원',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 우측: 회차 (상단에 배치)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red[300]!, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${record.sessionNumber}차',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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

    try {
      final record = DrinkingRecord(
        id: '', // Firestore에서 자동 생성
        date: date,
        sessionNumber: 0, // 서비스에서 자동 계산
        meetingName: '금주',
        drunkLevel: 0,
        yearMonth: DateFormat('yyyy-MM').format(_selectedDay!),
        drinkAmount: [],
        memo: {'text': '술을 한방울도 안마셨어요!'},
        cost: 0,
      );

      final service = ref.read(drinkingRecordServiceProvider);
      await service.createRecord(record);

      // 캘린더 새로고침을 위해 provider invalidate
      ref.invalidate(monthRecordsProvider(_focusedDay));
      // 소셜 탭의 프로필 카드 업데이트를 위해 friendsProvider 새로고침
      ref.invalidate(friendsProvider);

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

    showBottomHandleDialogue(
      context: context,
      child: AddRecordDialog(
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
    showBottomHandleDialogue(
      context: context,
      child: EditRecordDialog(
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
    showBottomHandleDialogue(
      context: context,
      child: DrinkingRecordDetailDialog(
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
        // 소셜 탭의 프로필 카드 업데이트를 위해 friendsProvider 새로고침
        ref.invalidate(friendsProvider);

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
