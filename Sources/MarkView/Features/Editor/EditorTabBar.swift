import SwiftUI

struct EditorTabBar: View {
    @Bindable var workspace: WorkspaceState

    @State private var canScrollLeft = false
    @State private var canScrollRight = false
    @State private var contentOverflows = false

    var body: some View {
        HStack(spacing: 0) {
            if contentOverflows {
                scrollButton(direction: .left, enabled: canScrollLeft)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(workspace.openDocuments) { doc in
                            TabItem(
                                document: doc,
                                isActive: doc.id == workspace.activeDocumentID,
                                onSelect: { workspace.activeDocumentID = doc.id },
                                onClose: { workspace.requestClose(doc.id) }
                            )
                            .id(doc.id)
                            Divider()
                                .frame(height: 20)
                        }
                        Spacer(minLength: 0)
                    }
                    .background(
                        GeometryReader { contentGeo in
                            Color.clear.preference(
                                key: TabContentWidthKey.self,
                                value: contentGeo.size.width
                            )
                        }
                    )
                }
                .background(
                    GeometryReader { scrollGeo in
                        Color.clear.preference(
                            key: TabScrollWidthKey.self,
                            value: scrollGeo.size.width
                        )
                    }
                )
                .onPreferenceChange(TabContentWidthKey.self) { contentWidth in
                    tabContentWidth = contentWidth
                    updateOverflow()
                }
                .onPreferenceChange(TabScrollWidthKey.self) { scrollWidth in
                    tabScrollWidth = scrollWidth
                    updateOverflow()
                }
                .onChange(of: workspace.activeDocumentID) { _, newID in
                    guard let newID else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }

            if contentOverflows {
                scrollButton(direction: .right, enabled: canScrollRight)
            }

            Divider()
                .frame(height: 20)

            EditorActionButtons(workspace: workspace)
                .padding(.horizontal, 8)
        }
        .frame(height: 32)
        .background(DesignTokens.chromeMaterial)
    }

    @State private var tabContentWidth: CGFloat = 0
    @State private var tabScrollWidth: CGFloat = 0

    private func updateOverflow() {
        contentOverflows = tabContentWidth > tabScrollWidth + 1
    }

    private enum ScrollDirection { case left, right }

    private func scrollButton(direction: ScrollDirection, enabled: Bool) -> some View {
        Button {
            scrollByDirection(direction)
        } label: {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func scrollByDirection(_ direction: ScrollDirection) {
        guard !workspace.openDocuments.isEmpty else { return }
        guard let activeID = workspace.activeDocumentID,
              let currentIndex = workspace.openDocuments.firstIndex(where: { $0.id == activeID }) else { return }
        let targetIndex = direction == .left
            ? max(0, currentIndex - 1)
            : min(workspace.openDocuments.count - 1, currentIndex + 1)
        workspace.activeDocumentID = workspace.openDocuments[targetIndex].id
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
        .overlay(alignment: .top) {
            if isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
    }
}

private struct TabContentWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct TabScrollWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
