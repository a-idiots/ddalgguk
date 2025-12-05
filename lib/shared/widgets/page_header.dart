import 'package:flutter/material.dart';

/// 공용 페이지 헤더 위젯
class CommonPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const CommonPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.height = 56,
  });

  final String title;
  final VoidCallback? onBack;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final backAction = onBack ??
        () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        };

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      leadingWidth: 52,
      leading: IconButton(
        onPressed: backAction,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        icon: const Icon(
          Icons.chevron_left,
          size: 26,
          color: Colors.black87,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}
