import SwiftUI
import Observation

@Observable
@MainActor
final class WorkspaceState {
    var columnVisibility: NavigationSplitViewVisibility = .all
    var isPreviewVisible: Bool = true

    var openDocuments: [OpenDocument] = []
    var activeDocumentID: URL?

    /// Non-nil while a "save changes before closing" prompt is pending for a tab close.
    var closeConfirmation: OpenDocument?

    var activeDocument: OpenDocument? {
        guard let id = activeDocumentID else { return nil }
        return openDocuments.first { $0.id == id }
    }

    var hasDirtyDocuments: Bool {
        openDocuments.contains(where: \.isDirty)
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

        if activeDocumentID == id {
            if openDocuments.isEmpty {
                activeDocumentID = nil
            } else {
                let nextIndex = min(index, openDocuments.count - 1)
                activeDocumentID = openDocuments[nextIndex].id
            }
        }
    }
}
