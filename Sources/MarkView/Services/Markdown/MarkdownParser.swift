import Foundation
import Markdown

enum MarkdownParser {
    /// Parses CommonMark text into a `Document` AST. Runs off the main actor.
    static func parse(_ text: String) async -> Document {
        await Task.detached(priority: .userInitiated) {
            Document(parsing: text)
        }.value
    }
}
