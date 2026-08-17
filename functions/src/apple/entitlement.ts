/**
 * Turns a verified App Store transaction into a PurchaseRecord.
 *
 * Pure: no network, no Firestore, no config — everything it needs is passed in,
 * which is what makes the awkward cases (grace periods, refunds, family
 * sharing, retired product ids) testable.
 */

import {PurchaseRecord} from '../entitlement';
import {MalformedTransactionError, UnsupportedProductError} from '../errors';
import {ProductKind, proProduct} from '../products';

/** Subscription status values from the App Store Server API. */
export const AppleSubscriptionStatus = {
  ACTIVE: 1,
  EXPIRED: 2,
  BILLING_RETRY: 3,
  BILLING_GRACE_PERIOD: 4,
  REVOKED: 5,
} as const;

const APPLE_AUTO_RENEWABLE = 'Auto-Renewable Subscription';
const FAMILY_SHARED = 'FAMILY_SHARED';

/** The subset of JWSTransactionDecodedPayload this module depends on. */
export interface AppleTransactionFields {
  productId?: string;
  originalTransactionId?: string;
  transactionId?: string;
  bundleId?: string;
  purchaseDate?: number;
  expiresDate?: number;
  revocationDate?: number;
  revocationReason?: number | string;
  inAppOwnershipType?: string;
  environment?: string;
  type?: string;
  /** When the App Store signed this payload. */
  signedDate?: number;
}

/** The subset of JWSRenewalInfoDecodedPayload this module depends on. */
export interface AppleRenewalFields {
  gracePeriodExpiresDate?: number;
  autoRenewStatus?: number;
  isInBillingRetryPeriod?: boolean;
}

export interface AppleRecordOptions {
  nowMs: number;
  /** Status from getAllSubscriptionStatuses, when available. */
  subscriptionStatus?: number | undefined;
  renewal?: AppleRenewalFields | undefined;
}

function revocationReasonLabel(reason: number | string | undefined): string {
  switch (reason) {
  case 1:
  case '1':
    return 'refunded_due_to_issue';
  case 0:
  case '0':
    return 'refunded_other';
  default:
    return 'revoked';
  }
}

/**
 * Decides whether a product behaves as a subscription.
 *
 * Apple's own `type` wins over the local catalog: if the store says a product
 * renews, treating it as a lifetime purchase would grant access forever.
 */
function resolveKind(
  transaction: AppleTransactionFields,
  catalogKind: ProductKind,
): ProductKind {
  if (transaction.type === APPLE_AUTO_RENEWABLE) {
    return 'subscription';
  }
  if (transaction.expiresDate !== undefined) {
    return 'subscription';
  }
  return catalogKind;
}

export function appleRecord(
  transaction: AppleTransactionFields,
  options: AppleRecordOptions,
): PurchaseRecord {
  const product = proProduct(transaction.productId);
  if (!product || !transaction.productId) {
    throw new UnsupportedProductError(transaction.productId);
  }

  const transactionId =
    transaction.originalTransactionId ?? transaction.transactionId;
  if (!transactionId) {
    throw new MalformedTransactionError(
      'Transaction has neither originalTransactionId nor transactionId',
    );
  }

  const kind = resolveKind(transaction, product.kind);
  const status = options.subscriptionStatus;

  let expiresAtMs: number | null = null;
  let inGracePeriod = false;

  if (kind === 'subscription') {
    if (transaction.expiresDate === undefined) {
      throw new MalformedTransactionError(
        `Subscription ${transaction.productId} has no expiresDate`,
      );
    }
    expiresAtMs = transaction.expiresDate;

    // A billing grace period keeps access alive past expiresDate. Folding it
    // into expiresAtMs means a single expiry comparison decides access
    // everywhere else in the system.
    const graceEnd = options.renewal?.gracePeriodExpiresDate;
    if (
      status === AppleSubscriptionStatus.BILLING_GRACE_PERIOD &&
      graceEnd !== undefined &&
      graceEnd > expiresAtMs
    ) {
      expiresAtMs = graceEnd;
      inGracePeriod = true;
    }
  }

  let revokedAtMs: number | null = null;
  let revocationReason: string | null = null;
  if (transaction.revocationDate !== undefined) {
    revokedAtMs = transaction.revocationDate;
    revocationReason = revocationReasonLabel(transaction.revocationReason);
  } else if (status === AppleSubscriptionStatus.REVOKED) {
    revokedAtMs = options.nowMs;
    revocationReason = 'revoked';
  }

  const autoRenewStatus = options.renewal?.autoRenewStatus;

  return {
    productId: transaction.productId,
    kind,
    source: 'app_store',
    environment: transaction.environment ?? 'Production',
    transactionId,
    latestTransactionId: transaction.transactionId ?? null,
    purchaseDateMs: transaction.purchaseDate ?? null,
    expiresAtMs,
    inGracePeriod,
    // StoreKit only reports Ask-to-Buy purchases as `pending`, and the client
    // never forwards those, so anything that reaches here is paid for.
    isPending: false,
    autoRenewing: autoRenewStatus === undefined ? null : autoRenewStatus === 1,
    revokedAtMs,
    revocationReason,
    isFamilyShared: transaction.inAppOwnershipType === FAMILY_SHARED,
    storeState: status === undefined ? null : `status_${status}`,
    signedAtMs: transaction.signedDate ?? null,
    lastVerifiedAtMs: options.nowMs,
  };
}
