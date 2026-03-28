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

struct StripPositionPreview: View {
    @Binding var positionX: Double
    @Binding var positionY: Double
    var isHorizontal: Bool

    private let previewWidth: CGFloat = 300
    private let previewHeight: CGFloat = 180

    private var stripWidth: CGFloat { isHorizontal ? 80 : 24 }
    private var stripHeight: CGFloat { isHorizontal ? 24 : 80 }

    var body: some View {
        let clampedX = min(max(positionX, 0), 1)
        let clampedY = min(max(positionY, 0), 1)
        let maxOffsetX = previewWidth - stripWidth
        let maxOffsetY = previewHeight - stripHeight
        let stripX = clampedX * maxOffsetX
        let stripY = clampedY * maxOffsetY

        ZStack(alignment: .topLeading) {
            // Blue gradient screen background
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: previewWidth, height: previewHeight)

            // Draggable strip thumbnail
            stripThumbnail
                .offset(x: stripX, y: stripY)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("screenPreview"))
                        .onChanged { value in
                            let newX = (value.location.x - stripWidth / 2) / maxOffsetX
                            let newY = (value.location.y - stripHeight / 2) / maxOffsetY
                            positionX = min(max(newX, 0), 1)
                            positionY = min(max(newY, 0), 1)
                        }
                )
        }
        .coordinateSpace(name: "screenPreview")
        .frame(width: previewWidth, height: previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var stripThumbnail: some View {
        let iconCount = 3
        let layout = isHorizontal ? AnyLayout(HStackLayout(spacing: 3)) : AnyLayout(VStackLayout(spacing: 3))

        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.25))
                .frame(width: stripWidth, height: stripHeight)

            layout {
                ForEach(0..<iconCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.25))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .frame(width: stripWidth, height: stripHeight)
    }
}

struct PreferencesView: View {
    @ObservedObject var store: LayoutStore
    @State private var selection: UUID?
    @State private var editingLayout: Layout?
    @State private var launchAtLogin = false
    @AppStorage("overlayOrientation") private var overlayOrientation: String = "horizontal"
    @AppStorage("overlayPositionX") private var overlayPositionX: Double = 0.5
    @AppStorage("overlayPositionY") private var overlayPositionY: Double = 0.0
    @AppStorage("overlayMaxWidth") private var overlayMaxWidth: Int = 300
    @AppStorage("overlayMargins") private var overlayMargins: Int = 700

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                layoutsTab
                    .tabItem { Text("Layouts") }

                optionsTab
                    .tabItem { Text("Options") }

                positioningTab
                    .tabItem { Text("Positioning") }
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

    // MARK: - Positioning Tab

    private var positioningTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Orientation section
            VStack(alignment: .leading, spacing: 8) {
                Text("Orientation")
                    .font(.headline)

                Text("Layout Icons can be arranged accross or down the screen.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Picker("", selection: $overlayOrientation) {
                    Text("Arrange Icons horizontally").tag("horizontal")
                    Text("Arrange Icons vertically").tag("vertical")
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            // Screen position section
            VStack(alignment: .leading, spacing: 8) {
                Text("Screen position")
                    .font(.headline)

                StripPositionPreview(
                    positionX: $overlayPositionX,
                    positionY: $overlayPositionY,
                    isHorizontal: overlayOrientation == "horizontal"
                )
            }

            // Dimensions section
            VStack(alignment: .leading, spacing: 8) {
                Text("Dimensions")
                    .font(.headline)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("Maximum Width:")
                        TextField("", value: $overlayMaxWidth, formatter: NumberFormatter())
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 4) {
                        Text("Margins:")
                        TextField("", value: $overlayMargins, formatter: NumberFormatter())
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
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
