import SwiftUI

struct PreviewEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Nothing to Preview")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("The rendered Markdown will appear here.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.contentMaterial)
    }
}

#Preview {
    PreviewEmptyState()
        .frame(width: 400, height: 400)
}
