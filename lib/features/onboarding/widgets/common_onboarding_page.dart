import 'package:flutter/material.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';

class CommonOnboardingPage extends StatelessWidget {
  const CommonOnboardingPage({
    super.key,
    required this.title,
    required this.content,
    this.onNext,
    required this.buttonText,
  });

  final String title;
  final Widget content;
  final VoidCallback? onNext;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 키보드 내림
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const SakuCharacter(size: 120), // Default size
            const SizedBox(height: 40),
            Expanded(child: content),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onNext != null
                      ? Colors.black
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
