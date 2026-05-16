import 'package:ddalgguk/features/settings/services/custom_drink_icon_service.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

/// 표준 asset 경로와 'custom://{id}' marker를 모두 지원하는 주종 아이콘 위젯.
class DrinkIcon extends StatelessWidget {
  const DrinkIcon({
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final customId = parseCustomDrinkIconId(imagePath);
    if (customId != null) {
      final bytes = getCustomDrinkIconBytes(customId);
      if (bytes != null) {
        // 업로드 사진은 원형으로 크롭 (짧은 변 기준 cover).
        return ClipOval(
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        );
      }
      return Image.asset(
        'assets/imgs/alcohol_icons/undecided.png',
        width: width,
        height: height,
        fit: fit,
      );
    }
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/imgs/alcohol_icons/undecided.png',
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
