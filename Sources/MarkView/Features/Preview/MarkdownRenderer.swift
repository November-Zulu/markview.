import SwiftUI
import AppKit
import Markdown

/// Renders a swift-markdown `Document` as SwiftUI views.
/// Supports the v1 element set: headings, paragraphs, bold/italic/inline-code/links,
/// ordered + unordered lists, blockquotes, code blocks, thematic breaks.
struct MarkdownRenderer: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(document.blockChildren.enumerated()), id: \.offset) { _, block in
                BlockView(block: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .textSelection(.enabled)
    }
}

// MARK: - Block rendering

private struct BlockView: View {
    let block: any BlockMarkup

    var body: some View {
        switch block {
        case let heading as Heading:
            headingView(heading)
        case let paragraph as Paragraph:
            Text(InlineRenderer.attributedString(for: paragraph))
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
        case let quote as BlockQuote:
            BlockQuoteView(blockQuote: quote)
        case let unordered as UnorderedList:
            ListBlockView(listItems: Array(unordered.listItems), ordered: false)
        case let ordered as OrderedList:
            ListBlockView(listItems: Array(ordered.listItems), ordered: true)
        case let codeBlock as CodeBlock:
            CodeBlockView(code: codeBlock.code)
        case is ThematicBreak:
            Divider()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func headingView(_ heading: Heading) -> some View {
        Text(InlineRenderer.attributedString(for: heading))
            .font(.system(size: fontSize(for: heading.level), weight: .bold))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, heading.level == 1 ? 4 : 2)
    }

    private func fontSize(for level: Int) -> CGFloat {
        switch level {
        case 1: return 28
        case 2: return 22
        case 3: return 18
        case 4: return 16
        case 5: return 14
        default: return 13
        }
    }
}

private struct BlockQuoteView: View {
    let blockQuote: BlockQuote

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(blockQuote.blockChildren.enumerated()), id: \.offset) { _, child in
                    BlockView(block: child)
                }
            }
            .padding(.leading, 12)
            .foregroundStyle(.secondary)
        }
    }
}

private struct ListBlockView: View {
    let listItems: [ListItem]
    let ordered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(listItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(marker(for: index))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(item.blockChildren.enumerated()), id: \.offset) { _, child in
                            BlockView(block: child)
                        }
                    }
                }
            }
        }
    }

    private func marker(for index: Int) -> String {
        ordered ? "\(index + 1)." : "•"
    }
}

private struct CodeBlockView: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(size: 13, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Inline rendering

private enum InlineRenderer {
    static func attributedString(for markup: any Markup) -> AttributedString {
        var result = AttributedString("")
        for child in markup.children {
            result.append(attributedString(forNode: child))
        }
        return result
    }

    private static func attributedString(forNode markup: Markup) -> AttributedString {
        switch markup {
        case let text as Markdown.Text:
            return AttributedString(text.string)

        case let emphasis as Emphasis:
            var s = attributedString(for: emphasis)
            s.inlinePresentationIntent = .emphasized
            return s

        case let strong as Strong:
            var s = attributedString(for: strong)
            s.inlinePresentationIntent = .stronglyEmphasized
            return s

        case let inlineCode as InlineCode:
            var s = AttributedString(inlineCode.code)
            s.inlinePresentationIntent = .code
            return s

        case let link as Markdown.Link:
            var s = attributedString(for: link)
            if let dest = link.destination, let url = URL(string: dest) {
                s.link = url
            }
            s.foregroundColor = NSColor.linkColor
            s.underlineStyle = NSUnderlineStyle.single
            return s

        case is SoftBreak:
            return AttributedString(" ")

        case is LineBreak:
            return AttributedString("\n")

        default:
            return attributedString(for: markup)
        }
    }
}
