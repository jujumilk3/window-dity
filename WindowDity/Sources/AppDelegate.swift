import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var dragDetector: DragDetector!
    private var overlayManager: OverlayManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        WindowManager.shared.checkAccessibility()

        overlayManager = OverlayManager()
        dragDetector = DragDetector()

        dragDetector.onDragStarted = { [weak self] in
            self?.overlayManager.showOverlays()
        }

        dragDetector.onDragMoved = { [weak self] point in
            self?.overlayManager.highlightZone(at: point)
        }

        dragDetector.onDragEnded = { [weak self] point in
            guard let self else { return }
            if let zone = self.overlayManager.zoneAtPoint(point) {
                WindowManager.shared.moveAndResize(to: zone.screenFrame)
            }
            self.overlayManager.hideOverlays()
        }

        dragDetector.start()

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x2", accessibilityDescription: "WindowDity")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WindowDity", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func openPreferences() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
