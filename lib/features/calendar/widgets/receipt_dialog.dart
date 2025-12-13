import 'package:flutter/material.dart';

/// 영수증 배경 이미지를 가진 Dialog 위젯
class ReceiptDialog extends StatelessWidget {
  const ReceiptDialog({required this.child, this.onClose, super.key});

  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // 영수증 배경 이미지와 콘텐츠
          Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: maxDialogHeight,
            ),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/imgs/calendar/receipt.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
          // 우측 상단 X 버튼
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: onClose ?? () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
