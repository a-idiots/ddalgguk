import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// 커스텀 프로필 사진 업로드 및 조회 서비스
/// 이미지를 512x512로 크롭/리사이즈 후 JPEG base64로 Firestore에 저장
class ProfilePhotoService {
  ProfilePhotoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'profilePhotos';

  /// 갤러리에서 선택한 이미지를 512x512로 처리 후 Firestore에 저장
  /// 기존 사진이 있으면 덮어씀
  Future<void> uploadPhotoFromFile(String uid, XFile file) async {
    final bytes = await file.readAsBytes();
    final base64Str = await compute(_processImage, bytes);
    await _firestore.collection(_collection).doc(uid).set({
      'photoBase64': base64Str,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Firestore에서 base64 인코딩된 사진 조회
  Future<String?> getPhotoBase64(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    return doc.data()?['photoBase64'] as String?;
  }

  /// 이미지 처리: 정사각형 센터 크롭 → 512x512 리사이즈 → JPEG 85% 품질 → base64
  /// compute()로 별도 isolate에서 실행됨
  static String _processImage(Uint8List bytes) {
    final image = img.decodeImage(bytes)!;

    // 정사각형 센터 크롭
    final minDim = image.width < image.height ? image.width : image.height;
    final x = (image.width - minDim) ~/ 2;
    final y = (image.height - minDim) ~/ 2;
    final cropped = img.copyCrop(
      image,
      x: x,
      y: y,
      width: minDim,
      height: minDim,
    );

    // 512x512로 리사이즈
    final resized = img.copyResize(
      cropped,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.linear,
    );

    // JPEG 85% 품질로 인코딩 후 base64 반환
    final jpegBytes = img.encodeJpg(resized, quality: 85);
    return base64Encode(jpegBytes);
  }
}
