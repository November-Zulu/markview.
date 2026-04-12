import Foundation
import Observation

@Observable
@MainActor
final class ProjectState {
    var rootURL: URL?
    var root: FileNode?
    var selection: URL?
    var loadErrorMessage: String?
    var isLoading: Bool = false

    private static let lastProjectKey = "lastProjectFolder"
    private var watcher: FileSystemWatcher?

    func openFolder(_ url: URL) async {
        rootURL = url
        UserDefaults.standard.set(url.path, forKey: Self.lastProjectKey)
        isLoading = true
        loadErrorMessage = nil
        selection = nil

        do {
            let tree = try await FileSystemService.loadTree(at: url)
            self.root = tree
        } catch {
            self.root = nil
            self.loadErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false

        // Start watching for external filesystem changes
        watcher?.stop()
        watcher = FileSystemWatcher { [weak self] in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        watcher?.watch(directory: url)
    }

    func closeProject() {
        watcher?.stop()
        watcher = nil
        rootURL = nil
        UserDefaults.standard.removeObject(forKey: Self.lastProjectKey)
        root = nil
        selection = nil
        loadErrorMessage = nil
        isLoading = false
    }

    func refresh() async {
        guard let url = rootURL else { return }
        do {
            let tree = try await FileSystemService.loadTree(at: url)
            self.root = tree
            // Clear selection if the selected file no longer exists in the tree
            if let sel = selection, !treeContains(url: sel, in: tree) {
                selection = nil
            }
        } catch {
            // Silently fail on refresh — keep existing tree
        }
    }

    private func treeContains(url: URL, in node: FileNode) -> Bool {
        if node.url == url { return true }
        return node.children?.contains(where: { treeContains(url: url, in: $0) }) ?? false
    }

    /// Restores the last opened project folder if it still exists on disk.
    func restoreLastProject() async {
        guard let path = UserDefaults.standard.string(forKey: Self.lastProjectKey) else { return }
        let url = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            UserDefaults.standard.removeObject(forKey: Self.lastProjectKey)
            return
        }
        await openFolder(url)
    }

    /// Returns the directory URL for the current "focus" in the navigator.
    /// If a folder is selected, returns it. If a file is selected, returns its parent.
    /// Falls back to the project root.
    func focusedDirectory() -> URL? {
        if let sel = selection {
            if let root, treeContains(url: sel, in: root) {
                // Check if the selected URL is a directory
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: sel.path, isDirectory: &isDir), isDir.boolValue {
                    return sel
                }
                return sel.deletingLastPathComponent()
            }
        }
        return rootURL
    }
}
