import 'dart:convert';

import 'package:ddalgguk/features/settings/providers/profile_photo_providers.dart';
import 'package:ddalgguk/shared/widgets/saku_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 프로필 아바타 위젯
///
/// profilePhoto 값에 따른 렌더링:
///  -1 : 커스텀 업로드 사진 (Firestore profilePhotos/{uid}에서 base64 로드)
///   0 : 기본 프로필 SVG (uid 해시로 4가지 색상 중 하나 결정)
///  1-10: 사쿠 캐릭터 (drunkLevel = profilePhoto * 10)
/// 11-19: 주종 아이콘
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.profilePhoto,
    required this.uid,
    this.size = 44,
  });

  final int profilePhoto;
  final String uid;
  final double size;

  // 기본 프로필 배경 색상 4종 (f2bfbf, cfa8a8, f59696, ffbcbc)
  static const _basicProfileColors = [
    'F2BFBF',
    'CFA8A8',
    'F59696',
    'FFBCBC',
  ];

  // 주종 아이콘 경로 (인덱스 11~19)
  static const _alcoholIcons = [
    'assets/imgs/alcohol_icons/soju.png',     // 11
    'assets/imgs/alcohol_icons/beer.png',     // 12
    'assets/imgs/alcohol_icons/cocktail.png', // 13
    'assets/imgs/alcohol_icons/wine.png',     // 14
    'assets/imgs/alcohol_icons/makgulli.png', // 15
    'assets/imgs/alcohol_icons/whiskey.png',  // 16
    'assets/imgs/alcohol_icons/highball.png', // 17
    'assets/imgs/alcohol_icons/sake.png',     // 18
    'assets/imgs/alcohol_icons/vodka.png',    // 19
  ];

  // 기본 프로필 SVG 템플릿 (배경색 BGCOLOR 치환)
  static const _basicProfileSvgTemplate = '<svg width="33" height="33" '
      'viewBox="0 0 33 33" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<path d="M33 16.5C33 7.3873 25.6127 0 16.5 0C7.3873 0 0 7.3873 0 16.5'
      'C0 25.6127 7.3873 33 16.5 33C25.6127 33 33 25.6127 33 16.5Z" '
      'fill="#BGCOLOR"/>'
      '<path fill-rule="evenodd" clip-rule="evenodd" '
      'd="M6.69338 26.7419C8.91745 23.6612 12.539 21.6562 16.6289 21.6562'
      'C20.6537 21.6562 24.2249 23.5978 26.4572 26.5954C23.8968 29.121 '
      '20.3805 30.6797 16.5 30.6797C12.6951 30.6797 9.24016 29.181 '
      '6.69338 26.7419ZM22.1719 13.2773C22.1719 16.481 19.6902 19.0781 '
      '16.6289 19.0781C13.5676 19.0781 11.0859 16.481 11.0859 13.2773'
      'C11.0859 10.0737 13.5676 7.47656 16.6289 7.47656C19.6902 7.47656 '
      '22.1719 10.0737 22.1719 13.2773Z" fill="white"/></svg>';

  /// uid 해시로 기본 프로필 배경색 결정 (일관성 유지)
  String _getColoredSvg(String uid) {
    final hash = uid.codeUnits.fold(0, (acc, c) => acc + c);
    final color = _basicProfileColors[hash % _basicProfileColors.length];
    return _basicProfileSvgTemplate.replaceFirst('BGCOLOR', color);
  }

  Widget _buildBasicProfile() {
    return SvgPicture.string(
      _getColoredSvg(uid),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -1: 커스텀 업로드 사진
    if (profilePhoto == -1) {
      final photoAsync = ref.watch(profilePhotoBase64Provider(uid));
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: photoAsync.when(
            data: (base64) {
              if (base64 != null) {
                return Image.memory(
                  base64Decode(base64),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                );
              }
              return _buildBasicProfile();
            },
            loading: () => Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => _buildBasicProfile(),
          ),
        ),
      );
    }

    // 0: 기본 프로필 SVG
    if (profilePhoto == 0) {
      return ClipOval(child: _buildBasicProfile());
    }

    // 1-10: 사쿠 캐릭터 (캐릭터를 80%로 축소해 잘림 방지, 배경색 유지)
    if (profilePhoto >= 1 && profilePhoto <= 10) {
      final drunkLevel = profilePhoto * 10;
      return ClipOval(
        child: Container(
          width: size,
          height: size,
          color: Colors.white,
          alignment: Alignment.center,
          child: SakuCharacter(drunkLevel: drunkLevel, size: size * 0.8),
        ),
      );
    }

    // 11-19: 주종 아이콘 (흰색 배경, 아이콘 70% 크기)
    final iconIndex = profilePhoto - 11;
    if (iconIndex >= 0 && iconIndex < _alcoholIcons.length) {
      return ClipOval(
        child: Container(
          width: size,
          height: size,
          color: Colors.white,
          padding: EdgeInsets.all(size * 0.15),
          child: Image.asset(_alcoholIcons[iconIndex], fit: BoxFit.contain),
        ),
      );
    }

    // 폴백: 기본 프로필
    return ClipOval(child: _buildBasicProfile());
  }
}

/// profilePhoto 값에 해당하는 주종 아이콘 경로 반환 (null이면 주종 아이콘 아님)
String? getAlcoholProfileIconPath(int profilePhoto) {
  const alcoholIcons = [
    'assets/imgs/alcohol_icons/soju.png',     // 11
    'assets/imgs/alcohol_icons/beer.png',     // 12
    'assets/imgs/alcohol_icons/cocktail.png', // 13
    'assets/imgs/alcohol_icons/wine.png',     // 14
    'assets/imgs/alcohol_icons/makgulli.png', // 15
    'assets/imgs/alcohol_icons/whiskey.png',  // 16
    'assets/imgs/alcohol_icons/highball.png', // 17
    'assets/imgs/alcohol_icons/sake.png',     // 18
    'assets/imgs/alcohol_icons/vodka.png',    // 19
  ];
  final index = profilePhoto - 11;
  if (index >= 0 && index < alcoholIcons.length) {
    return alcoholIcons[index];
  }
  return null;
}
