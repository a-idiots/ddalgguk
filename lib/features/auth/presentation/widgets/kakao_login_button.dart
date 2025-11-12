import 'package:flutter/material.dart';

/// Kakao Login Button Widget
class KakaoLoginButton extends StatelessWidget {
  const KakaoLoginButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500), // Kakao Yellow
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/kakao_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image is not found
                      return const Icon(
                        Icons.chat_bubble,
                        size: 24,
                        color: Colors.black87,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '카카오로 계속하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
