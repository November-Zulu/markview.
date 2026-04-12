import AppKit
import UniformTypeIdentifiers

/// Shared helpers for presenting `NSOpenPanel` for the two v1 open commands.
/// Used by both `AppCommands` (menu items) and `NavigatorEmptyState` (CTA button).
@MainActor
enum OpenPrompts {
    static func presentOpenFolder(into project: ProjectState) async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a folder to open as a project"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        await project.openFolder(url)
    }

    static func presentOpenFile(into workspace: WorkspaceState) async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a Markdown file to open"
        panel.allowedContentTypes = markdownContentTypes()

        guard panel.runModal() == .OK, let url = panel.url else { return }
        await workspace.openFile(url)
    }

    private static func markdownContentTypes() -> [UTType] {
        var types: [UTType] = [.plainText]
        for ext in ["md", "markdown", "mdown", "mkd"] {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        return types
    }
}
