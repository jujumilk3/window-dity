import AppKit
import ApplicationServices

protocol DragDetectorDelegate: AnyObject {
    func dragDidStart(windowRef: AXUIElement, mouseLocation: NSPoint)
    func dragDidMove(mouseLocation: NSPoint)
    func dragDidEnd(mouseLocation: NSPoint)
}

final class DragDetector {
    weak var delegate: DragDetectorDelegate?

    private var monitor: Any?
    private var capturedWindow: AXUIElement?
    private var initialWindowPosition: CGPoint?
    private var isDragging = false

    // The focused window must shift at least this much (points) for the gesture
    // to count as a window drag. Content drags — text selection, rubber-band
    // select, sliders, drag-and-drop — never move the window, so they're ignored.
    private let windowMoveThreshold: CGFloat = 3.0

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            self?.handleEvent(event)
        }
    }

    func stop() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
        reset()
    }

    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            handleMouseDown()
        case .leftMouseDragged:
            handleMouseDragged()
        case .leftMouseUp:
            handleMouseUp()
        default:
            break
        }
    }

    private func handleMouseDown() {
        // Capture the window and its position NOW, before the drag begins —
        // afterwards the frontmost app may change.
        capturedWindow = captureActiveWindow()
        initialWindowPosition = capturedWindow.flatMap(windowPosition)
        isDragging = false
    }

    private func handleMouseDragged() {
        if isDragging {
            delegate?.dragDidMove(mouseLocation: NSEvent.mouseLocation)
            return
        }
        guard let windowRef = capturedWindow,
              let initialPos = initialWindowPosition,
              let pos = windowPosition(windowRef) else { return }

        // Dragging a title bar moves the window's AX position; dragging content
        // leaves it put. Start the overlay the moment the window actually moves.
        let windowMoved = hypot(pos.x - initialPos.x, pos.y - initialPos.y)
        guard windowMoved >= windowMoveThreshold else { return }

        isDragging = true
        delegate?.dragDidStart(windowRef: windowRef, mouseLocation: NSEvent.mouseLocation)
        delegate?.dragDidMove(mouseLocation: NSEvent.mouseLocation)
    }

    private func handleMouseUp() {
        if isDragging {
            delegate?.dragDidEnd(mouseLocation: NSEvent.mouseLocation)
        }
        reset()
    }

    private func reset() {
        capturedWindow = nil
        initialWindowPosition = nil
        isDragging = false
    }

    private func captureActiveWindow() -> AXUIElement? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return nil
        }
        let appRef = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            appRef, kAXFocusedWindowAttribute as CFString, &value
        )
        guard err == .success, let value else { return nil }
        // AXUIElement is a CFTypeRef typedef — cast is always valid after success check
        return (value as! AXUIElement)
    }

    private func windowPosition(_ window: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &value) == .success,
              let value else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(value as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }
}
