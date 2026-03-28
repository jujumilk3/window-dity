#!/bin/bash
# WindowDity E2E Test
# Requires: Accessibility + Input Monitoring permissions for Terminal
#
# Usage: ./Tests/E2E/e2e_test.sh

set -uo pipefail
cd "$(dirname "$0")/../.."

E2E_DIR="Tests/E2E"
PASS=0
FAIL=0
BINARY=""
APP_PID=""

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

cleanup() {
    [[ -n "$APP_PID" ]] && kill "$APP_PID" 2>/dev/null || true
    osascript -e 'tell application "Finder" to close every window' 2>/dev/null || true
    echo ""
    echo "Results: $PASS passed, $FAIL failed"
    [[ $FAIL -eq 0 ]] && exit 0 || exit 1
}
trap cleanup EXIT

count_windows() {
    swift "$E2E_DIR/CountWindows.swift" "WindowDity" 2>/dev/null || echo "0"
}

# ── 1. Build ──
echo "── Build ──"
if swift build 2>&1 | tail -1 | grep -q "Build complete"; then
    pass "swift build"
else
    fail "swift build"
    exit 1
fi

BINARY=".build/arm64-apple-macosx/debug/WindowDity"
[[ ! -f "$BINARY" ]] && BINARY=".build/debug/WindowDity"

# ── 2. Launch ──
echo "── Launch ──"
"$BINARY" &
APP_PID=$!
sleep 2

if kill -0 "$APP_PID" 2>/dev/null; then
    pass "App launched (PID $APP_PID)"
else
    fail "App crashed on launch"
    APP_PID=""
    exit 1
fi

# ── 3. Menu bar status item ──
echo "── Menu Bar ──"
MENUBAR=$(osascript -e '
tell application "System Events"
    tell process "WindowDity"
        return count of menu bar items of menu bar 1
    end tell
end tell
' 2>/dev/null || echo "0")

if [[ "$MENUBAR" -gt 0 ]]; then
    pass "Status bar item found ($MENUBAR items)"
else
    fail "Status bar item not found"
fi

# ── 4. Open Finder window ──
echo "── Finder Window ──"
osascript -e '
tell application "Finder"
    activate
    make new Finder window
    set bounds of front Finder window to {100, 100, 700, 500}
end tell
' 2>/dev/null || true
sleep 1

FINDER_WINDOW=$(osascript -e '
tell application "Finder" to return count of Finder windows
' 2>/dev/null || echo "0")

if [[ "$FINDER_WINDOW" -gt 0 ]]; then
    pass "Finder window opened"
else
    fail "Could not open Finder window"
fi

# ── 5. Drag simulation ──
echo "── Drag Simulation ──"

WINDOWS_BEFORE=$(count_windows)

# Start drag in background (holds 0.5s at end before mouse up)
swift "$E2E_DIR/SimulateDrag.swift" 400 110 600 200 &
DRAG_PID=$!

# Wait for drag events to fire and overlays to render
sleep 2

# Count windows while drag is still holding
WINDOWS_DURING=$(count_windows)

# Wait for drag to complete
wait "$DRAG_PID" 2>/dev/null
DRAG_EXIT=$?

sleep 1
WINDOWS_AFTER=$(count_windows)

echo "    Windows: before=$WINDOWS_BEFORE during=$WINDOWS_DURING after=$WINDOWS_AFTER"

if [[ $DRAG_EXIT -eq 2 ]]; then
    echo "    ⚠ CGEvent failed — grant Input Monitoring permission to Terminal"
    fail "Drag simulation (no Input Monitoring permission)"
elif [[ "$WINDOWS_DURING" -gt "$WINDOWS_BEFORE" ]]; then
    pass "Overlay windows appeared during drag ($WINDOWS_DURING > $WINDOWS_BEFORE)"
else
    fail "No overlay windows detected during drag"
fi

if [[ "$WINDOWS_AFTER" -lt "$WINDOWS_DURING" ]]; then
    pass "Overlay windows disappeared after drag"
elif [[ "$WINDOWS_AFTER" -le "$WINDOWS_BEFORE" ]]; then
    pass "Overlay windows disappeared after drag"
else
    fail "Overlay windows still visible after drag ($WINDOWS_AFTER)"
fi

# ── 6. Preferences ──
echo "── Preferences ──"
osascript -e '
tell application "System Events"
    tell process "WindowDity"
        click menu bar item 1 of menu bar 1
        delay 0.3
        click menu item "Preferences…" of menu 1 of menu bar item 1 of menu bar 1
    end tell
end tell
' 2>/dev/null || true
sleep 1

PREFS_WINDOW=$(osascript -e '
tell application "System Events"
    tell process "WindowDity"
        return count of windows
    end tell
end tell
' 2>/dev/null || echo "0")

if [[ "$PREFS_WINDOW" -gt 0 ]]; then
    pass "Preferences window opened"
else
    fail "Preferences window did not open"
fi

# ── 7. About ──
echo "── About ──"
osascript -e '
tell application "System Events"
    tell process "WindowDity"
        click menu bar item 1 of menu bar 1
        delay 0.3
        click menu item "About WindowDity" of menu 1 of menu bar item 1 of menu bar 1
    end tell
end tell
' 2>/dev/null || true
sleep 1

ABOUT_WINDOW=$(osascript -e '
tell application "System Events"
    tell process "WindowDity"
        return count of windows
    end tell
end tell
' 2>/dev/null || echo "0")

if [[ "$ABOUT_WINDOW" -gt 0 ]]; then
    pass "About window opened"
else
    fail "About window did not open"
fi

echo ""
echo "── Done ──"
