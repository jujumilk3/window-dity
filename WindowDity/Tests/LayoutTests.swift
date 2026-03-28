import XCTest
@testable import WindowDity

final class LayoutTests: XCTestCase {

    // MARK: - frame(for:)

    func testLeftHalfFrame() {
        let layout = Layout(
            id: UUID(), name: "Left Half",
            rows: 1, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 0)]
        )
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 1080)
    }

    func testRightHalfFrame() {
        let layout = Layout(
            id: UUID(), name: "Right Half",
            rows: 1, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 1)]
        )
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame.origin.x, 960)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 1080)
    }

    func testFullScreenFrame() {
        let layout = Layout(
            id: UUID(), name: "Full Screen",
            rows: 1, cols: 1,
            selectedCells: [CellIndex(row: 0, col: 0)]
        )
        let screen = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame, screen)
    }

    func testQuarterFrame() {
        let layout = Layout(
            id: UUID(), name: "Top-Left Quarter",
            rows: 2, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 0)]
        )
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 540)
    }

    func testMultiCellSelection() {
        // Select top-left 2x2 block in a 3x3 grid
        let layout = Layout(
            id: UUID(), name: "Top-Left Block",
            rows: 3, cols: 3,
            selectedCells: [
                CellIndex(row: 0, col: 0), CellIndex(row: 0, col: 1),
                CellIndex(row: 1, col: 0), CellIndex(row: 1, col: 1)
            ]
        )
        let screen = CGRect(x: 0, y: 0, width: 1800, height: 1200)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 0)
        XCTAssertEqual(frame.width, 1200)  // 2/3 of 1800
        XCTAssertEqual(frame.height, 800)  // 2/3 of 1200
    }

    func testCentreLayout() {
        // Centre: 1x4 grid, cols 1 and 2 selected (middle half)
        let layout = Layout(
            id: UUID(), name: "Centre",
            rows: 1, cols: 4,
            selectedCells: [CellIndex(row: 0, col: 1), CellIndex(row: 0, col: 2)]
        )
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame.origin.x, 480)  // 1/4 of 1920
        XCTAssertEqual(frame.width, 960)     // 2/4 of 1920
        XCTAssertEqual(frame.height, 1080)
    }

    func testScreenWithOffset() {
        let layout = Layout(
            id: UUID(), name: "Left Half",
            rows: 1, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 0)]
        )
        // Screen with menu bar offset
        let screen = CGRect(x: 0, y: 25, width: 1920, height: 1055)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 25)
        XCTAssertEqual(frame.width, 960)
        XCTAssertEqual(frame.height, 1055)
    }

    func testEmptyCellsReturnsFullScreen() {
        let layout = Layout(
            id: UUID(), name: "Empty",
            rows: 2, cols: 2,
            selectedCells: []
        )
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = layout.frame(for: screen)

        XCTAssertEqual(frame, screen)
    }

    // MARK: - gridDescription

    func testGridDescriptionWithCells() {
        let layout = Layout(
            id: UUID(), name: "Test",
            rows: 2, cols: 4,
            selectedCells: [CellIndex(row: 0, col: 1), CellIndex(row: 1, col: 2)]
        )
        XCTAssertEqual(layout.gridDescription, "2 x 4 grid, from (1, 2) to (2, 3)")
    }

    func testGridDescriptionEmpty() {
        let layout = Layout(
            id: UUID(), name: "Test",
            rows: 3, cols: 3,
            selectedCells: []
        )
        XCTAssertEqual(layout.gridDescription, "3 x 3 grid")
    }

    func testGridDescriptionSingleCell() {
        let layout = Layout(
            id: UUID(), name: "Test",
            rows: 2, cols: 2,
            selectedCells: [CellIndex(row: 0, col: 0)]
        )
        XCTAssertEqual(layout.gridDescription, "2 x 2 grid, from (1, 1) to (1, 1)")
    }

    // MARK: - Codable

    func testLayoutEncodeDecode() throws {
        let original = Layout(
            id: UUID(), name: "Test Layout",
            rows: 3, cols: 4,
            selectedCells: [CellIndex(row: 0, col: 0), CellIndex(row: 1, col: 1)]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Layout.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.rows, original.rows)
        XCTAssertEqual(decoded.cols, original.cols)
        XCTAssertEqual(decoded.selectedCells, original.selectedCells)
    }

    func testLayoutArrayEncodeDecode() throws {
        let layouts = Layout.defaults
        let data = try JSONEncoder().encode(layouts)
        let decoded = try JSONDecoder().decode([Layout].self, from: data)

        XCTAssertEqual(decoded.count, layouts.count)
        for (a, b) in zip(layouts, decoded) {
            XCTAssertEqual(a.name, b.name)
            XCTAssertEqual(a.rows, b.rows)
            XCTAssertEqual(a.cols, b.cols)
            XCTAssertEqual(a.selectedCells, b.selectedCells)
        }
    }

    // MARK: - Defaults

    func testDefaultLayoutsExist() {
        let defaults = Layout.defaults
        XCTAssertEqual(defaults.count, 4)
        XCTAssertEqual(defaults[0].name, "Left Half")
        XCTAssertEqual(defaults[1].name, "Right Half")
        XCTAssertEqual(defaults[2].name, "Centre")
        XCTAssertEqual(defaults[3].name, "Full Screen")
    }
}
