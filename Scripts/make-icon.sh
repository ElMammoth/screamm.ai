#!/usr/bin/env bash
# Regenerate Resources/AppIcon.icns from Scripts/make-icon.swift.
# The icon is generated, not hand-drawn, so it stays reproducible and reviewable in git.
set -euo pipefail
cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> rendering 1024px master..."
swiftc -O -parse-as-library -o "$TMP/icongen" Scripts/make-icon.swift -framework AppKit
"$TMP/icongen" "$TMP/icon_1024.png"

echo "==> building iconset..."
SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"
for SIZE in 16 32 64 128 256 512; do
  sips -z $SIZE $SIZE "$TMP/icon_1024.png" --out "$SET/icon_${SIZE}x${SIZE}.png" >/dev/null
  DOUBLE=$((SIZE * 2))
  sips -z $DOUBLE $DOUBLE "$TMP/icon_1024.png" --out "$SET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
cp "$TMP/icon_1024.png" "$SET/icon_512x512@2x.png"

iconutil -c icns "$SET" -o Resources/AppIcon.icns
echo "OK: Resources/AppIcon.icns ($(du -h Resources/AppIcon.icns | cut -f1))"
