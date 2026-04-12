import SwiftUI

struct NavigatorView: View {
    @Bindable var project: ProjectState

    var body: some View {
        Group {
            if let root = project.root {
                tree(root: root)
            } else if project.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NavigatorEmptyState(project: project)
            }
        }
        .background(DesignTokens.sidebarBackground)
        .overlay(alignment: .bottom) {
            if let message = project.loadErrorMessage {
                errorBanner(message)
            }
        }
        .navigationTitle(project.rootURL?.lastPathComponent ?? "Project")
        .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 440)
    }

    @ViewBuilder
    private func tree(root: FileNode) -> some View {
        List(selection: $project.selection) {
            Section {
                OutlineGroup(root.children ?? [], id: \.id, children: \.children) { node in
                    row(for: node)
                }
            } header: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.secondary)
                    Text(root.name)
                        .font(.system(size: 11, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func row(for node: FileNode) -> some View {
        if node.isMarkdown {
            FileTreeRow(node: node).tag(node.url)
        } else {
            FileTreeRow(node: node)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Button {
                project.loadErrorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        .padding(8)
    }
}

#Preview("Empty") {
    NavigatorView(project: ProjectState())
        .frame(width: 280, height: 500)
}

#Preview("Empty state (standalone)") {
    NavigatorEmptyState(project: ProjectState())
        .frame(width: 280, height: 500)
}
