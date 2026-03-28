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
    private var mouseDownLocation: NSPoint?
    private var isDragging = false
    private let dragThreshold: CGFloat = 10.0

    func start() {
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
        mouseDownLocation = NSEvent.mouseLocation
        // CRITICAL: capture window ref NOW, before drag begins.
        // After drag starts the frontmost app may change.
        capturedWindow = captureActiveWindow()
        isDragging = false
    }

    private func handleMouseDragged() {
        guard let start = mouseDownLocation,
              let windowRef = capturedWindow else { return }

        let current = NSEvent.mouseLocation
        let dx = current.x - start.x
        let dy = current.y - start.y
        let distance = sqrt(dx * dx + dy * dy)

        if !isDragging && distance >= dragThreshold {
            isDragging = true
            delegate?.dragDidStart(windowRef: windowRef, mouseLocation: current)
        }

        if isDragging {
            delegate?.dragDidMove(mouseLocation: current)
        }
    }

    private func handleMouseUp() {
        if isDragging {
            delegate?.dragDidEnd(mouseLocation: NSEvent.mouseLocation)
        }
        reset()
    }

    private func reset() {
        mouseDownLocation = nil
        capturedWindow = nil
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
        guard err == .success else { return nil }
        return (value as! AXUIElement)
    }
}
