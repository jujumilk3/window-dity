import SwiftUI

struct LayoutGridPreview: View {
    let layout: Layout
    var width: CGFloat = 60
    var height: CGFloat = 40

    var body: some View {
        let cellW = width / CGFloat(layout.cols)
        let cellH = height / CGFloat(layout.rows)

        Canvas { context, _ in
            // Fill entire background with a subtle base
            let bg = CGRect(x: 0, y: 0, width: width, height: height)
            context.fill(Path(bg), with: .color(Color.accentColor.opacity(0.15)))

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
                                   with: .color(.secondary.opacity(0.4)),
                                   lineWidth: 1)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct PreferencesView: View {
    @ObservedObject var store: LayoutStore
    @State private var selection: UUID?
    @State private var editingLayout: Layout?
    @State private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                layoutsTab
                    .tabItem { Text("Layouts") }

                optionsTab
                    .tabItem { Text("Options") }
            }

            Divider()

            // Bottom bar
            HStack {
                Toggle("Launch WindowDity at login", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)

                Spacer()

                Button("Done") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 440, height: 400)
        .sheet(item: $editingLayout) { layout in
            LayoutEditorView(layout: layout) { updated in
                store.update(updated)
            }
        }
    }

    // MARK: - Layouts Tab

    private var layoutsTab: some View {
        VStack(spacing: 0) {
            Text("Drag layouts in this list to change their order. Double click a layout to edit its settings.")
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)

            List(selection: $selection) {
                ForEach(store.layouts) { layout in
                    HStack(spacing: 12) {
                        LayoutGridPreview(layout: layout, width: 60, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(layout.name)
                                .fontWeight(.bold)
                            Text(layout.gridDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("All Screens")
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

            HStack(spacing: 4) {
                Button(action: addLayout) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)

                Button(action: removeSelected) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(selection == nil)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Options Tab

    private var optionsTab: some View {
        Form {
            Text("General options will appear here.")
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Actions

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
