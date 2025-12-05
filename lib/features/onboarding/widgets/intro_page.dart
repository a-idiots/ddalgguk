import 'package:flutter/material.dart';
import 'package:ddalgguk/features/onboarding/widgets/common_onboarding_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return CommonOnboardingPage(
      title: '당신의 건강한 음주 생활을 위해\n몇 가지 정보가 필요해요!',
      content: const SizedBox.shrink(),
      onNext: onNext,
      buttonText: '다음',
    );
  }
}
