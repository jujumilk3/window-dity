#!/usr/bin/env bash
# Build WindowDity as a native, installable macOS .app (personal use, no distribution).
#
#   ./build-app.sh                  build + install to /Applications (fallback: ~/Applications)
#   ./build-app.sh ~/Applications   install to a specific directory
#   ./build-app.sh --no-install     just build the .app under ./build, don't install
#
# Ad-hoc code signing is used so the app has a stable bundle identity for the
# Accessibility (TCC) permission. A rebuild changes the signature, so the
# Accessibility toggle may need to be re-granted after reinstalling.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="WindowDity"
BUNDLE_ID="com.windowdity.app"
BUILD_APP="build/${APP_NAME}.app"

INSTALL_DIR="/Applications"
DO_INSTALL=1
case "${1:-}" in
  --no-install) DO_INSTALL=0 ;;
  "") ;;
  *) INSTALL_DIR="$1" ;;
esac

echo "==> Building release binary"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/${APP_NAME}"

if [ ! -f AppIcon.icns ]; then
  echo "==> AppIcon.icns missing, generating"
  ./make-icon.sh
fi

echo "==> Assembling ${APP_NAME}.app"
rm -rf "$BUILD_APP"
mkdir -p "$BUILD_APP/Contents/MacOS" "$BUILD_APP/Contents/Resources"
cp "$BIN" "$BUILD_APP/Contents/MacOS/${APP_NAME}"
cp AppIcon.icns "$BUILD_APP/Contents/Resources/AppIcon.icns"
cp Info.plist "$BUILD_APP/Contents/Info.plist"
printf 'APPL????' > "$BUILD_APP/Contents/PkgInfo"

PB=/usr/libexec/PlistBuddy
"$PB" -c "Add :CFBundleIconFile string AppIcon" "$BUILD_APP/Contents/Info.plist" 2>/dev/null \
  || "$PB" -c "Set :CFBundleIconFile AppIcon" "$BUILD_APP/Contents/Info.plist"
"$PB" -c "Add :LSMinimumSystemVersion string 13.0" "$BUILD_APP/Contents/Info.plist" 2>/dev/null || true

CERT_CN="WindowDity Self-Signed"
SIGN_ID="-"
if security find-identity -p codesigning 2>/dev/null | grep -q "$CERT_CN"; then
  SIGN_ID="$CERT_CN"
  echo "==> Code signing with stable identity: \"$CERT_CN\""
else
  echo "==> Code signing (ad-hoc)"
  echo "    tip: run ./make-cert.sh once so Accessibility survives rebuilds"
fi

if ! codesign --force --sign "$SIGN_ID" \
      --identifier "$BUNDLE_ID" \
      --entitlements WindowDity.entitlements \
      "$BUILD_APP" 2>/tmp/windowdity_codesign.err; then
  if [ "$SIGN_ID" != "-" ]; then
    echo "    \"$CERT_CN\" signing failed; falling back to ad-hoc:" >&2
    cat /tmp/windowdity_codesign.err >&2
    codesign --force --sign - --identifier "$BUNDLE_ID" \
      --entitlements WindowDity.entitlements "$BUILD_APP"
  else
    cat /tmp/windowdity_codesign.err >&2
    exit 1
  fi
fi
codesign --verify --strict "$BUILD_APP" && echo "    signature OK"

if [ "$DO_INSTALL" -eq 0 ]; then
  echo ""
  echo "Built (not installed): $(pwd)/${BUILD_APP}"
  exit 0
fi

install_to() {
  local dir="$1" dest
  dest="$dir/${APP_NAME}.app"
  mkdir -p "$dir" 2>/dev/null || return 1
  rm -rf "$dest" 2>/dev/null || return 1
  cp -R "$BUILD_APP" "$dest" 2>/dev/null || return 1
  printf '%s' "$dest"
}

echo "==> Installing to ${INSTALL_DIR}"
killall "$APP_NAME" 2>/dev/null || true
if DEST="$(install_to "$INSTALL_DIR")"; then
  :
else
  echo "    ${INSTALL_DIR} not writable; falling back to ~/Applications"
  DEST="$(install_to "$HOME/Applications")" || { echo "install failed"; exit 1; }
fi
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo ""
echo "Installed: $DEST"
echo "Launch it from Spotlight/Launchpad, or run:  open \"$DEST\""
