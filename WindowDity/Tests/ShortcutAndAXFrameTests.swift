import XCTest
import Carbon.HIToolbox
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

    // MARK: - Codable compatibility

    func testLayoutWithoutShortcutKeyStillDecodes() throws {
        let json = """
        [{"id":"9E2D1B9F-0000-0000-0000-000000000001","name":"Left Half","rows":1,"cols":2,
          "selectedCells":[{"row":0,"col":0}]}]
        """
        let decoded = try JSONDecoder().decode([Layout].self, from: Data(json.utf8))
        XCTAssertEqual(decoded.count, 1)
        XCTAssertNil(decoded[0].shortcut)
    }

    func testShortcutRoundTrips() throws {
        let shortcut = KeyShortcut(keyCode: UInt32(kVK_LeftArrow),
                                   modifiers: UInt32(controlKey | optionKey))
        let layout = Layout(id: UUID(), name: "L", rows: 1, cols: 2,
                            selectedCells: [CellIndex(row: 0, col: 0)], shortcut: shortcut)
        let decoded = try JSONDecoder().decode(Layout.self, from: JSONEncoder().encode(layout))
        XCTAssertEqual(decoded.shortcut, shortcut)
    }

    // MARK: - KeyShortcut

    func testDisplayStringUsesStandardModifierOrder() {
        let s = KeyShortcut(keyCode: UInt32(kVK_LeftArrow),
                            modifiers: UInt32(cmdKey | shiftKey | optionKey | controlKey))
        XCTAssertEqual(s.displayString, "⌃⌥⇧⌘←")
    }

    func testFunctionKeyName() {
        XCTAssertEqual(KeyShortcut(keyCode: UInt32(kVK_F5), modifiers: 0).displayString, "F5")
    }

    func testCarbonModifiersFromEventFlags() {
        let m = KeyShortcut.carbonModifiers(from: [.control, .option])
        XCTAssertEqual(m, UInt32(controlKey | optionKey))
    }

    func testShortcutRequiresCommandLikeModifierUnlessFunctionKey() throws {
        func event(_ keyCode: Int, _ flags: NSEvent.ModifierFlags) throws -> NSEvent {
            try XCTUnwrap(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "",
                isARepeat: false, keyCode: UInt16(keyCode)))
        }
        XCTAssertNil(KeyShortcut(event: try event(kVK_ANSI_A, [])))
        XCTAssertNil(KeyShortcut(event: try event(kVK_ANSI_A, [.shift])))
        XCTAssertNotNil(KeyShortcut(event: try event(kVK_ANSI_A, [.option])))
        XCTAssertNotNil(KeyShortcut(event: try event(kVK_LeftArrow, [.control, .option])))
        XCTAssertNotNil(KeyShortcut(event: try event(kVK_F5, [])))
    }
}
