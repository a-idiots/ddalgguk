import 'package:flutter/material.dart';

/// Settings screen constants
class SettingsConstants {
  // Padding values
  static const double listTileHorizontalPadding = 16.0;
  static const double listTileVerticalPadding = 0.0;
  static const double sectionHeaderTopPadding = 8.0;
  static const double sectionHeaderBottomPadding = 4.0;
  static const double sectionHeaderHorizontalPadding = 16.0;

  // Divider values
  static const double dividerHeight = 8.0;
  static const Color dividerColor = Color(0xFFEFEFEF);

  // Text styles
  static const double sectionHeaderFontSize = 12.0;
  static const double listTileFontSize = 16.0;
}

/// Section divider widget
class SettingsSectionDivider extends StatelessWidget {
  const SettingsSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SettingsConstants.dividerHeight,
      color: SettingsConstants.dividerColor,
    );
  }
}

/// Section header widget
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SettingsConstants.sectionHeaderHorizontalPadding,
        SettingsConstants.sectionHeaderTopPadding,
        SettingsConstants.sectionHeaderHorizontalPadding,
        SettingsConstants.sectionHeaderBottomPadding,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: SettingsConstants.sectionHeaderFontSize,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

/// Settings list tile widget
class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SettingsConstants.listTileHorizontalPadding,
        vertical: SettingsConstants.listTileVerticalPadding,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: SettingsConstants.listTileFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
