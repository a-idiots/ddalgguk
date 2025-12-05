import 'package:flutter/material.dart';
import 'package:ddalgguk/features/onboarding/widgets/common_onboarding_page.dart';

class BirthDatePage extends StatelessWidget {
  const BirthDatePage({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onNext,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return CommonOnboardingPage(
      title: '생년월일을 알려주세요',
      content: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                onDateSelected(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일'
                    : '날짜 선택',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      onNext: onNext,
      buttonText: '다음',
    );
  }
}
