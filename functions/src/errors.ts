/**
 * The error taxonomy shared by both stores.
 *
 * The distinction that matters is between "this payload is not trustworthy"
 * (reject the caller) and "we could not check right now" (tell the caller to
 * retry). Collapsing the two would either hand out PRO on a forged payload or
 * revoke PRO from a paying customer during a store outage.
 */

/** The payload is invalid, forged, or for a different app. Do not grant. */
export class UntrustedPayloadError extends Error {
  constructor(message: string, override readonly cause?: unknown) {
    super(message);
    this.name = 'UntrustedPayloadError';
  }
}

/** Verification could not be completed; the client should try again later. */
export class TransientVerificationError extends Error {
  constructor(message: string, override readonly cause?: unknown) {
    super(message);
    this.name = 'TransientVerificationError';
  }
}

/** A valid purchase, but not of a product that grants PRO. */
export class UnsupportedProductError extends Error {
  constructor(readonly productId: string | undefined) {
    super(`Product ${productId ?? '<missing>'} does not grant PRO`);
    this.name = 'UnsupportedProductError';
  }
}

/** The purchase data is internally inconsistent and cannot be trusted. */
export class MalformedTransactionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MalformedTransactionError';
  }
}
