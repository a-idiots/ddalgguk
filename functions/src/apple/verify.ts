/**
 * App Store verification.
 *
 * Two layers of trust:
 *  1. The JWS the device sends is verified cryptographically against Apple's
 *     root CAs, and its bundle id is checked. That alone already makes the
 *     payload unforgeable.
 *  2. The App Store Server API is then queried for the current state of the
 *     purchase, because a device-held JWS is a snapshot: it cannot know about a
 *     renewal, a refund, or a cancellation that happened afterwards.
 *
 * If step 2 is unavailable we fall back to step 1 and say so, rather than
 * refusing a purchase that we have already cryptographically verified. A stale
 * JWS can never over-grant: it carries its own expiry.
 */

import {
  APIException,
  Environment,
  JWSRenewalInfoDecodedPayload,
  JWSTransactionDecodedPayload,
  VerificationException,
  VerificationStatus,
} from '@apple/app-store-server-library';
import {logger} from 'firebase-functions';

import {PurchaseRecord} from '../entitlement';
import {appleBundleId} from '../config';
import {
  TransientVerificationError,
  UntrustedPayloadError,
} from '../errors';
import {AppleRenewalFields, appleRecord} from './entitlement';
import {apiClient, toEnvironment, transactionVerifier} from './verifier';

export interface AppleVerification {
  record: PurchaseRecord;
  /** The UUID the client attached at purchase time, if any. */
  appAccountToken: string | null;
  /** True when the App Store Server API confirmed the current state. */
  authoritative: boolean;
  environment: Environment;
}

const NETWORK_ERROR_PATTERN =
  /ECONNRESET|ECONNREFUSED|ETIMEDOUT|EAI_AGAIN|ENOTFOUND|socket hang up|network timeout|fetch failed|request to .* failed/i;

/**
 * Distinguishes a forged signature from Apple's OCSP responder being
 * unreachable. Both surface as VERIFICATION_FAILURE, but one means "reject the
 * user" and the other means "try again in a minute", so the difference decides
 * whether a paying customer keeps access during an Apple outage.
 */
function isTransientVerificationFailure(error: VerificationException): boolean {
  if (error.status !== VerificationStatus.VERIFICATION_FAILURE) {
    return false;
  }
  const cause = error.cause;
  const message = cause instanceof Error ? cause.message : String(cause ?? '');
  return NETWORK_ERROR_PATTERN.test(message);
}

async function decodeTransaction(
  signedTransaction: string,
): Promise<JWSTransactionDecodedPayload> {
  try {
    return await transactionVerifier().verifyAndDecodeTransaction(
      signedTransaction,
    );
  } catch (error) {
    if (error instanceof VerificationException) {
      if (isTransientVerificationFailure(error)) {
        throw new TransientVerificationError(
          'Could not complete App Store signature verification',
          error,
        );
      }
      throw new UntrustedPayloadError(
        `App Store signature verification failed (status ${error.status})`,
        error,
      );
    }
    throw error;
  }
}

async function decodeRenewalInfo(
  signedRenewalInfo: string | undefined,
): Promise<JWSRenewalInfoDecodedPayload | undefined> {
  if (!signedRenewalInfo) {
    return undefined;
  }
  try {
    return await transactionVerifier().verifyAndDecodeRenewalInfo(
      signedRenewalInfo,
    );
  } catch (error) {
    // Renewal info only refines the record (grace period, auto-renew flag);
    // losing it must not fail the whole verification.
    logger.warn('Could not decode renewal info', {error: String(error)});
    return undefined;
  }
}

function renewalFields(
  renewal: JWSRenewalInfoDecodedPayload | undefined,
): AppleRenewalFields | undefined {
  if (!renewal) {
    return undefined;
  }
  const fields: AppleRenewalFields = {};
  if (renewal.gracePeriodExpiresDate !== undefined) {
    fields.gracePeriodExpiresDate = renewal.gracePeriodExpiresDate;
  }
  if (typeof renewal.autoRenewStatus === 'number') {
    fields.autoRenewStatus = renewal.autoRenewStatus;
  }
  if (renewal.isInBillingRetryPeriod !== undefined) {
    fields.isInBillingRetryPeriod = renewal.isInBillingRetryPeriod;
  }
  return fields;
}

/**
 * Checks the fields the signed-data verifier does not check itself.
 *
 * verifyAndDecodeTransaction validates the signature and certificate chain but
 * not the bundle id, so without this a validly-signed transaction from a
 * different Apple app would be accepted.
 */
function assertExpectedApp(payload: JWSTransactionDecodedPayload): Environment {
  const expectedBundleId = appleBundleId();
  if (payload.bundleId !== expectedBundleId) {
    throw new UntrustedPayloadError(
      `Transaction belongs to bundle ${payload.bundleId ?? '<missing>'}, ` +
        `expected ${expectedBundleId}`,
    );
  }
  const environment = toEnvironment(
    typeof payload.environment === 'string' ? payload.environment : undefined,
  );
  if (environment === null) {
    throw new UntrustedPayloadError(
      `Unknown transaction environment ${String(payload.environment)}`,
    );
  }
  // Sandbox must be accepted in production: App Review and TestFlight testers
  // produce sandbox transactions against the shipped build.
  if (
    environment !== Environment.PRODUCTION &&
    environment !== Environment.SANDBOX
  ) {
    throw new UntrustedPayloadError(
      `Refusing ${environment} transaction`,
    );
  }
  return environment;
}

