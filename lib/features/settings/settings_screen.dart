import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/widgets/settings_dialogs.dart';
import 'package:ddalgguk/features/settings/edit_info_screen.dart';
import 'package:ddalgguk/features/settings/profile_edit_screen.dart';
import 'package:ddalgguk/features/settings/notification_settings_screen.dart';
import 'package:ddalgguk/features/settings/ranking_settings_screen.dart';
import 'package:ddalgguk/features/settings/screens/main_drink_settings_screen.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _buildProfileAvatar(int profilePhoto) {
    if (profilePhoto <= 10) {
      return SakuCharacter(size: 55, drunkLevel: profilePhoto * 10);
    }

    const alcoholIcons = [
      'assets/imgs/alcohol_icons/soju.png',
      'assets/imgs/alcohol_icons/beer.png',
      'assets/imgs/alcohol_icons/cocktail.png',
      'assets/imgs/alcohol_icons/wine.png',
      'assets/imgs/alcohol_icons/makgulli.png',
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

  Future<void> _backfillGoals(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final monthKeys = List.generate(
      now.month,
      (i) => '${now.year}-${(i + 1).toString().padLeft(2, '0')}',
    );

    try {
      await ref.read(authRepositoryProvider).backfillMonthlyGoals(monthKeys);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${monthKeys.join(', ')} 소급 적용 완료')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                              fontFamily: 'Pretendard',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.id ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
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
                        style: TextStyle(
                          fontFamily: 'Pretendard',
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
                  Text(
                    'Loading...',
                    style: TextStyle(fontFamily: 'Pretendard'),
                  ),
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
          SettingsListTile(
            title: '랭킹 설정',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RankingSettingsScreen(),
                ),
              );
            },
          ),
          const SettingsSectionDivider(),

          // Drinking Related Settings Section
          const SettingsSectionHeader(title: '음주 관련 설정'),
          SettingsListTile(
            title: '음주 빈도',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DrinkingFrequencyScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '주량',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlcoholToleranceScreen(),
                ),
              );
            },
          ),
          SettingsListTile(
            title: '메인 기록 주종',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MainDrinkSettingsScreen(),
                ),
              );
            },
          ),
          currentUser.when(
            data: (user) {
              if (user == null) {
                return const GoalToggleTile(currentGoal: true, onToggle: null);
              }
              return GoalToggleTile(
                currentGoal: user.goal ?? true,
                onToggle: (newGoal) async {
                  try {
                    final authRepository = ref.read(authRepositoryProvider);
                    await authRepository.saveProfileData(
                      id: user.id ?? '',
                      name: user.name ?? '',
                      goal: newGoal,
                      favoriteDrink: user.favoriteDrink ?? 0,
                      maxAlcohol: user.maxAlcohol ?? 0,
                      weeklyDrinkingFrequency:
                          user.weeklyDrinkingFrequency ?? 0,
                      gender: user.gender,
                      birthDate: user.birthDate,
                      height: user.height,
                      weight: user.weight,
                    );
                    ref.invalidate(currentUserProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newGoal ? '즐거운 음주로 변경되었습니다' : '건강한 절주로 변경되었습니다',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('변경 실패: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
            loading: () =>
                const GoalToggleTile(currentGoal: true, onToggle: null),
            error: (_, __) =>
                const GoalToggleTile(currentGoal: true, onToggle: null),
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
          const SettingsSectionDivider(),

          // Debug Section
          const SettingsSectionHeader(title: '디버그'),
          ref
              .watch(proProvider)
              .when(
                data: (isPro) => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text(
                    'DDALGGUK PRO (디버그)',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    isPro ? 'PRO 기능 활성화됨' : 'PRO 기능 비활성화됨',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                    ),
                  ),
                  value: isPro,
                  activeThumbColor: const Color(0xFFF0A9A9),
                  activeTrackColor: const Color(
                    0xFFF0A9A9,
                  ).withValues(alpha: 0.4),
                  onChanged: (_) => ref.read(proProvider.notifier).toggle(),
                ),
                loading: () => const SizedBox(height: 48),
                error: (_, __) => const SizedBox.shrink(),
              ),
          SettingsListTile(
            title: '[DEV] 월 목표 소급 적용',
            onTap: () => _backfillGoals(context, ref),
          ),
        ],
      ),
    );
  }
}
