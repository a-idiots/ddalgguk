/**
 * The canonical entitlement model.
 *
 * This module is deliberately free of Firebase imports so the merge/summarize
 * logic can be unit tested on its own. All instants are epoch milliseconds —
 * the Flutter client reads them with DateTime.fromMillisecondsSinceEpoch.
 */

import {ProductKind} from './products';

export type PurchaseSource = 'app_store' | 'play_store';

/** One verified purchase belonging to a user. */
export interface PurchaseRecord {
  /** Store product identifier, e.g. 'lifetime_v1'. */
  productId: string;
  kind: ProductKind;
  source: PurchaseSource;
  /** 'Production' | 'Sandbox' | 'Xcode' (Apple), 'Production' (Google). */
  environment: string;
  /**
   * Stable identifier for the purchase across renewals: Apple's
   * originalTransactionId, or Google's order id (falling back to the product id
   * when the order id is absent).
   */
  transactionId: string;
  /** Most recent transaction id seen for this purchase, for diagnostics. */
  latestTransactionId: string | null;
  purchaseDateMs: number | null;
  /**
   * When the entitlement lapses. null means it never does (lifetime).
   * For a subscription in a billing grace period this is the end of the grace
   * period, so a plain expiry comparison is always sufficient to decide access.
   */
  expiresAtMs: number | null;
  /** Informational: the subscription is being kept alive by a grace period. */
  inGracePeriod: boolean;
  /**
   * The purchase has not been paid for yet (Ask to Buy, slow bank transfer).
   * Never grants access, even for a product that otherwise never expires.
   */
  isPending: boolean;
  autoRenewing: boolean | null;
  /** Set when Apple/Google reports a refund or revocation. */
  revokedAtMs: number | null;
  revocationReason: string | null;
  /** Obtained through Family Sharing rather than bought directly. */
  isFamilyShared: boolean;
  /** Raw store status string, kept for diagnostics only. */
  storeState: string | null;
  /**
   * When the store signed/produced this snapshot — Apple's `signedDate`, or the
   * lookup time for Play (whose API always answers with current state).
   *
   * This, not the processing time, decides which of two conflicting payloads
   * wins: notifications arrive out of order, so an EXPIRED delivered after a
   * DID_RENEW must not be allowed to undo the renewal.
   */
  signedAtMs: number | null;
  lastVerifiedAtMs: number;
}

/** The client-facing summary stored at the top level of the document. */
export interface EntitlementSummary {
  isPro: boolean;
  activeProductId: string | null;
  activeKind: ProductKind | null;
  activeSource: PurchaseSource | null;
  /** null when not entitled, or when entitled through a lifetime purchase. */
  expiresAtMs: number | null;
}

export interface EntitlementDoc extends EntitlementSummary {
  schemaVersion: number;
  records: Record<string, PurchaseRecord>;
}

export const ENTITLEMENT_SCHEMA_VERSION = 1;

/**
 * Firestore map keys cannot be used in dotted field paths when they contain
 * '.', and Google order ids do ('GPA.3300-…'), so keys are normalised.
 */
export function recordKey(
  source: PurchaseSource,
  transactionId: string,
): string {
  const safe = transactionId.replace(/[^A-Za-z0-9_-]/g, '_');
  return `${source}_${safe}`;
}

/** Whether a single purchase currently grants access. */
export function isRecordActive(record: PurchaseRecord, nowMs: number): boolean {
  if (record.revokedAtMs !== null) {
    return false;
  }
  if (record.isPending) {
    return false;
  }
  if (record.kind === 'lifetime') {
    return true;
  }
  return record.expiresAtMs !== null && record.expiresAtMs > nowMs;
}

/**
 * Reduces every purchase a user holds to one answer.
 *
 * A lifetime purchase always wins; otherwise the subscription that runs longest
 * is reported. This is what keeps an EXPIRED notification for an old annual
 * subscription from revoking a later lifetime purchase.
 */
export function summarize(
  records: Record<string, PurchaseRecord>,
  nowMs: number,
): EntitlementSummary {
  const active = Object.values(records).filter((record) =>
    isRecordActive(record, nowMs),
  );

  if (active.length === 0) {
    return {
      isPro: false,
      activeProductId: null,
      activeKind: null,
      activeSource: null,
      expiresAtMs: null,
    };
  }

  const lifetime = active.find((record) => record.kind === 'lifetime');
  if (lifetime) {
    return {
      isPro: true,
      activeProductId: lifetime.productId,
      activeKind: 'lifetime',
      activeSource: lifetime.source,
      expiresAtMs: null,
    };
  }

  const longest = active.reduce((best, record) =>
    (record.expiresAtMs ?? 0) > (best.expiresAtMs ?? 0) ? record : best,
  );
  return {
    isPro: true,
    activeProductId: longest.productId,
    activeKind: longest.kind,
    activeSource: longest.source,
    expiresAtMs: longest.expiresAtMs,
  };
}

/**
 * Merges a freshly verified record into the stored set.
 *
 * Store notifications and client verifications race constantly — a renewal
 * notification can land while the app is still verifying the transaction before
 * it — so the newer snapshot always wins, and an older one is dropped rather
 * than allowed to shorten an entitlement it does not know about yet.
 */
export function mergeRecord(
  records: Record<string, PurchaseRecord>,
  incoming: PurchaseRecord,
): Record<string, PurchaseRecord> {
  const key = recordKey(incoming.source, incoming.transactionId);
  const existing = records[key];
  const merged: Record<string, PurchaseRecord> = {...records};

  if (!existing || !isStaleAgainst(incoming, existing)) {
    merged[key] = incoming;
    return merged;
  }

  // The incoming snapshot is older. Keep what we have, but record that we did
  // look, and never lose a revocation either payload knows about.
  merged[key] = {
    ...existing,
    revokedAtMs: existing.revokedAtMs ?? incoming.revokedAtMs,
    revocationReason: existing.revocationReason ?? incoming.revocationReason,
    lastVerifiedAtMs: Math.max(
      existing.lastVerifiedAtMs,
      incoming.lastVerifiedAtMs,
    ),
  };
  return merged;
}

export function isStaleAgainst(
  incoming: PurchaseRecord,
  existing: PurchaseRecord,
): boolean {
  // A revocation is always worth applying, whatever the timestamps say: it is
  // the one transition that must never be lost.
  if (incoming.revokedAtMs !== null && existing.revokedAtMs === null) {
    return false;
  }
  // When both sides carry a store-issued timestamp, that settles it — and it is
  // what lets an authoritative re-read shorten an expiry (a paused or on-hold
  // subscription) instead of being mistaken for stale data.
  if (incoming.signedAtMs !== null && existing.signedAtMs !== null) {
    return incoming.signedAtMs < existing.signedAtMs;
  }
  // Without one, fall back to never shortening a known-longer entitlement.
  const incomingExpiry = incoming.expiresAtMs ?? Number.MAX_SAFE_INTEGER;
  const existingExpiry = existing.expiresAtMs ?? Number.MAX_SAFE_INTEGER;
  return incomingExpiry < existingExpiry;
}

export function emptyDoc(): EntitlementDoc {
  return {
    schemaVersion: ENTITLEMENT_SCHEMA_VERSION,
    isPro: false,
    activeProductId: null,
    activeKind: null,
    activeSource: null,
    expiresAtMs: null,
    records: {},
  };
}
