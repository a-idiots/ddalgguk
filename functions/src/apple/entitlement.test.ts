import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {isRecordActive} from '../entitlement';
import {MalformedTransactionError, UnsupportedProductError} from '../errors';
import {
  AppleSubscriptionStatus,
  AppleTransactionFields,
  appleRecord,
} from './entitlement';

const NOW = Date.UTC(2026, 7, 17, 12, 0, 0);
const DAY = 24 * 60 * 60 * 1000;

const lifetime: AppleTransactionFields = {
  productId: 'lifetime_v1',
  originalTransactionId: '2000000111',
  transactionId: '2000000111',
  bundleId: 'com.aidiot.ddalgguk',
  purchaseDate: NOW - 30 * DAY,
  type: 'Non-Consumable',
  inAppOwnershipType: 'PURCHASED',
  environment: 'Production',
  signedDate: NOW,
};

const annual: AppleTransactionFields = {
  productId: 'yearly_v2',
  originalTransactionId: '2000000222',
  transactionId: '2000000999',
  bundleId: 'com.aidiot.ddalgguk',
  purchaseDate: NOW - 30 * DAY,
  expiresDate: NOW + 335 * DAY,
  type: 'Auto-Renewable Subscription',
  inAppOwnershipType: 'PURCHASED',
  environment: 'Production',
  signedDate: NOW,
};

describe('appleRecord — one-time purchase', () => {
  it('maps a lifetime purchase', () => {
    const result = appleRecord(lifetime, {nowMs: NOW});
    assert.equal(result.productId, 'lifetime_v1');
    assert.equal(result.kind, 'lifetime');
    assert.equal(result.source, 'app_store');
    assert.equal(result.expiresAtMs, null);
    assert.equal(result.revokedAtMs, null);
    assert.equal(result.signedAtMs, NOW);
    assert.equal(isRecordActive(result, NOW + 5000 * DAY), true);
  });

  it('keys the record on the original transaction id', () => {
    // Renewals change transactionId but not originalTransactionId, which is
    // what keeps one subscription from accumulating a record per renewal.
    const result = appleRecord(annual, {nowMs: NOW});
    assert.equal(result.transactionId, '2000000222');
    assert.equal(result.latestTransactionId, '2000000999');
  });

  it('records a refund as a revocation', () => {
    const result = appleRecord(
      {...lifetime, revocationDate: NOW - DAY, revocationReason: 1},
      {nowMs: NOW},
    );
    assert.equal(result.revokedAtMs, NOW - DAY);
    assert.equal(result.revocationReason, 'refunded_due_to_issue');
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('flags a family-shared purchase but still honours it', () => {
    const result = appleRecord(
      {...lifetime, inAppOwnershipType: 'FAMILY_SHARED'},
      {nowMs: NOW},
    );
    assert.equal(result.isFamilyShared, true);
    assert.equal(isRecordActive(result, NOW), true);
  });
});

describe('appleRecord — subscription', () => {
  it('maps an active annual subscription', () => {
    const result = appleRecord(annual, {
      nowMs: NOW,
      subscriptionStatus: AppleSubscriptionStatus.ACTIVE,
      renewal: {autoRenewStatus: 1},
    });
    assert.equal(result.kind, 'subscription');
    assert.equal(result.expiresAtMs, NOW + 335 * DAY);
    assert.equal(result.autoRenewing, true);
    assert.equal(result.inGracePeriod, false);
    assert.equal(isRecordActive(result, NOW), true);
  });

  it('stops granting access once it has expired', () => {
    const result = appleRecord(
      {...annual, expiresDate: NOW - DAY},
      {nowMs: NOW, subscriptionStatus: AppleSubscriptionStatus.EXPIRED},
    );
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('extends access through a billing grace period', () => {
    const result = appleRecord(
      {...annual, expiresDate: NOW - DAY},
      {
        nowMs: NOW,
        subscriptionStatus: AppleSubscriptionStatus.BILLING_GRACE_PERIOD,
        renewal: {gracePeriodExpiresDate: NOW + 10 * DAY},
      },
    );
    assert.equal(result.inGracePeriod, true);
    assert.equal(result.expiresAtMs, NOW + 10 * DAY);
    assert.equal(isRecordActive(result, NOW), true);
    // And the grace period is bounded — it is not an open-ended flag.
    assert.equal(isRecordActive(result, NOW + 11 * DAY), false);
  });

  it('ignores a grace period date when the status is not grace period', () => {
    const result = appleRecord(
      {...annual, expiresDate: NOW - DAY},
      {
        nowMs: NOW,
        subscriptionStatus: AppleSubscriptionStatus.BILLING_RETRY,
        renewal: {gracePeriodExpiresDate: NOW + 10 * DAY},
      },
    );
    assert.equal(result.inGracePeriod, false);
    assert.equal(result.expiresAtMs, NOW - DAY);
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('treats a REVOKED status as a revocation', () => {
    const result = appleRecord(annual, {
      nowMs: NOW,
      subscriptionStatus: AppleSubscriptionStatus.REVOKED,
    });
    assert.equal(result.revokedAtMs, NOW);
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('honours the retired yearly_v1 product', () => {
    const result = appleRecord(
      {...annual, productId: 'yearly_v1'},
      {nowMs: NOW, subscriptionStatus: AppleSubscriptionStatus.ACTIVE},
    );
    assert.equal(result.productId, 'yearly_v1');
    assert.equal(isRecordActive(result, NOW), true);
  });

  it('reports auto-renew off without ending access', () => {
    const result = appleRecord(annual, {
      nowMs: NOW,
      subscriptionStatus: AppleSubscriptionStatus.ACTIVE,
      renewal: {autoRenewStatus: 0},
    });
    assert.equal(result.autoRenewing, false);
    assert.equal(isRecordActive(result, NOW), true);
  });
});

describe('appleRecord — rejections', () => {
  it('rejects a product that does not grant PRO', () => {
    assert.throws(
      () => appleRecord({...lifetime, productId: 'sticker_pack'}, {nowMs: NOW}),
      UnsupportedProductError,
    );
  });

  it('rejects a transaction with no identifiers', () => {
    assert.throws(
      () =>
        appleRecord(
          {
            ...lifetime,
            originalTransactionId: undefined,
            transactionId: undefined,
          },
          {nowMs: NOW},
        ),
      MalformedTransactionError,
    );
  });

  it('rejects a subscription with no expiry instead of granting it', () => {
    assert.throws(
      () => appleRecord({...annual, expiresDate: undefined}, {nowMs: NOW}),
      MalformedTransactionError,
    );
  });

  it('believes the store over the local catalog about renewals', () => {
    // If the App Store says a product renews, treating it as a lifetime
    // purchase would hand out permanent access.
    const result = appleRecord(
      {
        ...lifetime,
        type: 'Auto-Renewable Subscription',
        expiresDate: NOW + DAY,
      },
      {nowMs: NOW},
    );
    assert.equal(result.kind, 'subscription');
    assert.equal(isRecordActive(result, NOW + 2 * DAY), false);
  });
});
