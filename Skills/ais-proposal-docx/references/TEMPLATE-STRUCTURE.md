# AIS Proposal Template — Structure Reference

Detailed layout of the AIS-branded proposal Word template, documenting sections, headers, footers, cover page fields, and paragraph ordering.

The default generator package preserves the existing tokenized title page and
adds the 2025.12 AIS proposal template source/glossary resources. The current
title page remains the standard cover; alternate title pages in the source
template are documented as references, not first-pass generation variants.

## Document Sections

The template has **two sections** with different page numbering and header/footer configurations:

### Section 0 — Cover Page + Table of Contents

| Property | Value |
|----------|-------|
| Page size | 8.5" × 11" (12240 × 15840 twips) |
| Margins | 1" all sides (1440 twips) |
| Header/footer margin | 0.3" (432 twips) |
| Page numbering | Lowercase Roman numerals, starting at 0 |
| Title page | Yes (different first page — cover page has no header/footer) |
| Default header | `header1.xml` — solicitation info bar |
| Default footer | `footer1.xml` — page number + disclaimer |

### Section 1 — Body Content

| Property | Value |
|----------|-------|
| Page size | 8.5" × 11" (12240 × 15840 twips) |
| Margins | 1" all sides (1440 twips) |
| Header/footer margin | 0.3" (432 twips) |
| Page numbering | Arabic numerals, starting at 1 |
| Even header | `header2.xml` — empty (for two-sided printing) |
| Default header | `header3.xml` — solicitation info bar |
| Even footer | `footer2.xml` — empty |
| Default footer | `footer3.xml` — page number + disclaimer |

## Cover Page Layout

The cover page is rendered inside **Structured Document Tags (SDT)**, which are Word content controls. The template has two SDT blocks — one for each cover (front and back of title page for two-sided printing).

Each cover page follows this paragraph order:

```
[tpgTitle]       {{title}}
[tpgInfo]        Solicitation Number: {{solicitation_number}}
[tpgInfo]        {{date}}
[tpgInfo]        (empty)
[tpgVolume]      {{volume_name}}
[tpgVolume]      {{volume_factor}}
[tpgInfo]        (empty)
[tpgInfo]        (empty)
[tpgInfo]        SUBMITTED BY:                    SUBMITTED TO:
[tpgInfo]        {{company_name}}                 {{agency_name}}
[tpgInfo]        {{company_address_line1}}        {{agency_org}}
[tpgInfo]        {{company_address_line2}}        {{agency_address_line1}}
[tpgInfo]        {{company_city_state_zip}}       {{agency_city_state_zip}}
[tpgInfo]        UEI: {{uei}}
[tpgInfo]        (empty)
[tpgInfo]        {{contract_contact_name}}
[tpgInfo]        {{contract_contact_email}}
[tpgInfo]        {{contract_contact_phone}}
[tpgInfo]        {{agency_co_name}}
[tpgInfo]        {{agency_co_email}}
[tpgInfo]        (empty)
[tpgInfo]        {{agency_cs_name}} {{agency_cs_email}}
[tpgDisclaimer]  (empty line)
[tpgDisclaimer]  {{disclaimer_text}}
```

### Cover Page Field Mapping

| Placeholder | Example Value | Notes |
|------------|---------------|-------|
| `{{title}}` | TTS NEXT BPAs Support Area 5 | Document/solicitation title |
| `{{solicitation_number}}` | RFQ1809121 | Solicitation/RFQ number |
| `{{date}}` | May 18, 2026 | Submission date |
| `{{volume_name}}` | Technical Capability | Volume title |
| `{{volume_factor}}` | Technical Factor 1 | Factor designation |
| `{{company_name}}` | Applied Information Sciences | Submitting company |
| `{{company_address_line1}}` | 11440 Commerce Park Drive | Street address line 1 |
| `{{company_address_line2}}` | Suite 600 | Street address line 2 |
| `{{company_city_state_zip}}` | Reston, VA 20191 | City, state, ZIP |
| `{{uei}}` | MGCZNCNTQPE9 | UEI number |
| `{{contract_contact_name}}` | Chelsea Cerwinski, Director of Contracts | AIS contracts contact |
| `{{contract_contact_email}}` | chelsea.cerwinski@ais.com | Contact email |
| `{{contract_contact_phone}}` | 703-860-7832 | Contact phone |
| `{{agency_name}}` | General Services Administration (GSA) | Receiving agency |
| `{{agency_org}}` | Technology Transformation Service (TTS) | Agency organization |
| `{{agency_address_line1}}` | 1800 F St NW | Agency street address |
| `{{agency_city_state_zip}}` | Washington, DC 20405 | Agency city/state/ZIP |
| `{{agency_co_name}}` | Jacqueline McGlone, Contracting Officer | CO name and title |
| `{{agency_co_email}}` | jacqueline.mcglone@gsa.gov | CO email |
| `{{agency_cs_name}}` | Krystal Zoufaly, Contract Specialist | CS name and title |
| `{{agency_cs_email}}` | krystal.zoufaly@gsa.gov | CS email |
| `{{disclaimer_text}}` | This proposal includes data... | Full disclaimer paragraph |

## Header Content

### Default Header (header1.xml / header3.xml)

Contains the AIS logo image and solicitation identification text:

```
{{agency_name}} {{solicitation_number}} {{title}} {{volume_name}}
```

Example: `General Services Administration (GSA) RFQ1809121 TTS NEXT BPAs Support Area 5 Technical Capability`

