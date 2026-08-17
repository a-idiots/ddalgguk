import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서버 검증을 아직 못 마친 결제 한 건.
///
/// 결제 직후 네트워크가 끊기거나 서버가 일시적으로 응답하지 않으면 영수증이
/// 그대로 사라질 수 있다. 그런 경우에도 다음 실행/복귀 때 다시 검증할 수 있도록
/// 로컬에 남겨둔다.
@immutable
class PendingVerification {
  const PendingVerification({
    required this.id,
    required this.platform,
    required this.productId,
    required this.verificationData,
    required this.firstSeenMs,
    this.attempts = 0,
  });

  factory PendingVerification.create({
    required String platform,
    required String productId,
    required String verificationData,
    required DateTime now,
  }) {
    return PendingVerification(
      id: idFor(verificationData),
      platform: platform,
      productId: productId,
      verificationData: verificationData,
      firstSeenMs: now.millisecondsSinceEpoch,
    );
  }

  /// 같은 영수증이 중복 저장되지 않도록 내용에서 만드는 안정적인 키.
  static String idFor(String verificationData) {
    final digest = sha256.convert(utf8.encode(verificationData));
    return digest.toString().substring(0, 32);
  }

  final String id;
  final String platform;
  final String productId;
  final String verificationData;
  final int firstSeenMs;
  final int attempts;

  PendingVerification withAttempt() => PendingVerification(
    id: id,
    platform: platform,
    productId: productId,
    verificationData: verificationData,
    firstSeenMs: firstSeenMs,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'productId': productId,
    'verificationData': verificationData,
    'firstSeenMs': firstSeenMs,
    'attempts': attempts,
  };

  static PendingVerification? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final verificationData = raw['verificationData'];
    final platform = raw['platform'];
    final productId = raw['productId'];
    if (verificationData is! String ||
        platform is! String ||
        productId is! String ||
        verificationData.isEmpty) {
      return null;
    }
    final id = raw['id'];
    return PendingVerification(
      id: id is String && id.isNotEmpty ? id : idFor(verificationData),
      platform: platform,
      productId: productId,
      verificationData: verificationData,
      firstSeenMs: raw['firstSeenMs'] is int ? raw['firstSeenMs'] as int : 0,
      attempts: raw['attempts'] is int ? raw['attempts'] as int : 0,
    );
  }
}

/// 미검증 결제 대기열 (SharedPreferences).
class PendingVerificationStore {
  PendingVerificationStore({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  static const String _key = 'iap_pending_verifications';

  /// 영수증 하나가 수 KB라 무한정 쌓이지 않도록 제한한다.
  static const int maxEntries = 10;

  /// 계속 실패하는 항목을 영원히 재시도하지 않도록 하는 상한.
  static const int maxAttempts = 12;

  /// 이 기간이 지나면 재시도해도 의미가 없다고 보고 버린다.
  static const Duration maxAge = Duration(days: 14);

  final DateTime Function() _now;

  Future<List<PendingVerification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key));
  }

  Future<void> add(PendingVerification entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _decode(prefs.getString(_key));
    // 같은 영수증이 이미 있으면 시도 횟수를 유지한 채 그대로 둔다.
    if (entries.any((e) => e.id == entry.id)) {
      return;
    }
    entries.add(entry);
    // 가장 오래된 것부터 버려 상한을 유지한다.
    while (entries.length > maxEntries) {
      entries.removeAt(0);
    }
    await _save(prefs, entries);
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _decode(prefs.getString(_key))
      ..removeWhere((e) => e.id == id);
    await _save(prefs, entries);
  }

  /// 실패를 기록하고, 한도를 넘었으면 대기열에서 제거한다.
  /// 제거된 경우 true를 반환한다.
  Future<bool> recordFailure(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _decode(prefs.getString(_key));
    final index = entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      return false;
    }
    final updated = entries[index].withAttempt();
    if (updated.attempts >= maxAttempts) {
      entries.removeAt(index);
      await _save(prefs, entries);
      return true;
    }
    entries[index] = updated;
    await _save(prefs, entries);
    return false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  List<PendingVerification> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      final cutoffMs = _now().subtract(maxAge).millisecondsSinceEpoch;
      return decoded
          .map(PendingVerification.fromJson)
          .whereType<PendingVerification>()
          .where((e) => e.firstSeenMs == 0 || e.firstSeenMs >= cutoffMs)
          .toList();
    } catch (e) {
      debugPrint('Pending verification queue is unreadable, dropping it: $e');
      return [];
    }
  }

  Future<void> _save(
    SharedPreferences prefs,
    List<PendingVerification> entries,
  ) async {
    if (entries.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
