import AppKit

final class OverlayManager {
    private let store: LayoutStore
    private var windows: [NSWindow] = []
    private var overlayViews: [OverlayView] = []
    /// Grouped layouts: each group shares a grid size and becomes one card
    private var groups: [[Layout]] = []

    private let cardWidth: CGFloat = 120
    private let cardHeight: CGFloat = 100
    private let spacing: CGFloat = 8

    init(store: LayoutStore) {
        self.store = store
    }

    func show() {
        let layouts = store.layouts
        guard !layouts.isEmpty,
              let screen = NSScreen.main else { return }

        // Group layouts by grid dimensions (rows x cols)
        let newGroups = groupLayouts(layouts)
        let frames = computeFrames(cardCount: newGroups.count, screen: screen)

        // If card count matches, just reposition (no flicker)
        if windows.count == frames.count {
            groups = newGroups
            for (i, frame) in frames.enumerated() {
                windows[i].setFrame(frame, display: true, animate: false)
                // Update view's layouts in case they changed
                let view = OverlayView(layouts: newGroups[i])
                view.frame = NSRect(origin: .zero, size: frame.size)
                windows[i].contentView = view
                overlayViews[i] = view
            }
            return
        }

        // Card count changed — rebuild
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
        overlayViews.removeAll()
        groups = newGroups

        for (i, group) in groups.enumerated() {
            let view = OverlayView(layouts: group)
            let window = NSWindow(
                contentRect: frames[i],
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .floating
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.contentView = view
            window.alphaValue = 0
            window.orderFront(nil)

            overlayViews.append(view)
            windows.append(window)
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            for w in windows { w.animator().alphaValue = 1 }
        }
    }

    func hide() {
        let toClose = windows
        windows = []
        overlayViews = []
        groups = []
        guard !toClose.isEmpty else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            for w in toClose { w.animator().alphaValue = 0 }
        }, completionHandler: {
            for w in toClose { w.orderOut(nil) }
        })
    }

    func updateHover(at point: NSPoint) {
        for (i, view) in overlayViews.enumerated() {
            let frame = windows[i].frame
            if frame.contains(point) {
                view.hoveredLayout = view.layoutAt(screenPoint: point, windowFrame: frame)
            } else {
                view.hoveredLayout = nil
            }
        }
    }

    func layoutUnderMouse(at point: NSPoint) -> Layout? {
        for (i, view) in overlayViews.enumerated() {
            let frame = windows[i].frame
            if frame.contains(point) {
                return view.layoutAt(screenPoint: point, windowFrame: frame)
            }
        }
        return nil
    }

    // MARK: - Grouping

    private func groupLayouts(_ layouts: [Layout]) -> [[Layout]] {
        var dict: [String: [Layout]] = [:]
        for layout in layouts {
            let key = "\(layout.rows)x\(layout.cols)"
            dict[key, default: []].append(layout)
        }
        // Preserve order: use the first layout in each group's position
        var seen: [String] = []
        for layout in layouts {
            let key = "\(layout.rows)x\(layout.cols)"
            if !seen.contains(key) { seen.append(key) }
        }
        return seen.compactMap { dict[$0] }
    }

    // MARK: - Frame Computation

    private func computeFrames(cardCount: Int, screen: NSScreen) -> [NSRect] {
        let sf = screen.visibleFrame
        let defaults = UserDefaults.standard
        let orientation = defaults.string(forKey: "overlayOrientation") ?? "horizontal"
        let posY = CGFloat(defaults.object(forKey: "overlayPositionY") as? Double ?? 0.5)
        let widthPct = CGFloat(defaults.object(forKey: "overlayWidthPercent") as? Double ?? 30)
        let maxWidth = sf.width * (widthPct / 100)

        let isVertical = orientation == "vertical"
        let count = CGFloat(cardCount)

        let naturalPrimary: CGFloat = isVertical
            ? count * cardHeight + (count - 1) * spacing
            : count * cardWidth + (count - 1) * spacing

        let scale: CGFloat = maxWidth / naturalPrimary
        let itemW = cardWidth * scale
        let itemH = cardHeight * scale
        let gap = spacing * scale

        let stripW: CGFloat = isVertical ? itemW : count * itemW + (count - 1) * gap
        let stripH: CGFloat = isVertical ? count * itemH + (count - 1) * gap : itemH

        let stripX = sf.midX - stripW / 2
        let travel = max(sf.height - stripH, 0)
        let stripY = sf.maxY - stripH - posY * travel

        var frames: [NSRect] = []
        for i in 0..<cardCount {
            let x: CGFloat
            let y: CGFloat
            if isVertical {
                x = stripX
                y = stripY + stripH - CGFloat(i + 1) * itemH - CGFloat(i) * gap
            } else {
                x = stripX + CGFloat(i) * (itemW + gap)
                y = stripY
            }
            frames.append(NSRect(x: x, y: y, width: itemW, height: itemH))
        }
        return frames
    }
}
