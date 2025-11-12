import 'package:flutter/material.dart';

/// Apple Login Button Widget
class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({
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
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/apple_logo.png',
                    height: 24,
                    width: 24,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image is not found
                      return const Icon(
                        Icons.apple,
                        size: 28,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Apple로 계속하기',
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
