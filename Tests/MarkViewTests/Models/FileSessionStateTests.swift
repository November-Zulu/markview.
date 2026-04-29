import XCTest
@testable import MarkView

final class FileSessionStateTests: XCTestCase {

    // MARK: - Tracer

    func testDefaults() {
        let session = FileSessionState()

        XCTAssertEqual(session.splitRatio, 0.5)
        XCTAssertTrue(session.isSyntaxHighlightingEnabled)
        XCTAssertFalse(session.isRendererCollapsed)
        XCTAssertFalse(session.isEditorLightModeEnabled)
        XCTAssertFalse(session.isScrollLockEnabled)
        XCTAssertFalse(session.isPreviewLightModeEnabled)
        XCTAssertFalse(session.isLinterPaneVisible)
        XCTAssertFalse(session.isLineNumbersEnabled)
    }

    // MARK: - setSplitRatio

    func testSetSplitRatioClampsBelowFloor() {
        var session = FileSessionState()

        session.setSplitRatio(0.0)

        XCTAssertEqual(session.splitRatio, FileSessionState.minSplitRatio)
    }

    func testSetSplitRatioClampsAboveCeiling() {
        var session = FileSessionState()

        session.setSplitRatio(0.9)

        XCTAssertEqual(session.splitRatio, FileSessionState.maxSplitRatio)
    }

    func testSetSplitRatioAcceptsInRangeValue() {
        var session = FileSessionState()

        session.setSplitRatio(0.6)

        XCTAssertEqual(session.splitRatio, 0.6, accuracy: 0.0001)
    }

    // MARK: - Linter pane

    func testToggleLinterPaneFlipsState() {
        var session = FileSessionState()
        XCTAssertFalse(session.isLinterPaneVisible)

        session.toggleLinterPane()
        XCTAssertTrue(session.isLinterPaneVisible)

        session.toggleLinterPane()
        XCTAssertFalse(session.isLinterPaneVisible)
    }

    func testSetLinterPaneVisibleFalseClosesRegardlessOfPriorState() {
        var session = FileSessionState()
        session.toggleLinterPane()
        XCTAssertTrue(session.isLinterPaneVisible)

        session.setLinterPaneVisible(false)

        XCTAssertFalse(session.isLinterPaneVisible)

        // Idempotent — calling again on a closed pane keeps it closed.
        session.setLinterPaneVisible(false)
        XCTAssertFalse(session.isLinterPaneVisible)
    }
}
