import type {Response} from 'express';
import {logger} from 'firebase-functions';
import type {Request} from 'firebase-functions/v2/https';

import {ConfigError} from '../config';
import {
  MalformedTransactionError,
  TransientVerificationError,
  UnsupportedProductError,
  UntrustedPayloadError,
} from '../errors';

/** An error carrying the HTTP status the client should see. */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export function sendJson(
  response: Response,
  status: number,
  body: Record<string, unknown>,
): void {
  response.status(status).set('Cache-Control', 'no-store').json(body);
}

/**
 * Maps an error onto a status code the client can act on.
 *
 * The client's behaviour depends entirely on this split: 4xx means stop and
 * forget the transaction, 5xx means keep it queued and retry. Getting it wrong
 * either loses a real purchase or retries a doomed one forever.
 */
export function toHttpError(error: unknown): HttpError {
  if (error instanceof HttpError) {
    return error;
  }
  if (error instanceof UntrustedPayloadError) {
    return new HttpError(403, 'untrusted_payload', error.message);
  }
  if (error instanceof UnsupportedProductError) {
    return new HttpError(409, 'unsupported_product', error.message);
  }
  if (error instanceof MalformedTransactionError) {
    return new HttpError(422, 'malformed_transaction', error.message);
  }
  if (error instanceof TransientVerificationError) {
    return new HttpError(503, 'store_unavailable', error.message);
  }
  if (error instanceof ConfigError) {
    // A deployment problem, not the client's fault — 503 so the app retries
    // once the configuration is fixed instead of discarding the purchase.
    return new HttpError(503, 'server_misconfigured', error.message);
  }
  return new HttpError(500, 'internal', 'Unexpected server error');
}

/** Wraps a handler so every thrown error becomes a well-formed JSON reply. */
export function handleErrors(
  name: string,
  handler: (request: Request, response: Response) => Promise<void>,
): (request: Request, response: Response) => Promise<void> {
  return async (request, response) => {
    try {
      await handler(request, response);
    } catch (error) {
      const httpError = toHttpError(error);
      const logPayload = {
        function: name,
        code: httpError.code,
        status: httpError.status,
        message: httpError.message,
        cause: error instanceof Error ? error.stack : String(error),
      };
      if (httpError.status >= 500) {
        logger.error('Request failed', logPayload);
      } else {
        logger.warn('Request rejected', logPayload);
      }
      sendJson(response, httpError.status, {
        error: httpError.code,
        message: httpError.message,
      });
    }
  };
}

export function requirePost(request: Request): void {
  if (request.method !== 'POST') {
    throw new HttpError(405, 'method_not_allowed', 'Use POST');
  }
}

export function bodyObject(request: Request): Record<string, unknown> {
  const body = request.body;
  if (body && typeof body === 'object' && !Array.isArray(body)) {
    return body as Record<string, unknown>;
  }
  return {};
}

export function requireString(
  body: Record<string, unknown>,
  field: string,
  maxLength = 8192,
): string {
  const value = body[field];
  if (typeof value !== 'string' || value.length === 0) {
    throw new HttpError(400, 'invalid_request', `${field} is required`);
  }
  if (value.length > maxLength) {
    throw new HttpError(400, 'invalid_request', `${field} is too long`);
  }
  return value;
}

export function optionalString(
  body: Record<string, unknown>,
  field: string,
  maxLength = 256,
): string | null {
  const value = body[field];
  if (value === undefined || value === null || value === '') {
    return null;
  }
  if (typeof value !== 'string' || value.length > maxLength) {
    throw new HttpError(400, 'invalid_request', `${field} is invalid`);
  }
  return value;
}
