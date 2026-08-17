/**
 * App Store Server Notifications V2.
 *
 * This is what makes revocation real: without it a refunded or lapsed
 * subscription would only be noticed the next time the app happened to ask.
 *
 * Register the endpoint URL in App Store Connect →  App Information →
 * App Store Server Notifications (both production and sandbox URLs).
 */

import {
  Environment,
  NotificationTypeV2,
  ResponseBodyV2DecodedPayload,
  VerificationException,
} from '@apple/app-store-server-library';
import {logger} from 'firebase-functions';

import {
  applyRecord,
  linkAccountToken,
  resolveUid,
  uidForAccountToken,
} from '../entitlementStore';
import {UnsupportedProductError, UntrustedPayloadError} from '../errors';
import {verifyNotificationTransaction} from './verify';
import {notificationVerifiers} from './verifier';

/** Notification types that change what a user is entitled to. */
const ENTITLEMENT_CHANGING: ReadonlySet<string> = new Set([
  NotificationTypeV2.SUBSCRIBED,
  NotificationTypeV2.DID_RENEW,
  NotificationTypeV2.DID_CHANGE_RENEWAL_PREF,
  NotificationTypeV2.DID_CHANGE_RENEWAL_STATUS,
  NotificationTypeV2.DID_FAIL_TO_RENEW,
  NotificationTypeV2.EXPIRED,
  NotificationTypeV2.GRACE_PERIOD_EXPIRED,
  NotificationTypeV2.OFFER_REDEEMED,
  NotificationTypeV2.REFUND,
  NotificationTypeV2.REFUND_REVERSED,
  NotificationTypeV2.REVOKE,
  NotificationTypeV2.RENEWAL_EXTENDED,
  NotificationTypeV2.ONE_TIME_CHARGE,
]);

export type NotificationOutcome =
  | {kind: 'applied'; uid: string; isPro: boolean}
  | {kind: 'ignored'; reason: string};

/**
 * Verifies a signed notification payload against both environments.
 *
 * A production app receives sandbox notifications too — App Review and
 * TestFlight run against the sandbox — and the verifier rejects payloads whose
 * environment does not match its own, so both are tried.
 */
export async function decodeNotification(
  signedPayload: string,
): Promise<ResponseBodyV2DecodedPayload> {
  const verifiers = notificationVerifiers();
  let lastError: unknown = null;
  for (const verifier of verifiers) {
    try {
      return await verifier.verifyAndDecodeNotification(signedPayload);
    } catch (error) {
      lastError = error;
      if (!(error instanceof VerificationException)) {
        throw error;
      }
    }
  }
  throw new UntrustedPayloadError(
    'Notification signature verification failed',
    lastError,
  );
}

/** Applies a decoded notification to the affected user's entitlement. */
export async function handleNotification(
  payload: ResponseBodyV2DecodedPayload,
  nowMs: number = Date.now(),
): Promise<NotificationOutcome> {
  const notificationType = String(payload.notificationType ?? '');
  const context = {
    notificationType,
    subtype: payload.subtype ?? null,
    notificationUUID: payload.notificationUUID ?? null,
    environment: payload.data?.environment ?? null,
  };

  if (notificationType === NotificationTypeV2.TEST) {
    logger.info('App Store test notification received', context);
    return {kind: 'ignored', reason: 'test'};
  }

  const signedTransactionInfo = payload.data?.signedTransactionInfo;
  if (!signedTransactionInfo) {
    logger.info('Notification carries no transaction', context);
    return {kind: 'ignored', reason: 'no_transaction'};
  }

  if (!ENTITLEMENT_CHANGING.has(notificationType)) {
    logger.info('Notification does not affect entitlements', context);
    return {kind: 'ignored', reason: 'not_entitlement_changing'};
  }

  let verified;
  try {
    verified = await verifyNotificationTransaction(signedTransactionInfo, {
      nowMs,
      status:
        typeof payload.data?.status === 'number'
          ? payload.data.status
          : undefined,
      signedRenewalInfo: payload.data?.signedRenewalInfo,
    });
  } catch (error) {
    if (error instanceof UnsupportedProductError) {
      // Another (non-PRO) product in the same app — nothing to do.
      logger.info('Notification for unrelated product', {
        ...context,
        productId: error.productId,
      });
      return {kind: 'ignored', reason: 'unsupported_product'};
    }
    throw error;
  }

  const {record, appAccountToken} = verified;

  // Prefer the token the app attached at purchase time: it identifies the user
  // even for a transaction this server has never seen before.
  let uid: string | null = null;
  if (appAccountToken) {
    uid = await uidForAccountToken(appAccountToken);
  }
  if (!uid) {
    uid = await resolveUid('app_store', record.transactionId);
  }

  if (!uid) {
    // Nothing is lost: the next time the app verifies or syncs, the purchase is
    // attached to the right account with current data.
    logger.warn('Notification could not be matched to a user', {
      ...context,
      transactionId: record.transactionId,
      hasAppAccountToken: appAccountToken !== null,
    });
    return {kind: 'ignored', reason: 'unknown_user'};
  }

  if (appAccountToken) {
    await linkAccountToken(appAccountToken, uid);
  }

  const summary = await applyRecord(uid, record, {nowMs});
  logger.info('Entitlement updated from notification', {
    ...context,
    uid,
    productId: record.productId,
    isPro: summary.isPro,
    expiresAtMs: summary.expiresAtMs,
    revoked: record.revokedAtMs !== null,
  });
  return {kind: 'applied', uid, isPro: summary.isPro};
}

/** Environments Apple may send notifications from. */
export const NOTIFICATION_ENVIRONMENTS = [
  Environment.PRODUCTION,
  Environment.SANDBOX,
];
