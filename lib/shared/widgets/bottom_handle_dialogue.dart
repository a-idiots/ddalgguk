import 'package:flutter/material.dart';

/// 기본 바텀 시트 위젯
///
/// 하단에서 올라오는 둥근 모서리 바텀 시트
/// 화면의 85% 고정 높이를 차지하며, 드래그 핸들 포함
class BottomHandleDialogue extends StatelessWidget {
  const BottomHandleDialogue({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (height != null) Expanded(child: child) else child,
          // Add bottom padding if dynamic height
          if (height == null)
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

/// 바텀 시트를 표시하는 헬퍼 함수
Future<T?> showBottomHandleDialogue<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
  double? height,
  bool fitContent = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      // 기본 높이는 85%
      // fitContent가 true면 내용물 크기에 맞게 (null)
      // height 값이 들어오면 그 값 우선 사용
      final screenHeight = MediaQuery.of(context).size.height;
      final effectiveHeight = fitContent
          ? null
          : (height ?? screenHeight * 0.85);

      return BottomHandleDialogue(height: effectiveHeight, child: child);
    },
  );
}