The header includes an image (AIS logo, `image2.png`, 12708 bytes).

### Even Header (header2.xml)

Empty — used for two-sided printing blank verso pages.

## Footer Content

### Default Footer (footer1.xml / footer3.xml)

Contains page number and proprietary disclaimer:

```
{{page_number}} Use or disclosure of data contained on this sheet is subject to the restriction on the title page of this proposal.
```

The footer includes an image (AIS logo, `image1.png` / `image20.png`, 11096 bytes).

### Even Footer (footer2.xml)

Empty — used for two-sided printing blank verso pages.

## Body Content Structure

After the section break, body content follows this pattern:

```
[Heading1]  Section title (with optional comment anchors)
[Body]      Introduction/overview paragraph
[Body]      Content paragraph
[Body]      Sub-topic label (bold inline, e.g., "Model Governance:")
[Body]      Sub-topic content
...repeat for each sub-topic...

[Heading1]  Next section title
...
```

The generator can also insert semantic proposal constructs in the body:

| JSON block | Word structure | Primary styles |
|------------|----------------|----------------|
| `theme` | Theme paragraph | `_Theme` |
| `callout` | Table-backed callout | `_Callout Title`, `_Callout Text`, `_Callout Bullet` |
| `figure` | Figure title, embedded image or placeholder, action caption | `_Figure Title`, `_Figure Placeholder`, `_Figure Action Caption` |
| `table` | AIS styled table with optional title | `_Table Title`, `_AIS_tbl_1`, `_AIS_tbl_2`, `_AIS_tbl_3`, `_Table*` cell styles |
| `qa` | Q&A table | `_AIS_tbl_Q&A`, `_Q&A Number`, `_Q&A Text` |
| `requirement` | Requirement excerpt paragraph | `_Req't Misc`, `_Req't Section C / PWS/SOW`, `_Req't Section L/ Instrcutions`, `_Req't Section M / Eval Criteria` |

### Paragraph Order in Template

```
P000–P018  Cover pages (inside SDT blocks) + TOC
P019–P021  TOC entries (TOC1 style, auto-generated)
P022–P024  Empty body paragraphs + section break
P025       Heading1: "Federal AI Implementation Approach" [Comments 32, 33]
P026–P040  Body paragraphs (intro, Model Governance, Explainability, Bias, Monitoring)
P041       Heading1: "Evaluating When AI is the Appropriate Solution" [Comment 35]
P042–P044  Body paragraphs
P045       Heading1: "Data Quality, Privacy, and Regulatory Alignment" [Comment 37]
P046–P055  Body paragraphs (intro, Data Quality, Privacy, Regulatory Alignment)
P056–P087  Bookmark ends + trailing body
```

## Comments

Comments are anchored to `Heading1` paragraphs and contain submission criteria:

| Comment ID | Author | Content | Anchored To |
|-----------|--------|---------|-------------|
| 32 | Funk, Joe | Instruction: Describe your approach to implementing AI/ML capabilities... | Heading: Federal AI Implementation Approach |
| 33 | Funk, Joe | Page Limit: 2 pages for entire volume | Heading: Federal AI Implementation Approach |
| 35 | Funk, Joe | Instruction: How do you evaluate when AI is appropriate... | Heading: Evaluating When AI is the Appropriate Solution |
| 37 | Funk, Joe | Instruction: Include how you handle data quality, privacy... | Heading: Data Quality, Privacy, and Regulatory Alignment |

### Comment XML Structure

Comments are stored in `word/comments.xml` and anchored via three elements in `word/document.xml`:

1. `<w:commentRangeStart w:id="32"/>` — Start of commented range
2. `<w:commentRangeEnd w:id="32"/>` — End of commented range
3. `<w:r><w:commentReference w:id="32"/></w:r>` — Reference marker (inside a run)

## Images

| File | Size | Usage |
|------|------|-------|
| `word/media/image1.png` | 11,096 bytes | AIS logo in footer |
| `word/media/image2.png` | 12,708 bytes | AIS logo in header |
| `word/media/image20.png` | 11,096 bytes | AIS logo (duplicate for second section) |

The 2025.12 source template contributes additional media assets used by Quick
Parts and alternate title page references. Generated `figure` blocks may embed
new images from local paths, repo-relative assets, or base64/data-URI payloads.
If source imagery is not ready, generated placeholders should include target
dimensions, alt text or replacement guidance, and a figure caption/action
caption so a human can drop in the final asset without changing the content
flow.

## Quick Parts and Title Page References

The source `.dotx` includes these reusable glossary document parts:

| Name | Category | First implementation status |
|------|----------|-----------------------------|
| `AIS Callout Box` | `AIS Quick Parts` | Implemented as the `callout` block |
| `AIS Q&A` | `AIS Quick Parts` | Implemented as the `qa` block |
| `AIS Title Page 1` | `AIS Title Pages` | Reference only |
| `AIS Title Page 2` | `AIS Title Pages` | Reference only |
| `AIS RFI Title Page` | `AIS Title Pages` | Reference only |
| `AIS White Paper Title Page` | `AIS Title Pages` | Reference only |
| `AIS Federal Proposal Title Page` | `AIS Title Pages` | Reference only |

## Table of Contents

The TOC is inside an SDT block and uses:
- `TOCHeading` style for the "Table of Contents" heading
- `TOC1` style for each entry (auto-generated from Heading1 paragraphs)

The TOC is generated by Word and should be marked for update (field codes), not manually populated.
