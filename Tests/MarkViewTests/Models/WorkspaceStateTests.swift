import XCTest
@testable import MarkView

@MainActor
final class WorkspaceStateTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("markview-workspace-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testOpenFileAddsAndActivates() async throws {
        let url = try writeFile("a.md", "# a")
        let ws = WorkspaceState()

        await ws.openFile(url)

        XCTAssertEqual(ws.openDocuments.count, 1)
        XCTAssertEqual(ws.activeDocumentID, url)
        XCTAssertEqual(ws.activeDocument?.content, "# a")
    }

    func testOpeningSameFileTwiceDoesNotDuplicate() async throws {
        let url = try writeFile("a.md", "# a")
        let other = try writeFile("b.md", "# b")
        let ws = WorkspaceState()

        await ws.openFile(url)
        await ws.openFile(other)
        await ws.openFile(url)

        XCTAssertEqual(ws.openDocuments.count, 2)
        XCTAssertEqual(ws.activeDocumentID, url)
    }

    func testCloseActiveTabActivatesNeighbour() async throws {
        let a = try writeFile("a.md", "a")
        let b = try writeFile("b.md", "b")
        let c = try writeFile("c.md", "c")
        let ws = WorkspaceState()

        await ws.openFile(a)
        await ws.openFile(b)
        await ws.openFile(c)
        // active = c
        ws.activeDocumentID = b
        ws.closeDocument(b)

        XCTAssertEqual(ws.openDocuments.map(\.url), [a, c])
        XCTAssertEqual(ws.activeDocumentID, c) // next index after b
    }

    func testRequestCloseOnCleanTabClosesImmediately() async throws {
        let url = try writeFile("a.md", "x")
        let ws = WorkspaceState()
        await ws.openFile(url)

        ws.requestClose(url)

        XCTAssertTrue(ws.openDocuments.isEmpty)
        XCTAssertNil(ws.closeConfirmation)
    }

    func testRequestCloseOnDirtyTabRaisesPrompt() async throws {
        let url = try writeFile("a.md", "x")
        let ws = WorkspaceState()
        await ws.openFile(url)
        ws.activeDocument?.content = "edited"

        ws.requestClose(url)

        XCTAssertEqual(ws.closeConfirmation?.url, url)
        XCTAssertEqual(ws.openDocuments.count, 1)
    }

    func testResolveCloseByDiscardingRemovesTab() async throws {
        let url = try writeFile("a.md", "x")
        let ws = WorkspaceState()
        await ws.openFile(url)
        ws.activeDocument?.content = "edited"
        ws.requestClose(url)

        ws.resolveCloseByDiscarding()

        XCTAssertNil(ws.closeConfirmation)
        XCTAssertTrue(ws.openDocuments.isEmpty)
    }

    func testCancelCloseKeepsTab() async throws {
        let url = try writeFile("a.md", "x")
        let ws = WorkspaceState()
        await ws.openFile(url)
        ws.activeDocument?.content = "edited"
        ws.requestClose(url)

        ws.cancelCloseRequest()

        XCTAssertNil(ws.closeConfirmation)
        XCTAssertEqual(ws.openDocuments.count, 1)
        XCTAssertTrue(ws.openDocuments[0].isDirty)
    }

    func testResolveCloseBySavingWritesAndRemovesTab() async throws {
        let url = try writeFile("a.md", "original")
        let ws = WorkspaceState()
        await ws.openFile(url)
        ws.activeDocument?.content = "saved content"
        ws.requestClose(url)

        await ws.resolveCloseBySaving()

        XCTAssertNil(ws.closeConfirmation)
        XCTAssertTrue(ws.openDocuments.isEmpty)
        let onDisk = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(onDisk, "saved content")
    }

    func testCloseLastTabClearsActive() async throws {
        let a = try writeFile("a.md", "a")
        let ws = WorkspaceState()

        await ws.openFile(a)
        ws.closeDocument(a)

        XCTAssertTrue(ws.openDocuments.isEmpty)
        XCTAssertNil(ws.activeDocumentID)
    }

    // MARK: - helpers

    private func writeFile(_ name: String, _ contents: String) throws -> URL {
        let url = tempRoot.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
