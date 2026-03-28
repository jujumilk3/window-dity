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

            // Interactive grid
            let cellSize: CGFloat = 50
            let gridW = CGFloat(cols) * cellSize
            let gridH = CGFloat(rows) * cellSize

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
                                .onTapGesture {
                                    if selected {
                                        selectedCells.remove(idx)
                                    } else {
                                        selectedCells.insert(idx)
                                    }
                                }
                        }
                    }
                }
            }
            .frame(width: gridW, height: gridH)
            .border(Color.secondary.opacity(0.6), width: 1)

            // Preview
            LayoutGridPreview(layout: currentLayout, size: 80)
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
        .frame(width: 360, height: 440)
    }

    private var currentLayout: Layout {
        Layout(id: layoutID, name: name, rows: rows, cols: cols, selectedCells: selectedCells)
    }

    private func pruneSelection() {
        selectedCells = selectedCells.filter { $0.row < rows && $0.col < cols }
    }
}
