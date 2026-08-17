/**
 * Lazily constructed App Store verifiers and API clients.
 *
 * Instances are cached at module scope so a warm function instance reuses the
 * verified-certificate cache instead of re-running OCSP on every call.
 */

import {existsSync, readFileSync} from 'fs';
import {join} from 'path';

import {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier,
} from '@apple/app-store-server-library';

import {
  APP_STORE_ISSUER_ID,
  APP_STORE_KEY_ID,
  APP_STORE_PRIVATE_KEY,
  ConfigError,
  appleAppAppleId,
  appleBundleId,
} from '../config';

const ROOT_CERT_FILES = [
  'AppleRootCA-G3.cer',
  'AppleRootCA-G2.cer',
  'AppleIncRootCertificate.cer',
];

/**
 * Revocation checking talks to Apple's OCSP responder. It is the strict,
 * Apple-recommended setting; callers must treat a verification failure as a
 * retryable server error rather than as "this user did not pay".
 */
const ENABLE_ONLINE_CHECKS = true;

let rootCertificates: Buffer[] | null = null;

function certsDirectory(): string {
  // Compiled to lib/apple/verifier.js, so certs/ is two levels up. The cwd
  // fallback covers the emulator being started from the functions directory.
  const candidates = [
    join(__dirname, '..', '..', 'certs'),
    join(process.cwd(), 'certs'),
  ];
  for (const candidate of candidates) {
    if (existsSync(join(candidate, ROOT_CERT_FILES[0] as string))) {
      return candidate;
    }
  }
  throw new ConfigError(
    'Apple root certificates are missing. Run `npm run certs` in functions/.',
  );
}

export function appleRootCertificates(): Buffer[] {
  if (rootCertificates) {
    return rootCertificates;
  }
  const directory = certsDirectory();
  rootCertificates = ROOT_CERT_FILES.map((file) =>
    readFileSync(join(directory, file)),
  );
  return rootCertificates;
}

/**
 * Secret Manager round-trips can turn newlines into the two characters `\n`,
 * which makes the PEM unparseable. Normalise both forms.
 */
function signingKey(): string {
  const raw = APP_STORE_PRIVATE_KEY.value();
  if (!raw || !raw.includes('PRIVATE KEY')) {
    throw new ConfigError(
      'APP_STORE_PRIVATE_KEY does not look like a PEM private key. Set it to ' +
        'the full contents of the .p8 downloaded from App Store Connect.',
    );
  }
  return raw.replace(/\\n/g, '\n');
}

let transactionVerifierInstance: SignedDataVerifier | null = null;

/**
 * Verifier used for transaction JWS received from a device.
 *
 * The library only enforces bundle id / environment for *notifications*, so a
 * single production-configured verifier can check the signature of both
 * production and sandbox transactions — and callers must validate bundle id and
 * environment themselves. See verifyAppleTransaction.
 */
export function transactionVerifier(): SignedDataVerifier {
  if (!transactionVerifierInstance) {
    transactionVerifierInstance = new SignedDataVerifier(
      appleRootCertificates(),
      ENABLE_ONLINE_CHECKS,
      Environment.PRODUCTION,
      appleBundleId(),
      appleAppAppleId(),
    );
  }
  return transactionVerifierInstance;
}

const notificationVerifierCache = new Map<Environment, SignedDataVerifier>();

/**
 * Notification verifiers, production first.
 *
 * verifyAndDecodeNotification checks that the payload's environment matches the
 * verifier's, so both environments need their own instance: App Review and
 * TestFlight testers generate sandbox notifications for a production app.
 */
export function notificationVerifiers(): SignedDataVerifier[] {
  const environments = [Environment.PRODUCTION, Environment.SANDBOX];
  return environments.map((environment) => {
    const cached = notificationVerifierCache.get(environment);
    if (cached) {
      return cached;
    }
    const verifier = new SignedDataVerifier(
      appleRootCertificates(),
      ENABLE_ONLINE_CHECKS,
      environment,
      appleBundleId(),
      environment === Environment.PRODUCTION ? appleAppAppleId() : undefined,
    );
    notificationVerifierCache.set(environment, verifier);
    return verifier;
  });
}

const apiClientCache = new Map<string, AppStoreServerAPIClient>();

/** App Store Server API client for the environment a transaction came from. */
export function apiClient(environment: Environment): AppStoreServerAPIClient {
  const cached = apiClientCache.get(environment);
  if (cached) {
    return cached;
  }
  const keyId = APP_STORE_KEY_ID.value().trim();
  const issuerId = APP_STORE_ISSUER_ID.value().trim();
  if (!keyId || !issuerId) {
    throw new ConfigError(
      'APP_STORE_KEY_ID / APP_STORE_ISSUER_ID are not configured.',
    );
  }
  const client = new AppStoreServerAPIClient(
    signingKey(),
    keyId,
    issuerId,
    appleBundleId(),
    environment,
  );
  apiClientCache.set(environment, client);
  return client;
}

/** Maps the environment string in a signed payload onto the library enum. */
export function toEnvironment(value: string | undefined): Environment | null {
  switch (value) {
  case Environment.PRODUCTION:
    return Environment.PRODUCTION;
  case Environment.SANDBOX:
    return Environment.SANDBOX;
  case Environment.XCODE:
    return Environment.XCODE;
  case Environment.LOCAL_TESTING:
    return Environment.LOCAL_TESTING;
  default:
    return null;
  }
}
