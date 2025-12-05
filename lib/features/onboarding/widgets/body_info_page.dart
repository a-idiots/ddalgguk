import 'package:flutter/material.dart';
import 'package:ddalgguk/features/onboarding/widgets/common_onboarding_page.dart';

class BodyInfoPage extends StatelessWidget {
  const BodyInfoPage({
    super.key,
    required this.height,
    required this.weight,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onNext,
  });

  final double? height;
  final double? weight;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return CommonOnboardingPage(
      title: '키와 몸무게를 알려주세요',
      content: Column(
        children: [
          _BodyInfoInput(
            label: '키 (cm)',
            onChanged: onHeightChanged,
            initialValue: height?.toString(),
          ),
          const SizedBox(height: 16),
          _BodyInfoInput(
            label: '몸무게 (kg)',
            onChanged: onWeightChanged,
            initialValue: weight?.toString(),
          ),
        ],
      ),
      onNext: onNext,
      buttonText: '다음',
    );
  }
}

class _BodyInfoInput extends StatelessWidget {
  const _BodyInfoInput({
    required this.label,
    required this.onChanged,
    this.initialValue,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
