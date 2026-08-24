---
name: ais-proposal-docx
description: >-
  Generate AIS-branded proposal Word documents (.docx) from structured JSON
  input. Fills a branded template preserving exact formatting and built-in
  styles — cover page, headers, footers, TOC, body sections, tables, callouts,
  and comments. Use when asked to create a proposal document, generate a Word
  doc for a submission, populate a proposal template, or produce a formatted
  technical volume.
license: Proprietary
compatibility: Requires Python 3.10+ and uv (https://docs.astral.sh/uv/)
metadata:
  author: ais-internal
  version: "1.0"
---

# AIS Proposal Document Generator

Generate AIS-branded proposal Word documents from structured JSON input. The
skill uses a template-fill approach that preserves exact formatting — no new
styles are created, and all AIS branding (logos, colors, fonts) is maintained.

## When to Use

- User asks to generate a proposal document
- User asks to populate a proposal template
- User asks to create a formatted technical volume or submission document
- User has structured proposal data (sections, headings, content) ready to format
- User wants to extract or inject review comments in a proposal document

## Available Scripts

- **`scripts/generate.py`** — Main generator: validates JSON input → fills template → outputs .docx. Includes built-in OOXML validation.
- **`scripts/extract_comments.py`** — Extracts comments from any .docx as JSON
- **`scripts/inject_comments.py`** — Adds/updates comments in a .docx from JSON
- **`scripts/validate_styles.py`** — Verifies no new styles were created during generation

## Tool Usage Declaration

This skill uses only repository-local Python scripts and local filesystem
inputs/outputs. It does not require MCP services, browser automation, cloud
services, network calls, or external document-processing APIs.

Expected local commands:

- `uv run scripts/generate.py --input data.json --output proposal.docx`
- `uv run scripts/generate.py --validate proposal.docx`
- `uv run scripts/generate.py --validate proposal.docx --strict`
- `uv run scripts/validate_styles.py --generated proposal.docx`
- `uv run scripts/extract_comments.py --input document.docx --output comments.json`
- `uv run scripts/inject_comments.py --input document.docx --comments comments.json --output updated.docx`

## Workflow

### Step 1: Prepare Input Data

Create a JSON file conforming to `assets/proposal-schema.json`. The schema defines:

- **cover_page**: Title, solicitation number, date, volume name, submitted-by/to details
- **header**: Text for the header bar on body pages
- **footer**: Optional custom footer disclaimer
- **sections**: Array of body content sections (heading + content blocks)
- **comments**: Optional array of comments to anchor to sections

See `examples/sample-input.json` for the legacy paragraph-block example and
`examples/rich-template-input.json` for semantic proposal constructs.

Read the schema for field details:
```
assets/proposal-schema.json
```

### Step 2: Generate the Document

```bash
uv run scripts/generate.py --input data.json --output proposal.docx
```

The script will:
1. Validate input against the JSON schema
2. Open the branded template
3. Replace cover page, header, and footer placeholders
4. Clear template body content and insert new sections with correct styles
5. Inject comments if provided
6. Post-process the OOXML package (fix namespace declarations, wire comment relationships)
7. Run OOXML validation and report any issues
8. Write the output .docx

Validation runs automatically after generation and must pass before delivery.
If validation fails, fix the generated document or input data and rerun the
generator.

### Step 3: Validate an Existing Document

The generator includes a standalone validation mode that checks for common OOXML issues that cause Word errors:

```bash
# Validate any .docx
uv run scripts/generate.py --validate proposal.docx

# Strict mode — treat warnings as errors
uv run scripts/generate.py --validate proposal.docx --strict
```

Validation checks:
- Required OOXML parts exist
- All XML is well-formed
- `mc:Ignorable` namespace prefixes all have matching `xmlns:` declarations
- `[Content_Types].xml` covers all parts
- Relationship targets resolve to files in the archive
- Comment anchors, ranges, and `comments.xml` are consistent
- No empty `.rels` files
- No residual personal/machine file paths

### Step 4: Validate Styles

```bash
uv run scripts/validate_styles.py --generated proposal.docx
```

This confirms no new styles were created. The output should show `PASSED`.

## Working with Comments

### Extract Comments from a Document

To read submission criteria, reviewer feedback, or any comments from an existing .docx:

```bash
uv run scripts/extract_comments.py --input document.docx --output comments.json
```

Output JSON structure:
```json
[
  {
    "id": "32",
    "author": "Funk, Joe",
    "date": "2026-04-30T11:11:00Z",
    "text": "Instruction: Describe your approach...",
    "anchor_paragraph_index": 25,
    "anchor_text": "Federal AI Implementation Approach",
    "anchor_style": "Heading1"
  }
]
```

### Inject Comments into a Document

To add review comments or submission criteria to a document:

```bash
uv run scripts/inject_comments.py --input document.docx --comments new-comments.json --output updated.docx
```

The comments JSON must include `anchor_paragraph_index`, `text`, and optionally `author` and `date`.

### Comment-Driven Update Workflow

1. Extract reviewer comments from a returned document:
   ```bash
   uv run scripts/extract_comments.py --input reviewed.docx --output feedback.json
   ```
2. Read the feedback, generate updated content addressing each comment
3. Create a new input JSON with the updated sections
4. Re-generate the document:
   ```bash
   uv run scripts/generate.py --input updated-data.json --output revised.docx
   ```
5. Optionally inject resolution comments:
   ```bash
   uv run scripts/inject_comments.py --input revised.docx --comments resolutions.json --output final.docx
   ```

## Content Block Types

When building the `sections[].content[]` array, prefer semantic blocks when
they improve the proposal flow. Use plain paragraph blocks for narrative, and
use richer constructs when the content naturally calls for emphasis, evidence,
structured comparison, solicitation traceability, or visual support.

### Paragraph Blocks

| Type | Style Applied | Usage |
|------|---------------|-------|
| `body` | `_Body` | Standard body paragraph |
| `body_0_after` | `_Body_0_after` | Body paragraph with zero spacing after |
| `heading2` | `heading 2` | Numbered second-level heading |
| `heading3` | `heading 3` | Numbered third-level heading |
| `heading_a` | `_Heading A` | Unnumbered heading style A |
| `heading_b` | `_Heading B` | Unnumbered heading style B |
| `bullet1` | `_Bullet1` | Level 1 bullet |
| `bullet1_0_after` | `_Bullet1_0_after` | Level 1 bullet, zero spacing after |
| `bullet2` | `_Bullet2` | Level 2 bullet |
| `bullet2_0_after` | `_Bullet2_0_after` | Level 2 bullet, zero spacing after |
| `bullet3` | `_Bullet3` | Level 3 bullet |
| `bullet3_0_after` | `_Bullet3_0_after` | Level 3 bullet, zero spacing after |
| `callout_title` | `_Callout Title` | Callout box title |
| `callout_text` | `_Callout Text` | Callout box text |
| `callout_bullet` | `_Callout Bullet` | Callout box bullet |

Use `bold_label` on body blocks to create a bold prefix (e.g., "Model Governance:").

### Semantic Blocks

| Type | Template Construct | Use When |
|------|--------------------|----------|
| `theme` | `_Theme` paragraph | The proposal needs a clear win theme, narrative anchor, or evaluator-facing takeaway. |
| `callout` | AIS callout table with `_Callout*` styles | Content should stand out as a key point, differentiator, assumption, risk, decision, or reviewer emphasis. |
| `figure` | `_Figure Title`, image or `_Figure Placeholder`, `_Figure Action Caption` | The response references screenshots, diagrams, process flows, architecture, UX, evidence, or another visual. |
| `table` | AIS table styles `_AIS_tbl_1`, `_AIS_tbl_2`, `_AIS_tbl_3` | Content compares options, maps phases, shows roles, summarizes compliance, or presents structured tradeoffs. |
| `qa` | AIS Q&A Quick Part/table | A solicitation question or direct response prompt should remain visible with the response. |
| `requirement` | `_Req't*` styles | The response needs to preserve Section C/L/M, PWS/SOW, evaluation criteria, or miscellaneous requirement excerpts. |

Figures may embed images from a local path, a path relative to the input JSON,
a repo-relative asset reference, or a base64/data-URI payload. If the final
image is unavailable, use a `figure` block with `width_inches`,
`height_inches`, `alt_text`, and `replacement_guidance` so the generated DOCX
contains a correctly sized placeholder for later replacement.

See `examples/rich-template-input.json` for a complete sample with a theme,
callout, figure placeholder, styled table, requirement block, and Q&A block.

## Gotchas

- **Never create new styles.** The template has 90+ built-in styles and bundled 2025.12 Quick Parts. If you need formatting not covered by existing styles, use the closest semantic construct. Run `validate_styles.py` to verify.
- **Placeholders span runs.** In OOXML, `{{placeholder}}` text may be split across multiple `<w:r>` elements. The generate script handles this by joining all run text before replacement.
- **TOC is not auto-updated.** The Table of Contents uses Word field codes. After generation, the user must open the document in Word and press Ctrl+A → F9 to update the TOC.
- **Cover page is inside SDT blocks.** The cover page content is rendered inside Structured Document Tags. The generate script handles SDT content replacement automatically.
- **Two-sided printing.** The template includes even-page headers/footers (blank) for two-sided printing. These are preserved as-is.
- **Comments need unique IDs.** The inject script auto-generates IDs starting from 200 to avoid conflicts with existing comments.
- **Do not edit template XML with lxml.** lxml strips "unused" namespace declarations and renames prefixes, which breaks `mc:Ignorable` and causes Word's "unreachable content" error. Use string manipulation for template XML edits. The generator's post-processing step automatically repairs namespace declarations after python-docx saves.
- **"Unreachable content" errors.** If Word shows this error, run `--validate` against the file. The most common cause is `mc:Ignorable` listing namespace prefixes without matching `xmlns:` declarations — this must be correct in *every* XML part (document.xml, headers, footers, etc.).

## Reference Materials

For detailed style catalog and template layout documentation:

- [Style Catalog](references/STYLES.md) — Complete list of all 90+ styles with IDs and usage guidance
- [Template Structure](references/TEMPLATE-STRUCTURE.md) — Sections, headers, footers, cover page layout, and paragraph ordering
