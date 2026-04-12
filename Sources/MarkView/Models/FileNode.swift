import Foundation

struct FileNode: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileNode]?

    var id: URL { url }

    var isMarkdown: Bool {
        !isDirectory && FileNode.markdownExtensions.contains(url.pathExtension.lowercased())
    }

    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]
}
