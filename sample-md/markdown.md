# Markdown

Markdown is a **lightweight markup language** created by *John Gruber* in 2004 that enables
users to format text using a plain-text editor. The language emphasizes readability, allowing
documents to remain readable as plain text without appearing heavily marked up with tags or
formatting instructions.

> "An easy-to-read and easy-to-write plain text format, optionally convert it to structurally
> valid XHTML or HTML."
>
> --- John Gruber, describing the design goal of Markdown

## History

### Creation and Inspiration

Markdown was launched on **March 9, 2004**, with version 1.0.1 released on December 17, 2004.
*Aaron Swartz* served as Gruber's "sounding board" during the language's development. The
design drew inspiration from several earlier conventions and markup languages:

- Conventions used in **email** and **Usenet** posts for plain-text formatting
- **Setext** (c. 1992) --- one of the earliest lightweight markup languages
- **Textile** (c. 2002) --- a markup language used in web publishing
- **reStructuredText** (c. 2002) --- a markup syntax used heavily in Python documentation

Gruber deliberately avoided using curly braces in the syntax to *"unofficially reserve them
for implementation-specific extensions,"* giving developers freedom for custom features while
maintaining core compatibility.

### Rise and Divergence

As Markdown gained popularity, numerous implementations emerged, each adding features like
tables, footnotes, and definition lists. The original informal specification created
ambiguities, causing variants to diverge from the reference implementation. This fragmentation
led to calls for a formal standard.

## Technical Specifications

| Property       | Value                          |
|----------------|--------------------------------|
| File extension | `.md`, `.markdown`             |
| MIME type      | `text/markdown`                |
| UTI            | `net.daringfireball.markdown`  |
| Format type    | Open file format               |
| License        | Permissive                     |

## Core Syntax

Markdown's syntax is designed to be intuitive and mirror the conventions people already use
when writing plain-text emails or documents. Below are the major formatting elements.

### Headings

Headings use the `#` symbol. The number of hashes indicates the heading level:

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

An alternative syntax uses underlines for the first two levels:

```markdown
Heading 1
=========

Heading 2
---------
```

### Emphasis

Text can be styled with *italic* and **bold** formatting:

```markdown
*italic* or _italic_
**bold** or __bold__
***bold and italic***
```

### Lists

**Unordered lists** use dashes, asterisks, or plus signs:

```markdown
- First item
- Second item
  - Nested item
  - Another nested item
- Third item
```

**Ordered lists** use numbers followed by periods:

```markdown
1. First item
2. Second item
3. Third item
```

### Links and Images

Links are formatted with square brackets for the text and parentheses for the URL:

```markdown
[Link text](https://example.com)
[Link with title](https://example.com "Title")
```

Images use the same syntax, prefixed with an exclamation mark:

```markdown
![Alt text](image.png)
![Photo](photo.jpg "Optional title")
```

### Code

Inline code uses single backticks: `` `code here` ``

Code blocks use triple backticks with an optional language identifier:

````markdown
```python
def hello():
    print("Hello, world!")
```
````

### Blockquotes

Blockquotes use the `>` prefix:

```markdown
> This is a blockquote.
> It can span multiple lines.
>
> And multiple paragraphs.
```

### Horizontal Rules

A horizontal rule is created with three or more dashes, asterisks, or underscores:

```markdown
---
***
___
```

### Tables

Tables use pipes and dashes to create columns and rows:

```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

### Line Breaks and Paragraphs

- **Paragraphs** are separated by blank lines
- **Line breaks** within a paragraph are created with two trailing spaces at the end of a line
- **Inline HTML** tags are also supported for additional formatting

## Standardization Efforts

### CommonMark

The most significant standardization effort began in 2012, led by figures including
**Jeff Atwood** and **John MacFarlane**:

1. The project launched in 2012 to address the ambiguities in Gruber's original specification
2. It was rebranded as *CommonMark* in September 2014 after Gruber objected to using
   "Markdown" in the name
3. The initiative established formal specifications and comprehensive test suites
4. Despite planning a 1.0 finalized spec for 2019, major issues still remain unsolved

### RFC Publications

In **March 2016**, two important RFCs were published:

- **RFC 7763** --- introduced the MIME type `text/markdown`
- **RFC 7764** --- discussed design philosophies and registered multiple Markdown variants

## Major Variants

### GitHub Flavored Markdown (GFM)

GitHub released its formalized GFM specification in **2017**, building on CommonMark as a
strict superset. GFM adds several practical extensions:

- **Tables** --- pipe-delimited column syntax
- **Strikethrough** --- using `~~tildes~~` for ~~struck-through text~~
- **Autolinks** --- automatic URL detection
- **Task lists** --- checkboxes with `- [ ]` and `- [x]` syntax
- **Heading requirements** --- now requires a space after the `#` symbol

> GFM has become the de facto standard for developer-facing documentation, used across
> GitHub, GitLab, and many other platforms.

### Markdown Extra

Originally implemented in PHP, with ports to Python and Ruby, Markdown Extra adds:

- Fenced code blocks
- Tables
- Definition lists
- Footnotes
- Abbreviations

It is supported by content management systems like **Drupal**, **TYPO3**, and **Textpattern**.

## Adoption and Ecosystem

Markdown has achieved remarkable adoption across the software industry and beyond. It is
the primary formatting language for:

- **Code platforms** --- GitHub, GitLab, Bitbucket
- **Q&A sites** --- Stack Overflow, Stack Exchange
- **Social platforms** --- Reddit, Discord
- **Documentation tools** --- Read the Docs, MkDocs, Docusaurus
- **Note-taking apps** --- Obsidian, Notion, Bear
- **Blogging platforms** --- Jekyll, Hugo, Ghost

Implementations exist for **over a dozen programming languages**, with plugins available for
major code editors including VS Code, Sublime Text, and Vim. Many editors offer real-time
syntax highlighting and side-by-side preview capabilities.

## Why Markdown Endures

Markdown's lasting appeal comes from a few key principles:

1. **Readability** --- the source text is pleasant to read even without rendering
2. **Simplicity** --- the core syntax can be learned in minutes
3. **Portability** --- plain text files work everywhere, on every platform
4. **Flexibility** --- variants and extensions adapt it to specialized needs
5. **Ecosystem** --- massive tooling support across languages and platforms

What began as one developer's formatting tool for blog posts has become the lingua franca
of technical writing on the web.

---

*Source: [Markdown --- Wikipedia](https://en.wikipedia.org/wiki/Markdown)*
