#!/usr/bin/env bash
# Build Screamm.app from source and sign it with the stable self-signed cert.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="Screamm.app"
CERT="${SCREAMM_CERT:-Screamm Self-Signed}"

echo "==> building release binary..."
swift build -c release --product Screamm

echo "==> assembling ${APP}..."
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp ".build/release/Screamm" "${APP}/Contents/MacOS/Screamm"
cp "Resources/Info.plist" "${APP}/Contents/Info.plist"

if security find-certificate -c "${CERT}" >/dev/null 2>&1; then
  echo "==> signing with stable cert '${CERT}' (permissions persist across rebuilds)..."
  codesign --force --deep \
    --entitlements "Resources/Screamm.entitlements" \
    --sign "${CERT}" "${APP}"
  codesign --verify --verbose=2 "${APP}"
  echo "OK: built + signed with stable cert -> ${APP}"
else
  echo "==> no stable cert '${CERT}'; ad-hoc signing so it runs NOW..."
  echo "    (You'll re-grant Accessibility on each rebuild. Run ./Scripts/make-cert.sh once to stop that.)"
  codesign --force --deep \
    --entitlements "Resources/Screamm.entitlements" \
    --sign - "${APP}"
  codesign --verify --verbose=2 "${APP}"
  echo "OK: built + ad-hoc signed -> ${APP}"
fi

echo ""
echo "Run it:"
echo "  open ./${APP}                         # launches into the menu bar"
echo "  ./${APP}/Contents/MacOS/Screamm       # run in terminal to see logs"
echo ""
echo "First launch: grant Microphone + Accessibility when prompted, then it downloads"
echo "the turbo model once. Look for the mic glyph in your menu bar. Hold Right Cmd to dictate."
