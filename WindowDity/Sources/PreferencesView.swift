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

struct ScreenPositionPreview: View {
    @Binding var positionY: Double
    var isHorizontal: Bool

    private let previewWidth: CGFloat = 280
    private let previewHeight: CGFloat = 160
    private var stripWidth: CGFloat { isHorizontal ? 80 : 24 }
    private var stripHeight: CGFloat { isHorizontal ? 24 : 80 }

    var body: some View {
        let maxOffsetY = previewHeight - stripHeight
        let stripY = min(max(positionY, 0), 1) * maxOffsetY

        HStack(spacing: 12) {
            // Screen preview with strip indicator
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Strip thumbnail centered horizontally, positioned by slider
                stripThumbnail
                    .offset(x: (previewWidth - stripWidth) / 2, y: stripY)
            }
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Vertical slider — rotated so top=0, bottom=1
            Slider(value: Binding(
                get: { 1.0 - positionY },
                set: { positionY = 1.0 - $0 }
            ), in: 0...1)
                .rotationEffect(.degrees(-90))
                .frame(width: previewHeight, height: 20)
                .frame(width: 20, height: previewHeight)
                .tint(.clear)
        }
    }

    private var stripThumbnail: some View {
        let layout = isHorizontal ? AnyLayout(HStackLayout(spacing: 3)) : AnyLayout(VStackLayout(spacing: 3))
        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.25))
                .frame(width: stripWidth, height: stripHeight)
            layout {
                ForEach(0..<3, id: \.self) { _ in
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
    var overlayManager: OverlayManager?
    @State private var selection: UUID?
    @State private var editingLayout: Layout?
    @State private var launchAtLogin = false
    @AppStorage("overlayOrientation") private var overlayOrientation: String = "horizontal"
    @AppStorage("overlayPositionY") private var overlayPositionY: Double = 0.5
    @AppStorage("overlayWidthPercent") private var overlayWidthPercent: Double = 30

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                layoutsTab
                    .tabItem { Text("Layouts") }

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
        .frame(width: 440, height: 520)
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

    // MARK: - Positioning Tab

    private var positioningTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Orientation section
            VStack(alignment: .leading, spacing: 8) {
                Text("Orientation")
                    .font(.headline)

                Text("Layout Icons can be arranged across or down the screen.")
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

                ScreenPositionPreview(
                    positionY: $overlayPositionY,
                    isHorizontal: overlayOrientation == "horizontal"
                )
            }

            // Strip size section
            VStack(alignment: .leading, spacing: 8) {
                Text("Strip size")
                    .font(.headline)

                HStack {
                    Text("Width")
                    Slider(value: $overlayWidthPercent, in: 10...100, step: 5)
                    Text("\(Int(overlayWidthPercent))%")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
                .frame(maxWidth: 312)
            }

            Spacer()
        }
        .padding(16)
        .onAppear { overlayManager?.show() }
        .onDisappear { overlayManager?.hide() }
        .onChange(of: overlayPositionY) { _ in overlayManager?.show() }
        .onChange(of: overlayOrientation) { _ in overlayManager?.show() }
        .onChange(of: overlayWidthPercent) { _ in overlayManager?.show() }
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
