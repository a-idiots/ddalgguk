import 'package:flutter/material.dart';
import 'package:ddalgguk/features/onboarding/widgets/common_onboarding_page.dart';

class GenderPage extends StatelessWidget {
  const GenderPage({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
    required this.onNext,
  });

  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return CommonOnboardingPage(
      title: '성별을 알려주세요',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GenderButton(
            label: '남성',
            isSelected: selectedGender == 'male',
            onTap: () => onGenderSelected('male'),
          ),
          const SizedBox(width: 16),
          _GenderButton(
            label: '여성',
            isSelected: selectedGender == 'female',
            onTap: () => onGenderSelected('female'),
          ),
        ],
      ),
      onNext: onNext,
      buttonText: '다음',
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
