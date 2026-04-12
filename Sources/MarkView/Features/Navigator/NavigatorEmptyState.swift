import SwiftUI

struct NavigatorEmptyState: View {
    let project: ProjectState

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No Project Open")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Open a folder to start browsing its Markdown files.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button {
                Task { await OpenPrompts.presentOpenFolder(into: project) }
            } label: {
                Label("Open Folder…", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigatorEmptyState(project: ProjectState())
        .frame(width: 260, height: 420)
}
