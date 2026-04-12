import XCTest
@testable import MarkView

final class FileSystemServiceTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("markview-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    func testLoadsSimpleTreeWithDirsFirst() async throws {
        try write("readme.md", "# hi")
        try write("zeta.txt", "x")
        try makeDir("alpha")
        try write("alpha/inside.md", "a")

        let root = try await FileSystemService.loadTree(at: tempRoot)

        XCTAssertTrue(root.isDirectory)
        XCTAssertEqual(root.children?.count, 3)

        let names = root.children?.map(\.name) ?? []
        XCTAssertEqual(names, ["alpha", "readme.md", "zeta.txt"])

        let alpha = root.children?.first
        XCTAssertEqual(alpha?.children?.map(\.name), ["inside.md"])
    }

    func testSkipsHiddenFiles() async throws {
        try write("visible.md", "y")
        try write(".secret", "nope")
        try makeDir(".hidden-dir")
        try write(".hidden-dir/nested.md", "hidden")

        let root = try await FileSystemService.loadTree(at: tempRoot)
        let names = root.children?.map(\.name) ?? []

        XCTAssertEqual(names, ["visible.md"])
    }

    func testIdentifiesMarkdownByExtension() async throws {
        try write("a.md", "1")
        try write("b.markdown", "2")
        try write("c.MDown", "3")
        try write("d.txt", "4")

        let root = try await FileSystemService.loadTree(at: tempRoot)
        let byName = Dictionary(uniqueKeysWithValues: (root.children ?? []).map { ($0.name, $0) })

        XCTAssertTrue(byName["a.md"]?.isMarkdown ?? false)
        XCTAssertTrue(byName["b.markdown"]?.isMarkdown ?? false)
        XCTAssertTrue(byName["c.MDown"]?.isMarkdown ?? false)
        XCTAssertFalse(byName["d.txt"]?.isMarkdown ?? true)
    }

    func testReadReturnsFileContents() async throws {
        try write("hello.md", "# Hello\nworld")
        let url = tempRoot.appendingPathComponent("hello.md")

        let contents = try await FileSystemService.read(url)

        XCTAssertEqual(contents, "# Hello\nworld")
    }

    func testWriteCreatesFileWithContents() async throws {
        let url = tempRoot.appendingPathComponent("out.md")

        try await FileSystemService.write("hello\nworld", to: url)

        let roundTripped = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(roundTripped, "hello\nworld")
    }

    func testWriteOverwritesExistingFile() async throws {
        let url = tempRoot.appendingPathComponent("out.md")
        try "first".write(to: url, atomically: true, encoding: .utf8)

        try await FileSystemService.write("second", to: url)

        let roundTripped = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(roundTripped, "second")
    }

    func testWriteFailsOnMissingDirectory() async throws {
        let url = tempRoot
            .appendingPathComponent("nope", isDirectory: true)
            .appendingPathComponent("out.md")

        do {
            try await FileSystemService.write("x", to: url)
            XCTFail("Expected unwritable error")
        } catch FileSystemError.unwritable {
            // expected
        }
    }

    func testReadFailsOnMissingFile() async throws {
        let url = tempRoot.appendingPathComponent("missing.md")

        do {
            _ = try await FileSystemService.read(url)
            XCTFail("Expected unreadable error")
        } catch FileSystemError.unreadable {
            // expected
        }
    }

    func testRejectsNonDirectoryRoot() async throws {
        try write("file.md", "x")
        let filePath = tempRoot.appendingPathComponent("file.md")

        do {
            _ = try await FileSystemService.loadTree(at: filePath)
            XCTFail("Expected notADirectory error")
        } catch FileSystemError.notADirectory {
            // expected
        }
    }

    // MARK: - helpers

    private func write(_ relative: String, _ contents: String) throws {
        let url = tempRoot.appendingPathComponent(relative)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func makeDir(_ relative: String) throws {
        let url = tempRoot.appendingPathComponent(relative, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
