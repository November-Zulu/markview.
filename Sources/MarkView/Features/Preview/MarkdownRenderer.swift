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
    @Environment(\.markdownTheme) private var theme

    var body: some View {
        switch block {
        case let heading as Heading:
            headingView(heading)
        case let paragraph as Paragraph:
            Text(InlineRenderer(theme: theme).attributedString(for: paragraph))
                .font(.system(size: theme.bodyFontSize))
                .fixedSize(horizontal: false, vertical: true)
        case let quote as BlockQuote:
            BlockQuoteView(blockQuote: quote)
        case let unordered as UnorderedList:
            ListBlockView(listItems: Array(unordered.listItems), ordered: false)
        case let ordered as OrderedList:
            ListBlockView(listItems: Array(ordered.listItems), ordered: true)
        case let codeBlock as CodeBlock:
            CodeBlockView(code: codeBlock.code)
        case let table as Markdown.Table:
            TableBlockView(table: table)
        case is ThematicBreak:
            Divider()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func headingView(_ heading: Heading) -> some View {
        Text(InlineRenderer(theme: theme).attributedString(for: heading))
            .font(.system(size: theme.headingSize(level: heading.level), weight: .bold))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, heading.level == 1 ? 4 : 2)
    }
}

private struct BlockQuoteView: View {
    let blockQuote: BlockQuote
    @Environment(\.markdownTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(theme.blockQuoteRule)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(blockQuote.blockChildren.enumerated()), id: \.offset) { _, child in
                    BlockView(block: child)
                }
            }
            .padding(.leading, 12)
            .foregroundStyle(theme.blockQuoteText)
        }
    }
}

private struct ListBlockView: View {
    let listItems: [ListItem]
    let ordered: Bool
    @Environment(\.markdownTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(listItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let checkbox = item.checkbox {
                        Image(systemName: checkbox == .checked
                              ? "checkmark.square.fill" : "square")
                            .font(.system(size: theme.codeFontSize))
                            .foregroundStyle(checkbox == .checked
                                             ? theme.checkboxCheckedColor
                                             : theme.checkboxUncheckedColor)
                            .frame(minWidth: 20, alignment: .trailing)
                    } else {
                        Text(marker(for: index))
                            .font(.system(size: theme.bodyFontSize))
                            .foregroundStyle(theme.listMarkerColor)
                            .frame(minWidth: 20, alignment: .trailing)
                    }
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
    @Environment(\.markdownTheme) private var theme

    var body: some View {
        Text(code)
            .font(.system(size: theme.codeFontSize, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(theme.codeBlockBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Table rendering

private struct TableBlockView: View {
    let table: Markdown.Table
    @Environment(\.markdownTheme) private var theme

    var body: some View {
        let alignments = table.columnAlignments
        let headerCells = Array(table.head.cells)
        let bodyRows = Array(table.body.rows)
        let inline = InlineRenderer(theme: theme)

        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            // Header row
            GridRow {
                ForEach(Array(headerCells.enumerated()), id: \.offset) { colIndex, cell in
                    Text(inline.attributedString(for: cell))
                        .font(.system(size: theme.codeFontSize, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: gridAlignment(alignments, column: colIndex))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
            }

            Divider()

            // Body rows
            ForEach(Array(bodyRows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { colIndex, cell in
                        Text(inline.attributedString(for: cell))
                            .font(.system(size: theme.codeFontSize))
                            .frame(maxWidth: .infinity, alignment: gridAlignment(alignments, column: colIndex))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                }
                Divider()
            }
        }
        .background(theme.tableBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(theme.tableBorder, lineWidth: 1)
        )
    }

    private func gridAlignment(_ alignments: [Markdown.Table.ColumnAlignment?], column: Int) -> Alignment {
        guard column < alignments.count, let alignment = alignments[column] else {
            return .leading
        }
        switch alignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

// MARK: - Inline rendering

struct InlineRenderer {
    let theme: MarkdownTheme

    func attributedString(for markup: any Markup) -> AttributedString {
        var result = AttributedString("")
        for child in markup.children {
            result.append(attributedString(forNode: child))
        }
        return result
    }

    private func attributedString(forNode markup: Markup) -> AttributedString {
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
            s.foregroundColor = NSColor(theme.linkColor)
            s.underlineStyle = NSUnderlineStyle.single
            return s

        case let strike as Strikethrough:
            var s = attributedString(for: strike)
            s.strikethroughStyle = .single
            s.foregroundColor = NSColor(theme.strikethroughColor)
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
