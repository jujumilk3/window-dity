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
        hide()

        let layouts = store.layouts
        guard !layouts.isEmpty,
              let screen = NSScreen.main else { return }

        let defaults = UserDefaults.standard
        let orientation = defaults.string(forKey: "overlayOrientation") ?? "horizontal"
        let posY = CGFloat(defaults.object(forKey: "overlayPositionY") as? Double ?? 0.5)
        let maxWidth = CGFloat(max(defaults.integer(forKey: "overlayMaxWidth"), 100))

        let isVertical = orientation == "vertical"
        let count = CGFloat(layouts.count)

        // Natural strip size at full scale
        let naturalPrimary: CGFloat
        if isVertical {
            naturalPrimary = count * overlayHeight + (count - 1) * spacing
        } else {
            naturalPrimary = count * overlayWidth + (count - 1) * spacing
        }

        // Scale down if strip exceeds maxWidth
        let scale: CGFloat = naturalPrimary > maxWidth ? maxWidth / naturalPrimary : 1.0
        let itemW = overlayWidth * scale
        let itemH = overlayHeight * scale
        let gap = spacing * scale

        // Final strip dimensions
        let stripW: CGFloat
        let stripH: CGFloat
        if isVertical {
            stripW = itemW
            stripH = count * itemH + (count - 1) * gap
        } else {
            stripW = count * itemW + (count - 1) * gap
            stripH = itemH
        }

        // Position: horizontally centered, vertically controlled by posY (0=top, 1=bottom)
        // NSScreen uses bottom-left origin, so invert Y
        let sf = screen.visibleFrame
        let stripX = sf.midX - stripW / 2
        let stripY = sf.maxY - stripH - posY * (sf.height - stripH)

        for (i, layout) in layouts.enumerated() {
            let view = OverlayView(layout: layout)

            let x: CGFloat
            let y: CGFloat
            if isVertical {
                x = stripX
                // Vertical: stack top-to-bottom, but NSScreen Y goes up
                y = stripY + stripH - CGFloat(i + 1) * itemH - CGFloat(i) * gap
            } else {
                x = stripX + CGFloat(i) * (itemW + gap)
                y = stripY
            }

            let window = NSWindow(
                contentRect: NSRect(x: x, y: y, width: itemW, height: itemH),
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
            for w in windows {
                w.animator().alphaValue = 1
            }
        }
    }

    func hide() {
        let toClose = windows
        let views = overlayViews
        windows = []
        overlayViews = []

        guard !toClose.isEmpty else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            for w in toClose {
                w.animator().alphaValue = 0
            }
        }, completionHandler: {
            for w in toClose {
                w.orderOut(nil)
            }
        })
        _ = views // silence unused warning
    }

    func updateHover(at point: NSPoint) {
        for (i, view) in overlayViews.enumerated() {
            let frame = windows[i].frame
            view.isHovered = frame.contains(point)
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
}
