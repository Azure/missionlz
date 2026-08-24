# Tracked Changes

The redline workflow enables `w:trackRevisions` in `word/settings.xml` and wraps
targeted paragraph edits in WordprocessingML insertion/deletion elements.

## Practical Caveats

- Structural validation is not the same as visual validation in Word.
- Programmatic OOXML edits can represent text insertions and deletions, but Word
  may display complex table or content-control changes differently than manual
  editing.
- New table cell text is marked as inserted, but the table structure itself may
  need visual confirmation.
- Existing comments are preserved by default. Response comments are added as new
  comments anchored to the same paragraph, not automatically accepted or closed.

## Recommended QA

1. Run `validate_redline_docx.py`.
2. Open the DOCX in Word or render it through the document workflow.
3. Confirm tracked changes are visible and understandable.
4. Confirm reviewer comments and response comments are visible.
5. Confirm formatting, tables, cover page, headers, and footers did not drift.
6. Confirm page counts still satisfy submission limits.
