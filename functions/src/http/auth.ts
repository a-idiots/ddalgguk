import {getAuth} from 'firebase-admin/auth';
import type {Request} from 'firebase-functions/v2/https';

import {db} from '../firebase';
import {HttpError} from './respond';

/**
 * Authenticates a request with the caller's Firebase ID token.
 *
 * A plain HTTPS function rather than a callable keeps the client free of the
 * cloud_functions plugin — the app already has `http`, and adding a native
 * plugin to a release branch is not worth it for one endpoint.
 */
export async function requireUid(request: Request): Promise<string> {
  const header = request.get('authorization') ?? '';
  const match = /^Bearer (.+)$/i.exec(header.trim());
  if (!match || !match[1]) {
    throw new HttpError(
      401,
      'unauthenticated',
      'Missing Authorization: Bearer <Firebase ID token>',
    );
  }

  // Ensure the Admin SDK is initialised before getAuth() is called.
  db();

  try {
    // checkRevoked catches tokens belonging to a disabled or deleted account.
    const decoded = await getAuth().verifyIdToken(match[1], true);
    return decoded.uid;
  } catch (error) {
    throw new HttpError(401, 'unauthenticated', `Invalid ID token: ${String(
      error instanceof Error ? error.message : error,
    )}`);
  }
}
