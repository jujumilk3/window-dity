# WindowDity Loop Harness Interview (2026-03-28)

## Stage 1: Objective

**Goal:** Build a Window Tidy-style macOS window management app (WindowDity)

- Native macOS app that lives in the menu bar
- Quick Layout popup: click menu bar icon -> grid popup -> drag to select window size/position
- Control other applications' windows via macOS Accessibility API
- Most native tech stack possible -> **Swift + AppKit/SwiftUI**

## Stage 2: Deliverables

**Output location:** Project root (`WindowDity/` directory)

**Required files:**
- `WindowDity/` — Xcode project (.xcodeproj or Package.swift)
- `WindowDity/Sources/AppDelegate.swift` — app lifecycle, menu bar status item
- `WindowDity/Sources/StatusBarController.swift` — menu bar icon + popover management
- `WindowDity/Sources/QuickLayoutView.swift` — SwiftUI grid popup (layout selection)
- `WindowDity/Sources/WindowManager.swift` — Accessibility API window control (move/resize)
- `WindowDity/Sources/LayoutPreset.swift` — preset definitions
- `WindowDity/Sources/PreferencesView.swift` — custom size settings
- `WindowDity/Info.plist` — includes NSAccessibilityUsageDescription
- `WindowDity/WindowDity.entitlements` — accessibility entitlement

**Presets:**
- Quarters (top-left, top-right, bottom-left, bottom-right)
- Horizontal halves (top, bottom)
- Vertical halves (left, right)
- Full screen
- Custom size (user-defined pixel/ratio)

## Stage 3: Verification

**verify() checks:**
1. **File existence** — 5 required Swift source files
2. **Project structure** — .xcodeproj or Package.swift exists
3. **Info.plist** — NSAccessibilityUsageDescription present
4. **Core class grep** — WindowManager, StatusBarController/NSStatusBar, AXUIElement found in sources
5. **Build verification** — xcodebuild or swift build succeeds

**POST_PHASE (e2e):**
- Launch the built .app bundle
- Verify menu bar status item appears (AppleScript/accessibility)
- Capture crash logs on failure
- Max 3 attempts

## Stage 4: Constraints

- **No constraints** — agent has full freedom
- loop.sh ENGINE, SETUP sections must not be modified (harness rules)

## Decisions

| Item | Decision |
|---|---|
| App name | WindowDity |
| Tech stack | Swift + AppKit (system integration) + SwiftUI (UI) |
| Window control | macOS Accessibility API (AXUIElement) |
| UI interaction | Menu bar icon -> Quick Layout popup (grid drag) |
| Output location | Project root `WindowDity/` |
| Build tool | Xcode (xcodebuild) or Swift Package Manager |

---

## loop.sh Changes

Based on the interview results, the PROMPTS, POST PHASES, and VERIFY sections of `loop.sh` were modified. The ENGINE/SETUP/RUN sections were left untouched.

### gen_plan_prompt()

Updated to include the WindowDity app objective and full deliverable file list.

```bash
gen_plan_prompt() {
    cat <<'PROMPT_EOF'
You are a planning agent. Create a task plan for the objective below.

## Objective
Build "WindowDity" — a native macOS window management app (Swift + AppKit/SwiftUI).
The app lives in the menu bar. Clicking the menu bar icon opens a Quick Layout popup
where the user drags over a grid to select a window position/size, then the focused
window snaps to that layout. The app uses the macOS Accessibility API to control
windows belonging to other applications.

## Deliverables
All files are created in the project root:
- `WindowDity/` — Xcode project directory with a working .xcodeproj or Swift Package
- `WindowDity/Sources/AppDelegate.swift` — app lifecycle, menu bar status item
- `WindowDity/Sources/StatusBarController.swift` — menu bar icon + popover management
- `WindowDity/Sources/QuickLayoutView.swift` — SwiftUI grid popup for layout selection
- `WindowDity/Sources/WindowManager.swift` — Accessibility API window control (move/resize)
- `WindowDity/Sources/LayoutPreset.swift` — preset definitions (left half, right half, top half, bottom half, quarters, full screen, custom)
- `WindowDity/Sources/PreferencesView.swift` — settings for custom sizes
- `WindowDity/Info.plist` — with NSAccessibilityUsageDescription
- `WindowDity/WindowDity.entitlements` — with accessibility entitlement

## Context
1. Read `output/progress.txt` first; do not duplicate work already marked as done.
2. Keep tasks minimal and directly tied to the objective.

## Job
1. Read what has been completed and what remains from `output/progress.txt`.
2. Generate `output/plan.json` with exact JSON only.
3. Tasks must be ordered by execution priority.

Schema: (standard T-### task schema)

## Completion
When done, output: <promise>PLAN_COMPLETE</promise>
PROMPT_EOF
}
```