/**
 * Asks the App Store for the authoritative current state of a purchase.
 *
 * Returns null when the lookup is unavailable, leaving the caller with the
 * device-supplied (still cryptographically verified) snapshot.
 */
async function authoritativeState(
  environment: Environment,
  transactionId: string,
  isSubscription: boolean,
): Promise<{
  transaction: JWSTransactionDecodedPayload;
  renewal?: JWSRenewalInfoDecodedPayload | undefined;
  status?: number | undefined;
} | null> {
  try {
    const client = apiClient(environment);

    if (!isSubscription) {
      const response = await client.getTransactionInfo(transactionId);
      if (!response.signedTransactionInfo) {
        return null;
      }
      const transaction = await decodeTransaction(
        response.signedTransactionInfo,
      );
      return {transaction};
    }

    const statuses = await client.getAllSubscriptionStatuses(transactionId);
    for (const group of statuses.data ?? []) {
      for (const item of group.lastTransactions ?? []) {
        if (item.originalTransactionId !== transactionId) {
          continue;
        }
        if (!item.signedTransactionInfo) {
          continue;
        }
        const transaction = await decodeTransaction(item.signedTransactionInfo);
        const renewal = await decodeRenewalInfo(item.signedRenewalInfo);
        return {
          transaction,
          renewal,
          status: typeof item.status === 'number' ? item.status : undefined,
        };
      }
    }
    return null;
  } catch (error) {
    if (error instanceof APIException) {
      logger.warn('App Store Server API lookup failed', {
        httpStatusCode: error.httpStatusCode,
        apiError: error.apiError,
        transactionId,
        environment,
      });
      return null;
    }
    if (error instanceof UntrustedPayloadError) {
      // Apple returned data we cannot verify — that is worth surfacing.
      throw error;
    }
    logger.warn('App Store Server API lookup errored', {
      error: String(error),
      transactionId,
      environment,
    });
    return null;
  }
}

/**
 * Verifies a transaction JWS produced by StoreKit 2 on the device.
 *
 * @param signedTransaction the value of PurchaseVerificationData.serverVerificationData
 */
export async function verifyAppleTransaction(
  signedTransaction: string,
  nowMs: number = Date.now(),
): Promise<AppleVerification> {
  if (!signedTransaction || signedTransaction.split('.').length !== 3) {
    throw new UntrustedPayloadError('Not a JWS');
  }

  const payload = await decodeTransaction(signedTransaction);
  const environment = assertExpectedApp(payload);

  // Builds from the device payload first, so an unsupported product is rejected
  // before spending an App Store Server API call on it.
  const deviceRecord = appleRecord(payload, {nowMs});

  const authoritative = await authoritativeState(
    environment,
    deviceRecord.transactionId,
    deviceRecord.kind === 'subscription',
  );

  if (!authoritative) {
    logger.info('Using device transaction snapshot', {
      productId: deviceRecord.productId,
      transactionId: deviceRecord.transactionId,
      environment,
    });
    return {
      record: deviceRecord,
      appAccountToken: payload.appAccountToken ?? null,
      authoritative: false,
      environment,
    };
  }

  // The authoritative payload must describe the same app; it comes from Apple
  // over an authenticated channel but is verified all the same.
  assertExpectedApp(authoritative.transaction);

  const record = appleRecord(authoritative.transaction, {
    nowMs,
    subscriptionStatus: authoritative.status,
    renewal: renewalFields(authoritative.renewal),
  });

  return {
    record,
    appAccountToken:
      authoritative.transaction.appAccountToken ??
      payload.appAccountToken ??
      null,
    authoritative: true,
    environment,
  };
}

/**
 * Re-reads a stored Apple purchase from the App Store.
 *
 * Used by the periodic client sync so a lapsed or refunded subscription is
 * noticed even if the corresponding notification never arrived.
 */
export async function refreshAppleRecord(
  stored: PurchaseRecord,
  nowMs: number = Date.now(),
): Promise<PurchaseRecord | null> {
  const environment =
    toEnvironment(stored.environment) ?? Environment.PRODUCTION;
  const authoritative = await authoritativeState(
    environment,
    stored.transactionId,
    stored.kind === 'subscription',
  );
  if (!authoritative) {
    return null;
  }
  try {
    assertExpectedApp(authoritative.transaction);
    return appleRecord(authoritative.transaction, {
      nowMs,
      subscriptionStatus: authoritative.status,
      renewal: renewalFields(authoritative.renewal),
    });
  } catch (error) {
    logger.warn('Could not refresh Apple purchase', {
      transactionId: stored.transactionId,
      error: String(error),
    });
    return null;
  }
}

/** Verifies a transaction JWS that arrived inside a server notification. */
export async function verifyNotificationTransaction(
  signedTransaction: string,
  options: {
    nowMs: number;
    status?: number | undefined;
    signedRenewalInfo?: string | undefined;
  },
): Promise<{record: PurchaseRecord; appAccountToken: string | null}> {
  const payload = await decodeTransaction(signedTransaction);
  assertExpectedApp(payload);
  const renewal = await decodeRenewalInfo(options.signedRenewalInfo);
  const record = appleRecord(payload, {
    nowMs: options.nowMs,
    subscriptionStatus: options.status,
    renewal: renewalFields(renewal),
  });
  return {record, appAccountToken: payload.appAccountToken ?? null};
}
