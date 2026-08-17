/**
 * Turns a Play Developer API purchase response into a PurchaseRecord.
 *
 * Pure: no network, no Firestore. Play's two purchase endpoints have completely
 * different shapes, so each gets its own mapper and they meet at PurchaseRecord.
 */

import {PurchaseRecord} from '../entitlement';
import {MalformedTransactionError, UnsupportedProductError} from '../errors';
import {proProduct} from '../products';
import {PlayProductPurchase, PlaySubscriptionPurchase} from './client';

/** purchaseState values on the one-time product endpoint. */
const PRODUCT_PURCHASED = 0;
const PRODUCT_CANCELED = 1;
const PRODUCT_PENDING = 2;

/**
 * Subscription states that still grant access.
 *
 * CANCELED means auto-renew was switched off, not that access ended — the user
 * keeps it until expiryTime. IN_GRACE_PERIOD is a failed payment Google is
 * retrying while access continues.
 */
const ENTITLING_SUBSCRIPTION_STATES: ReadonlySet<string> = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_CANCELED',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
]);

const GRACE_PERIOD_STATE = 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD';
const PENDING_STATE = 'SUBSCRIPTION_STATE_PENDING';

/**
 * Renewal order ids are the original with a `..N` suffix, so stripping it
 * yields an id that stays stable across renewals — the equivalent of Apple's
 * originalTransactionId.
 */
export function baseOrderId(orderId: string | undefined): string | null {
  if (!orderId) {
    return null;
  }
  const index = orderId.indexOf('..');
  return index === -1 ? orderId : orderId.slice(0, index);
}

function parseMillis(value: string | undefined): number | null {
  if (!value) {
    return null;
  }
  // The product endpoint returns epoch millis as a string, the subscription
  // endpoint an RFC 3339 timestamp.
  if (/^\d+$/.test(value)) {
    return Number(value);
  }
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}

export function playProductRecord(
  productId: string,
  purchase: PlayProductPurchase,
  nowMs: number,
): PurchaseRecord {
  const product = proProduct(productId);
  if (!product) {
    throw new UnsupportedProductError(productId);
  }
  if (product.kind !== 'lifetime') {
    throw new MalformedTransactionError(
      `${productId} is a subscription but was verified as a one-time product`,
    );
  }

  const state = purchase.purchaseState ?? PRODUCT_PURCHASED;
  const transactionId =
    baseOrderId(purchase.orderId) ?? `product_${productId}`;

  return {
    productId,
    kind: 'lifetime',
    source: 'play_store',
    environment: 'Production',
    transactionId,
    latestTransactionId: purchase.orderId ?? null,
    purchaseDateMs: parseMillis(purchase.purchaseTimeMillis),
    expiresAtMs: null,
    inGracePeriod: false,
    isPending: state === PRODUCT_PENDING,
    autoRenewing: null,
    revokedAtMs: state === PRODUCT_CANCELED ? nowMs : null,
    revocationReason: state === PRODUCT_CANCELED ? 'refunded' : null,
    isFamilyShared: false,
    storeState: `purchaseState_${state}`,
    // Play has no signing timestamp; the lookup time serves the same purpose
    // because its API always answers with the purchase's current state.
    signedAtMs: nowMs,
    lastVerifiedAtMs: nowMs,
  };
}

export function playSubscriptionRecord(
  productId: string,
  purchase: PlaySubscriptionPurchase,
  nowMs: number,
): PurchaseRecord {
  const product = proProduct(productId);
  if (!product) {
    throw new UnsupportedProductError(productId);
  }

  const state = purchase.subscriptionState ?? '';
  const lineItem =
    purchase.lineItems?.find((item) => item.productId === productId) ??
    purchase.lineItems?.[0];
  const expiryMs = parseMillis(lineItem?.expiryTime);

  // Everything except the entitling states is folded into "already expired", so
  // one expiry comparison decides access for both stores. Without this, a paused
  // or on-hold subscription whose expiryTime is still in the future would keep
  // granting PRO.
  const entitling = ENTITLING_SUBSCRIPTION_STATES.has(state);
  const expiresAtMs = entitling ? expiryMs : Math.min(expiryMs ?? nowMs, nowMs);

  const transactionId =
    baseOrderId(purchase.latestOrderId) ?? `subscription_${productId}`;

  return {
    productId,
    kind: 'subscription',
    source: 'play_store',
    environment: purchase.testPurchase ? 'Sandbox' : 'Production',
    transactionId,
    latestTransactionId: purchase.latestOrderId ?? null,
    purchaseDateMs: parseMillis(purchase.startTime),
    expiresAtMs,
    inGracePeriod: state === GRACE_PERIOD_STATE,
    isPending: state === PENDING_STATE,
    autoRenewing: lineItem?.autoRenewingPlan?.autoRenewEnabled ?? null,
    revokedAtMs: null,
    revocationReason: null,
    isFamilyShared: false,
    storeState: state || null,
    signedAtMs: nowMs,
    lastVerifiedAtMs: nowMs,
  };
}
