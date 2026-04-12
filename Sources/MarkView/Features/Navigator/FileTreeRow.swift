import SwiftUI
import AppKit

struct FileTreeRow: View {
    let node: FileNode

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 16)
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(nameColor)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([node.url])
            }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(node.url.path, forType: .string)
            }
        }
    }

    private var iconName: String {
        if node.isDirectory { return "folder" }
        if node.isMarkdown { return "doc.text" }
        return "doc"
    }

    private var iconColor: Color {
        if node.isDirectory { return .accentColor }
        if node.isMarkdown { return .primary }
        return .secondary
    }

    private var nameColor: Color {
        (node.isDirectory || node.isMarkdown) ? .primary : .secondary
    }
}
