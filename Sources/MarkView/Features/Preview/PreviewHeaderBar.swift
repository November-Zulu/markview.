import SwiftUI

struct PreviewHeaderBar: View {
    @Bindable var workspace: WorkspaceState

    var body: some View {
        HStack(spacing: 0) {
            Text(workspace.activeDocument?.displayName ?? "")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.leading, 12)

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                toggleButton(
                    icon: workspace.activeSession.isScrollLockEnabled
                        ? "lock.fill" : "lock.open.fill",
                    tooltip: "Toggle scroll lock",
                    isOn: workspace.activeSession.isScrollLockEnabled
                ) {
                    workspace.activeSession.isScrollLockEnabled.toggle()
                }

                toggleButton(
                    icon: workspace.activeSession.isPreviewLightModeEnabled
                        ? "sun.max.fill" : "moon.fill",
                    tooltip: "Toggle light mode",
                    isOn: workspace.activeSession.isPreviewLightModeEnabled
                ) {
                    workspace.activeSession.isPreviewLightModeEnabled.toggle()
                }

                toggleButton(
                    icon: workspace.activeSession.isRendererCollapsed
                        ? "rectangle.righthalf.inset.filled.arrow.right"
                        : "rectangle.righthalf.inset.filled",
                    tooltip: "Toggle Preview Pane",
                    isOn: !workspace.activeSession.isRendererCollapsed
                ) {
                    workspace.activeSession.isRendererCollapsed.toggle()
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 32)
        .background(DesignTokens.sidebarBackground)
    }

    private func toggleButton(icon: String, tooltip: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isOn ? .primary : .tertiary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOn ? Color.accentColor.opacity(0.15) : .clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}
