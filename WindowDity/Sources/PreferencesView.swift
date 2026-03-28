import SwiftUI

struct LayoutGridPreview: View {
    let layout: Layout
    let size: CGFloat

    var body: some View {
        let cellW = size / CGFloat(layout.cols)
        let cellH = size / CGFloat(layout.rows)

        Canvas { context, _ in
            for row in 0..<layout.rows {
                for col in 0..<layout.cols {
                    let rect = CGRect(
                        x: CGFloat(col) * cellW,
                        y: CGFloat(row) * cellH,
                        width: cellW,
                        height: cellH
                    )
                    let isSelected = layout.selectedCells.contains(CellIndex(row: row, col: col))
                    if isSelected {
                        context.fill(Path(rect.insetBy(dx: 1, dy: 1)),
                                     with: .color(.accentColor))
                    }
                    context.stroke(Path(rect.insetBy(dx: 0.5, dy: 0.5)),
                                   with: .color(.secondary.opacity(0.5)),
                                   lineWidth: 1)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct PreferencesView: View {
    @ObservedObject var store: LayoutStore
    @State private var selection: UUID?
    @State private var editingLayout: Layout?

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(store.layouts) { layout in
                    HStack(spacing: 12) {
                        LayoutGridPreview(layout: layout, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(layout.name)
                                .fontWeight(.medium)
                            Text("\(layout.rows) \u{00d7} \(layout.cols) grid")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .tag(layout.id)
                    .onTapGesture(count: 2) {
                        editingLayout = layout
                    }
                }
                .onMove { source, destination in
                    store.move(from: source, to: destination)
                }
                .onDelete { offsets in
                    store.remove(at: offsets)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            HStack {
                Button(action: addLayout) {
                    Image(systemName: "plus")
                }
                Button(action: removeSelected) {
                    Image(systemName: "minus")
                }
                .disabled(selection == nil)

                Spacer()

                Button("Edit") {
                    guard let sel = selection,
                          let layout = store.layouts.first(where: { $0.id == sel }) else { return }
                    editingLayout = layout
                }
                .disabled(selection == nil)
            }
            .padding(8)
        }
        .frame(width: 400, height: 350)
        .sheet(item: $editingLayout) { layout in
            LayoutEditorView(layout: layout) { updated in
                store.update(updated)
            }
        }
    }

    private func addLayout() {
        let layout = Layout(
            id: UUID(),
            name: "New Layout",
            rows: 2, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 0)]
        )
        store.add(layout)
        selection = layout.id
        editingLayout = layout
    }

    private func removeSelected() {
        guard let sel = selection else { return }
        store.remove(id: sel)
        selection = nil
    }
}
