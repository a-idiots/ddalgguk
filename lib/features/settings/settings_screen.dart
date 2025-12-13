import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/widgets/settings_dialogs.dart';
import 'package:ddalgguk/features/settings/edit_info_screen.dart';
import 'package:ddalgguk/features/settings/notice_screen.dart';
import 'package:ddalgguk/features/settings/profile_edit_screen.dart';
import 'package:ddalgguk/features/settings/notification_settings_screen.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showLogoutDialog(context);

    if (confirmed == true && context.mounted) {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.signOut();

        // Force provider update to trigger router redirect
        ref.invalidate(authStateProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그아웃 실패: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Show confirmation dialog
    final confirmed = await showAccountDeletionDialog(context);

    if (confirmed == true && context.mounted) {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.deleteAccount();

        // Force provider update to trigger router redirect
        ref.invalidate(authStateProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('회원 탈퇴 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileAvatar(int profilePhoto) {
    if (profilePhoto <= 10) {
      return SakuCharacter(size: 55, drunkLevel: profilePhoto * 10);
    }

    const alcoholIcons = [
      'assets/alcohol_icons/soju.png',
      'assets/alcohol_icons/beer.png',
      'assets/alcohol_icons/cocktail.png',
      'assets/alcohol_icons/wine.png',
      'assets/alcohol_icons/makgulli.png',
    ];
    final iconIndex = profilePhoto - 11;

    if (iconIndex >= 0 && iconIndex < alcoholIcons.length) {
      return Center(
        child: Image.asset(
          alcoholIcons[iconIndex],
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      );
    }

    return const SakuCharacter(size: 55);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const TabPageHeader(title: 'Settings'),
      body: ListView(
        children: [
          // User Info Section
          currentUser.when(
            data: (user) {
              if (user == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _buildProfileAvatar(user.profilePhoto),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'Unknown User',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.id ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        );
                        ref.invalidate(currentUserProvider);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF0A9A9)),
                        foregroundColor: const Color(0xFFF0A9A9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        '프로필 편집',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 32, child: CircularProgressIndicator()),
                  SizedBox(width: 16),
                  Text('Loading...', style: TextStyle(fontFamily: 'Inter')),
                ],
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SettingsSectionDivider(),

          // Account Settings Section
          const SettingsSectionHeader(title: '계정 설정'),
          SettingsListTile(
            title: '정보 수정',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditInfoScreen()),
              );
            },
          ),
          SettingsListTile(
            title: '알림 설정',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const SettingsSectionDivider(),

          // Usage Guide Section
          const SettingsSectionHeader(title: '이용 안내'),
          SettingsListTile(
            title: '앱 버전',
            onTap: () => showVersionDialog(context),
          ),
          SettingsListTile(
            title: '문의하기',
            onTap: () => showContactDialog(context),
          ),
          SettingsListTile(
            title: '공지사항',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NoticeScreen()),
              );
            },
          ),
          const SettingsSectionDivider(),

          // Other Section
          const SettingsSectionHeader(title: '기타'),
          SettingsListTile(
            title: '회원 탈퇴',
            onTap: () => _handleAccountDeletion(context, ref),
          ),
          SettingsListTile(
            title: '로그아웃',
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }
}
