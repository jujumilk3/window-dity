import AppKit

final class OverlayManager {
    private let store: LayoutStore
    private var windows: [NSWindow] = []
    private var overlayViews: [OverlayView] = []

    private let overlayWidth: CGFloat = 120
    private let overlayHeight: CGFloat = 100
    private let spacing: CGFloat = 8

    init(store: LayoutStore) {
        self.store = store
    }

    func show() {
        let layouts = store.layouts
        guard !layouts.isEmpty,
              let screen = NSScreen.main else { return }

        let frames = computeFrames(layouts: layouts, screen: screen)

        // If window count matches, just move existing windows (no flicker)
        if windows.count == frames.count {
            for (i, frame) in frames.enumerated() {
                windows[i].setFrame(frame, display: true, animate: false)
            }
            return
        }

        // Layout count changed — rebuild windows
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
        overlayViews.removeAll()

        for (i, layout) in layouts.enumerated() {
            let view = OverlayView(layout: layout)
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
            view.isHovered = windows[i].frame.contains(point)
        }
    }

    func layoutUnderMouse(at point: NSPoint) -> Layout? {
        for (i, window) in windows.enumerated() {
            if window.frame.contains(point) {
                return overlayViews[i].layout
            }
        }
        return nil
    }

    // MARK: - Frame Computation

    private func computeFrames(layouts: [Layout], screen: NSScreen) -> [NSRect] {
        let sf = screen.visibleFrame
        let defaults = UserDefaults.standard
        let orientation = defaults.string(forKey: "overlayOrientation") ?? "horizontal"
        let posY = CGFloat(defaults.object(forKey: "overlayPositionY") as? Double ?? 0.5)
        let widthPct = CGFloat(defaults.object(forKey: "overlayWidthPercent") as? Double ?? 30)
        let maxWidth = sf.width * (widthPct / 100)

        let isVertical = orientation == "vertical"
        let count = CGFloat(layouts.count)

        let naturalPrimary: CGFloat = isVertical
            ? count * overlayHeight + (count - 1) * spacing
            : count * overlayWidth + (count - 1) * spacing

        let scale: CGFloat = naturalPrimary > maxWidth ? maxWidth / naturalPrimary : 1.0
        let itemW = overlayWidth * scale
        let itemH = overlayHeight * scale
        let gap = spacing * scale

        let stripW: CGFloat = isVertical ? itemW : count * itemW + (count - 1) * gap
        let stripH: CGFloat = isVertical ? count * itemH + (count - 1) * gap : itemH

        let stripX = sf.midX - stripW / 2
        let travel = max(sf.height - stripH, 0)
        let stripY = sf.maxY - stripH - posY * travel

        var frames: [NSRect] = []
        for i in 0..<layouts.count {
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
