---
name: ais-proposal-redline-docx
description: >-
  Modify existing AIS proposal Word drafts by merging red-draft content into
  pink DOCX forms while preserving formatting, reviewer comments, tracked
  changes, and comment-response traceability. Use when asked to revise an
  existing reviewed proposal document instead of generating a new DOCX from
  scratch.
license: Proprietary
compatibility: >-
  Requires Python 3.10+ and uv (https://docs.astral.sh/uv/).
  Final threaded replies require Windows, Microsoft Word, and pywin32.
metadata:
  author: ais-internal
  version: "2.0"
---

# AIS Proposal Redline DOCX

Use this skill for pink-to-red proposal revision when the reviewed DOCX is the
source of truth. The goal is to preserve the existing form, tables, styles,
comments, and page discipline while applying targeted content changes and
documenting how reviewer feedback was addressed.

Use `ais-proposal-docx` instead when the user wants to generate a new proposal
document from structured JSON.

## Principles

- Treat the pink DOCX as the source of truth.
- **Every change is self-explaining.** A reviewer opening the red draft must be
  able to see what changed and why without a side document. Each operation
  carries its own `rationale` and declares its `source`; a document-wide
  decision is declared once as a theme and referenced by its members. The
  applier anchors an explanation comment to the changed range, so explanation
  travels with the change rather than with the comment that happened to trigger
  it. Changes that only answer a reviewer comment leave the rest of the redline
  unexplained, which is what makes a red draft hard to review.
- Make text-only edits unless a bounded table insertion is explicitly needed.
- Preserve existing comments; do not accept, delete, or resolve them by default.
- Add concise response comments that state what changed and how it addressed the
  reviewer feedback.
- Use `AIS Specify` as the generated author identity for tracked revisions and
  response comments unless the user explicitly requires a different author. The
  merge plan pins this value and the tooling rejects a plan that carries a
  different author unless the run passes `--allow-author-override`.
- When a merge plan contains reviewer-response comments, create those responses
  with `apply_merge_plan_with_word_replies.py`. This is the default and
  required path for real Word reply threads because it uses Microsoft Word's
  native `Comment.Replies.Add()` API and validates that every original reviewer
  comment has at least one reply.
- Enable tracked revisions and validate structurally, then visually QA the final
  DOCX in Word or through a render workflow before delivery.
- Keep Track Changes enabled during any follow-up Word automation or manual
  content/layout edits. Do not disable tracking for page-fit changes, image
  placement, table replacement, or past-performance updates unless the change is
  intentionally non-substantive and documented.
- Do not invent metrics, past performance claims, or compliance assertions. Mark
  unsupported claims for user confirmation.

## Skill Integrity

The copy of this skill in the repository at
`Skills/ais-proposal-redline-docx/` is authoritative. Any copy under an agent
skills cache such as `~/.agents/skills/ais-proposal-redline-docx/` is a
derived install that can go stale and silently take precedence at load time.

Every script prints a one-line identity banner to stderr on each run, for
example `[skill] ais-proposal-redline-docx v2.0 (<path>)`. Read it. If the path
is not the repository copy, or the version is not the version in this file,
refresh the cache before trusting the output. See
[Skill Integrity](references/SKILL-INTEGRITY.md).

## Available Scripts

- `scripts/extract_review_context.py` - extracts comments, anchors, paragraphs,
  table counts, and tracked-change state from a DOCX.
- `scripts/build_merge_plan.py` - creates a merge-plan skeleton from extracted
  review context.
- `scripts/apply_merge_plan.py` - applies targeted paragraph/table operations
  to the existing DOCX. Use `--skip-comment-replies` when replies will be added
  through Word automation. Use `--allow-root-response-comments` only for an
  explicitly accepted draft-only fallback. Do not use this script alone for
  final deliverables that require threaded replies.
- `scripts/apply_merge_plan_with_word_replies.py` - applies the merge plan,
  then uses Microsoft Word's native `Comment.Replies.Add()` API to create real
  threaded replies for each original reviewer comment. Use this as the normal
  apply step whenever `comment_replies[]` contains reviewer responses.
- `scripts/validate_redline_docx.py` - validates the resulting DOCX for package
  health, comments, response comments, and tracked-change indicators.

## Workflow

### 1. Extract reviewer context

```bash
uv run Skills/ais-proposal-redline-docx/scripts/extract_review_context.py \
  --input pink.docx \
  --output review-context.json
```

Read the extracted comments in context before drafting changes. Use paragraph
indices from this file as anchors for merge-plan operations.

### 2. Build a merge plan

```bash
uv run Skills/ais-proposal-redline-docx/scripts/build_merge_plan.py \
  --review-context review-context.json \
  --source-docx pink.docx \
  --output-docx redline.docx \
  --output merge-plan.json
```

Fill `operations` with only the needed changes. Fill every applicable
`comment_replies[].reply` with a specific response. Leave uncertain items as
`needs_confirmation` rather than forcing unsupported content.

Supported operation types:

- `replace_paragraph_text`
- `insert_paragraph_after`
- `insert_table_after`

Every enabled operation must carry:

- `rationale` - what changed and why, in reviewer language. Stock phrases such
  as `Addressed.` are rejected.
- `source` - one of `reviewer_comment:<id>`, `review_call:<id>`,
  `compliance:<rule-id>`, or `internal_qa`. The grammar is closed so the run
  summary can report how many changes came from each kind of driver.
- `theme` - optional. Reference a `themes[]` entry when the change is one
  instance of a document-wide decision.

Declare a `themes[]` entry when the same reasoning applies to several
operations. The theme carries the `rationale`, `source`, and an
`anchor_paragraph_index`, and produces exactly one comment for the whole group.
This keeps a single editorial decision from arriving as a dozen identical
notes, which is the failure mode that makes reviewers stop reading comments.

Disabled operations (`"enabled": false`) are exempt because nothing reaches the
document.

The plan is validated in full before the applier writes anything, so a bad plan
yields a complete list of problems and no partial output.

See `examples/merge-plan.sample.json`, `schemas/merge-plan.schema.json`, and
[Change Provenance](references/CHANGE-PROVENANCE.md).

### 3. Apply the merge plan

```bash
uv run Skills/ais-proposal-redline-docx/scripts/apply_merge_plan_with_word_replies.py \
  --input C:\absolute\path\pink.docx \
  --plan C:\absolute\path\merge-plan.json \
  --output C:\absolute\path\redline.docx
```

The script preserves the DOCX package, edits the targeted body XML, enables
tracked revisions in document settings, and adds threaded replies for reviewer
comments with non-empty replies. This wrapper requires Windows, Microsoft Word,
and pywin32 because it uses Word COM through Python. If Word automation is
unavailable, run `apply_merge_plan.py` directly only for a no-replies merge
plan, or pass `--allow-root-response-comments` for a draft-only fallback that
does not satisfy final threaded-reply readiness. Final deliverables with
required reviewer reply threads must either run this wrapper on Windows with
Word installed or be manually repaired and validated in Word before delivery.

### 4. Validate the redline DOCX

```bash
uv run Skills/ais-proposal-redline-docx/scripts/validate_redline_docx.py \
  --input redline.docx \
  --plan merge-plan.json \
  --require-track-revisions \
  --fail-generic-replies
```

Pass `--plan` so the validator re-checks provenance and the pinned response
author against the plan that produced the deliverable. Use
`--expect-reviewer-comments` and `--expect-resolution-comments` when counts are
known. Prefer leaving `--resolution-author` unset: overriding it to match
whatever the document contains removes the mismatch signal that catches a
wrong-author run. Structural validation reports package/comment health and the
`AIS Specify` response author default, but it does not prove Word-native
threaded-reply readiness. A passing structural validation does not replace
visual QA.

### 5. Visual QA

Open or render the DOCX and verify:

- page limits are still met
- formatting, tables, headers, footers, and cover-page fields did not drift
- comments are preserved and response comments are visible
- every substantive change carries a visible explanation comment, and each
  theme's explanation appears exactly once
- tracked insertions/deletions are understandable
- follow-up content additions, image/table replacements, and formatting changes
  appear in revision markup when they are substantive proposal edits
- no generic comment responses remain

### 6. Create Recovery Report

Create a recovery report that accompanies the recovered draft for the current
gate transition. Name the transition explicitly, such as Pink-to-Red,
Red-to-Gold, Gold-to-White-Glove, or White-Glove-to-Final. The report should be
a concise handoff artifact for the pursuit lead and proposal manager, not an
engineering log dump. Use it to explain what content changed, why it changed,
what gate or reviewer feedback drove the change, impact to
compliance/page budget/risk, validation evidence, and any open actions before
the next Shipley-style gate.

For Pink-to-Red recovery, focus on Pink reviewer comment disposition and content
changes in the recovered Red draft. Do not include internal tool-debugging
history unless it materially affects submission risk or the deliverable's
reviewability.

When the recovery report accompanies a proposal redline, generate it with the
proposal-branded DOCX workflow (`ais-proposal-docx`) or the current proposal
template so the report uses the same cover page, headers/footers, and proposal
style catalog as the response package.

Name the recovery report from the recovered draft name so it sorts with the
draft package. Preserve the draft gate prefix and HubSpot/opportunity ID when
known from project context or the draft filename. If the ID is not known, keep
the gate prefix and draft title without inventing one.

Examples:

- `Red - 60353159195 - USDA AI Assisted Dev RFI Solution Brief.docx` ->
  `Red - 60353159195 - USDA AI Assisted Dev RFI Solution Brief - Recovery Report.docx`
- `Red - USDA AI Assisted Dev RFI Solution Brief.docx` ->
  `Red - USDA AI Assisted Dev RFI Solution Brief - Recovery Report.docx`

Required recovery sections:

- Recovery summary
- Gate context and recovery trigger
- Change ledger
- Impact assessment
- Validation evidence
- Open items and owner/action/date
- Recommended next gate decision

See `references/RECOVERY-REPORT.md`.

## Reference Materials

- [Merge Strategy](references/MERGE-STRATEGY.md)
- [Change Provenance](references/CHANGE-PROVENANCE.md)
- [Comment Replies](references/COMMENT-REPLIES.md)
- [Tracked Changes](references/TRACKED-CHANGES.md)
- [Skill Integrity](references/SKILL-INTEGRITY.md)
- [Recovery Report](references/RECOVERY-REPORT.md)
- [Merge Plan Schema](schemas/merge-plan.schema.json)
