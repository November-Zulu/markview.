import SwiftUI
import Observation

@Observable
@MainActor
final class WorkspaceState {
    var columnVisibility: NavigationSplitViewVisibility = .all
    var isPreviewVisible: Bool = true

    var openDocuments: [OpenDocument] = []
    var activeDocumentID: URL?

    /// Per-file session state (split ratio, toggles). Session-only, not persisted.
    var fileSessions: [URL: FileSessionState] = [:]

    /// Editor scroll position as a fraction (0.0 = top, 1.0 = bottom).
    /// Used for scroll lock synchronization with the preview pane.
    var editorScrollFraction: CGFloat = 0

    /// Non-nil while a "save changes before closing" prompt is pending for a tab close.
    var closeConfirmation: OpenDocument?

    var activeDocument: OpenDocument? {
        guard let id = activeDocumentID else { return nil }
        return openDocuments.first { $0.id == id }
    }

    /// Returns the session state for the active document, creating a default if needed.
    var activeSession: FileSessionState {
        get {
            guard let id = activeDocumentID else { return FileSessionState() }
            return fileSessions[id, default: FileSessionState()]
        }
        set {
            guard let id = activeDocumentID else { return }
            fileSessions[id] = newValue
        }
    }

    private static let openTabsKey = "openTabPaths"
    private static let activeTabKey = "activeTabPath"

    var hasDirtyDocuments: Bool {
        openDocuments.contains(where: \.isDirty)
    }

    /// Persists the current open tab URLs and active tab to UserDefaults.
    func saveTabState() {
        let paths = openDocuments.map { $0.url.path }
        UserDefaults.standard.set(paths, forKey: Self.openTabsKey)
        UserDefaults.standard.set(activeDocumentID?.path, forKey: Self.activeTabKey)
    }

    /// Restores previously open tabs. Only opens files that still exist on disk.
    func restoreTabs() async {
        guard let paths = UserDefaults.standard.stringArray(forKey: Self.openTabsKey),
              !paths.isEmpty else { return }
        let activePath = UserDefaults.standard.string(forKey: Self.activeTabKey)

        for path in paths {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else { continue }
            await openFile(url)
        }

        if let activePath {
            let activeURL = URL(fileURLWithPath: activePath)
            if openDocuments.contains(where: { $0.url == activeURL }) {
                activeDocumentID = activeURL
            }
        }
    }

    func toggleNavigator() {
        columnVisibility = (columnVisibility == .all) ? .detailOnly : .all
    }

    func togglePreview() {
        isPreviewVisible.toggle()
    }

    /// Opens a file, or activates the existing tab if it's already open.
    /// Loads content asynchronously.
    func openFile(_ url: URL) async {
        if let existing = openDocuments.first(where: { $0.url == url }) {
            activeDocumentID = existing.id
            return
        }
        let doc = OpenDocument(url: url)
        openDocuments.append(doc)
        activeDocumentID = doc.id
        await doc.load()
        saveTabState()
    }

    /// Requests closing a tab. If the document is dirty, raises a confirmation prompt;
    /// otherwise closes immediately.
    func requestClose(_ id: URL) {
        guard let doc = openDocuments.first(where: { $0.id == id }) else { return }
        if doc.isDirty {
            closeConfirmation = doc
        } else {
            closeDocument(id)
        }
    }

    /// Saves the pending-close document and removes it on success. If the save fails,
    /// the prompt clears but the document stays open and dirty (the error surfaces on
    /// the document itself).
    func resolveCloseBySaving() async {
        guard let doc = closeConfirmation else { return }
        closeConfirmation = nil
        let ok = await doc.save()
        if ok {
            closeDocument(doc.id)
        }
    }

    /// Discards the pending-close document without saving.
    func resolveCloseByDiscarding() {
        guard let doc = closeConfirmation else { return }
        closeConfirmation = nil
        closeDocument(doc.id)
    }

    func cancelCloseRequest() {
        closeConfirmation = nil
    }

    /// Closes the tab with the given id. If it was active, activates a neighbour (or nil).
    func closeDocument(_ id: URL) {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else { return }
        openDocuments.remove(at: index)
        fileSessions.removeValue(forKey: id)

        if activeDocumentID == id {
            if openDocuments.isEmpty {
                activeDocumentID = nil
            } else {
                let nextIndex = min(index, openDocuments.count - 1)
                activeDocumentID = openDocuments[nextIndex].id
            }
        }
        saveTabState()
    }
}
