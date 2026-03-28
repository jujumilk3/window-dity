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

        // Read positioning settings from UserDefaults
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "overlayOrientation": "horizontal",
            "overlayPositionX": 0.5,
            "overlayPositionY": 0.0,
            "overlayMaxWidth": 300,
            "overlayMargins": 700
        ])
        let orientation = defaults.string(forKey: "overlayOrientation") ?? "horizontal"
        let posX = defaults.double(forKey: "overlayPositionX")
        let posY = defaults.double(forKey: "overlayPositionY")
        let maxWidth = CGFloat(defaults.integer(forKey: "overlayMaxWidth"))
        let margins = CGFloat(defaults.integer(forKey: "overlayMargins"))

        let isVertical = orientation == "vertical"
        let count = CGFloat(layouts.count)

        // Calculate natural strip length along primary axis
        let naturalLength: CGFloat
        if isVertical {
            naturalLength = count * overlayHeight + (count - 1) * spacing
        } else {
            naturalLength = count * overlayWidth + (count - 1) * spacing
        }

        // Scale thumbnails down if strip exceeds maxWidth
        let scale: CGFloat = (maxWidth > 0 && naturalLength > maxWidth)
            ? maxWidth / naturalLength
            : 1.0
        let itemW = overlayWidth * scale
        let itemH = overlayHeight * scale
        let gap = spacing * scale

        // Compute final strip dimensions
        let stripWidth: CGFloat
        let stripHeight: CGFloat
        if isVertical {
            stripWidth = itemW
            stripHeight = count * itemH + (count - 1) * gap
        } else {
            stripWidth = count * itemW + (count - 1) * gap
            stripHeight = itemH
        }

        // Position within usable screen area (inset by margins split on each side)
        let sf = screen.frame
        let halfMargin = margins / 2
        let usableW = max(sf.width - margins, stripWidth)
        let usableH = max(sf.height - margins, stripHeight)
        let stripX = sf.origin.x + halfMargin + posX * (usableW - stripWidth)
        let stripY = sf.origin.y + halfMargin + posY * (usableH - stripHeight)

        for (i, layout) in layouts.enumerated() {
            let view = OverlayView(layout: layout)

            let x: CGFloat
            let y: CGFloat
            if isVertical {
                x = stripX
                y = stripY + CGFloat(i) * (itemH + gap)
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
