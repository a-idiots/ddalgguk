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
    this.titleOutside = false,
  });

  final String title;
  final Widget? subtitle;
  final Widget content;
  final EdgeInsetsGeometry padding;

  final bool titleOutside;

  @override
  Widget build(BuildContext context) {
    if (titleOutside) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and subtitle row (Outside)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) subtitle!,
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Content Container
            Container(
              width: double.infinity,
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
              child: content,
            ),
          ],
        ),
      );
    }

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
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              if (subtitle != null) subtitle!,
            ],
          ),
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
    return Text(text, style: TextStyle(fontSize: 14, color: color));
  }
}
