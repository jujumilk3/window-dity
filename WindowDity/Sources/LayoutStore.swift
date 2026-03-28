import Foundation
import Combine

final class LayoutStore: ObservableObject {
    private static let key = "layouts"

    @Published var layouts: [Layout] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([Layout].self, from: data) {
            self.layouts = decoded
        } else {
            self.layouts = Layout.defaults
        }
    }

    func add(_ layout: Layout) {
        layouts.append(layout)
    }

    func remove(at offsets: IndexSet) {
        layouts.remove(atOffsets: offsets)
    }

    func remove(id: UUID) {
        layouts.removeAll { $0.id == id }
    }

    func move(from source: IndexSet, to destination: Int) {
        layouts.move(fromOffsets: source, toOffset: destination)
    }

    func update(_ layout: Layout) {
        guard let idx = layouts.firstIndex(where: { $0.id == layout.id }) else { return }
        layouts[idx] = layout
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(layouts) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
