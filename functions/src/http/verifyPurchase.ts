/**
 * POST /verifyPurchase
 *
 * Body: {platform: 'ios' | 'android', productId, verificationData}
 *   ios     → verificationData is the StoreKit 2 JWS
 *             (PurchaseVerificationData.serverVerificationData)
 *   android → verificationData is the Play purchaseToken
 *
 * Returns the resulting entitlement. The client treats 4xx as "give up on this
 * transaction" and 5xx as "keep it queued and retry".
 */

import type {Response} from 'express';
import {logger} from 'firebase-functions';
import type {Request} from 'firebase-functions/v2/https';

import {verifyAppleTransaction} from '../apple/verify';
import {applyRecord, linkAccountToken} from '../entitlementStore';
import {verifyPlayPurchase} from '../google/verify';
import {requireUid} from './auth';
import {
  HttpError,
  bodyObject,
  handleErrors,
  requirePost,
  requireString,
  sendJson,
} from './respond';

/** A StoreKit 2 JWS with its certificate chain runs to a few kilobytes. */
const MAX_VERIFICATION_DATA = 32768;

async function handler(request: Request, response: Response): Promise<void> {
  requirePost(request);
  const uid = await requireUid(request);
  const body = bodyObject(request);
  const platform = requireString(body, 'platform', 16);
  const productId = requireString(body, 'productId', 128);
  const verificationData = requireString(
    body,
    'verificationData',
    MAX_VERIFICATION_DATA,
  );

  const nowMs = Date.now();

  if (platform === 'ios') {
    const verification = await verifyAppleTransaction(verificationData, nowMs);
    const {record, appAccountToken, authoritative} = verification;

    if (record.productId !== productId) {
      // Legitimate for a subscription that was upgraded or renamed within its
      // group: the latest transaction carries the new product id.
      logger.info('Verified product differs from the requested one', {
        uid,
        requested: productId,
        verified: record.productId,
      });
    }

    // Only the token embedded in the *verified* transaction is trusted. A
    // client-asserted token would let a caller claim someone else's purchase
    // and receive their renewal notifications.
    if (appAccountToken) {
      await linkAccountToken(appAccountToken, uid);
    }

    const summary = await applyRecord(uid, record, {nowMs});
    logger.info('Purchase verified', {
      uid,
      platform,
      productId: record.productId,
      transactionId: record.transactionId,
      environment: record.environment,
      authoritative,
      isPro: summary.isPro,
    });
    sendJson(response, 200, {...summary, authoritative});
    return;
  }

  if (platform === 'android') {
    const verification = await verifyPlayPurchase(
      productId,
      verificationData,
      nowMs,
    );
    const summary = await applyRecord(uid, verification.record, {
      purchaseToken: verificationData,
      nowMs,
    });
    logger.info('Purchase verified', {
      uid,
      platform,
      productId: verification.record.productId,
      transactionId: verification.record.transactionId,
      isPro: summary.isPro,
    });
    sendJson(response, 200, {...summary, authoritative: true});
    return;
  }

  throw new HttpError(
    400,
    'invalid_request',
    `Unsupported platform ${platform}`,
  );
}

export const verifyPurchaseHandler = handleErrors('verifyPurchase', handler);
