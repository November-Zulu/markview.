import Foundation
import Observation

@Observable
@MainActor
final class OpenDocument: Identifiable {
    let url: URL
    var content: String
    var savedContent: String
    var isLoading: Bool
    var loadErrorMessage: String?
    var saveErrorMessage: String?
    var lintViolations: [LintViolation] = []
    var lintSourceHash: Int?

    nonisolated var id: URL { url }
    nonisolated var displayName: String { url.lastPathComponent }
    var isDirty: Bool { content != savedContent }

    init(url: URL) {
        self.url = url
        self.content = ""
        self.savedContent = ""
        self.isLoading = true
    }

    func load() async {
        isLoading = true
        loadErrorMessage = nil
        do {
            let text = try await FileSystemService.read(url)
            self.content = text
            self.savedContent = text
        } catch {
            self.loadErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    /// Writes the current content to disk. Returns true on success.
    /// On failure, `saveErrorMessage` is populated and the document stays dirty.
    @discardableResult
    func save() async -> Bool {
        saveErrorMessage = nil
        let snapshot = content
        do {
            try await FileSystemService.write(snapshot, to: url)
            savedContent = snapshot
            return true
        } catch {
            saveErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}
