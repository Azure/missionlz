# Merge Strategy

Use this workflow when reviewers expect edits in the existing pink DOCX rather
than a regenerated red draft.

## Operating Model

1. Start from the pink DOCX.
2. Extract reviewer comments and paragraph anchors.
3. Draft the revised content outside the document.
4. Convert the approved edits into a small merge plan.
5. Apply only those targeted operations.
6. Validate comments, tracked revisions, and package structure.
7. Open or render the result for visual QA.

The merge plan is intentionally explicit. It prevents broad rewrites from
changing cover pages, form tables, headers, footers, or page discipline.

## Supported Operations

Use `replace_paragraph_text` for a direct paragraph replacement when the target
paragraph is simple body text.

Use `insert_paragraph_after` when replacing the paragraph would risk disturbing
nearby comments, table structures, or reviewer anchors.

Use `insert_table_after` only for bounded tables that are explicitly part of the
red-draft change. Keep rows and cells small; verify formatting visually.

## Provenance Is Part of the Operation

Every enabled operation must declare `rationale` and `source`, and may reference
a `theme`. This is enforced by the applier and the validator, and the plan is
validated in full before anything is written. See
[Change Provenance](CHANGE-PROVENANCE.md) for the field grammar, theme rollup,
and how the run summary reports where a redline came from.

Plan the provenance while planning the operation. Deciding the rationale after
the edit is written tends to produce a description of the edit rather than a
reason for it, which is the same as no rationale from a reviewer's point of
view.

## What to Avoid

- Do not use paragraph operations on complex image, field, footnote, or content
  control paragraphs without visual QA.
- Do not target by text search alone; use extracted paragraph indices and inspect
  surrounding text.
- Do not use broad section regeneration for a form that must preserve formatting.
- Do not accept or remove reviewer comments unless the user explicitly asks.

## Page Limits

The scripts do not calculate page count. After applying a merge plan, render or
open the DOCX and verify that the edited sections still meet page limits.

Comments are not part of that measurement. A page limit is assessed with
revisions accepted and comments removed, so explanation comments never cost
page budget. Keep them proportionate for reviewer attention, not for length.
