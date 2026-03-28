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

        let totalWidth = CGFloat(layouts.count) * overlayWidth
            + CGFloat(layouts.count - 1) * spacing
        let stripX = screen.frame.midX - totalWidth / 2
        let stripY = screen.frame.origin.y + 60

        for (i, layout) in layouts.enumerated() {
            let view = OverlayView(layout: layout)
            let window = NSWindow(
                contentRect: NSRect(
                    x: stripX + CGFloat(i) * (overlayWidth + spacing),
                    y: stripY,
                    width: overlayWidth,
                    height: overlayHeight
                ),
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
