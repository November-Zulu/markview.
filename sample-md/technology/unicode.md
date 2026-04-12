# Unicode

Unicode is a universal character encoding standard that assigns a unique number to every character across the world's writing systems. Created to replace the fragmented landscape of incompatible encoding schemes, Unicode has become the foundation of modern text processing.

> Before Unicode, "any two encodings chosen were often totally unworkable when used together, with text encoded in one interpreted as garbage characters by the other."

## History

The concept emerged in the late 1980s when **Joe Becker** (Xerox), along with Apple engineers **Lee Collins** and **Mark Davis**, began exploring the feasibility of a universal character set. In August 1988, Becker published a draft proposal describing Unicode as having a name *"intended to suggest a unique, unified, universal encoding."*

The **Unicode Consortium** was incorporated in California on **January 3, 1991**. Major technology companies -- including *Apple*, *Google*, *IBM*, *Microsoft*, and *Meta* -- serve as full members.

## Architecture

### Code Points and Codespace

Unicode assigns each character a **code point** -- a unique number written in the format `U+XXXX` (hexadecimal). The full codespace ranges from `U+0000` to `U+10FFFF`, providing capacity for over **1.1 million** characters.

### Planes

The codespace is organized into **17 planes** of 65,536 code points each:

| Plane | Range | Name | Contents |
|-------|-------|------|----------|
| 0 | `U+0000`--`U+FFFF` | **Basic Multilingual Plane (BMP)** | Most common characters |
| 1 | `U+10000`--`U+1FFFF` | Supplementary Multilingual Plane | Historic scripts, emoji, symbols |
| 2 | `U+20000`--`U+2FFFF` | Supplementary Ideographic Plane | CJK unified ideographs |
| 3--13 | `U+30000`--`U+DFFFF` | Unassigned | Reserved for future use |
| 14 | `U+E0000`--`U+EFFFF` | Supplementary Special-purpose | Tags, variation selectors |
| 15--16 | `U+F0000`--`U+10FFFF` | Private Use Areas | Application-defined characters |

### Example Code Points

| Character | Code Point | Name |
|-----------|-----------|------|
| A | `U+0041` | Latin Capital Letter A |
| Z | `U+005A` | Latin Capital Letter Z |
| a | `U+0061` | Latin Small Letter A |
| 0 | `U+0030` | Digit Zero |
| $ | `U+0024` | Dollar Sign |
| (c) | `U+00A9` | Copyright Sign |
| (pi) | `U+03C0` | Greek Small Letter Pi |
| (Chinese character) | `U+4E16` | CJK Unified Ideograph (meaning "world") |

### Character Coverage

As of version 17.0, Unicode defines **159,801 characters** across **172 scripts**, including:

- Major modern scripts (Latin, Arabic, Chinese, Devanagari, Cyrillic)
- Historical scripts (Egyptian hieroglyphs, Linear B, cuneiform)
- Mathematical and musical symbols
- **3,790 emoji** characters

## Encoding Forms

Unicode text must be encoded into binary for storage and transmission. Three primary encodings exist:

### UTF-8

The **dominant** encoding on the modern internet. UTF-8 is a variable-length scheme using 1 to 4 bytes per character:

- **1 byte** for ASCII characters (`U+0000`--`U+007F`)
- **2 bytes** for Latin, Greek, Cyrillic, Arabic, Hebrew (`U+0080`--`U+07FF`)
- **3 bytes** for most CJK characters and the rest of the BMP (`U+0800`--`U+FFFF`)
- **4 bytes** for supplementary characters, including emoji (`U+10000`--`U+10FFFF`)

UTF-8 is **backward compatible with ASCII**, which was critical to its widespread adoption.

### UTF-16

Uses 2-byte or 4-byte sequences. Characters in the BMP use a single 16-bit code unit; supplementary characters use a **surrogate pair** of two 16-bit units. Historically significant as the internal encoding for Windows, Java, and JavaScript.

### UTF-32

A fixed-width encoding using **4 bytes per character**. Simplifies character indexing (every character is the same width) but at the cost of significantly larger file sizes. Rarely used for storage or transmission.

## Adoption

Unicode has achieved near-universal acceptance in modern computing. The vast majority of internet content, web pages, operating systems, programming languages, and development tools now rely on Unicode -- with **UTF-8** as the preferred encoding.

The widespread adoption of Unicode was instrumental in popularizing **emoji** globally, transforming them from Japan-specific cultural elements into worldwide communication tools.

The Unicode Consortium releases updated versions regularly, adding new scripts and characters while maintaining backward compatibility with all previously encoded text.

---

*Source: [Unicode -- Wikipedia](https://en.wikipedia.org/wiki/Unicode). Content adapted and reformatted for demonstration purposes.*
