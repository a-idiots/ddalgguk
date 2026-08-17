import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Cloud Functions 배포 리전. functions/src/config.ts의 REGION과 반드시 같아야 한다.
const String kFunctionsRegion = 'asia-northeast3';

/// 개발 중 에뮬레이터를 가리키고 싶을 때만 .env에 넣는다. 없으면 프로젝트 ID로 만든다.
const String _kFunctionsBaseUrlEnvKey = 'FUNCTIONS_BASE_URL';

/// 결제 권한 문서(`entitlements/{uid}`)를 읽은 결과.
///
/// 이 값은 서버만 쓸 수 있고 클라이언트는 읽기만 한다. 즉 여기 담긴 isPro는
/// 스토어 영수증이 서버에서 검증됐다는 뜻이다.
@immutable
class Entitlement {
  const Entitlement({
    required this.isPro,
    this.activeProductId,
    this.activeKind,
    this.expiresAt,
  });

  static const Entitlement none = Entitlement(isPro: false);

  final bool isPro;
  final String? activeProductId;

  /// 'lifetime' | 'subscription'
  final String? activeKind;

  /// 구독 만료 시각. 평생 상품이거나 권한이 없으면 null.
  final DateTime? expiresAt;

  bool get isLifetime => activeKind == 'lifetime';

  /// 서버에 저장된 isPro는 만료 시각이 지나는 순간부터 낡은 값이 된다
  /// (알림이 늦거나 누락될 수 있으므로). 그래서 만료를 한 번 더 확인한다.
  bool isActiveAt(DateTime now) {
    if (!isPro) {
      return false;
    }
    final expiry = expiresAt;
    return expiry == null || expiry.isAfter(now);
  }

  static Entitlement fromMap(Map<String, dynamic> data) {
    final expiresAtMs = data['expiresAtMs'];
    return Entitlement(
      isPro: data['isPro'] == true,
      activeProductId: data['activeProductId'] as String?,
      activeKind: data['activeKind'] as String?,
      expiresAt: expiresAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(expiresAtMs)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'isPro': isPro,
    'activeProductId': activeProductId,
    'activeKind': activeKind,
    'expiresAtMs': expiresAt?.millisecondsSinceEpoch,
  };

  static Entitlement? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return Entitlement.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.isPro == isPro &&
      other.activeProductId == activeProductId &&
      other.activeKind == activeKind &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(isPro, activeProductId, activeKind, expiresAt);

  @override
  String toString() =>
      'Entitlement(isPro: $isPro, product: $activeProductId, '
      'kind: $activeKind, expiresAt: $expiresAt)';
}

/// 서버 검증 결과. 상태에 따라 클라이언트 동작이 갈린다.
enum VerificationStatus {
  /// 검증 성공. 권한 문서가 갱신됐다.
  verified,

  /// 서버가 영수증을 거부했다. 다시 보내도 결과는 같으므로 재시도하지 않는다.
  rejected,

  /// 지금은 확인할 수 없다(네트워크/스토어/서버 문제). 대기열에 남겨 재시도한다.
  retryLater,

  /// 로그인 상태가 아니라 권한을 계정에 붙일 수 없다. 로그인 후 재시도한다.
  unauthenticated,
}

@immutable
class VerificationResult {
  const VerificationResult(this.status, {this.entitlement, this.message});

  final VerificationStatus status;
  final Entitlement? entitlement;
  final String? message;

  bool get shouldRetry =>
      status == VerificationStatus.retryLater ||
      status == VerificationStatus.unauthenticated;
}

/// 결제 영수증 서버 검증과 권한 문서 조회를 담당한다.
///
/// Cloud Functions는 콜러블이 아니라 일반 HTTPS 엔드포인트로 부른다. 앱에
/// cloud_functions 네이티브 플러그인을 새로 추가하지 않기 위한 선택이고,
/// 인증은 Firebase ID 토큰을 Authorization 헤더로 보내 처리한다.
class EntitlementService {
  EntitlementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
    String? baseUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? http.Client(),
       _baseUrlOverride = baseUrl;

  static const Duration _requestTimeout = Duration(seconds: 20);

  /// appAccountToken 생성용 고정 네임스페이스(UUIDv5). 값 자체에 의미는 없고,
  /// 서버/클라이언트가 같은 uid에서 같은 토큰을 얻기 위한 상수다.
  static const List<int> _accountTokenNamespace = [
    0x64, 0x64, 0x61, 0x6c, 0x67, 0x67, 0x75, 0x6b,
    0x2d, 0x69, 0x61, 0x70, 0x2d, 0x76, 0x31, 0x00,
  ];

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;
  final String? _baseUrlOverride;

  DocumentReference<Map<String, dynamic>> _docFor(String uid) =>
      _firestore.collection('entitlements').doc(uid);

  /// 권한 문서 실시간 구독.
  ///
  /// 문서가 없으면 null을 준다. "권한 없음(false)"과 "아직 검증한 적 없음(null)"은
  /// 다르게 다뤄야 한다 — 후자에서 캐시를 지우면 기존 구매자를 잘못 강등한다.
  Stream<Entitlement?> watch(String uid) {
    return _docFor(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return Entitlement.fromMap(data);
    });
  }

