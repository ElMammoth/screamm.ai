#!/usr/bin/env bash
# Create a STABLE self-signed code-signing certificate.
#
# Why: macOS ties TCC permissions (Accessibility, Microphone) to the app's code-signing
# identity. Plain ad-hoc signing (codesign -s -) has NO stable identity, so permissions
# reset on every rebuild. A stable self-signed cert keeps the identity constant, so you
# grant Accessibility/Mic ONCE and it survives rebuilds.

set -euo pipefail
CERT="${SCREAMM_CERT:-Screamm Self-Signed}"

if security find-certificate -c "$CERT" >/dev/null 2>&1; then
  echo "✅ Certificate '$CERT' already exists in your keychain. You're set."
  exit 0
fi

cat <<EOF
No certificate named '$CERT' found. Create it once via Keychain Access (~2 min):

  1. Open  Keychain Access.app
  2. Menu:  Keychain Access ▸ Certificate Assistant ▸ Create a Certificate…
  3. Fill in:
        Name:             $CERT
        Identity Type:    Self Signed Root
        Certificate Type: Code Signing
  4. Click Create, accept the defaults, then Done.

Then build + sign the app:
  SCREAMM_CERT="$CERT" ./Scripts/build-app.sh

(This is the reliable, Apple-supported path. It needs no Apple Developer ID and costs \$0.)
EOF
