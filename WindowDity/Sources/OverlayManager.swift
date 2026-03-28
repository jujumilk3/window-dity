import AppKit

class OverlayManager {
    private var overlayWindows: [(window: NSWindow, zone: DropZone, view: DropZoneView)] = []

    func showOverlays() {
        hideOverlays()

        guard let screen = NSScreen.main else { return }
        let zones = DropZone.allZones(for: screen)

        for zone in zones {
            let window = NSWindow(
                contentRect: zone.screenFrame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window.hasShadow = false
            window.alphaValue = 0

            let zoneView = DropZoneView(zone: zone)
            zoneView.frame = NSRect(origin: .zero, size: zone.screenFrame.size)
            zoneView.autoresizingMask = [.width, .height]
            window.contentView = zoneView

            window.orderFront(nil)

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                window.animator().alphaValue = 1
            }

            overlayWindows.append((window: window, zone: zone, view: zoneView))
        }
    }

    func highlightZone(at point: NSPoint) {
        for entry in overlayWindows {
            entry.view.isHighlighted = entry.zone.screenFrame.contains(point)
        }
    }

    func hideOverlays() {
        let windows = overlayWindows
        overlayWindows.removeAll()

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            for entry in windows {
                entry.window.animator().alphaValue = 0
            }
        }, completionHandler: {
            for entry in windows {
                entry.window.orderOut(nil)
            }
        })
    }

    func zoneAtPoint(_ point: NSPoint) -> DropZone? {
        overlayWindows.first(where: { $0.zone.screenFrame.contains(point) })?.zone
    }
}
