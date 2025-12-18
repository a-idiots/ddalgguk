import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/gradient_background.dart';
import 'package:ddalgguk/features/profile/widgets/scroll_indicator.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMainView extends ConsumerStatefulWidget {
  const ProfileMainView({
    super.key,
    this.showCharacter = true,
    this.characterKey,
    this.opacity = 1.0,
    required this.theme,
    required this.drunkLevel,
  });

  final bool showCharacter;
  final GlobalKey? characterKey;
  final double opacity;
  final AppTheme theme;
  final int drunkLevel;

  @override
  ConsumerState<ProfileMainView> createState() => _ProfileMainViewState();
}

class _ProfileMainViewState extends ConsumerState<ProfileMainView> {
  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    // Listen to stats changes and update currentDrunkLevel in database
    ref.listen(currentProfileStatsProvider, (previous, next) {
      next.whenData((stats) {
        final authRepository = ref.read(authRepositoryProvider);
        authRepository.updateCurrentDrunkLevel(stats.todayDrunkLevel);
        // Parent already has the data via provider, no need to notify back
      });
    });

    return currentUserAsync.when(
      skipLoadingOnReload: true,
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return currentStatsAsync.when(
          skipLoadingOnReload: true,
          data: (stats) {
            return ProfileGradientBackground(
              theme: widget.theme,
              child: SafeArea(
                child: Stack(
                  children: [
                    // Main content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          // User info and status at top
                          Column(
                            children: [
                              Text(
                                user.name ?? 'User',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    if (stats.hasTodayRecord &&
                                        stats.isTodayDrinking) ...[
                                      // Case 1: Drinking today
                                      const TextSpan(text: '이번 달 '),
                                      TextSpan(
                                        text:
                                            '${stats.thisMonthDrinkingCount}일',
                                        style: TextStyle(
                                          color: widget.theme.secondaryColor,
                                        ),
                                      ),
                                      const TextSpan(text: ' 술을 마셨어요!'),
                                    ] else if (stats.hasTodayRecord &&
                                        !stats.isTodayDrinking) ...[
                                      // Case 2: Sober today
                                      const TextSpan(text: '이번 달 '),
                                      TextSpan(
                                        text: '${stats.thisMonthSoberCount}일',
                                        style: TextStyle(
                                          color: widget.theme.secondaryColor,
                                        ),
                                      ),
                                      const TextSpan(text: ' 금주 성공했어요!'),
                                    ] else ...[
                                      // Case 3: No records at all
                                      const TextSpan(text: '오늘 기록을 추가해주세요!'),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 1),
                          // Saku character image
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: widget.showCharacter
                                ? SakuCharacter(
                                    size: 150,
                                    drunkLevel: widget.drunkLevel,
                                  )
                                : Container(key: widget.characterKey),
                          ),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                    // Scroll indicator at bottom
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: widget.opacity,
                        child: const AnimatedScrollIndicator(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => ProfileGradientBackground(
            theme: AppColors.getTheme(0),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (error, stack) => ProfileGradientBackground(
            theme: AppColors.getTheme(0),
            child: Center(
              child: Text(
                'Error loading stats',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
