import SwiftUI
import Markdown

struct PreviewPaneView: View {
    @Bindable var workspace: WorkspaceState
    @State private var parsed: Document?

    private var isScrollLocked: Bool {
        workspace.activeSession.isScrollLockEnabled
    }

    var body: some View {
        Group {
            if workspace.activeDocument == nil {
                PreviewEmptyState()
            } else if let parsed {
                previewScrollView(for: parsed)
            } else {
                Color.clear
            }
        }
        .background(DesignTokens.paneBackground)
        .onChange(of: workspace.activeDocument?.id) { _, _ in
            parsed = nil
        }
        .task(id: workspace.activeDocument?.content ?? "") {
            guard let doc = workspace.activeDocument else {
                parsed = nil
                return
            }
            // Debounce: 150ms after the last keystroke. If content changes again
            // before we wake, this task is cancelled and replaced.
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            let result = await MarkdownParser.parse(doc.content)
            guard !Task.isCancelled else { return }
            parsed = result
        }
    }

    @ViewBuilder
    private func previewScrollView(for document: Document) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                MarkdownRenderer(document: document)
                    .id("preview-content")
            }
            .onChange(of: workspace.editorScrollFraction) { _, fraction in
                guard isScrollLocked else { return }
                withAnimation(.easeOut(duration: 0.05)) {
                    proxy.scrollTo("preview-content", anchor: UnitPoint(x: 0.5, y: fraction))
                }
            }
        }
    }
}

#Preview {
    PreviewPaneView(workspace: WorkspaceState())
        .frame(width: 500, height: 600)
}
