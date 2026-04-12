import SwiftUI

/// Editor surface for a single open document. Switches between a loading spinner,
/// an error state, and the `MarkdownTextView` once contents are ready.
struct DocumentContentView: View {
    @Bindable var document: OpenDocument
    @Binding var scrollFraction: CGFloat
    var syntaxHighlightingEnabled: Bool = true
    var editorLightModeEnabled: Bool = false

    var body: some View {
        Group {
            if document.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = document.loadErrorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                MarkdownTextView(
                    text: $document.content,
                    scrollFraction: $scrollFraction,
                    syntaxHighlightingEnabled: syntaxHighlightingEnabled,
                    editorLightModeEnabled: editorLightModeEnabled
                )
            }
        }
        .background(DesignTokens.editorBackground)
    }
}
