import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/widgets/settings_dialogs.dart';
import 'package:ddalgguk/features/settings/edit_info_screen.dart';
import 'package:ddalgguk/features/settings/profile_edit_screen.dart';
import 'package:ddalgguk/features/settings/notification_settings_screen.dart';
import 'package:ddalgguk/features/settings/ranking_settings_screen.dart';
import 'package:ddalgguk/features/settings/screens/main_drink_settings_screen.dart';
import 'package:ddalgguk/shared/widgets/profile_avatar.dart';
import 'package:ddalgguk/shared/widgets/page_header.dart';
import 'package:ddalgguk/shared/widgets/pro_plan_popup.dart';
import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/core/services/analytics_service.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/calendar/data/providers/calendar_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAccountDeletionDialog(context);
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.deleteAccount();
      await AnalyticsService.instance.logDeleteAccount();
      ref.invalidate(drinkingRecordsLastUpdatedProvider);
      ref.invalidate(weeklyStatsProvider);
      ref.invalidate(weeklyStatsOffsetProvider);
      ref.invalidate(weeklyStatsByMondayProvider);
      ref.invalidate(currentProfileStatsProvider);
      ref.invalidate(alcoholGuidelineDataProvider);
      ref.invalidate(prevMonthAvgSpendingProvider);
      ref.invalidate(userBadgesProvider);
      ref.invalidate(userPhysicalInfoProvider);
      ref.invalidate(proProvider);
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원 탈퇴 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isPro = ref.watch(proProvider).valueOrNull ?? false;

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
                    ProfileAvatar(
                      profilePhoto: user.profilePhoto,
                      uid: user.uid,
                      size: 64,
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
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        );
                        ref.invalidate(currentUserProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '프로필 편집',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
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

          if (!isPro) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showProPlanPopup(context, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/imgs/popup/setting_pro.png',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            const SettingsSectionDivider(),
          ],

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

          // 계정 관리 — Apple Guideline 5.1.1(v): 앱 내 계정 삭제 필수.
          const SettingsSectionHeader(title: '계정 관리'),
          SettingsListTile(
            title: '회원 탈퇴',
            onTap: () => _handleAccountDeletion(context, ref),
          ),

          // TODO(debug): 제출 전 제거할 것 — Pro 상태 토글용 개발자 메뉴.
          const SettingsSectionDivider(),
          const SettingsSectionHeader(title: '[DEBUG] 개발자'),
          SettingsListTile(
            title: isPro ? 'Pro 해제 (현재: ON)' : 'Pro 활성 (현재: OFF)',
            onTap: () async {
              await ref.read(proProvider.notifier).setValue(!isPro);
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pro 상태: ${!isPro ? "ON" : "OFF"}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
