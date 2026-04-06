import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/features/calendar/widgets/forms/drinking_record_form.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // 성공적으로 추가되었는지 여부 (취소 로그 방지용)
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logDrinkRecordStart();
  }

  @override
  void dispose() {
    if (!_isSuccess) {
      AnalyticsService.instance.logDrinkRecordCancel();
    }
    super.dispose();
  }

  Future<void> _handleSubmit({
    required String meetingName,
    required double drunkLevel,
    required List<CompletedDrinkRecord> records,
    required int cost,
    required String memo,
  }) async {
    // 중복 제출 방지
    if (_isSuccess) {
      return;
    }

    // Navigator and Messenger capture
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 완료된 기록들을 DrinkAmount로 변환
    final drinkAmounts = <DrinkAmount>[];
    for (var record in records) {
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

    final record = DrinkingRecord(
      id: '', // Firestore에서 자동 생성
      date: widget.selectedDate,
      sessionNumber: widget.sessionNumber,
      meetingName: meetingName,
      drunkLevel: drunkLevel,
      yearMonth:
          '${widget.selectedDate.year.toString().padLeft(4, '0')}-'
          '${widget.selectedDate.month.toString().padLeft(2, '0')}',
      drinkAmount: drinkAmounts,
      memo: {'text': memo},
      cost: cost,
    );

    // pop() 전에 필요한 참조를 캡처
    final service = ref.read(drinkingRecordServiceProvider);
    final lastUpdatedNotifier = ref.read(
      drinkingRecordsLastUpdatedProvider.notifier,
    );

    // Optimistic UI: 즉시 로컬 상태 업데이트 → 다이얼로그 닫기
    lastUpdatedNotifier.state = DateTime.now();
    widget.onRecordAdded();
    _isSuccess = true;

    navigator.pop();
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('기록이 추가되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );

    // 백그라운드에서 Firestore write + 부수 효과 처리
    try {
      await service.createRecord(record);

      // 서버 기록 완료 후 정확한 데이터로 캘린더 갱신 (sessionNumber 등)
      lastUpdatedNotifier.state = DateTime.now();

      AnalyticsService.instance.logDrinkRecordComplete(type: 'drink');
    } catch (e) {
      debugPrint('기록 추가 실패: $e');
      // 실패 시 캘린더 새로고침하여 optimistic 상태 되돌리기
      lastUpdatedNotifier.state = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            return DrinkingRecordForm(
              sessionNumber: widget.sessionNumber,
              submitButtonText: '추가',
              onSubmit: _handleSubmit,
            );
          },
        ),
      ),
    );
  }
}
