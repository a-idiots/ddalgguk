import {defineSecret, defineString} from 'firebase-functions/params';

/**
 * Deployment region.
 *
 * Must stay in sync with `kFunctionsRegion` in the Flutter client
 * (lib/core/services/entitlement_service.dart) — the client builds the endpoint
 * URL from it.
 */
export const REGION = 'asia-northeast3';

// ── Secrets (Secret Manager) ───────────────────────────────────────────────
// Set with:
//   firebase functions:secrets:set APP_STORE_KEY_ID
//   firebase functions:secrets:set APP_STORE_ISSUER_ID
//   firebase functions:secrets:set APP_STORE_PRIVATE_KEY   # paste the whole .p8
export const APP_STORE_KEY_ID = defineSecret('APP_STORE_KEY_ID');
export const APP_STORE_ISSUER_ID = defineSecret('APP_STORE_ISSUER_ID');
export const APP_STORE_PRIVATE_KEY = defineSecret('APP_STORE_PRIVATE_KEY');

/** Every function that talks to the App Store needs all three. */
export const APPLE_SECRETS = [
  APP_STORE_KEY_ID,
  APP_STORE_ISSUER_ID,
  APP_STORE_PRIVATE_KEY,
];

// ── Plain params (functions/.env.<project-id>) ─────────────────────────────
export const APPLE_BUNDLE_ID = defineString('APPLE_BUNDLE_ID', {
  default: 'com.aidiot.ddalgguk',
});

/**
 * The app's numeric Apple ID (App Store Connect → App Information → Apple ID).
 * Required: the App Store signed-data verifier refuses to run against the
 * production environment without it.
 */
export const APPLE_APP_APPLE_ID = defineString('APPLE_APP_APPLE_ID', {
  default: '',
});

export const ANDROID_PACKAGE_NAME = defineString('ANDROID_PACKAGE_NAME', {
  default: 'com.aidiot.ddalgguk',
});

/** Thrown when a deployment is missing configuration it cannot work without. */
export class ConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigError';
  }
}

export function appleBundleId(): string {
  const value = APPLE_BUNDLE_ID.value().trim();
  if (!value) {
    throw new ConfigError('APPLE_BUNDLE_ID is empty.');
  }
  return value;
}

export function appleAppAppleId(): number {
  const raw = APPLE_APP_APPLE_ID.value().trim();
  const parsed = Number(raw);
  if (!raw || !Number.isSafeInteger(parsed) || parsed <= 0) {
    throw new ConfigError(
      'APPLE_APP_APPLE_ID is not configured. Set it to the app\'s numeric ' +
        'Apple ID from App Store Connect → App Information → Apple ID, in ' +
        'functions/.env.<project-id>.',
    );
  }
  return parsed;
}

export function androidPackageName(): string {
  const value = ANDROID_PACKAGE_NAME.value().trim();
  if (!value) {
    throw new ConfigError('ANDROID_PACKAGE_NAME is empty.');
  }
  return value;
}
