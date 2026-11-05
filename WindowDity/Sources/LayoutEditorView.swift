import SwiftUI

struct LayoutEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var rows: Int
    @State private var cols: Int
    @State private var selectedCells: Set<CellIndex>

    private let layoutID: UUID
    private let onSave: (Layout) -> Void

    init(layout: Layout, onSave: @escaping (Layout) -> Void) {
        self.layoutID = layout.id
        self.onSave = onSave
        _name = State(initialValue: layout.name)
        _rows = State(initialValue: layout.rows)
        _cols = State(initialValue: layout.cols)
        _selectedCells = State(initialValue: layout.selectedCells)
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Layout Name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 20) {
                Picker("Rows", selection: $rows) {
                    ForEach(1...6, id: \.self) { Text("\($0)").tag($0) }
                }
                .frame(width: 120)
                .onChange(of: rows) { _ in pruneSelection() }

                Picker("Cols", selection: $cols) {
                    ForEach(1...6, id: \.self) { Text("\($0)").tag($0) }
                }
                .frame(width: 120)
                .onChange(of: cols) { _ in pruneSelection() }
            }

            // Interactive grid — a fixed 16:9 screen sliced into rows x cols,
            // so cells keep the proportions they will have on a real monitor.
            // Drag to select a rectangular region.
            let gridW = Self.gridWidth
            let gridH = Self.gridHeight
            let cellW = gridW / CGFloat(cols)
            let cellH = gridH / CGFloat(rows)

            ZStack(alignment: .topLeading) {
                // Grid cells
                VStack(spacing: 0) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<cols, id: \.self) { col in
                                let idx = CellIndex(row: row, col: col)
                                let selected = selectedCells.contains(idx)
                                Rectangle()
                                    .fill(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .border(Color.secondary.opacity(0.4), width: 0.5)
                                    .frame(width: cellW, height: cellH)
                            }
                        }
                    }
                }

                // Drag overlay to capture gesture
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                let startCell = cellAt(value.startLocation, cellW: cellW, cellH: cellH)
                                let endCell = cellAt(value.location, cellW: cellW, cellH: cellH)
                                selectedCells = cellsInRect(from: startCell, to: endCell)
                            }
                    )
            }
            .frame(width: gridW, height: gridH)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.6), lineWidth: 1)
            )

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    onSave(currentLayout)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCells.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    /// Editor grid size: 16:9, the common monitor aspect ratio.
    static let gridWidth: CGFloat = 320
    static let gridHeight: CGFloat = gridWidth * 9 / 16

    private var currentLayout: Layout {
        Layout(id: layoutID, name: name, rows: rows, cols: cols, selectedCells: selectedCells)
    }

    private func pruneSelection() {
        selectedCells = selectedCells.filter { $0.row < rows && $0.col < cols }
    }

    private func cellAt(_ point: CGPoint, cellW: CGFloat, cellH: CGFloat) -> CellIndex {
        let col = max(0, min(cols - 1, Int(point.x / cellW)))
        let row = max(0, min(rows - 1, Int(point.y / cellH)))
        return CellIndex(row: row, col: col)
    }

    private func cellsInRect(from a: CellIndex, to b: CellIndex) -> Set<CellIndex> {
        let minRow = min(a.row, b.row)
        let maxRow = max(a.row, b.row)
        let minCol = min(a.col, b.col)
        let maxCol = max(a.col, b.col)
        var cells = Set<CellIndex>()
        for r in minRow...maxRow {
            for c in minCol...maxCol {
                cells.insert(CellIndex(row: r, col: c))
            }
        }
        return cells
    }
}
