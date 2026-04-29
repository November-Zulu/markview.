import Foundation

@MainActor
final class SelectionCoordinator {
    private weak var project: ProjectState?
    private weak var workspace: WorkspaceState?

    init(project: ProjectState, workspace: WorkspaceState) {
        self.project = project
        self.workspace = workspace
    }

    func navigatorDidSelect(_ url: URL?) async {
        guard let url, !url.hasDirectoryPath else { return }
        await workspace?.openFile(url)
    }

    func tabDidActivate(_ id: URL?) {
        project?.selection = id
    }
}
