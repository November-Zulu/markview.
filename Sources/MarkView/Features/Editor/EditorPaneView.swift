import SwiftUI

struct EditorPaneView: View {
    @Bindable var workspace: WorkspaceState
    @State private var scrollToLine: Int?

    var body: some View {
        if workspace.openDocuments.isEmpty {
            EditorEmptyState()
        } else {
            VStack(spacing: 0) {
                EditorTabBar(workspace: workspace)
                Divider()
                if let active = workspace.activeDocument {
                    documentWithLinter(active)
                        .id(active.id)
                } else {
                    EditorEmptyState()
                }
            }
        }
    }

    @ViewBuilder
    private func documentWithLinter(_ active: OpenDocument) -> some View {
        let session = workspace.activeSession
        let linterVisible = session.isLinterPaneVisible
        if linterVisible {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    documentContent(active, session: session)
                        .frame(height: geo.size.height * 0.67)
                    Divider()
                    LinterPaneView(
                        violations: active.lintViolations,
                        document: active,
                        lintSourceHash: active.lintSourceHash,
                        onNavigate: { line in scrollToLine = line },
                        onClose: { workspace.activeSession.isLinterPaneVisible = false }
                    )
                    .frame(maxHeight: .infinity)
                }
            }
        } else {
            documentContent(active, session: session)
        }
    }

    private func documentContent(_ active: OpenDocument, session: FileSessionState) -> some View {
        let bindableDoc = Bindable(active)
        return DocumentContentView(
            document: active,
            scrollFraction: $workspace.editorScrollFraction,
            lintViolations: bindableDoc.lintViolations,
            lintSourceHash: bindableDoc.lintSourceHash,
            scrollToLine: $scrollToLine,
            syntaxHighlightingEnabled: session.isSyntaxHighlightingEnabled,
            editorLightModeEnabled: session.isEditorLightModeEnabled,
            lineNumbersEnabled: session.isLineNumbersEnabled
        )
    }
}
