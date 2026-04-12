import XCTest
@testable import MarkView

@MainActor
final class OpenDocumentTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("markview-opendoc-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testNewlyLoadedDocumentIsClean() async throws {
        let url = try writeFile("a.md", "hello")
        let doc = OpenDocument(url: url)

        await doc.load()

        XCTAssertEqual(doc.content, "hello")
        XCTAssertEqual(doc.savedContent, "hello")
        XCTAssertFalse(doc.isDirty)
    }

    func testEditingMakesDocumentDirty() async throws {
        let url = try writeFile("a.md", "hello")
        let doc = OpenDocument(url: url)
        await doc.load()

        doc.content = "hello!"

        XCTAssertTrue(doc.isDirty)
    }

    func testRevertingContentClearsDirty() async throws {
        let url = try writeFile("a.md", "hello")
        let doc = OpenDocument(url: url)
        await doc.load()

        doc.content = "changed"
        XCTAssertTrue(doc.isDirty)

        doc.content = "hello"
        XCTAssertFalse(doc.isDirty)
    }

    func testSaveWritesContentAndClearsDirty() async throws {
        let url = try writeFile("a.md", "hello")
        let doc = OpenDocument(url: url)
        await doc.load()
        doc.content = "hello, world"
        XCTAssertTrue(doc.isDirty)

        let ok = await doc.save()

        XCTAssertTrue(ok)
        XCTAssertFalse(doc.isDirty)
        XCTAssertNil(doc.saveErrorMessage)
        let onDisk = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(onDisk, "hello, world")
    }

    func testSaveToUnwritablePathSetsErrorAndKeepsDirty() async throws {
        let missingDir = tempRoot.appendingPathComponent("nope", isDirectory: true)
        let url = missingDir.appendingPathComponent("a.md")
        let doc = OpenDocument(url: url)
        // Bypass load (which would also fail); simulate an in-memory doc.
        doc.content = "unsaved work"
        doc.savedContent = ""

        let ok = await doc.save()

        XCTAssertFalse(ok)
        XCTAssertTrue(doc.isDirty)
        XCTAssertNotNil(doc.saveErrorMessage)
    }

    func testLoadFailureSetsErrorMessage() async throws {
        let url = tempRoot.appendingPathComponent("nope.md")
        let doc = OpenDocument(url: url)

        await doc.load()

        XCTAssertNotNil(doc.loadErrorMessage)
        XCTAssertFalse(doc.isLoading)
    }

    // MARK: - helpers

    private func writeFile(_ name: String, _ contents: String) throws -> URL {
        let url = tempRoot.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
