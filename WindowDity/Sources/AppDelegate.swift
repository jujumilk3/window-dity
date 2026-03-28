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
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(store: layoutStore)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "WindowDity Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        preferencesWindow = window
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
