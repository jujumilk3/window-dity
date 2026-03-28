import AppKit
import ApplicationServices

final class WindowManager {
    static let shared = WindowManager()
    private init() {}

    /// Prompt for accessibility permission if not already granted.
    func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Get the AXUIElement for the currently focused window.
    func getFocusedWindow() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppValue: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedAppValue) == .success else {
            return nil
        }
        let focusedApp = focusedAppValue as! AXUIElement

        var focusedWindowValue: AnyObject?
        guard AXUIElementCopyAttributeValue(focusedApp, kAXFocusedWindowAttribute as CFString, &focusedWindowValue) == .success else {
            return nil
        }
        return (focusedWindowValue as! AXUIElement)
    }

    /// Move and resize the focused window to the given frame (in NSScreen coordinates).
    func moveAndResize(to frame: CGRect) {
        guard let window = getFocusedWindow() else { return }
        let axFrame = convertToAXCoordinates(frame)

        var position = CGPoint(x: axFrame.origin.x, y: axFrame.origin.y)
        if let posValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }

        var size = CGSize(width: axFrame.width, height: axFrame.height)
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    /// Convert from NSScreen coordinates (bottom-left origin) to AX coordinates (top-left origin).
    func convertToAXCoordinates(_ frame: CGRect) -> CGRect {
        guard let primaryScreen = NSScreen.screens.first else { return frame }
        let screenHeight = primaryScreen.frame.height
        let axY = screenHeight - frame.origin.y - frame.height
        return CGRect(x: frame.origin.x, y: axY, width: frame.width, height: frame.height)
    }
}
