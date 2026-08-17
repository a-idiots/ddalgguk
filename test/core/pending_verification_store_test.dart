import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ddalgguk/core/services/pending_verification_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 8, 17, 12);

  PendingVerification entry(String data, {String product = 'lifetime_v1'}) {
    return PendingVerification.create(
      platform: 'ios',
      productId: product,
      verificationData: data,
      now: now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('저장한 항목을 다시 읽는다', () async {
    final store = PendingVerificationStore(clock: () => now);
    await store.add(entry('jws-a'));

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.productId, 'lifetime_v1');
    expect(loaded.first.verificationData, 'jws-a');
    expect(loaded.first.attempts, 0);
  });

  test('같은 영수증을 두 번 넣어도 하나만 남는다', () async {
    final store = PendingVerificationStore(clock: () => now);
    await store.add(entry('jws-a'));
    await store.add(entry('jws-a'));

    expect(await store.load(), hasLength(1));
  });

  test('검증이 끝난 항목은 제거된다', () async {
    final store = PendingVerificationStore(clock: () => now);
    final pending = entry('jws-a');
    await store.add(pending);
    await store.remove(pending.id);

    expect(await store.load(), isEmpty);
  });

  test('실패는 누적되고 한도를 넘으면 버려진다', () async {
    final store = PendingVerificationStore(clock: () => now);
    final pending = entry('jws-a');
    await store.add(pending);

    for (var i = 1; i < PendingVerificationStore.maxAttempts; i++) {
      final dropped = await store.recordFailure(pending.id);
      expect(dropped, isFalse, reason: '$i번째 시도에서는 아직 버리지 않는다');
      final loaded = await store.load();
      expect(loaded.single.attempts, i);
    }

    // 마지막 시도에서 한도에 도달한다.
    expect(await store.recordFailure(pending.id), isTrue);
    expect(await store.load(), isEmpty);
  });

  test('없는 항목의 실패 기록은 무시된다', () async {
    final store = PendingVerificationStore(clock: () => now);
    expect(await store.recordFailure('nope'), isFalse);
  });

  test('상한을 넘으면 가장 오래된 항목부터 버린다', () async {
    final store = PendingVerificationStore(clock: () => now);
    for (var i = 0; i < PendingVerificationStore.maxEntries + 3; i++) {
      await store.add(entry('jws-$i'));
    }

    final loaded = await store.load();
    expect(loaded, hasLength(PendingVerificationStore.maxEntries));
    // 앞의 세 개가 밀려났다.
    expect(loaded.first.verificationData, 'jws-3');
    expect(loaded.last.verificationData, 'jws-12');
  });

  test('너무 오래된 항목은 읽을 때 걸러진다', () async {
    final store = PendingVerificationStore(clock: () => now);
    await store.add(entry('jws-old'));

    final later = PendingVerificationStore(
      clock: () => now.add(PendingVerificationStore.maxAge * 2),
    );
    expect(await later.load(), isEmpty);
  });

  test('저장된 값이 깨져 있으면 빈 목록으로 시작한다', () async {
    SharedPreferences.setMockInitialValues({
      'iap_pending_verifications': 'not json at all',
    });
    final store = PendingVerificationStore(clock: () => now);
    expect(await store.load(), isEmpty);
  });

  test('영수증이 없는 항목은 무시한다', () async {
    SharedPreferences.setMockInitialValues({
      'iap_pending_verifications':
          '[{"platform":"ios","productId":"lifetime_v1"}]',
    });
    final store = PendingVerificationStore(clock: () => now);
    expect(await store.load(), isEmpty);
  });

  test('clear는 전부 지운다', () async {
    final store = PendingVerificationStore(clock: () => now);
    await store.add(entry('jws-a'));
    await store.clear();
    expect(await store.load(), isEmpty);
  });
}
