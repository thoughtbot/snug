#!/bin/bash
# Creates a stable self-signed "Snug Dev" code-signing identity.
#
# Why: ad-hoc signatures change every build, so macOS TCC re-prompts for
# camera/mic after each rebuild. A stable identity keeps the grants.
#
# This script imports the identity into a dedicated keychain so codesign can
# use it without GUI prompts. The final trust step (add-trusted-cert) may show
# one system authorization dialog.
set -euo pipefail

CERT_NAME="Snug Dev"
KEYCHAIN="$HOME/Library/Keychains/snug-dev.keychain-db"
KEYCHAIN_PASS="snug-dev"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if security find-identity -p codesigning -v 2>/dev/null | grep -q "$CERT_NAME"; then
    echo "'$CERT_NAME' identity already exists."
    exit 0
fi

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$TMP_DIR/key.pem" -out "$TMP_DIR/cert.pem" \
    -subj "/CN=$CERT_NAME" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -addext "basicConstraints=critical,CA:false"

# Legacy PBE/MAC algorithms: macOS `security import` rejects OpenSSL 3's
# default PKCS12 encryption.
openssl pkcs12 -export -out "$TMP_DIR/cert.p12" \
    -inkey "$TMP_DIR/key.pem" -in "$TMP_DIR/cert.pem" -passout pass:temp \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

if [ ! -f "$KEYCHAIN" ]; then
    security create-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN"
fi
security unlock-keychain -p "$KEYCHAIN_PASS" "$KEYCHAIN"
security set-keychain-settings "$KEYCHAIN"   # no auto-lock
security import "$TMP_DIR/cert.p12" -k "$KEYCHAIN" -P temp \
    -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "$KEYCHAIN_PASS" "$KEYCHAIN" >/dev/null

# Add to the user's keychain search list (idempotent-ish: preserves existing).
EXISTING=$(security list-keychains -d user | tr -d '" ' | grep -v "snug-dev" || true)
# shellcheck disable=SC2086
security list-keychains -d user -s $EXISTING "$KEYCHAIN"

# Trust the cert for code signing (this step may show ONE auth dialog).
security add-trusted-cert -r trustRoot -p codeSign \
    -k "$KEYCHAIN" "$TMP_DIR/cert.pem"

echo "Done. Verify with: security find-identity -p codesigning -v | grep '$CERT_NAME'"
