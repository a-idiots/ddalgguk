import 'package:flutter/material.dart';

/// Reusable section widget with title, subtitle, and content
/// Used for consistent styling across profile sections
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget? subtitle;
  final Widget content;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (subtitle != null) subtitle!,
            ],
          ),
          const SizedBox(height: 16),
          // Content
          content,
        ],
      ),
    );
  }
}

/// Simple subtitle text widget
class SectionSubtitle extends StatelessWidget {
  const SectionSubtitle({
    super.key,
    required this.text,
    this.color = Colors.grey,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: color,
      ),
    );
  }
}

/// Subtitle button widget
class SectionSubtitleButton extends StatelessWidget {
  const SectionSubtitleButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF27B7B),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFF27B7B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
