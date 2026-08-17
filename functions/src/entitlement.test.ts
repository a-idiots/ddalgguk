import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {
  PurchaseRecord,
  isRecordActive,
  isStaleAgainst,
  mergeRecord,
  recordKey,
  summarize,
} from './entitlement';

const NOW = Date.UTC(2026, 7, 17, 12, 0, 0);
const DAY = 24 * 60 * 60 * 1000;

function record(overrides: Partial<PurchaseRecord> = {}): PurchaseRecord {
  return {
    productId: 'lifetime_v1',
    kind: 'lifetime',
    source: 'app_store',
    environment: 'Production',
    transactionId: '2000000111',
    latestTransactionId: '2000000111',
    purchaseDateMs: NOW - 10 * DAY,
    expiresAtMs: null,
    inGracePeriod: false,
    isPending: false,
    autoRenewing: null,
    revokedAtMs: null,
    revocationReason: null,
    isFamilyShared: false,
    storeState: null,
    signedAtMs: NOW,
    lastVerifiedAtMs: NOW,
    ...overrides,
  };
}

function subscription(overrides: Partial<PurchaseRecord> = {}): PurchaseRecord {
  return record({
    productId: 'yearly_v2',
    kind: 'subscription',
    transactionId: '2000000222',
    expiresAtMs: NOW + 30 * DAY,
    autoRenewing: true,
    ...overrides,
  });
}

describe('isRecordActive', () => {
  it('grants a lifetime purchase forever', () => {
    assert.equal(isRecordActive(record(), NOW), true);
    assert.equal(isRecordActive(record(), NOW + 3650 * DAY), true);
  });

  it('grants a subscription only until it expires', () => {
    const sub = subscription();
    assert.equal(isRecordActive(sub, NOW), true);
    assert.equal(isRecordActive(sub, NOW + 31 * DAY), false);
  });

  it('never grants a revoked purchase', () => {
    assert.equal(
      isRecordActive(record({revokedAtMs: NOW - DAY}), NOW),
      false,
    );
  });

  it('never grants an unpaid purchase, even a lifetime one', () => {
    assert.equal(isRecordActive(record({isPending: true}), NOW), false);
  });

  it('treats a subscription with no expiry as not entitling', () => {
    assert.equal(
      isRecordActive(subscription({expiresAtMs: null}), NOW),
      false,
    );
  });
});

describe('summarize', () => {
  it('reports no entitlement when there are no records', () => {
    const summary = summarize({}, NOW);
    assert.equal(summary.isPro, false);
    assert.equal(summary.activeProductId, null);
    assert.equal(summary.expiresAtMs, null);
  });

  it('reports the subscription expiry when only a subscription is active', () => {
    const sub = subscription();
    const summary = summarize({a: sub}, NOW);
    assert.equal(summary.isPro, true);
    assert.equal(summary.activeProductId, 'yearly_v2');
    assert.equal(summary.activeKind, 'subscription');
    assert.equal(summary.expiresAtMs, sub.expiresAtMs);
  });

  it('lets a lifetime purchase outrank an expired subscription', () => {
    const summary = summarize(
      {
        lifetime: record(),
        expired: subscription({expiresAtMs: NOW - DAY}),
      },
      NOW,
    );
    assert.equal(summary.isPro, true);
    assert.equal(summary.activeKind, 'lifetime');
    // A lifetime entitlement has no expiry to report.
    assert.equal(summary.expiresAtMs, null);
  });

  it('keeps a lifetime purchase when the subscription is revoked', () => {
    // The regression this guards: a refund notification for an old annual
    // subscription must not revoke a later lifetime purchase.
    const summary = summarize(
      {
        lifetime: record(),
        refunded: subscription({revokedAtMs: NOW - DAY}),
      },
      NOW,
    );
    assert.equal(summary.isPro, true);
    assert.equal(summary.activeProductId, 'lifetime_v1');
  });

  it('reports the longest-running subscription', () => {
    const summary = summarize(
      {
        short: subscription({
          transactionId: 'a',
          expiresAtMs: NOW + 5 * DAY,
        }),
        long: subscription({
          transactionId: 'b',
          productId: 'yearly_v1',
          expiresAtMs: NOW + 100 * DAY,
        }),
      },
      NOW,
    );
    assert.equal(summary.activeProductId, 'yearly_v1');
    assert.equal(summary.expiresAtMs, NOW + 100 * DAY);
  });

  it('honours a still-valid legacy annual subscription', () => {
    const summary = summarize(
      {legacy: subscription({productId: 'yearly_v1'})},
      NOW,
    );
    assert.equal(summary.isPro, true);
    assert.equal(summary.activeProductId, 'yearly_v1');
  });
});

