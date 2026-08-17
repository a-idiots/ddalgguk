/**
 * POST /syncEntitlement
 *
 * Re-reads every purchase the caller holds from the store that issued it and
 * returns the refreshed entitlement. Body: {force?: boolean}.
 *
 * This is the safety net under the notification webhook: a subscription that
 * lapses while notifications are misconfigured, dropped, or never registered
 * still stops granting PRO the next time the app checks in.
 */

import type {Response} from 'express';
import {logger} from 'firebase-functions';
import type {Request} from 'firebase-functions/v2/https';

import {refreshAppleRecord} from '../apple/verify';
import {EntitlementSummary, PurchaseRecord, recordKey} from '../entitlement';
import {
  applyRecord,
  readEntitlement,
  readPurchaseTokens,
  refreshSummary,
} from '../entitlementStore';
import {refreshPlayRecord} from '../google/verify';
import {requireUid} from './auth';
import {bodyObject, handleErrors, requirePost, sendJson} from './respond';

/**
 * How long a store lookup stays good enough.
 *
 * The app calls this on every launch and resume; without a window that would be
 * an App Store round-trip per resume for every paying user. Expiry is still
 * recomputed on every call — only the outbound lookups are throttled.
 */
const FRESH_WINDOW_MS = 15 * 60 * 1000;

async function refreshRecord(
  record: PurchaseRecord,
  tokens: Record<string, string>,
  nowMs: number,
): Promise<PurchaseRecord | null> {
  if (record.source === 'app_store') {
    return refreshAppleRecord(record, nowMs);
  }
  const key = recordKey(record.source, record.transactionId);
  return refreshPlayRecord(record, tokens[key], nowMs);
}

export async function syncUserEntitlement(
  uid: string,
  options: {force?: boolean; nowMs?: number} = {},
): Promise<EntitlementSummary & {refreshed: boolean}> {
  const nowMs = options.nowMs ?? Date.now();
  const doc = await readEntitlement(uid);
  const records = Object.values(doc.records);

  if (records.length === 0) {
    const summary = await refreshSummary(uid, nowMs);
    return {...summary, refreshed: false};
  }

  const stale =
    options.force === true ||
    records.some((record) => nowMs - record.lastVerifiedAtMs > FRESH_WINDOW_MS);

  if (!stale) {
    // Still recompute: `isPro` is materialised, so it goes stale on its own as
    // soon as an expiry passes.
    const summary = await refreshSummary(uid, nowMs);
    return {...summary, refreshed: false};
  }

  const needsTokens = records.some(
    (record) => record.source === 'play_store',
  );
  const tokens = needsTokens ? await readPurchaseTokens(uid) : {};

  let refreshedAny = false;
  for (const record of records) {
    const refreshed = await refreshRecord(record, tokens, nowMs);
    if (!refreshed) {
      continue;
    }
    refreshedAny = true;
    await applyRecord(uid, refreshed, {nowMs});
  }

  const summary = await refreshSummary(uid, nowMs);
  return {...summary, refreshed: refreshedAny};
}

async function handler(request: Request, response: Response): Promise<void> {
  requirePost(request);
  const uid = await requireUid(request);
  const force = bodyObject(request).force === true;

  const result = await syncUserEntitlement(uid, {force});
  logger.debug('Entitlement synced', {uid, ...result});
  sendJson(response, 200, {...result});
}

export const syncEntitlementHandler = handleErrors(
  'syncEntitlement',
  handler,
);
