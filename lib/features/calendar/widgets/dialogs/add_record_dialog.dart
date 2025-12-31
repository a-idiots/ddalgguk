import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';
import 'package:ddalgguk/features/calendar/domain/models/drinking_record.dart';
import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/features/calendar/widgets/forms/drinking_record_form.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
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
      final record = DrinkingRecord(
        id: '', // Firestore에서 자동 생성
        date: widget.selectedDate,
        sessionNumber: 0, // 서비스에서 자동 계산
        meetingName: meetingName,
        drunkLevel: drunkLevel,
        yearMonth: DateFormat('yyyy-MM').format(widget.selectedDate),
        drinkAmount: drinkAmounts,
        memo: {'text': memo},
        cost: cost,
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
