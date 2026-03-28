import AppKit

final class OverlayView: NSView {
    let layout: Layout
    var isHovered = false { didSet { needsDisplay = true } }

    private let gridInset = NSEdgeInsets(top: 10, left: 10, bottom: 24, right: 10)
    private var trackingArea: NSTrackingArea?

    init(layout: Layout) {
        self.layout = layout
        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 100))
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bgColor: NSColor = isHovered
            ? NSColor.white.withAlphaComponent(0.25)
            : NSColor.black.withAlphaComponent(0.55)
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 10, yRadius: 10)
        bgColor.setFill()
        path.fill()

        if isHovered {
            NSColor.controlAccentColor.withAlphaComponent(0.6).setStroke()
            path.lineWidth = 2
            path.stroke()
        }

        // Grid area
        let gridRect = NSRect(
            x: gridInset.left,
            y: gridInset.bottom,
            width: bounds.width - gridInset.left - gridInset.right,
            height: bounds.height - gridInset.top - gridInset.bottom
        )

        let cellW = gridRect.width / CGFloat(layout.cols)
        let cellH = gridRect.height / CGFloat(layout.rows)

        for row in 0..<layout.rows {
            for col in 0..<layout.cols {
                let cellRect = NSRect(
                    x: gridRect.origin.x + CGFloat(col) * cellW,
                    y: gridRect.origin.y + gridRect.height - CGFloat(row + 1) * cellH,
                    width: cellW,
                    height: cellH
                ).insetBy(dx: 1.5, dy: 1.5)

                let cellPath = NSBezierPath(roundedRect: cellRect, xRadius: 2, yRadius: 2)

                if layout.selectedCells.contains(CellIndex(row: row, col: col)) {
                    NSColor.controlAccentColor.withAlphaComponent(0.8).setFill()
                    cellPath.fill()
                } else {
                    NSColor.white.withAlphaComponent(0.15).setFill()
                    cellPath.fill()
                    NSColor.white.withAlphaComponent(0.3).setStroke()
                    cellPath.lineWidth = 0.5
                    cellPath.stroke()
                }
            }
        }

        // Layout name label
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
        ]
        let name = layout.name as NSString
        let nameSize = name.size(withAttributes: attrs)
        let namePoint = NSPoint(
            x: (bounds.width - nameSize.width) / 2,
            y: (gridInset.bottom - nameSize.height) / 2
        )
        name.draw(at: namePoint, withAttributes: attrs)
    }
}
