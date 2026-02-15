import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/features/calendar/widgets/forms/drinking_record_form.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
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
  // 초기 데이터
  late final List<CompletedDrinkRecord> _initialRecords;

  @override
  void initState() {
    super.initState();
    _initialRecords = _prepareInitialRecords();
  }

  List<CompletedDrinkRecord> _prepareInitialRecords() {
    final records = <CompletedDrinkRecord>[];
    for (var drink in widget.record.drinkAmount) {
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

      records.add(
        CompletedDrinkRecord(
          drinkType: drink.drinkType,
          alcoholContent: drink.alcoholContent,
          amount: amount,
          unit: unit,
        ),
      );
    }
    return records;
  }

  Future<void> _handleSubmit({
    required String meetingName,
    required double drunkLevel,
    required List<CompletedDrinkRecord> records,
    required int cost,
    required String memo,
  }) async {
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

    try {
      final updatedRecord = DrinkingRecord(
        id: widget.record.id, // 기존 ID 유지
        date: widget.record.date, // 날짜는 변경하지 않음
        sessionNumber: widget.record.sessionNumber, // 회차 유지
        meetingName: meetingName,
        drunkLevel: drunkLevel,
        yearMonth: widget.record.yearMonth, // 기존 yearMonth 유지
        drinkAmount: drinkAmounts,
        memo: {'text': memo},
        cost: cost,
      );

      final service = DrinkingRecordService();
      await service.updateRecord(updatedRecord);

      // 데이터 변경 알림
      ref.read(drinkingRecordsLastUpdatedProvider.notifier).state =
          DateTime.now();

      // 소셜 탭의 프로필 카드 업데이트를 위해 friendsProvider 새로고침
      ref.invalidate(friendsProvider);

      widget.onRecordUpdated();

      if (mounted) {
        navigator.pop();
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('기록이 수정되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
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
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            return DrinkingRecordForm(
              sessionNumber: widget.record.sessionNumber,
              submitButtonText: '수정',
              initialMeetingName: widget.record.meetingName,
              initialCost: widget.record.cost > 0
                  ? widget.record.cost.toString()
                  : '',
              initialMemo: widget.record.memo['text'] as String? ?? '',
              initialDrunkLevel: widget.record.drunkLevel.toDouble(),
              initialRecords: _initialRecords,
              onSubmit: _handleSubmit,
            );
          },
        ),
      ),
    );
  }
}
