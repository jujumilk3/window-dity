import AppKit

final class OverlayView: NSView {
    let layouts: [Layout]
    private let gridRows: Int
    private let gridCols: Int
    var hoveredLayout: Layout? { didSet { needsDisplay = true } }
    var isHovered: Bool { hoveredLayout != nil }

    private let gridInset = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)

    init(layouts: [Layout]) {
        self.layouts = layouts
        self.gridRows = layouts.first?.rows ?? 1
        self.gridCols = layouts.first?.cols ?? 1
        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 100))
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Returns which layout the given point (in screen coords) falls on,
    /// or nil if outside any selected region.
    func layoutAt(screenPoint: NSPoint, windowFrame: NSRect) -> Layout? {
        let localX = screenPoint.x - windowFrame.origin.x
        let localY = screenPoint.y - windowFrame.origin.y

        let gridRect = self.gridRect
        guard gridRect.contains(NSPoint(x: localX, y: localY)) else { return nil }

        let cellW = gridRect.width / CGFloat(gridCols)
        let cellH = gridRect.height / CGFloat(gridRows)

        let col = Int((localX - gridRect.origin.x) / cellW)
        let row = gridRows - 1 - Int((localY - gridRect.origin.y) / cellH) // flip Y

        let cell = CellIndex(row: row, col: col)
        return layouts.first { $0.selectedCells.contains(cell) }
    }

    private var gridRect: NSRect {
        NSRect(
            x: gridInset.left,
            y: gridInset.bottom,
            width: bounds.width - gridInset.left - gridInset.right,
            height: bounds.height - gridInset.top - gridInset.bottom
        )
    }

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

        let gr = gridRect
        let cellW = gr.width / CGFloat(gridCols)
        let cellH = gr.height / CGFloat(gridRows)

        // Draw screen background
        let screenBg = NSBezierPath(roundedRect: gr.insetBy(dx: 1, dy: 1), xRadius: 3, yRadius: 3)
        NSColor.white.withAlphaComponent(0.1).setFill()
        screenBg.fill()
        NSColor.white.withAlphaComponent(0.3).setStroke()
        screenBg.lineWidth = 0.5
        screenBg.stroke()

        // Draw each layout's region as a filled block
        for layout in layouts {
            guard !layout.selectedCells.isEmpty else { continue }

            let minRow = layout.selectedCells.map(\.row).min()!
            let maxRow = layout.selectedCells.map(\.row).max()!
            let minCol = layout.selectedCells.map(\.col).min()!
            let maxCol = layout.selectedCells.map(\.col).max()!

            let blockRect = NSRect(
                x: gr.origin.x + CGFloat(minCol) * cellW + 2,
                y: gr.origin.y + gr.height - CGFloat(maxRow + 1) * cellH + 2,
                width: CGFloat(maxCol - minCol + 1) * cellW - 4,
                height: CGFloat(maxRow - minRow + 1) * cellH - 4
            )

            let isThis = hoveredLayout?.id == layout.id
            let fillAlpha: CGFloat = isThis ? 0.9 : 0.5
            let blockPath = NSBezierPath(roundedRect: blockRect, xRadius: 3, yRadius: 3)
            NSColor.controlAccentColor.withAlphaComponent(fillAlpha).setFill()
            blockPath.fill()

            if isThis {
                NSColor.white.withAlphaComponent(0.8).setStroke()
                blockPath.lineWidth = 2
                blockPath.stroke()
            }
        }
    }
}
