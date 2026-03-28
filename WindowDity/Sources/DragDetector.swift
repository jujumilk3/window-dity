import AppKit

final class DragDetector {
    var onDragStarted: (() -> Void)?
    var onDragMoved: ((NSPoint) -> Void)?
    var onDragEnded: ((NSPoint) -> Void)?

    private var dragMonitor: Any?
    private var mouseUpMonitor: Any?
    private var dragStartPoint: NSPoint?
    private var isDragging = false

    private let dragThreshold: CGFloat = 10.0

    func start() {
        stop()

        dragMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged]
        ) { [weak self] event in
            self?.handleEvent(event)
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .leftMouseUp
        ) { [weak self] event in
            self?.handleMouseUp(event)
        }
    }

    func stop() {
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
            dragMonitor = nil
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
        }
        reset()
    }

    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            dragStartPoint = NSEvent.mouseLocation
            isDragging = false

        case .leftMouseDragged:
            let currentPoint = NSEvent.mouseLocation
            guard let startPoint = dragStartPoint else { return }

            if !isDragging {
                let dx = currentPoint.x - startPoint.x
                let dy = currentPoint.y - startPoint.y
                let distance = sqrt(dx * dx + dy * dy)
                if distance >= dragThreshold {
                    isDragging = true
                    onDragStarted?()
                }
            }

            if isDragging {
                onDragMoved?(currentPoint)
            }

        default:
            break
        }
    }

    private func handleMouseUp(_ event: NSEvent) {
        if isDragging {
            let finalPoint = NSEvent.mouseLocation
            onDragEnded?(finalPoint)
        }
        reset()
    }

    private func reset() {
        dragStartPoint = nil
        isDragging = false
    }

    deinit {
        stop()
    }
}