  Future<Entitlement?> fetchOnce(String uid) async {
    final snapshot = await _docFor(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return Entitlement.fromMap(data);
  }

  /// Apple의 appAccountToken은 UUID여야 하는데 Firebase uid는 UUID가 아니다.
  /// uid에서 결정론적으로 UUIDv5를 만들어 쓰면, 서버가 갱신/환불 알림을 받을 때
  /// 어느 계정의 결제인지 바로 찾을 수 있다.
  static String appAccountTokenForUid(String uid) {
    final digest = sha1.convert([
      ..._accountTokenNamespace,
      ...utf8.encode(uid),
    ]);
    final bytes = Uint8List.fromList(digest.bytes.sublist(0, 16));
    // RFC 4122: version 5, variant 10x
    bytes[6] = (bytes[6] & 0x0f) | 0x50;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String get _baseUrl {
    if (_baseUrlOverride != null && _baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    if (dotenv.isInitialized) {
      final configured = dotenv.env[_kFunctionsBaseUrlEnvKey];
      if (configured != null && configured.isNotEmpty) {
        return configured;
      }
    }
    final projectId = Firebase.app().options.projectId;
    return 'https://$kFunctionsRegion-$projectId.cloudfunctions.net';
  }

  /// 영수증을 서버에 보내 검증한다.
  ///
  /// [verificationData]는 iOS에서는 StoreKit 2의 JWS,
  /// Android에서는 Play purchaseToken이다.
  Future<VerificationResult> verifyPurchase({
    required String platform,
    required String productId,
    required String verificationData,
  }) {
    return _post('verifyPurchase', {
      'platform': platform,
      'productId': productId,
      'verificationData': verificationData,
    });
  }

  /// 서버에 저장된 결제를 스토어에서 다시 읽어 권한을 최신화한다.
  ///
  /// 만료·환불 알림이 유실됐더라도 이 호출로 결국 바로잡힌다.
  Future<VerificationResult> sync({bool force = false}) {
    return _post('syncEntitlement', {'force': force});
  }

  Future<VerificationResult> _post(
    String function,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const VerificationResult(
        VerificationStatus.unauthenticated,
        message: '로그인이 필요합니다.',
      );
    }

    String token;
    try {
      token = await user.getIdToken() ?? '';
    } catch (e) {
      debugPrint('Could not get ID token for $function: $e');
      return VerificationResult(
        VerificationStatus.retryLater,
        message: e.toString(),
      );
    }
    if (token.isEmpty) {
      return const VerificationResult(VerificationStatus.unauthenticated);
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/$function'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } catch (e) {
      // 네트워크 문제는 "권한 없음"이 아니다. 나중에 다시 시도한다.
      debugPrint('$function request failed: $e');
      return VerificationResult(
        VerificationStatus.retryLater,
        message: e.toString(),
      );
    }

    return _interpret(function, response);
  }

  VerificationResult _interpret(String function, http.Response response) {
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        payload = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // 본문이 JSON이 아니면 상태 코드만으로 판단한다.
    }

    final status = response.statusCode;
    if (status == 200) {
      return VerificationResult(
        VerificationStatus.verified,
        entitlement: Entitlement.fromMap(payload),
      );
    }

    final message = payload['message'] as String? ?? 'HTTP $status';

    if (status == 401) {
      return VerificationResult(
        VerificationStatus.unauthenticated,
        message: message,
      );
    }
    // 4xx는 이 영수증으로는 절대 성공하지 못한다는 뜻이므로 재시도하지 않는다.
    if (status >= 400 && status < 500) {
      debugPrint('$function rejected the purchase: $status $message');
      return VerificationResult(
        VerificationStatus.rejected,
        message: message,
      );
    }
    debugPrint('$function failed: $status $message');
    return VerificationResult(VerificationStatus.retryLater, message: message);
  }

  void dispose() => _httpClient.close();
}

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  final service = EntitlementService();
  ref.onDispose(service.dispose);
  return service;
});

/// 로그인한 사용자의 권한 문서 스트림.
///
/// null = 아직 서버가 검증한 결제가 없음, Entitlement = 서버 판단.
final entitlementProvider = StreamProvider<Entitlement?>((ref) {
  final auth = FirebaseAuth.instance;
  final service = ref.watch(entitlementServiceProvider);

  // 로그인 상태가 바뀌면 다른 계정의 문서를 봐야 하므로 구독을 다시 만든다.
  return auth.authStateChanges().switchMap((user) {
    if (user == null) {
      return Stream<Entitlement?>.value(null);
    }
    return service.watch(user.uid);
  });
});

extension _SwitchMap<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T value) mapper) {
    late StreamController<R> controller;
    StreamSubscription<R>? inner;
    StreamSubscription<T>? outer;

    controller = StreamController<R>(
      onListen: () {
        outer = listen(
          (value) {
            inner?.cancel();
            inner = mapper(value).listen(
              controller.add,
              onError: controller.addError,
            );
          },
          onError: controller.addError,
          onDone: () => controller.close(),
        );
      },
      onCancel: () async {
        await inner?.cancel();
        await outer?.cancel();
      },
    );
    return controller.stream;
  }
}
