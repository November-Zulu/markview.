import XCTest
@testable import MarkView

@MainActor
final class SelectionCoordinatorTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("markview-selection-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    // MARK: - Tracer

    func testNavigatorDidSelectOpensFileAsTab() async throws {
        let url = try writeFile("a.md", "# a")
        let project = ProjectState()
        let workspace = WorkspaceState()
        let coordinator = SelectionCoordinator(project: project, workspace: workspace)

        await coordinator.navigatorDidSelect(url)

        XCTAssertEqual(workspace.activeDocumentID, url)
        XCTAssertEqual(workspace.openDocuments.count, 1)
        XCTAssertEqual(workspace.openDocuments.first?.url, url)
    }

    func testNavigatorDidSelectNilIsNoOp() async throws {
        let url = try writeFile("a.md", "# a")
        let project = ProjectState()
        let workspace = WorkspaceState()
        let coordinator = SelectionCoordinator(project: project, workspace: workspace)
        await coordinator.navigatorDidSelect(url)
        XCTAssertEqual(workspace.openDocuments.count, 1)

        await coordinator.navigatorDidSelect(nil)

        XCTAssertEqual(workspace.openDocuments.count, 1)
        XCTAssertEqual(workspace.activeDocumentID, url)
    }

    func testNavigatorDidSelectDirectoryIsNoOp() async throws {
        let folder = tempRoot.appendingPathComponent("subfolder", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let project = ProjectState()
        let workspace = WorkspaceState()
        let coordinator = SelectionCoordinator(project: project, workspace: workspace)

        await coordinator.navigatorDidSelect(folder)

        XCTAssertTrue(workspace.openDocuments.isEmpty)
        XCTAssertNil(workspace.activeDocumentID)
    }

    func testTabDidActivateSyncsProjectSelection() throws {
        let url = try writeFile("a.md", "# a")
        let project = ProjectState()
        let workspace = WorkspaceState()
        let coordinator = SelectionCoordinator(project: project, workspace: workspace)

        coordinator.tabDidActivate(url)

        XCTAssertEqual(project.selection, url)
    }

    func testTabDidActivateNilClearsProjectSelection() throws {
        let url = try writeFile("a.md", "# a")
        let project = ProjectState()
        let workspace = WorkspaceState()
        let coordinator = SelectionCoordinator(project: project, workspace: workspace)
        coordinator.tabDidActivate(url)
        XCTAssertEqual(project.selection, url)

        coordinator.tabDidActivate(nil)

        XCTAssertNil(project.selection)
    }

    func testReselectingOpenFileActivatesExistingTab() async throws {
        let a = try writeFile("a.md", "# a")
        let b = try writeFile("b.md", "# b")
        let project = ProjectState()
        let workspace = WorkspaceState()
        let coordinator = SelectionCoordinator(project: project, workspace: workspace)
        await coordinator.navigatorDidSelect(a)
        await coordinator.navigatorDidSelect(b)
        XCTAssertEqual(workspace.activeDocumentID, b)

        await coordinator.navigatorDidSelect(a)

        XCTAssertEqual(workspace.openDocuments.count, 2)
        XCTAssertEqual(workspace.activeDocumentID, a)
    }

    // MARK: - helpers

    private func writeFile(_ name: String, _ contents: String) throws -> URL {
        let url = tempRoot.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
