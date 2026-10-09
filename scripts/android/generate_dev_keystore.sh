#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

STORE_PASS="${STORE_PASS:-test@cake_wallet}"
KEY_PASS="${KEY_PASS:-test@cake_wallet}"
DEST="${1:-}"

if [[ -z "$DEST" ]]; then
  DEST="$(cd ../.. && pwd)/android/app/key.jks"
elif [[ "$DEST" != /* ]]; then
  DEST="$(cd ../.. && pwd)/$DEST"
fi

P12="$(mktemp /tmp/cakewallet-dev-XXXXXX.p12)"
cleanup() { rm -f "$P12"; }
trap cleanup EXIT

openssl pkcs12 -export \
  -inkey "$PWD/dev-test-key.pem" \
  -in "$PWD/dev-test-key.crt" \
  -out "$P12" \
  -name testKey \
  -passout "pass:${STORE_PASS}" \
  -certpbe PBE-SHA1-3DES \
  -keypbe PBE-SHA1-3DES \
  -macalg sha1

mkdir -p "$(dirname "$DEST")"
rm -f "$DEST"

keytool -importkeystore \
  -srckeystore "$P12" \
  -srcstoretype PKCS12 \
  -srcstorepass "$STORE_PASS" \
  -destkeystore "$DEST" \
  -deststoretype JKS \
  -deststorepass "$STORE_PASS" \
  -destkeypass "$KEY_PASS" \
  -srcalias testKey \
  -destalias testKey \
  -noprompt

echo "Wrote $DEST"
