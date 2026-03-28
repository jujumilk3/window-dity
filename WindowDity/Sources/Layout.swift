import Foundation
import CoreGraphics

struct CellIndex: Codable, Hashable {
    let row: Int
    let col: Int
}

struct Layout: Codable, Identifiable {
    var id: UUID
    var name: String
    var rows: Int
    var cols: Int
    var selectedCells: Set<CellIndex>

    var gridDescription: String {
        guard !selectedCells.isEmpty else {
            return "\(rows) x \(cols) grid"
        }
        let minRow = selectedCells.map(\.row).min()! + 1
        let maxRow = selectedCells.map(\.row).max()! + 1
        let minCol = selectedCells.map(\.col).min()! + 1
        let maxCol = selectedCells.map(\.col).max()! + 1
        return "\(rows) x \(cols) grid, from (\(minRow), \(minCol)) to (\(maxRow), \(maxCol))"
    }

    func frame(for screenFrame: CGRect) -> CGRect {
        guard !selectedCells.isEmpty else { return screenFrame }

        let minRow = selectedCells.map(\.row).min()!
        let maxRow = selectedCells.map(\.row).max()!
        let minCol = selectedCells.map(\.col).min()!
        let maxCol = selectedCells.map(\.col).max()!

        let cellWidth = screenFrame.width / CGFloat(cols)
        let cellHeight = screenFrame.height / CGFloat(rows)

        let x = screenFrame.origin.x + CGFloat(minCol) * cellWidth
        let y = screenFrame.origin.y + CGFloat(minRow) * cellHeight
        let w = CGFloat(maxCol - minCol + 1) * cellWidth
        let h = CGFloat(maxRow - minRow + 1) * cellHeight

        return CGRect(x: x, y: y, width: w, height: h)
    }

    static let defaults: [Layout] = [
        Layout(
            id: UUID(),
            name: "Left Half",
            rows: 1, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 0)]
        ),
        Layout(
            id: UUID(),
            name: "Right Half",
            rows: 1, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 1)]
        ),
        Layout(
            id: UUID(),
            name: "Centre",
            rows: 1, cols: 4,
            selectedCells: [CellIndex(row: 0, col: 1), CellIndex(row: 0, col: 2)]
        ),
        Layout(
            id: UUID(),
            name: "Full Screen",
            rows: 1, cols: 1,
            selectedCells: [CellIndex(row: 0, col: 0)]
        ),
    ]
}
