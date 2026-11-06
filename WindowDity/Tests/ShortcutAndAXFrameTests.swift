import XCTest
@testable import WindowDity

final class ShortcutAndAXFrameTests: XCTestCase {

    // MARK: - axFrame(inVisibleFrame:primaryScreenHeight:)

    // 1920x1080 primary screen, 25pt menu bar at the top, no Dock.
    private let primaryHeight: CGFloat = 1080
    private let visible = CGRect(x: 0, y: 0, width: 1920, height: 1055)

    func testTopRowLandsAtTopOfScreen() {
        let topHalf = Layout(id: UUID(), name: "Top", rows: 2, cols: 1,
                             selectedCells: [CellIndex(row: 0, col: 0)])
        let f = topHalf.axFrame(inVisibleFrame: visible, primaryScreenHeight: primaryHeight)
        XCTAssertEqual(f, CGRect(x: 0, y: 25, width: 1920, height: 527.5))
    }

    func testBottomRowLandsAtBottomOfScreen() {
        let bottomHalf = Layout(id: UUID(), name: "Bottom", rows: 2, cols: 1,
                                selectedCells: [CellIndex(row: 1, col: 0)])
        let f = bottomHalf.axFrame(inVisibleFrame: visible, primaryScreenHeight: primaryHeight)
        XCTAssertEqual(f, CGRect(x: 0, y: 552.5, width: 1920, height: 527.5))
    }

    func testSecondaryScreenBelowPrimary() {
        // Cocoa frame of a 1280x800 screen placed right of and lower than primary.
        let secondary = CGRect(x: 1920, y: -200, width: 1280, height: 800)
        let topRow = Layout(id: UUID(), name: "Top", rows: 4, cols: 1,
                            selectedCells: [CellIndex(row: 0, col: 0)])
        let f = topRow.axFrame(inVisibleFrame: secondary, primaryScreenHeight: primaryHeight)
        XCTAssertEqual(f, CGRect(x: 1920, y: 480, width: 1280, height: 200))
    }
}
