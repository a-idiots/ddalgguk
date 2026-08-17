/**
 * Firestore persistence for entitlements.
 *
 * Layout:
 *   entitlements/{uid}                  client-readable, server-written
 *   purchaseIndex/{source_transaction}  server only — maps a purchase to a uid
 *   purchaseSecrets/{uid}               server only — Google purchase tokens
 *
 * Purchase tokens live outside the client-readable document on purpose: they
 * are bearer credentials for the Play Developer API.
 */

import {FieldValue} from 'firebase-admin/firestore';
import {logger} from 'firebase-functions';

import {db} from './firebase';
import {
  EntitlementDoc,
  EntitlementSummary,
  ENTITLEMENT_SCHEMA_VERSION,
  PurchaseRecord,
  PurchaseSource,
  emptyDoc,
  mergeRecord,
  recordKey,
  summarize,
} from './entitlement';

const ENTITLEMENTS = 'entitlements';
const PURCHASE_INDEX = 'purchaseIndex';
const PURCHASE_SECRETS = 'purchaseSecrets';
const ACCOUNT_TOKENS = 'purchaseAccountTokens';

interface StoredEntitlement extends EntitlementDoc {
  updatedAt?: unknown;
}

function readDoc(data: unknown): EntitlementDoc {
  if (!data || typeof data !== 'object') {
    return emptyDoc();
  }
  const raw = data as Partial<StoredEntitlement>;
  return {
    schemaVersion: raw.schemaVersion ?? ENTITLEMENT_SCHEMA_VERSION,
    isPro: raw.isPro ?? false,
    activeProductId: raw.activeProductId ?? null,
    activeKind: raw.activeKind ?? null,
    activeSource: raw.activeSource ?? null,
    expiresAtMs: raw.expiresAtMs ?? null,
    records: raw.records ?? {},
  };
}

function toWrite(doc: EntitlementDoc): Record<string, unknown> {
  return {
    schemaVersion: ENTITLEMENT_SCHEMA_VERSION,
    isPro: doc.isPro,
    activeProductId: doc.activeProductId,
    activeKind: doc.activeKind,
    activeSource: doc.activeSource,
    expiresAtMs: doc.expiresAtMs,
    records: doc.records,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function applySummary(
  records: Record<string, PurchaseRecord>,
  nowMs: number,
): EntitlementDoc {
  return {
    schemaVersion: ENTITLEMENT_SCHEMA_VERSION,
    records,
    ...summarize(records, nowMs),
  };
}

export async function readEntitlement(uid: string): Promise<EntitlementDoc> {
  const snapshot = await db().collection(ENTITLEMENTS).doc(uid).get();
  return readDoc(snapshot.data());
}

/**
 * Stores a verified purchase and returns the resulting entitlement.
 *
 * If the purchase is already indexed against a different account — the same
 * Apple ID restoring onto a second 딸꾹 login — the entitlement is transferred,
 * so one purchase never keeps two accounts alive at once.
 */
export async function applyRecord(
  uid: string,
  record: PurchaseRecord,
  options: {purchaseToken?: string | null; nowMs?: number} = {},
): Promise<EntitlementSummary> {
  const nowMs = options.nowMs ?? Date.now();
  const key = recordKey(record.source, record.transactionId);
  const firestore = db();
  const ownRef = firestore.collection(ENTITLEMENTS).doc(uid);
  const indexRef = firestore.collection(PURCHASE_INDEX).doc(key);

  const summary = await firestore.runTransaction(async (tx) => {
    const [ownSnap, indexSnap] = await Promise.all([
      tx.get(ownRef),
      tx.get(indexRef),
    ]);

    const previousUid = indexSnap.exists
      ? (indexSnap.data()?.uid as string | undefined)
      : undefined;

    // Read the losing account before any write — Firestore forbids reads after
    // writes inside a transaction.
    let previousDoc: EntitlementDoc | null = null;
    if (previousUid && previousUid !== uid) {
      const previousSnap = await tx.get(
        firestore.collection(ENTITLEMENTS).doc(previousUid),
      );
      previousDoc = readDoc(previousSnap.data());
    }

    if (previousUid && previousUid !== uid && previousDoc) {
      const {[key]: _removed, ...remaining} = previousDoc.records;
      const rebuilt = applySummary(remaining, nowMs);
      tx.set(
        firestore.collection(ENTITLEMENTS).doc(previousUid),
        toWrite(rebuilt),
      );
      logger.info('Transferred purchase between accounts', {
        recordKey: key,
        fromUid: previousUid,
        toUid: uid,
      });
    }

    const own = readDoc(ownSnap.data());
    const merged = mergeRecord(own.records, record);
    const next = applySummary(merged, nowMs);
    tx.set(ownRef, toWrite(next));
    tx.set(indexRef, {
      uid,
      source: record.source,
      productId: record.productId,
      transactionId: record.transactionId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      isPro: next.isPro,
      activeProductId: next.activeProductId,
      activeKind: next.activeKind,
      activeSource: next.activeSource,
      expiresAtMs: next.expiresAtMs,
    } satisfies EntitlementSummary;
  });

  if (record.source === 'play_store' && options.purchaseToken) {
    await firestore
      .collection(PURCHASE_SECRETS)
      .doc(uid)
      .set({tokens: {[key]: options.purchaseToken}}, {merge: true});
  }

  return summary;
}

/**
 * Recomputes the summary from stored records against the current time.
 *
 * Needed because `isPro` is a materialised value: without a store notification
 * a lapsed subscription would otherwise stay `true` in the document.
 */
export async function refreshSummary(
  uid: string,
  nowMs: number = Date.now(),
): Promise<EntitlementSummary> {
  const firestore = db();
  const ref = firestore.collection(ENTITLEMENTS).doc(uid);
  return firestore.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      // Do not create an empty document for a user who has never had a
      // purchase verified. The *absence* of the document is what lets the app
      // tell "never verified" apart from "verified, not entitled" — writing a
      // false one here would downgrade a paying customer whose restore has not
      // finished yet.
      return summarize({}, nowMs);
    }
    const doc = readDoc(snap.data());
    const next = applySummary(doc.records, nowMs);
    if (
      next.isPro === doc.isPro &&
      next.expiresAtMs === doc.expiresAtMs &&
      next.activeProductId === doc.activeProductId
    ) {
      // Nothing changed — skip the write so the document's updatedAt stays
      // meaningful.
      return next;
    }
    tx.set(ref, toWrite(next));
    return next;
  });
}

