import SwiftUI

struct EditorPaneView: View {
    @Bindable var workspace: WorkspaceState

    private var session: FileSessionState {
        workspace.activeSession
    }

    var body: some View {
        if workspace.openDocuments.isEmpty {
            EditorEmptyState()
        } else {
            VStack(spacing: 0) {
                EditorTabBar(workspace: workspace)
                Divider()
                if let active = workspace.activeDocument {
                    DocumentContentView(
                        document: active,
                        syntaxHighlightingEnabled: session.isSyntaxHighlightingEnabled,
                        editorLightModeEnabled: session.isEditorLightModeEnabled
                    )
                        .id(active.id)
                } else {
                    EditorEmptyState()
                }
            }
        }
    }
}
