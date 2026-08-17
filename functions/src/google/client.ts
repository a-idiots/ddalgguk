/**
 * Minimal Play Developer API client.
 *
 * Uses google-auth-library directly rather than the `googleapis` package: only
 * two endpoints are needed and googleapis adds tens of megabytes to the deploy,
 * which shows up as cold-start latency on a purchase flow.
 *
 * Credentials come from the function's own service account (ADC). Grant it
 * access in Play Console → Users and permissions → invite the service account
 * email with "View financial data, orders, and cancellation survey responses".
 * For local runs, point PLAY_SERVICE_ACCOUNT_JSON at a service account key.
 */

import {GoogleAuth} from 'google-auth-library';

const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const BASE_URL = 'https://androidpublisher.googleapis.com/androidpublisher/v3';

/** Play returned a definitive "this purchase is not valid" answer. */
export class PlayNotFoundError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PlayNotFoundError';
  }
}

/** Play could not be reached or refused the request; retry later. */
export class PlayUnavailableError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = 'PlayUnavailableError';
  }
}

let auth: GoogleAuth | null = null;

function googleAuth(): GoogleAuth {
  if (auth) {
    return auth;
  }
  const inlineKey = process.env.PLAY_SERVICE_ACCOUNT_JSON;
  if (inlineKey) {
    auth = new GoogleAuth({
      scopes: [SCOPE],
      credentials: JSON.parse(inlineKey),
    });
  } else {
    auth = new GoogleAuth({scopes: [SCOPE]});
  }
  return auth;
}

async function playGet<T>(path: string): Promise<T> {
  let token: string | null | undefined;
  try {
    const client = await googleAuth().getClient();
    const accessToken = await client.getAccessToken();
    token = accessToken.token;
  } catch (error) {
    throw new PlayUnavailableError(
      `Could not obtain Play API credentials: ${String(error)}`,
    );
  }
  if (!token) {
    throw new PlayUnavailableError('Play API credentials returned no token');
  }

  let response: Response;
  try {
    response = await fetch(`${BASE_URL}${path}`, {
      headers: {Authorization: `Bearer ${token}`},
    });
  } catch (error) {
    throw new PlayUnavailableError(`Play API request failed: ${String(error)}`);
  }

  if (response.status === 404 || response.status === 410) {
    throw new PlayNotFoundError(`Play API returned ${response.status}`);
  }
  if (!response.ok) {
    throw new PlayUnavailableError(
      `Play API returned ${response.status}`,
      response.status,
    );
  }
  return (await response.json()) as T;
}

// ── Response shapes (only the fields used here) ────────────────────────────

export interface PlayProductPurchase {
  /** 0 = purchased, 1 = canceled/refunded, 2 = pending. */
  purchaseState?: number;
  purchaseTimeMillis?: string;
  orderId?: string;
  acknowledgementState?: number;
  obfuscatedExternalAccountId?: string;
  regionCode?: string;
}

export interface PlaySubscriptionLineItem {
  productId?: string;
  expiryTime?: string;
  autoRenewingPlan?: {autoRenewEnabled?: boolean};
}

export interface PlaySubscriptionPurchase {
  subscriptionState?: string;
  latestOrderId?: string;
  linkedPurchaseToken?: string;
  startTime?: string;
  acknowledgementState?: string;
  testPurchase?: object;
  lineItems?: PlaySubscriptionLineItem[];
  externalAccountIdentifiers?: {obfuscatedExternalAccountId?: string};
}

export function getProductPurchase(
  packageName: string,
  productId: string,
  purchaseToken: string,
): Promise<PlayProductPurchase> {
  return playGet<PlayProductPurchase>(
    `/applications/${encodeURIComponent(packageName)}` +
      `/purchases/products/${encodeURIComponent(productId)}` +
      `/tokens/${encodeURIComponent(purchaseToken)}`,
  );
}

export function getSubscriptionPurchase(
  packageName: string,
  purchaseToken: string,
): Promise<PlaySubscriptionPurchase> {
  return playGet<PlaySubscriptionPurchase>(
    `/applications/${encodeURIComponent(packageName)}` +
      `/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
  );
}