describe('recordKey', () => {
  it('strips characters Firestore cannot use in a field path', () => {
    assert.equal(
      recordKey('play_store', 'GPA.3300-1234-5678-90123'),
      'play_store_GPA_3300-1234-5678-90123',
    );
  });

  it('is stable for Apple transaction ids', () => {
    assert.equal(recordKey('app_store', '2000000111'), 'app_store_2000000111');
  });
});

describe('isStaleAgainst', () => {
  it('drops an older snapshot', () => {
    const existing = subscription({signedAtMs: NOW});
    const incoming = subscription({
      signedAtMs: NOW - DAY,
      expiresAtMs: NOW - DAY,
    });
    assert.equal(isStaleAgainst(incoming, existing), true);
  });

  it('accepts a newer snapshot even when it shortens the entitlement', () => {
    // A paused Play subscription: the authoritative re-read must be able to
    // pull the expiry back to now.
    const existing = subscription({signedAtMs: NOW - DAY});
    const incoming = subscription({signedAtMs: NOW, expiresAtMs: NOW});
    assert.equal(isStaleAgainst(incoming, existing), false);
  });

  it('always accepts a revocation', () => {
    const existing = subscription({signedAtMs: NOW + DAY});
    const incoming = subscription({signedAtMs: NOW, revokedAtMs: NOW});
    assert.equal(isStaleAgainst(incoming, existing), false);
  });

  it('falls back to not shortening when timestamps are missing', () => {
    const existing = subscription({signedAtMs: null});
    const incoming = subscription({signedAtMs: null, expiresAtMs: NOW});
    assert.equal(isStaleAgainst(incoming, existing), true);
  });
});

describe('mergeRecord', () => {
  it('adds a record that is not there yet', () => {
    const merged = mergeRecord({}, subscription());
    assert.deepEqual(Object.keys(merged), ['app_store_2000000222']);
  });

  it('replaces a record with a newer snapshot', () => {
    const key = 'app_store_2000000222';
    const existing = {[key]: subscription({signedAtMs: NOW - DAY})};
    const renewed = subscription({
      signedAtMs: NOW,
      expiresAtMs: NOW + 395 * DAY,
    });
    const merged = mergeRecord(existing, renewed);
    assert.equal(merged[key]?.expiresAtMs, NOW + 395 * DAY);
  });

  it('keeps the newer expiry when an out-of-order payload arrives', () => {
    // EXPIRED delivered after DID_RENEW: the renewal must survive.
    const key = 'app_store_2000000222';
    const renewed = subscription({
      signedAtMs: NOW,
      expiresAtMs: NOW + 395 * DAY,
    });
    const staleExpiry = subscription({
      signedAtMs: NOW - 60 * 1000,
      expiresAtMs: NOW - DAY,
    });
    const merged = mergeRecord({[key]: renewed}, staleExpiry);
    assert.equal(merged[key]?.expiresAtMs, NOW + 395 * DAY);
  });

  it('never loses a revocation reported by a stale payload', () => {
    const key = 'app_store_2000000222';
    const current = subscription({signedAtMs: NOW});
    const staleRefund = subscription({
      signedAtMs: NOW - DAY,
      expiresAtMs: NOW - DAY,
      revokedAtMs: NOW - DAY,
      revocationReason: 'refunded_other',
    });
    const merged = mergeRecord({[key]: current}, staleRefund);
    assert.equal(merged[key]?.revokedAtMs, NOW - DAY);
    assert.equal(isRecordActive(merged[key] as PurchaseRecord, NOW), false);
  });
});
