import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/features/profile/widgets/gradient_background.dart';
import 'package:ddalgguk/features/profile/widgets/scroll_indicator.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMainView extends ConsumerWidget {
  const ProfileMainView({
    super.key,
    this.showCharacter = true,
    this.characterKey,
    this.opacity = 1.0,
  });

  final bool showCharacter;
  final GlobalKey? characterKey;
  final double opacity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentStatsAsync = ref.watch(currentProfileStatsProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return currentStatsAsync.when(
          data: (stats) {
            final thisMonthDrunkDays = stats.thisMonthDrunkDays;
            final theme = AppColors.getTheme(thisMonthDrunkDays);

            return ProfileGradientBackground(
              theme: theme,
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
                                    if (stats.consecutiveDrinkingDays > 0) ...[
                                      const TextSpan(text: '이번 달 '),
                                      TextSpan(
                                        text:
                                            '${stats.thisMonthDrinkingCount}번째',
                                        style: TextStyle(
                                          color: theme.secondaryColor,
                                        ),
                                      ),
                                      const TextSpan(text: ' 음주 중이네요!'),
                                    ] else ...[
                                      TextSpan(
                                        text: '${stats.consecutiveSoberDays}일째',
                                        style: TextStyle(
                                          color: theme.secondaryColor,
                                        ),
                                      ),
                                      const TextSpan(text: ' 금주 중이네요!'),
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
                            child: showCharacter
                                ? SakuCharacter(
                                    size: 150,
                                    drunkLevel: stats.todayDrunkLevel,
                                  )
                                : Container(key: characterKey),
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
                        opacity: opacity,
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
