# WindowDity — Loop Iteration History

This project is an example app built using [looprinter](https://github.com/tapesymbolstate/looprinter) — a loop template repository for building iterative agent harnesses. The `loop.sh` harness was copied from looprinter and customized through a series of conversational interviews to produce a working macOS window management app.

The document below records how the loop was iteratively refined through conversation — the "outer loop" of human feedback driving prompt improvements, while the "inner loop" (agent iterations inside loop.sh) executed the refined instructions.

## Iteration 1: Initial Interview (`f654502`)

**Process:** `/looprinter-interview` skill used to conduct 4-stage interview (Objective, Deliverables, Verification, Constraints).

**Initial understanding (wrong):**
- Menu bar app with a "Quick Layout" grid popup
- Click menu bar icon → popover with draggable grid → select area → window snaps
- Basically a menu bar popover tool

**loop.sh configured with:**
- `gen_plan_prompt()` — menu bar + QuickLayoutView + grid popup
- `gen_build_prompt()` — SwiftUI grid + NSPopover
- `verify()` — file checks + `swift build`
- `POST_PHASES=("e2e")` — app launch test

**Result:** App built successfully in ~20 min, but UX was completely wrong.

## Iteration 2: UX Correction — Drag & Drop (`1b65d23`)

**User feedback:** "When you grab a window and start dragging, layout zones appear on screen. Drop the window on a zone → it snaps to that size."

**Key changes to loop.sh:**
- Objective rewritten: drag detection → overlay drop zones → snap on drop
- New files: `DragDetector.swift`, `OverlayManager.swift`, `DropZone.swift`, `DropZoneView.swift`
- Removed: `StatusBarController.swift`, `QuickLayoutView.swift`
- verify() updated for new file/class list
- `.gitignore` updated with Swift/Xcode entries

**Result:** App rebuilt with drag-overlay architecture. Full-screen zone overlays appeared on drag.

## Iteration 3: User-Defined Layouts (`8196abe`)

**User feedback:** Shared `references/preference.png` (Window Tidy Preferences screenshot). Layouts should be user-defined in Preferences, not hardcoded. Each layout is grid-based with a preview thumbnail.

**Key changes to loop.sh:**
- `SPEC.md` created as single source of truth
- Prompts reference `SPEC.md` + `references/` directory
- New files: `Layout.swift`, `LayoutStore.swift`, `LayoutEditorView.swift`, `OverlayView.swift`
- Removed: `DropZone.swift`, `DropZoneView.swift`, `LayoutPreset.swift`
- Architecture: Layout model (Codable) + LayoutStore (ObservableObject, UserDefaults JSON)
- Bug fixes embedded in prompts:
  1. Capture window ref on mouseDown (before drag starts)
  2. Preferences window opening fix (NSMenuItem target)
  3. Overlays as thumbnail strip, not full-screen zones

**Result:** Full rebuild with user-configurable layouts, grid editor, and thumbnail strip overlays.

## Iteration 4: Preferences Bug Fix (`5a9c522`)

**User feedback:** "Preferences still doesn't open. Make it match the reference UI."

**Key changes to loop.sh:**
- Switched from "rewrite" to "update" mode — prompts say "Do NOT delete existing files"
- Bug details made explicit: `NSMenuItem.target = self` fix
- Reference UI requirements spelled out in detail

**Changes (code-level, not rewrite):**
- `AppDelegate.swift` — `prefsItem.target = self` on NSMenuItem
- `PreferencesView.swift` — TabView (Layouts/Options), 60x40 landscape thumbnails, gridDescription
- `LayoutEditorView.swift` — screen position preview (200x120)
- `Layout.swift` — `gridDescription` computed property

**Result:** Preferences opens correctly, UI matches reference.

## Iteration 5: Positioning Tab (`6831972`)

**User feedback:** Shared `references/preference2.png` — Window Tidy's Positioning tab.

**Key changes to loop.sh:**
- Feature description added: Positioning tab with orientation, screen position preview, dimensions
- Prompts specify @AppStorage keys and normalized position values

**Changes (code-level):**
- `PreferencesView.swift` — Positioning tab: orientation radio, draggable StripPositionPreview, max width/margins fields
- `OverlayManager.swift` — reads positioning settings, applies orientation/position/size

**Result:** Overlay strip positioning fully configurable from Preferences.

---

## Patterns Observed

### What worked well
1. **SPEC.md as single source of truth** — once created, prompts just reference it
2. **Reference screenshots** — giving the agent visual targets dramatically improved UI output
3. **Bug details in prompts** — explicit root cause + fix direction prevented agents from guessing wrong
4. **"Update, not rewrite" mode** — later iterations preserved working code instead of starting over
5. **verify() evolving with architecture** — each iteration updated the file list and grep patterns

### What needed correction
1. **First attempt was wrong** — interview alone wasn't enough; needed the user to clarify the actual UX
2. **Preferences not opening** — took 2 iterations to fix; first attempt used wrong approach (sendAction), second found the real issue (NSMenuItem.target)
3. **Full rewrites were wasteful** — iterations 2-3 deleted everything; iteration 4+ switched to surgical updates

### Loop improvement strategy
```
User describes intent → Loop runs → User tests → User gives feedback
    → Prompts updated with specific fixes → Loop runs again (smaller scope)
```

The outer loop (human feedback → prompt refinement) is where the real value is. The inner loop (agent iterations) just executes the refined instructions.
