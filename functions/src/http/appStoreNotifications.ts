/**
 * POST /appStoreNotifications — App Store Server Notifications V2 endpoint.
 *
 * Register the deployed URL in App Store Connect for both the production and
 * the sandbox environment.
 *
 * Status codes matter here: Apple retries on 5xx (for up to three days) and
 * gives up on 2xx. So anything we could not process *yet* must be a 5xx, and
 * anything we deliberately ignore must be a 2xx.
 */

import type {Response} from 'express';
import {logger} from 'firebase-functions';
import type {Request} from 'firebase-functions/v2/https';

import {decodeNotification, handleNotification} from '../apple/notifications';
import {UntrustedPayloadError} from '../errors';
import {handleErrors, requirePost, sendJson} from './respond';

async function handler(request: Request, response: Response): Promise<void> {
  requirePost(request);

  const body = request.body;
  const signedPayload =
    body && typeof body === 'object'
      ? (body as Record<string, unknown>).signedPayload
      : undefined;

  if (typeof signedPayload !== 'string' || signedPayload.length === 0) {
    // Malformed and never going to become valid — 400 stops the retries.
    sendJson(response, 400, {
      error: 'invalid_request',
      message: 'signedPayload is required',
    });
    return;
  }

  let payload;
  try {
    payload = await decodeNotification(signedPayload);
  } catch (error) {
    if (error instanceof UntrustedPayloadError) {
      logger.warn('Rejected an unverifiable App Store notification', {
        message: error.message,
      });
      sendJson(response, 401, {error: 'untrusted_payload'});
      return;
    }
    throw error;
  }

  const outcome = await handleNotification(payload);
  sendJson(response, 200, {status: outcome.kind});
}

export const appStoreNotificationsHandler = handleErrors(
  'appStoreNotifications',
  handler,
);