/** Marks a stored purchase as revoked (refund, family removal, chargeback). */
export async function revokeRecord(
  source: PurchaseSource,
  transactionId: string,
  options: {revokedAtMs: number; reason: string; nowMs?: number},
): Promise<{uid: string; summary: EntitlementSummary} | null> {
  const nowMs = options.nowMs ?? Date.now();
  const key = recordKey(source, transactionId);
  const firestore = db();
  const indexRef = firestore.collection(PURCHASE_INDEX).doc(key);

  return firestore.runTransaction(async (tx) => {
    const indexSnap = await tx.get(indexRef);
    const uid = indexSnap.exists
      ? (indexSnap.data()?.uid as string | undefined)
      : undefined;
    if (!uid) {
      return null;
    }
    const ref = firestore.collection(ENTITLEMENTS).doc(uid);
    const snap = await tx.get(ref);
    const doc = readDoc(snap.data());
    const existing = doc.records[key];
    if (!existing) {
      return null;
    }
    const records: Record<string, PurchaseRecord> = {
      ...doc.records,
      [key]: {
        ...existing,
        revokedAtMs: options.revokedAtMs,
        revocationReason: options.reason,
        lastVerifiedAtMs: nowMs,
      },
    };
    const next = applySummary(records, nowMs);
    tx.set(ref, toWrite(next));
    return {
      uid,
      summary: {
        isPro: next.isPro,
        activeProductId: next.activeProductId,
        activeKind: next.activeKind,
        activeSource: next.activeSource,
        expiresAtMs: next.expiresAtMs,
      },
    };
  });
}

/** Which account a purchase belongs to, if we have ever verified it. */
export async function resolveUid(
  source: PurchaseSource,
  transactionId: string,
): Promise<string | null> {
  const snap = await db()
    .collection(PURCHASE_INDEX)
    .doc(recordKey(source, transactionId))
    .get();
  if (!snap.exists) {
    return null;
  }
  return (snap.data()?.uid as string | undefined) ?? null;
}

/**
 * Remembers which account an appAccountToken belongs to.
 *
 * App Store Server Notifications carry the token but not our uid, and the token
 * is a one-way hash of the uid, so the mapping has to be stored when the
 * purchase is first verified. It is what lets a renewal or refund notification
 * find its user even if the client never got to verify that transaction.
 */
export async function linkAccountToken(
  token: string,
  uid: string,
): Promise<void> {
  await db()
    .collection(ACCOUNT_TOKENS)
    .doc(token)
    .set({uid, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
}

export async function uidForAccountToken(
  token: string,
): Promise<string | null> {
  const snap = await db().collection(ACCOUNT_TOKENS).doc(token).get();
  if (!snap.exists) {
    return null;
  }
  return (snap.data()?.uid as string | undefined) ?? null;
}

/** Google purchase tokens previously stored for a user, keyed by record key. */
export async function readPurchaseTokens(
  uid: string,
): Promise<Record<string, string>> {
  const snap = await db().collection(PURCHASE_SECRETS).doc(uid).get();
  if (!snap.exists) {
    return {};
  }
  const tokens = snap.data()?.tokens;
  if (!tokens || typeof tokens !== 'object') {
    return {};
  }
  return tokens as Record<string, string>;
}
