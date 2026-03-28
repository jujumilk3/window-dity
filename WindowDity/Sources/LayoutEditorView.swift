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

            // Interactive grid — drag to select rectangular region
            let cellSize: CGFloat = 50
            let gridW = CGFloat(cols) * cellSize
            let gridH = CGFloat(rows) * cellSize

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
                                    .frame(width: cellSize, height: cellSize)
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
                                let startCell = cellAt(value.startLocation, cellSize: cellSize)
                                let endCell = cellAt(value.location, cellSize: cellSize)
                                selectedCells = cellsInRect(from: startCell, to: endCell)
                            }
                    )
            }
            .frame(width: gridW, height: gridH)
            .border(Color.secondary.opacity(0.6), width: 1)

            // Screen position preview
            VStack(spacing: 4) {
                Text("Screen Position")
                    .font(.caption)
                    .foregroundColor(.secondary)
                LayoutPositionPreview(layout: currentLayout)
            }
            .padding(.top, 4)

            Spacer()

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
        .frame(width: 360, height: 520)
    }

    private var currentLayout: Layout {
        Layout(id: layoutID, name: name, rows: rows, cols: cols, selectedCells: selectedCells)
    }

    private func pruneSelection() {
        selectedCells = selectedCells.filter { $0.row < rows && $0.col < cols }
    }

    private func cellAt(_ point: CGPoint, cellSize: CGFloat) -> CellIndex {
        let col = max(0, min(cols - 1, Int(point.x / cellSize)))
        let row = max(0, min(rows - 1, Int(point.y / cellSize)))
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

private struct LayoutPositionPreview: View {
    let layout: Layout

    private let previewWidth: CGFloat = 200
    private let previewHeight: CGFloat = 120

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                )

            if !layout.selectedCells.isEmpty {
                let screenRect = CGRect(x: 0, y: 0, width: previewWidth, height: previewHeight)
                let frame = layout.frame(for: screenRect)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
            }
        }
        .frame(width: previewWidth, height: previewHeight)
    }
}
