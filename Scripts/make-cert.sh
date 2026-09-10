#!/usr/bin/env bash
# Create a STABLE self-signed code-signing certificate, automatically.
#
# Why: macOS ties TCC permissions (Accessibility, Microphone) to the app's code-signing
# identity. Plain ad-hoc signing (codesign -s -) has NO stable identity, so permissions
# reset on every rebuild. A stable self-signed cert keeps the identity constant, so you
# grant Accessibility/Mic ONCE and it survives rebuilds.
#
# This creates the cert with openssl and imports it into your login keychain. No Apple
# Developer ID, $0. If the automated path fails, it prints the Keychain Access GUI steps.

set -euo pipefail
CERT="${SCREAMM_CERT:-Screamm Self-Signed}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$CERT" >/dev/null 2>&1; then
  echo "OK: certificate '$CERT' already exists in your keychain. Nothing to do."
  exit 0
fi

echo "==> creating self-signed code-signing certificate '$CERT'..."
DIR="$(mktemp -d)"
trap 'rm -rf "$DIR"' EXIT

cat > "$DIR/cs.cnf" <<CNF
[ req ]
distinguished_name = dn
x509_extensions = ext
prompt = no
[ dn ]
CN = $CERT
[ ext ]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$DIR/key.pem" -out "$DIR/cert.pem" \
  -days 3650 -config "$DIR/cs.cnf" >/dev/null 2>&1

# OpenSSL 3 (e.g. Homebrew) writes a PKCS12 that Apple's `security` can't read unless we
# pass -legacy. LibreSSL (/usr/bin/openssl) doesn't know -legacy and doesn't need it, so
# try -legacy first and fall back.
if ! openssl pkcs12 -export -legacy \
      -inkey "$DIR/key.pem" -in "$DIR/cert.pem" \
      -name "$CERT" -out "$DIR/id.p12" -passout pass:screamm >/dev/null 2>&1; then
  openssl pkcs12 -export \
      -inkey "$DIR/key.pem" -in "$DIR/cert.pem" \
      -name "$CERT" -out "$DIR/id.p12" -passout pass:screamm >/dev/null 2>&1
fi

# -A: allow apps (codesign) to use the key without a per-use keychain prompt.
security import "$DIR/id.p12" -k "$KEYCHAIN" -P screamm -A >/dev/null 2>&1

if security find-certificate -c "$CERT" >/dev/null 2>&1; then
  echo "OK: '$CERT' created and imported into your login keychain."
  echo "    Now build + sign:  SCREAMM_CERT=\"$CERT\" ./Scripts/build-app.sh"
else
  echo "Automated creation did not stick. Fallback (Keychain Access GUI, ~2 min):"
  echo "  Keychain Access > Certificate Assistant > Create a Certificate"
  echo "  Name: $CERT   Identity Type: Self Signed Root   Certificate Type: Code Signing"
  exit 1
fi
