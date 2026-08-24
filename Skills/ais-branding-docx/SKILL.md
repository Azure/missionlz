---
name: ais-branding-docx
description: >-
  Generate AIS-branded Word documents (.docx) from structured JSON input.
  Fills a branded template preserving exact formatting, cover page, headers,
  footers, TOC, heading hierarchy, and all built-in styles. Supports technical
  documentation, runbooks, SOWs, and other deliverables. Use when asked to
  create a branded document, generate a Word doc, or produce formatted
  technical documentation.
license: Proprietary
compatibility: Requires Python 3.10+ and uv (https://docs.astral.sh/uv/)
metadata:
  author: ais-internal
  version: "1.0"
---

# AIS Branded Document Generator

Generate AIS-branded Word documents from structured JSON input. The skill uses
a template-fill approach that preserves exact formatting — cover page branding,
header/footer styling, heading hierarchy, and all AIS design elements are
maintained from the template.

## When to Use

- User asks to generate a branded document or technical deliverable
- User asks to create a runbook, SOW, or system documentation
- User has structured content (sections, headings, steps) ready to format
- User wants AIS-branded output with consistent styling

## Available Scripts

- **`scripts/generate.py`** — Main generator: validates JSON input → fills template → outputs .docx. Includes built-in OOXML validation.

## Workflow

### Step 1: Prepare Input Data

Create a JSON file conforming to `assets/document-schema.json`. The schema defines:

- **cover_page**: Title, subtitle, date, version, prepared-for/by, confidentiality notice
- **footer**: Optional subtitle and version overrides for the footer
- **sections**: Array of body content sections (heading + content blocks)
- **comments**: Optional array of review comments

See `examples/sample-input.json` for a runbook example and `examples/style-guide-input.json` for a comprehensive reference showing all content block types, heading levels, bullet/numbered lists, tables, and inline formatting.

Read the schema for field details:
```
assets/document-schema.json
```

### Step 2: Generate the Document

```bash
uv run scripts/generate.py --input data.json --output document.docx
```

The script will:
1. Validate input against the JSON schema
2. Open the branded template
3. Replace cover page, header, and footer placeholders (with XML-safe escaping)
4. Generate a Table of Contents with field codes and static entries
5. Clear template body content and insert new sections with correct styles
6. Apply bullet/number formatting to list items
7. Generate tables from row data
8. Inject comments if provided
9. Post-process namespace declarations for OOXML compatibility
10. Run OOXML validation and report any issues
11. Write the output .docx

> **Note:** After opening in Word, press **Ctrl+A → F9** to update the Table of Contents with page numbers.

### Step 3: Validate an Existing Document

```bash
# Validate any .docx
uv run scripts/generate.py --validate document.docx

# Strict mode — treat warnings as errors
uv run scripts/generate.py --validate document.docx --strict
```

## Content Block Types

When building the `sections[].content[]` array, use these types:

| Type | Style Applied | Usage |
|------|--------------|-------|
| `body` | Normal | Standard body paragraph |
| `first_paragraph` | FirstParagraph | Opening paragraph of a section (slightly different spacing) |
| `heading2` | Heading 2 | Subsection heading (appears in TOC) |
| `heading3` | Heading 3 | Step heading or sub-subsection (appears in TOC) |
| `heading4` | Heading 4 | Detail-level heading (medium blue) |
| `heading5` | Heading 5 | Minor detail heading (dark navy) |
| `compact` | Compact | Tightly-spaced body text |
| `list_paragraph` | ListParagraph | Bulleted list item (• bullet) |
| `bullet` | ListParagraph | Alias for `list_paragraph` |
| `numbered_list` | ListParagraph | Numbered list item (1. 2. 3.) |
| `body_text` | Body Text | Body text with note/callout styling |
| `source_code` | Source Code | Code blocks or command-line examples |
| `bold_blue` | AIS Bold Blue | Bold blue accent text for emphasis |
| `table` | Grid Table 4 | Data table from row arrays (see below) |

Use `bold_label` on any text block to create a bold prefix (e.g., "Important:", "Note:").

Use `level` (0–3) on `bullet` or `numbered_list` items for nested indentation.

### Tables

Tables use a separate content block format with `rows` instead of `text`:

```json
{
  "type": "table",
  "rows": [
    ["Header 1", "Header 2", "Header 3"],
    ["Cell A1", "Cell A2", "Cell A3"],
    ["Cell B1", "Cell B2", "Cell B3"]
  ],
  "header": true
}
```

The first row is treated as a header row by default. Set `"header": false` to treat all rows equally. Cell text supports inline formatting (`**bold**`, `*italic*`, `` `code` ``).

### Inline Formatting

Text content supports markdown-style inline formatting:

- `**bold text**` → renders bold
- `*italic text*` → renders italic
- `` `code text` `` → renders with VerbatimChar style (monospace)

## Gotchas

- **TOC is not auto-updated.** The Table of Contents uses Word field codes. After generation, open in Word and press Ctrl+A → F9 to update the TOC.
- **Cover page uses anchored drawings.** The cover page has positioned text boxes and shapes — the generator replaces text within them via raw XML string replacement.
- **Images are branding only.** The template contains only the AIS logo images. Customer screenshots should not be embedded — reference them externally or describe them in text.
- **Do not edit template XML with lxml.** lxml strips namespace declarations and renames prefixes, breaking `mc:Ignorable`. Use string manipulation. The generator's post-processing step repairs namespaces automatically.
- **"Unreachable content" errors.** If Word shows this error, run `--validate` against the file. The most common cause is `mc:Ignorable` listing undeclared namespace prefixes.

## Alignment with AIS Branding

This skill implements the document standards defined in the
[`ais-branding-pptx`](../ais-branding-pptx/SKILL.md) skill:

- **Color palette**: Dark Navy (`#1C2C57`) headings, AIS Orange (`#F7901E`) accents, Dark Gray (`#3C3C3C`) body text
- **Typography**: Arial font family, consistent heading hierarchy
- **Logo placement**: AIS logo in cover page and headers
- **Footer**: Applied Information Sciences branding with page numbers
