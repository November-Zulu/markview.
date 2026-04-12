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

    func openFolder(_ url: URL) async {
        rootURL = url
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
    }
}
