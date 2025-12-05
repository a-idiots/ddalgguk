import 'package:flutter/material.dart';
import 'package:ddalgguk/features/onboarding/widgets/common_onboarding_page.dart';

class OutroPage extends StatelessWidget {
  const OutroPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return CommonOnboardingPage(
      title: '준비가 완료되었어요!\n이제 시작해볼까요?',
      content: const SizedBox.shrink(),
      onNext: onStart,
      buttonText: '시작하기',
    );
  }
}
