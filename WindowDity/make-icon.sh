#!/usr/bin/env bash
# Render AppIcon.icns from make-icon.swift. Run standalone to regenerate the icon.
set -euo pipefail
cd "$(dirname "$0")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Rendering 1024px master"
swift make-icon.swift "$WORK/master.png" >/dev/null

ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
size() { sips -z "$1" "$1" "$WORK/master.png" --out "$ICONSET/$2" >/dev/null; }
size 16  icon_16x16.png
size 32  icon_16x16@2x.png
size 32  icon_32x32.png
size 64  icon_32x32@2x.png
size 128 icon_128x128.png
size 256 icon_128x128@2x.png
size 256 icon_256x256.png
size 512 icon_256x256@2x.png
size 512 icon_512x512.png
cp "$WORK/master.png" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o AppIcon.icns
echo "==> Wrote $(pwd)/AppIcon.icns"
