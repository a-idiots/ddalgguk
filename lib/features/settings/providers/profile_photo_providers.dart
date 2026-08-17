import 'package:ddalgguk/features/settings/services/profile_photo_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ProfilePhotoService 프로바이더
final profilePhotoServiceProvider = Provider<ProfilePhotoService>(
  (ref) => ProfilePhotoService(),
);

/// 특정 uid의 커스텀 프로필 사진 base64 문자열을 로드하는 프로바이더
/// profilePhoto == -1인 유저에게만 사용
final profilePhotoBase64Provider = FutureProvider.family
    .autoDispose<String?, String>((ref, uid) async {
      final service = ref.read(profilePhotoServiceProvider);
      return service.getPhotoBase64(uid);
    });
