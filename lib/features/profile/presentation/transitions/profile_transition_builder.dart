import 'package:flutter/material.dart';
import 'package:ddalgguk/features/profile/presentation/transitions/profile_transition_data.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/gradient_background.dart';
import 'package:ddalgguk/features/profile/presentation/widgets/scroll_indicator.dart';

/// Widget that interpolates between ProfileScreen and ProfileDetailScreen layouts
class ProfileTransitionBuilder extends StatelessWidget {
  const ProfileTransitionBuilder({
    super.key,
    required this.animation,
    required this.transitionData,
    required this.child,
  });

  final Animation<double> animation;
  final ProfileTransitionData transitionData;
  final Widget child; // ProfileDetailScreen

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;

        // Calculate all interpolated values
        final sakuPosition = _calculateSakuPosition(context, progress);
        final sakuSize = _calculateSakuSize(progress);
        final gradientOpacity = _calculateGradientOpacity(progress);
        final bgColor = _calculateBackgroundColor(context, progress);
        final scrollIndicatorOpacity = _calculateScrollIndicatorOpacity(
          progress,
        );
        final centerInfoOpacity = _calculateCenterInfoOpacity(progress);
        final badgeOpacity = _calculateBadgeOpacity(progress);
        final statusMessageOpacity = _calculateStatusMessageOpacity(progress);
        final detailContentOpacity = _calculateDetailContentOpacity(progress);

        // Always build interpolated UI
        return Scaffold(
          body: Stack(
            children: [
              // Background layer
              Positioned.fill(
                child: Container(
                  color: bgColor,
                  child: Opacity(
                    opacity: gradientOpacity,
                    child: ProfileGradientBackground(
                      theme: transitionData.theme,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),

              // Saku character (interpolates position and size)
              Positioned(
                left: sakuPosition.dx,
                top: sakuPosition.dy,
                child: _buildSakuCharacter(sakuSize, progress),
              ),

              // Center content (fades out)
              if (centerInfoOpacity > 0.01)
                SafeArea(
                  child: Center(
                    child: Opacity(
                      opacity: centerInfoOpacity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          // User info
                          Column(
                            children: [
                              Text(
                                transitionData.user.name ??
                                    transitionData.user.displayName ??
                                    'User',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '@${transitionData.user.id ?? 'username'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 200 + 64), // Space for Saku + gap
                          const Spacer(flex: 2),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),

              // Drunk level badge (fades out)
              if (badgeOpacity > 0.01)
                SafeArea(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -30),
                      child: Opacity(
                        opacity: badgeOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${transitionData.drunkLevel}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Status message (fades out)
              if (statusMessageOpacity > 0.01)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).size.height * 0.3,
                  child: Opacity(
                    opacity: statusMessageOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        transitionData.stats.statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              // Scroll indicator (fades out)
              if (scrollIndicatorOpacity > 0.01)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: scrollIndicatorOpacity,
                    child: const AnimatedScrollIndicator(),
                  ),
                ),

              // Detail screen content (fades in)
              if (detailContentOpacity > 0.01)
                Opacity(opacity: detailContentOpacity, child: child!),
            ],
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSakuCharacter(double size, double progress) {
    final isCircular = progress > 0.5;

    final sakuImage = Image.asset(
      transitionData.sakuImagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/saku/body.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      },
    );

    if (isCircular) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
        ),
        child: ClipOval(child: sakuImage),
      );
    }

    return sakuImage;
  }

  Offset _calculateSakuPosition(BuildContext context, double progress) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final topPadding = MediaQuery.of(context).padding.top;

    // Start position: center
    final startX = (screenWidth - 200) / 2;
    final startY = (screenHeight - 200) / 2;

    // End position: top-right header (considering circular avatar size = 80px)
    final endX = screenWidth - 96; // 80px avatar + 16px padding
    final endY = topPadding + 20; // SafeArea + padding

    // Interpolate with easeOutCubic curve
    final t = Curves.easeOutCubic.transform(
      Interval(0.3, 0.8).transform(progress),
    );

    return Offset(
      Tween<double>(begin: startX, end: endX).transform(t),
      Tween<double>(begin: startY, end: endY).transform(t),
    );
  }

  double _calculateSakuSize(double progress) {
    // Interpolate size from 200px to 80px
    final t = Curves.easeOutCubic.transform(
      Interval(0.3, 0.8).transform(progress),
    );
    return Tween<double>(begin: 200.0, end: 80.0).transform(t);
  }

  double _calculateGradientOpacity(double progress) {
    // Fade out gradient between 0.3 and 0.7
    return 1.0 - Interval(0.3, 0.7).transform(progress);
  }

  Color _calculateBackgroundColor(BuildContext context, double progress) {
    // Fade in white/grey background between 0.7 and 1.0
    final bgOpacity = Interval(0.7, 1.0).transform(progress);
    return Color.lerp(
      Colors.transparent,
      Colors.grey[50] ?? Colors.white,
      bgOpacity,
    )!;
  }

  double _calculateScrollIndicatorOpacity(double progress) {
    // Fade out quickly at the start
    return 1.0 - Interval(0.0, 0.2).transform(progress);
  }

  double _calculateCenterInfoOpacity(double progress) {
    // Fade out between 0.4 and 0.7
    return 1.0 - Interval(0.4, 0.7).transform(progress);
  }

  double _calculateBadgeOpacity(double progress) {
    // Fade out between 0.0 and 0.3
    return 1.0 - Interval(0.0, 0.3).transform(progress);
  }

  double _calculateStatusMessageOpacity(double progress) {
    // Fade out between 0.0 and 0.3
    return 1.0 - Interval(0.0, 0.3).transform(progress);
  }

  double _calculateDetailContentOpacity(double progress) {
    // Fade in between 0.7 and 1.0
    return Interval(0.7, 1.0).transform(progress);
  }
}
