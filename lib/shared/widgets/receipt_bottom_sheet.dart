import 'package:flutter/material.dart';

/// 기본 바텀 시트 위젯
///
/// 하단에서 올라오는 둥근 모서리 바텀 시트
/// 화면의 약 80% 높이를 차지하며, 드래그 핸들 포함
class ReceiptBottomSheet extends StatelessWidget {
  const ReceiptBottomSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.8; // 화면의 80% 높이

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          // 내용
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 바텀 시트를 표시하는 헬퍼 함수
Future<T?> showReceiptBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReceiptBottomSheet(child: child),
  );
}