### gen_replan_prompt()

Includes the same Objective/Deliverables as gen_plan_prompt(), plus injects `$build_errors` to pass previous cycle errors to the replanning agent.

### gen_build_prompt()

Includes WindowDity context and specifies SwiftUI/AppKit/AXUIElement usage rules.

```bash
gen_build_prompt() {
    cat <<'PROMPT_EOF'
You are a build agent. Execute one task from the plan.

## Objective context
Build "WindowDity" — a native macOS window management app with menu bar Quick Layout popup,
using Swift + AppKit/SwiftUI and Accessibility API.

## Rules
- ONE task per iteration.
- Actually create/modify the target files — do not just toggle passes.
- All app source files go under `WindowDity/` in the project root.
- Use SwiftUI for UI components, AppKit for system integration (NSStatusBar, NSPopover).
- Use AXUIElement API for window management via Accessibility framework.

## Completion
If ALL tasks have `passes: true`, output: <promise>CYCLE_DONE</promise>
PROMPT_EOF
}
```

### POST_PHASES + gen_e2e_prompt()

Added E2E phase for post-build app launch testing.

```bash
POST_PHASES=("e2e")

gen_e2e_prompt() {
    cat <<'PROMPT_EOF'
You are an E2E testing agent. The WindowDity macOS app has been built.

## Job
1. Locate the built .app bundle under the WindowDity build directory.
2. Launch the app using `open` command and verify it starts without crashing.
3. Check that the menu bar status item appears (use AppleScript or accessibility checks).
4. Kill the app process after testing.
5. Report results to `output/progress.txt`.

## Rules
- Max 3 attempts to verify the app runs.
- If the app crashes on launch, capture the crash log and report it.
- Do not modify source code — only test.

## Completion
If all tests pass, output: <promise>E2E_DONE</promise>
If tests fail, describe what failed and output: <promise>E2E_PROGRESS</promise>
PROMPT_EOF
}
```

### verify() — deliverable checks appended

The existing plan.json validation logic was preserved. The following deliverable checks were inserted after the plan validation block, before the final error report:

```bash
# === DELIVERABLE CHECKS ===

# 1. Required source files must exist
local required_files=(
    "WindowDity/Sources/AppDelegate.swift"
    "WindowDity/Sources/StatusBarController.swift"
    "WindowDity/Sources/QuickLayoutView.swift"
    "WindowDity/Sources/WindowManager.swift"
    "WindowDity/Sources/LayoutPreset.swift"
)
for f in "${required_files[@]}"; do
    [[ ! -f "$f" ]] && errors+=("Missing required file: $f")
done

# 2. Project structure (.xcodeproj or Package.swift)
if ! ls WindowDity/*.xcodeproj 1>/dev/null 2>&1 && [[ ! -f "WindowDity/Package.swift" ]]; then
    errors+=("No Xcode project or Package.swift found in WindowDity/.")
fi

# 3. Info.plist + NSAccessibilityUsageDescription
if [[ -f "WindowDity/Info.plist" ]]; then
    grep -q "NSAccessibilityUsageDescription" "WindowDity/Info.plist" 2>/dev/null || \
        errors+=("Info.plist missing NSAccessibilityUsageDescription.")
else
    errors+=("WindowDity/Info.plist not found.")
fi

# 4. Core class/API grep
grep -rq "class WindowManager" WindowDity/Sources/ 2>/dev/null || \
    grep -rq "struct WindowManager" WindowDity/Sources/ 2>/dev/null || \
    errors+=("WindowManager class/struct not found in sources.")
grep -rq "StatusBarController\|NSStatusBar\|NSStatusItem" WindowDity/Sources/ 2>/dev/null || \
    errors+=("StatusBar integration not found in sources.")
grep -rq "AXUIElement\|CGWindowListCopyWindowInfo" WindowDity/Sources/ 2>/dev/null || \
    errors+=("Accessibility API usage not found in sources.")

# 5. Swift build verification
if ls WindowDity/*.xcodeproj 1>/dev/null 2>&1; then
    xcodebuild -project "WindowDity/..." -scheme "..." -configuration Debug build
elif [[ -f "WindowDity/Package.swift" ]]; then
    cd WindowDity && swift build
fi
```
