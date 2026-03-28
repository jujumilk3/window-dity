import AppKit
import SwiftUI
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate, DragDetectorDelegate {
    private var statusItem: NSStatusItem!
    private let layoutStore = LayoutStore()
    private var dragDetector: DragDetector!
    private var overlayManager: OverlayManager!
    private var capturedWindowRef: AXUIElement?
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !WindowManager.hasAccessibilityPermission {
            WindowManager.requestAccessibilityPermission()
        }

        setupStatusItem()

        overlayManager = OverlayManager(store: layoutStore)

        dragDetector = DragDetector()
        dragDetector.delegate = self
        dragDetector.start()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.split.2x2",
                accessibilityDescription: "WindowDity"
            )
        }

        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About WindowDity",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit WindowDity",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
    }

    @objc private func openPreferences() {
        // Stop drag detection so it doesn't interfere with Preferences clicks
        dragDetector.stop()

        // Temporarily become a regular app so the window can receive focus
        NSApp.setActivationPolicy(.regular)

        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(store: layoutStore, overlayManager: overlayManager)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "WindowDity Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // When window closes, resume drag detection and go back to accessory mode
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            NSApp.setActivationPolicy(.accessory)
            self?.preferencesWindow = nil
            self?.dragDetector.start()
        }

        preferencesWindow = window
    }

    @objc private func showAbout() {
        let credits = NSAttributedString(
            string: "A Window Tidy-inspired window manager.\nBuilt with looprinter.\n\nhttps://github.com/jujumilk3/window-dity",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "WindowDity",
            .applicationVersion: "1.0",
            .version: "1",
            .credits: credits
        ]
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    // MARK: - DragDetectorDelegate

    func dragDidStart(windowRef: AXUIElement, mouseLocation: NSPoint) {
        capturedWindowRef = windowRef
        overlayManager.show()
    }

    func dragDidMove(mouseLocation: NSPoint) {
        overlayManager.updateHover(at: mouseLocation)
    }

    func dragDidEnd(mouseLocation: NSPoint) {
        defer {
            overlayManager.hide()
            capturedWindowRef = nil
        }

        guard let windowRef = capturedWindowRef,
              let layout = overlayManager.layoutUnderMouse(at: mouseLocation),
              let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let layoutFrame = layout.frame(for: screenFrame)

        // Convert from NSScreen coords (origin bottom-left) to AX coords (origin top-left)
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let axFrame = CGRect(
            x: layoutFrame.origin.x,
            y: primaryHeight - layoutFrame.origin.y - layoutFrame.height,
            width: layoutFrame.width,
            height: layoutFrame.height
        )

        WindowManager.move(windowRef, to: axFrame)
    }
}
