# AIS Proposal Template — Style Catalog

Complete catalog of all styles defined in the AIS-branded proposal Word template. These styles must be preserved exactly — never create new styles during document generation.

The default generator template now carries the 2025.12 AIS proposal Quick Parts
source while preserving the existing templatized title page. Body generation
should use semantic constructs where they fit the proposal content: callouts for
key takeaways, figures/placeholders for visual evidence, Q&A blocks for
solicitation prompts, and AIS table styles for structured comparison or
traceability.

## Style Hierarchy

The template uses a layered style architecture:

```
Base styles (zBase_*)     → Define shared formatting foundations
  ├── Content styles      → Body, Heading, Bullet, etc. (what authors use)
  ├── Cover page styles   → tpg* (title page specific)
  ├── Table styles        → _Table*, _AIS_tbl_*
  └── Utility styles      → _Footer, _Header, _PILB, _tiny, etc.
```

## Paragraph Styles — Content

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `Body` | `_Body` | `zBaseBody` | Standard body text. Primary content style. |
| `Body0after` | `_Body_0_after` | `zBaseBody` | Body text with zero spacing after. |
| `Heading1` | `heading 1` | `zBaseHeading123` | Numbered top-level section headings. |
| `Heading2` | `heading 2` | `zBaseHeading123` | Numbered second-level headings. |
| `Heading3` | `heading 3` | `zBaseHeading123` | Numbered third-level headings. |
| `Heading4` | `heading 4` | `zBaseHeading123` | Fourth-level headings. |
| `Heading5` | `heading 5` | `Heading4` | Fifth-level headings. |
| `Heading6`–`Heading9` | `heading 6`–`9` | `Normal` | Lower-level headings (rarely used). |
| `HeadingA` | `_Heading A` | `zBaseHeadingAB` | Unnumbered heading, style A. |
| `HeadingB` | `_Heading B` | `zBaseHeadingAB` | Unnumbered heading, style B. |
| `UnnumberedHeadingforTOC` | `_Unnumbered Heading for TOC` | `Heading1` | Unnumbered heading that appears in TOC. |

## Paragraph Styles — Lists

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `Bullet1` | `_Bullet1` | `Body` | Level 1 bullet list item. |
| `Bullet10after` | `_Bullet1_0_after` | `Bullet1` | Level 1 bullet, zero spacing after. |
| `Bullet2` | `_Bullet2` | `Bullet1` | Level 2 bullet list item. |
| `Bullet20after` | `_Bullet2_0_after` | `Bullet2` | Level 2 bullet, zero spacing after. |
| `Bullet3` | `_Bullet3` | `Bullet2` | Level 3 bullet list item. |
| `Bullet30after` | `_Bullet3_0_after` | `Bullet3` | Level 3 bullet, zero spacing after. |
| `ListParagraph` | `List Paragraph` | `Normal` | Generic list paragraph (Word built-in). |

## Paragraph Styles — Cover Page (Title Page)

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `tpgTitle` | `_tpgTitle` | `zBaseTitlePage` | Document title on cover page. |
| `tpgInfo` | `_tpgInfo` | `zBaseTitlePage` | Cover page info fields (solicitation, contacts, addresses). |
| `tpgVolume` | `_tpgVolume` | `zBaseTitlePage` | Volume/factor labels on cover page. |
| `tpgDisclaimer` | `_tpgDisclaimer` | `zBaseTitlePage` | Proprietary information disclaimer text. |

## Paragraph Styles — Tables

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `TableBody` | `_Table Body` | `zBaseTable` | Table cell body text. |
| `TableBodyCentered` | `_Table Body Centered` | `TableBody` | Centered table cell text. |
| `TableBullet1` | `_Table Bullet1` | `TableBody` | Bullet list inside table cell. |
| `TableBullet2` | `_Table Bullet2` | `TableBullet1` | Level 2 bullet inside table cell. |
| `TableHeader` | `_Table Header` | `zBaseTable` | Table header row text. |
| `TableHeaderLeft` | `_Table Header Left` | `TableHeader` | Left-aligned table header. |
| `TableSubheader` | `_Table Subheader` | `TableHeader` | Table subheader row text. |
| `TableTitle` | `_Table Title` | `zBaseFigTable` | Table caption/title. |

## Paragraph Styles — Callouts

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `CalloutText` | `_Callout Text` | `zBaseTable` | Text inside callout boxes. |
| `CalloutBullet` | `_Callout Bullet` | `CalloutText` | Bullet list inside callout boxes. |
| `CalloutTitle` | `_Callout Title` | `TableHeader` | Title of a callout box. |

## Paragraph Styles — Figures

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `FigurePlaceholder` | `_Figure Placeholder` | `zBaseBody` | Placeholder for figure image. |
| `FigureTitle` | `_Figure Title` | `zBaseFigTable` | Figure caption. |
| `FigureActionCaption` | `_Figure Action Caption` | `zBaseBody` | Action-oriented figure caption. |

## Paragraph Styles — TOC

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `TOCHeading` | `TOC Heading` | `Heading1` | "Table of Contents" heading. |
| `TOC1`–`TOC9` | `toc 1`–`toc 9` | Various | TOC entry levels. |

