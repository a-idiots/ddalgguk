#!/usr/bin/env bash
# Downloads Apple's public root CA certificates used to verify App Store signed
# payloads (JWS transactions and App Store Server Notifications V2).
#
# These are public certificates, not secrets — they are committed to the repo so
# deploys do not depend on apple.com being reachable. Re-run this script if
# Apple publishes a new root CA.
#
# Note the two different hosts: the modern G2/G3 roots live under
# /certificateauthority/, the 2007 "Apple Inc." root under /appleca/.
#
# Usage: npm run certs   (from the functions/ directory)
set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/certs"

CERT_URLS=(
  'https://www.apple.com/certificateauthority/AppleRootCA-G3.cer'
  'https://www.apple.com/certificateauthority/AppleRootCA-G2.cer'
  'https://www.apple.com/appleca/AppleIncRootCertificate.cer'
)

mkdir -p "$DEST"

for url in "${CERT_URLS[@]}"; do
  name="$(basename "$url")"
  echo "Fetching ${name}…"
  curl --fail --silent --show-error --location --max-time 30 \
    --output "${DEST}/${name}" "$url"
  # A DER-encoded certificate starts with the SEQUENCE tag 0x30; anything else
  # (an HTML error page, for example) means the download is not usable.
  if [ "$(head -c 1 "${DEST}/${name}" | od -An -tx1 | tr -d ' \n')" != '30' ]; then
    echo "ERROR: ${name} is not a DER certificate — aborting." >&2
    rm -f "${DEST}/${name}"
    exit 1
  fi
done

echo "Done. ${#CERT_URLS[@]} certificates in ${DEST}"
