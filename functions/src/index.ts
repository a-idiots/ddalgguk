/**
 * 딸꾹 purchase verification backend.
 *
 * Three endpoints:
 *   verifyPurchase          the app submits a transaction after buying/restoring
 *   syncEntitlement         the app asks for the current state on launch/resume
 *   appStoreNotifications   Apple pushes renewals, expirations and refunds
 *
 * The client never decides whether it is PRO — it reads entitlements/{uid},
 * which only this backend writes.
 */

import {setGlobalOptions} from 'firebase-functions';
import {onRequest} from 'firebase-functions/v2/https';

import {APPLE_SECRETS, REGION} from './config';
import {appStoreNotificationsHandler} from './http/appStoreNotifications';
import {syncEntitlementHandler} from './http/syncEntitlement';
import {verifyPurchaseHandler} from './http/verifyPurchase';

setGlobalOptions({
  region: REGION,
  // Purchase traffic is low; the cap is a spend guard, not a throughput target.
  maxInstances: 10,
});

/**
 * 512MiB rather than the default: verifying a JWS certificate chain pulls in
 * jsrsasign, and the extra headroom shortens cold starts on the one request the
 * user is actually waiting for.
 */
const VERIFICATION_OPTIONS = {
  secrets: APPLE_SECRETS,
  memory: '512MiB' as const,
  timeoutSeconds: 60,
};

export const verifyPurchase = onRequest(
  VERIFICATION_OPTIONS,
  verifyPurchaseHandler,
);

export const syncEntitlement = onRequest(
  VERIFICATION_OPTIONS,
  syncEntitlementHandler,
);

export const appStoreNotifications = onRequest(
  VERIFICATION_OPTIONS,
  appStoreNotificationsHandler,
);
