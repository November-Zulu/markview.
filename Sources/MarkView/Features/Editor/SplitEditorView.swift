import SwiftUI

struct SplitEditorView: View {
    @Bindable var workspace: WorkspaceState

    var body: some View {
        GeometryReader { geo in
            let showPreview = workspace.isPreviewVisible
                && !workspace.activeSession.isRendererCollapsed
                && workspace.activeDocument != nil
            let ratio = showPreview ? workspace.activeSession.splitRatio : 1.0
            let editorWidth = geo.size.width * ratio

            HStack(spacing: 0) {
                EditorPaneView(workspace: workspace)
                    .frame(width: showPreview ? editorWidth : nil)
                    .frame(maxHeight: .infinity)

                if showPreview {
                    SplitDivider()
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    let newRatio = value.location.x / geo.size.width
                                    workspace.activeSession.splitRatio =
                                        min(max(newRatio, 0.25), 0.75)
                                }
                        )

                    VStack(spacing: 0) {
                        PreviewHeaderBar(workspace: workspace)
                        Divider()
                        previewContent
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        let preview = PreviewPaneView(workspace: workspace)
        if workspace.activeSession.isPreviewLightModeEnabled {
            preview.environment(\.colorScheme, .light)
        } else {
            preview
        }
    }
}

struct SplitDivider: View {
    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(isHovering ? Color.accentColor.opacity(0.5) : Color(nsColor: .separatorColor))
            .frame(width: isHovering ? 4 : 1)
            .contentShape(Rectangle().size(width: 8, height: .infinity))
            .padding(.horizontal, isHovering ? 0 : 1.5)
            .frame(width: 5)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
