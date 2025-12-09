import 'package:flutter/material.dart';

/// 공용 페이지 헤더 위젯 (뒤로가기 버튼 있음)
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
    final backAction =
        onBack ??
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
          Icons.chevron_left, // 뒤로가기 아이콘 (< 모양임)
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

/// 탭 페이지 헤더 위젯 (뒤로가기 버튼 없음)
class TabPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const TabPageHeader({
    super.key,
    required this.title,
    this.actions,
    this.height = 56,
    this.fontSize = 18,
    this.centerTitle = true,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final double height;
  final double fontSize;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
