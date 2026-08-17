/**
 * Google Play verification.
 *
 * Unlike StoreKit 2 there is no signed payload to check locally: the
 * purchaseToken is opaque and only the Play Developer API can say what it means,
 * so every verification is a server-to-server lookup.
 */

import {logger} from 'firebase-functions';

import {androidPackageName} from '../config';
import {PurchaseRecord} from '../entitlement';
import {
  TransientVerificationError,
  UnsupportedProductError,
  UntrustedPayloadError,
} from '../errors';
import {proProduct} from '../products';
import {
  PlayNotFoundError,
  PlayUnavailableError,
  getProductPurchase,
  getSubscriptionPurchase,
} from './client';
import {playProductRecord, playSubscriptionRecord} from './entitlement';

export interface PlayVerification {
  record: PurchaseRecord;
  /** Always true: Play answers are looked up server-side by definition. */
  authoritative: true;
}

function rethrow(error: unknown): never {
  if (error instanceof PlayNotFoundError) {
    throw new UntrustedPayloadError('Play does not know this purchase', error);
  }
  if (error instanceof PlayUnavailableError) {
    throw new TransientVerificationError('Play API unavailable', error);
  }
  throw error;
}

export async function verifyPlayPurchase(
  productId: string,
  purchaseToken: string,
  nowMs: number = Date.now(),
): Promise<PlayVerification> {
  const product = proProduct(productId);
  if (!product) {
    throw new UnsupportedProductError(productId);
  }
  if (!purchaseToken) {
    throw new UntrustedPayloadError('Missing purchase token');
  }

  const packageName = androidPackageName();

  try {
    if (product.kind === 'subscription') {
      const purchase = await getSubscriptionPurchase(
        packageName,
        purchaseToken,
      );
      return {
        record: playSubscriptionRecord(productId, purchase, nowMs),
        authoritative: true,
      };
    }
    const purchase = await getProductPurchase(
      packageName,
      productId,
      purchaseToken,
    );
    return {
      record: playProductRecord(productId, purchase, nowMs),
      authoritative: true,
    };
  } catch (error) {
    return rethrow(error);
  }
}

/**
 * Re-reads a stored Play purchase.
 *
 * Returns null when the lookup fails, so a Play outage leaves the stored record
 * untouched instead of revoking it.
 */
export async function refreshPlayRecord(
  stored: PurchaseRecord,
  purchaseToken: string | undefined,
  nowMs: number = Date.now(),
): Promise<PurchaseRecord | null> {
  if (!purchaseToken) {
    return null;
  }
  try {
    const verification = await verifyPlayPurchase(
      stored.productId,
      purchaseToken,
      nowMs,
    );
    return verification.record;
  } catch (error) {
    if (error instanceof UntrustedPayloadError) {
      // Play now denies a purchase it previously honoured: treat it as revoked
      // rather than silently keeping access.
      logger.warn('Play no longer recognises a stored purchase', {
        productId: stored.productId,
        transactionId: stored.transactionId,
      });
      return {
        ...stored,
        revokedAtMs: stored.revokedAtMs ?? nowMs,
        revocationReason: stored.revocationReason ?? 'not_found',
        lastVerifiedAtMs: nowMs,
      };
    }
    logger.warn('Could not refresh Play purchase', {
      productId: stored.productId,
      error: String(error),
    });
    return null;
  }
}
