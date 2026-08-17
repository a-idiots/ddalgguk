import {getApps, initializeApp} from 'firebase-admin/app';
import {getFirestore, Firestore} from 'firebase-admin/firestore';

let cached: Firestore | null = null;

/** Lazily initialised Admin SDK Firestore handle. */
export function db(): Firestore {
  if (cached) {
    return cached;
  }
  if (getApps().length === 0) {
    initializeApp();
  }
  cached = getFirestore();
  return cached;
}