## Paragraph Styles — Page Elements

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `Header` | `header` | `Normal` | Built-in header style. |
| `Header0` | `_Header` | `zBasePageMargin` | Custom header style. |
| `Footer` | `_Footer` | `zBasePageMargin` | Custom footer style. |
| `Footer0` | `footer` | `Normal` | Built-in footer style. |
| `FooterDisclaimer` | `_Footer Disclaimer` | `zBasePageMargin` | Footer disclaimer text. |

## Paragraph Styles — Requirements

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `ReqtMisc` | `_Req't Misc` | `zBaseReqt` | Miscellaneous requirement text. |
| `ReqtSectionLInstrcutions` | `_Req't Section L/ Instrcutions` | `ReqtMisc` | Section L instructions. |
| `ReqtSectionMEvalCriteria` | `_Req't Section M / Eval Criteria` | `ReqtMisc` | Section M evaluation criteria. |
| `ReqtSectionCPWSSOW` | `_Req't Section C / PWS/SOW` | `ReqtMisc` | Section C PWS/SOW requirements. |

## Paragraph Styles — Specialty

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `QAText` | `_Q&A Text` | `zBaseBody` | Q&A response text. |
| `QANumber` | `_Q&A Number` | `TableHeader` | Q&A question number. |
| `PILB` | `_PILB` | `zBaseTable` | Proposal Information Label Block. |
| `PILB11x17` | `_PILB 11x17` | `PILB` | PILB for 11x17 pages. |
| `Theme` | `_Theme` | `zBaseBody` | Theme/topic text. |
| `tiny` | `_tiny` | (none) | Tiny/hidden text. |

## Character Styles

| Style ID | Display Name | Usage |
|----------|-------------|-------|
| `ChBold` | `_Ch Bold` | Bold character formatting. |
| `ChItalic` | `_Ch Italic` | Italic character formatting. |
| `ChEmphasizedText` | `_Ch Emphasized Text` | Emphasized/highlighted text. |
| `Hyperlink` | `Hyperlink` | Hyperlink text formatting. |
| `FollowedHyperlink` | `FollowedHyperlink` | Visited hyperlink formatting. |
| `CommentReference` | `annotation reference` | Comment reference marker. |
| `PlaceholderText` | `Placeholder Text` | Content control placeholder. |
| `UnresolvedMention` | `Unresolved Mention` | @-mention formatting. |

## Table Styles

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `TableGrid` | `Table Grid` | `TableNormal` | Standard grid table. |
| `AIStbl0` | `_AIS_tbl_0` | `TableGrid` | AIS base table style. |
| `AIStbl1` | `_AIS_tbl_1` | `AIStbl0` | AIS table variant 1. |
| `AIStbl2` | `_AIS_tbl_2` | `AIStbl1` | AIS table variant 2. |
| `AIStbl3` | `_AIS_tbl_3` | `AIStbl0` | AIS table variant 3. |
| `AIStblQA` | `_AIS_tbl_Q&A` | `TableGrid` | AIS Q&A table style. |

## 2025.12 Quick Parts Source

The source template includes reusable Word Quick Parts. The generator may clone
or reconstruct these structures with the same table geometry and styles:

| Quick Part | Category | Generator Use |
|------------|----------|---------------|
| `AIS Callout Box` | `AIS Quick Parts` | `callout` semantic block |
| `AIS Q&A` | `AIS Quick Parts` | `qa` semantic block |
| `AIS Title Page 1` | `AIS Title Pages` | Reference only; current templatized title page remains standard |
| `AIS Title Page 2` | `AIS Title Pages` | Reference only |
| `AIS RFI Title Page` | `AIS Title Pages` | Reference only |
| `AIS White Paper Title Page` | `AIS Title Pages` | Reference only |
| `AIS Federal Proposal Title Page` | `AIS Title Pages` | Reference only |

## Numbering Styles

| Style ID | Display Name | Based On | Usage |
|----------|-------------|----------|-------|
| `NumList` | `_NumList` | (none) | Numbered list definition. |
| `Bullets` | `_Bullets` | `NoList` | Bullet list definition. |

## Base Styles (Internal — Do Not Use Directly)

| Style ID | Display Name | Purpose |
|----------|-------------|---------|
| `zBaseBody` | `zBase_Body` | Foundation for body text styles. |
| `zBaseFigTable` | `zBase_Fig Table` | Foundation for figure/table caption styles. |
| `zBaseHeading123` | `zBase_Heading_123` | Foundation for numbered headings 1-3. |
| `zBaseHeadingAB` | `zBase_Heading_AB` | Foundation for unnumbered headings A/B. |
| `zBaseTable` | `zBase_Table` | Foundation for table cell text styles. |
| `zBasePageMargin` | `zBase_PageMargin` | Foundation for header/footer styles. |
| `zBaseReqt` | `zBase_Req't` | Foundation for requirement styles. |
| `zBaseTitlePage` | `zBase_TitlePage` | Foundation for cover page styles. |
| `zColor0`–`zColor3` | `zColor0`–`zColor3` | Color palette definition styles. |

## Critical Rules

1. **Never create new styles.** All paragraph, character, table, and numbering styles already exist in the template. The generate script must only reference existing style IDs.
2. **Use style IDs, not display names.** When setting `paragraph.style`, use the ID (e.g., `Body`, `Heading1`, `Bullet1`) not the display name (e.g., `_Body`, `heading 1`).
3. **Preserve the base style hierarchy.** Do not modify base styles (`zBase_*`) — they cascade to all derived styles.
4. **Use `_0_after` variants** when a paragraph should have zero spacing after (e.g., last item in a bullet list before body text).
