import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
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
            SnackBar(
              content: Text('로그아웃 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // User Info Section
          authState.when(
            data: (user) {
              if (user == null) {
                return const SizedBox.shrink();
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user.displayName ?? 'Unknown User'),
                subtitle: Text(user.email ?? ''),
              );
            },
            loading: () => const ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator()),
              title: Text('Loading...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),

          // Settings Options
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('서비스 이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 정보'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to app info
            },
          ),
          const Divider(),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }
}
