import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {isRecordActive} from '../entitlement';
import {MalformedTransactionError, UnsupportedProductError} from '../errors';
import {
  baseOrderId,
  playProductRecord,
  playSubscriptionRecord,
} from './entitlement';

const NOW = Date.UTC(2026, 7, 17, 12, 0, 0);
const DAY = 24 * 60 * 60 * 1000;

function iso(ms: number): string {
  return new Date(ms).toISOString();
}

describe('baseOrderId', () => {
  it('strips the renewal suffix so the id survives renewals', () => {
    assert.equal(
      baseOrderId('GPA.3300-1234-5678-90123..7'),
      'GPA.3300-1234-5678-90123',
    );
  });

  it('leaves a first-purchase order id alone', () => {
    assert.equal(
      baseOrderId('GPA.3300-1234-5678-90123'),
      'GPA.3300-1234-5678-90123',
    );
  });

  it('handles a missing order id', () => {
    assert.equal(baseOrderId(undefined), null);
  });
});

describe('playProductRecord', () => {
  it('maps a completed one-time purchase', () => {
    const result = playProductRecord(
      'lifetime_v1',
      {
        purchaseState: 0,
        purchaseTimeMillis: String(NOW - 5 * DAY),
        orderId: 'GPA.3300-1111-2222-33333',
      },
      NOW,
    );
    assert.equal(result.kind, 'lifetime');
    assert.equal(result.source, 'play_store');
    assert.equal(result.transactionId, 'GPA.3300-1111-2222-33333');
    assert.equal(result.purchaseDateMs, NOW - 5 * DAY);
    assert.equal(result.expiresAtMs, null);
    assert.equal(isRecordActive(result, NOW + 1000 * DAY), true);
  });

  it('treats a cancelled purchase as revoked', () => {
    const result = playProductRecord(
      'lifetime_v1',
      {purchaseState: 1, orderId: 'GPA.1'},
      NOW,
    );
    assert.equal(result.revokedAtMs, NOW);
    assert.equal(result.revocationReason, 'refunded');
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('does not grant access while payment is still pending', () => {
    // Without the pending flag a lifetime product would be granted on the
    // strength of an unpaid order.
    const result = playProductRecord(
      'lifetime_v1',
      {purchaseState: 2, orderId: 'GPA.2'},
      NOW,
    );
    assert.equal(result.isPending, true);
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('falls back to a stable id when Play omits the order id', () => {
    const result = playProductRecord('lifetime_v1', {purchaseState: 0}, NOW);
    assert.equal(result.transactionId, 'product_lifetime_v1');
  });

  it('rejects an unknown product', () => {
    assert.throws(
      () => playProductRecord('sticker_pack', {purchaseState: 0}, NOW),
      UnsupportedProductError,
    );
  });

  it('refuses to verify a subscription as a one-time product', () => {
    assert.throws(
      () => playProductRecord('yearly_v2', {purchaseState: 0}, NOW),
      MalformedTransactionError,
    );
  });
});

describe('playSubscriptionRecord', () => {
  const activeSubscription = {
    subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
    latestOrderId: 'GPA.3300-4444-5555-66666..2',
    startTime: iso(NOW - 400 * DAY),
    lineItems: [
      {
        productId: 'yearly_v2',
        expiryTime: iso(NOW + 300 * DAY),
        autoRenewingPlan: {autoRenewEnabled: true},
      },
    ],
  };

  it('maps an active subscription', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      activeSubscription,
      NOW,
    );
    assert.equal(result.kind, 'subscription');
    assert.equal(result.transactionId, 'GPA.3300-4444-5555-66666');
    assert.equal(result.expiresAtMs, NOW + 300 * DAY);
    assert.equal(result.autoRenewing, true);
    assert.equal(isRecordActive(result, NOW), true);
  });

  it('keeps access after the user turns off auto-renew', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      {
        ...activeSubscription,
        subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
        lineItems: [
          {
            productId: 'yearly_v2',
            expiryTime: iso(NOW + 10 * DAY),
            autoRenewingPlan: {autoRenewEnabled: false},
          },
        ],
      },
      NOW,
    );
    assert.equal(result.autoRenewing, false);
    assert.equal(isRecordActive(result, NOW), true);
    assert.equal(isRecordActive(result, NOW + 11 * DAY), false);
  });

  it('keeps access during a grace period', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      {
        ...activeSubscription,
        subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
        lineItems: [
          {productId: 'yearly_v2', expiryTime: iso(NOW + 3 * DAY)},
        ],
      },
      NOW,
    );
    assert.equal(result.inGracePeriod, true);
    assert.equal(isRecordActive(result, NOW), true);
  });

  it('ends access for a paused subscription with a future expiry', () => {
    // Play can report a future expiryTime for a paused plan; without clamping
    // it the user would keep PRO while paying nothing.
    const result = playSubscriptionRecord(
      'yearly_v2',
      {
        ...activeSubscription,
        subscriptionState: 'SUBSCRIPTION_STATE_PAUSED',
        lineItems: [
          {productId: 'yearly_v2', expiryTime: iso(NOW + 300 * DAY)},
        ],
      },
      NOW,
    );
    assert.equal(result.expiresAtMs, NOW);
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('ends access for an on-hold subscription', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      {
        ...activeSubscription,
        subscriptionState: 'SUBSCRIPTION_STATE_ON_HOLD',
        lineItems: [
          {productId: 'yearly_v2', expiryTime: iso(NOW + 30 * DAY)},
        ],
      },
      NOW,
    );
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('does not grant access to a pending subscription', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      {
        ...activeSubscription,
        subscriptionState: 'SUBSCRIPTION_STATE_PENDING',
        lineItems: [
          {productId: 'yearly_v2', expiryTime: iso(NOW + 30 * DAY)},
        ],
      },
      NOW,
    );
    assert.equal(result.isPending, true);
    assert.equal(isRecordActive(result, NOW), false);
  });

  it('marks a test purchase as sandbox', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      {...activeSubscription, testPurchase: {}},
      NOW,
    );
    assert.equal(result.environment, 'Sandbox');
  });

  it('picks the line item for the product being verified', () => {
    const result = playSubscriptionRecord(
      'yearly_v2',
      {
        ...activeSubscription,
        lineItems: [
          {productId: 'something_else', expiryTime: iso(NOW + DAY)},
          {productId: 'yearly_v2', expiryTime: iso(NOW + 200 * DAY)},
        ],
      },
      NOW,
    );
    assert.equal(result.expiresAtMs, NOW + 200 * DAY);
  });
});
