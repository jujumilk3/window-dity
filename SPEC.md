# WindowDity Spec

## What it is
A Window Tidy-style native macOS window management app (Swift + AppKit).

## Core UX
1. User grabs a window and starts dragging it
2. Layout drop zones appear on screen as a strip of thumbnails
3. Each zone shows a preview of the layout (e.g. left half, right half, full screen)
4. User drops the window onto a zone → window snaps to that layout's frame
5. Zones disappear after drop or when drag is cancelled

## Preferences
- Layouts tab: scrollable list of user-defined layouts
  - Each layout shows: grid preview thumbnail, name, grid dimensions, "All Screens"
  - Reorder by drag, double-click to edit, add/remove buttons
  - Default layouts: Left Half, Right Half, Centre, Full Screen
- Layout editor: name field, grid size picker (rows x cols), click cells to select region
- General: launch at login

## Layout Model
- Name (string)
- Grid dimensions (rows x cols)
- Selected cells (which cells in the grid are filled)
- Computed screen frame from selected cells relative to screen bounds

## Technical
- Menu bar agent (LSUIElement=true, no dock icon)
- Accessibility API (AXUIElement) for window move/resize
- Global NSEvent monitor for drag detection
- Capture window reference on mouseDown (before drag starts) so resize works on the dragged window
- Overlays: borderless NSWindows as horizontal strip near bottom-center of screen
- Preferences window must actually open when clicked
