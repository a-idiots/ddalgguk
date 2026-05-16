import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ddalgguk/core/constants/storage_keys.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

final customDrinkIconServiceProvider = Provider<CustomDrinkIconService>((ref) {
  return CustomDrinkIconService();
});

const String kCustomDrinkIconPrefix = 'custom://';

String customDrinkIconMarker(int drinkId) => '$kCustomDrinkIconPrefix$drinkId';

int? parseCustomDrinkIconId(String imagePath) {
  if (!imagePath.startsWith(kCustomDrinkIconPrefix)) {
    return null;
  }
  return int.tryParse(imagePath.substring(kCustomDrinkIconPrefix.length));
}

class CustomDrinkIconService {
  CustomDrinkIconService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const _collection = 'customDrinkIcons';

  String? get _uid => _auth.currentUser?.uid;

  /// 갤러리에서 선택한 이미지를 200x200 JPEG로 처리하여 base64 바이트 반환.
  /// 저장은 [persist]에서 별도로 수행 (drinkId 확정 후).
  Future<Uint8List?> processImageBytes(Uint8List rawBytes) async {
    return compute(_processImage, rawBytes);
  }

  /// 처리된 바이트를 Firestore + SharedPreferences + 인메모리 캐시에 저장.
  Future<void> persist(int drinkId, Uint8List jpegBytes) async {
    final base64Str = base64Encode(jpegBytes);

    // 인메모리 캐시 갱신.
    final cache = Map<int, Uint8List>.from(customDrinkIconCacheSnapshot());
    cache[drinkId] = jpegBytes;
    updateCustomDrinkIconCache(cache);

    // SharedPreferences 캐시 갱신.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.customDrinkIcons);
    final map = raw == null
        ? <String, dynamic>{}
        : (jsonDecode(raw) as Map<String, dynamic>);
    map[drinkId.toString()] = base64Str;
    await prefs.setString(StorageKeys.customDrinkIcons, jsonEncode(map));

    // Firestore 동기화.
    final uid = _uid;
    if (uid != null) {
      await _firestore.collection(_collection).doc(uid).set({
        drinkId.toString(): base64Str,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// 커스텀 주종 삭제 시 함께 호출. 캐시/Firestore에서 해당 아이콘 제거.
  Future<void> delete(int drinkId) async {
    final cache = Map<int, Uint8List>.from(customDrinkIconCacheSnapshot());
    cache.remove(drinkId);
    updateCustomDrinkIconCache(cache);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.customDrinkIcons);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.remove(drinkId.toString());
      await prefs.setString(StorageKeys.customDrinkIcons, jsonEncode(map));
    }

    final uid = _uid;
    if (uid != null) {
      await _firestore.collection(_collection).doc(uid).set({
        drinkId.toString(): FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  /// 새 기기/재로그인 시 Firestore에서 아이콘 일괄 복원.
  /// SharedPreferences + 인메모리 캐시 갱신.
  Future<void> restoreFromFirestore() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    final doc = await _firestore.collection(_collection).doc(uid).get();
    final data = doc.data();
    if (data == null) {
      return;
    }

    final newCache = <int, Uint8List>{};
    final prefsMap = <String, String>{};
    for (final entry in data.entries) {
      if (entry.key == 'updatedAt') {
        continue;
      }
      final id = int.tryParse(entry.key);
      final value = entry.value;
      if (id == null || value is! String) {
        continue;
      }
      try {
        newCache[id] = base64Decode(value);
        prefsMap[entry.key] = value;
      } catch (_) {
        // skip malformed entries
      }
    }
    if (newCache.isEmpty) {
      return;
    }
    updateCustomDrinkIconCache(newCache);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.customDrinkIcons, jsonEncode(prefsMap));
  }

  /// 이미지 처리: 정사각형 센터 크롭 → 200x200 → JPEG 80%.
  static Uint8List _processImage(Uint8List bytes) {
    final image = img.decodeImage(bytes)!;
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
    final resized = img.copyResize(
      cropped,
      width: 200,
      height: 200,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }
}
