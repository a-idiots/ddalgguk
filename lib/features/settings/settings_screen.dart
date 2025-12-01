import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/router/app_router.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/widgets/settings_dialogs.dart';
import 'package:ddalgguk/features/settings/edit_info_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃', style: TextStyle(fontFamily: 'Inter')),
        content: const Text('정말 로그아웃 하시겠습니까?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃', style: TextStyle(fontFamily: 'Inter', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.signOut();

        if (context.mounted) {
          // Navigation will be handled automatically by go_router redirect
          context.go(Routes.login);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그아웃 실패: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(),
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
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? const Icon(Icons.person, size: 32)
                          : null,
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditInfoScreen(),
                          ),
                        );
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
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                        ),
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
                MaterialPageRoute(
                  builder: (context) => const EditInfoScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '알림 설정',
            onTap: () {
              // TODO: Navigate to notification settings
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
              // TODO: Navigate to notices
            },
          ),
          const SettingsSectionDivider(),

          // Other Section
          const SettingsSectionHeader(title: '기타'),
          SettingsListTile(
            title: '회원 탈퇴',
            onTap: () {
              // TODO: Navigate to account deletion
            },
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
