import SwiftUI

struct SplitEditorView: View {
    @Bindable var workspace: WorkspaceState
    @GestureState private var dragOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private var showPreview: Bool {
        workspace.isPreviewVisible
            && !workspace.activeSession.isRendererCollapsed
            && workspace.activeDocument != nil
    }

    private var effectiveRatio: CGFloat {
        guard showPreview, containerWidth > 0 else { return 1.0 }
        let base = workspace.activeSession.splitRatio * containerWidth
        let newRatio = (base + dragOffset) / containerWidth
        return min(max(newRatio, 0.25), 0.75)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    EditorPaneView(workspace: workspace)
                        .frame(width: showPreview ? geo.size.width * effectiveRatio : nil)
                        .frame(maxHeight: .infinity)

                    if showPreview {
                        VStack(spacing: 0) {
                            PreviewHeaderBar(workspace: workspace)
                            Divider()
                            previewContent
                                .frame(maxHeight: .infinity)
                        }
                    }
                }

                // Divider overlay sits on top of both panes so hover works from either side
                if showPreview {
                    SplitDivider()
                        .position(x: geo.size.width * effectiveRatio, y: geo.size.height / 2)
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    let base = workspace.activeSession.splitRatio * geo.size.width
                                    let newRatio = (base + value.translation.width) / geo.size.width
                                    workspace.activeSession.setSplitRatio(newRatio)
                                }
                        )
                }
            }
            .onChange(of: geo.size.width) { _, newWidth in
                containerWidth = newWidth
            }
            .onAppear { containerWidth = geo.size.width }
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        let preview = PreviewPaneView(workspace: workspace)
        if workspace.activeSession.isPreviewLightModeEnabled {
            preview
                .environment(\.colorScheme, .light)
                .background(Color.white)
        } else {
            preview
        }
    }
}

struct SplitDivider: View {
    @State private var isHovering = false

    var body: some View {
        ZStack {
            // Invisible wide hit area for hover and drag
            Color.clear
                .frame(width: 12)
                .contentShape(Rectangle())

            // Visible divider line
            Rectangle()
                .fill(isHovering ? Color.accentColor.opacity(0.5) : Color(nsColor: .separatorColor))
                .frame(width: isHovering ? 3 : 1)
        }
        .frame(width: 12)
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
