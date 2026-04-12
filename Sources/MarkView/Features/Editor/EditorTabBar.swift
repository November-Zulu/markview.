import SwiftUI

struct EditorTabBar: View {
    @Bindable var workspace: WorkspaceState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(workspace.openDocuments) { doc in
                    TabItem(
                        document: doc,
                        isActive: doc.id == workspace.activeDocumentID,
                        onSelect: { workspace.activeDocumentID = doc.id },
                        onClose: { workspace.requestClose(doc.id) }
                    )
                    Divider()
                        .frame(height: 20)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 32)
        .background(DesignTokens.sidebarBackground)
    }
}

private struct TabItem: View {
    @Bindable var document: OpenDocument
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            if document.isDirty {
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
            }

            Text(document.displayName)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundStyle(isActive ? .primary : .secondary)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
                    .background(
                        Circle().fill(isHovering ? Color.secondary.opacity(0.2) : .clear)
                    )
            }
            .buttonStyle(.plain)
            .opacity(isActive || isHovering ? 1 : 0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? DesignTokens.paneBackground : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
    }
}
