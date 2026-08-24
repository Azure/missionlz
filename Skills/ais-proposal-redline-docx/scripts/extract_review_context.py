# /// script
# dependencies = [
#   "lxml>=5.0.0",
# ]
# requires-python = ">=3.10"
# ///

"""Extract reviewer context from a pink proposal DOCX."""

from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path

from docx_redline_lib import (
    body_paragraphs,
    body_tables,
    comments_to_list,
    emit_skill_identity,
    extract_comment_anchors,
    paragraph_style,
    paragraph_text,
    read_xml_part,
    settings_has_track_revisions,
    tracked_revision_counts,
)


def extract_review_context(docx_path: str | Path) -> dict:
    docx_path = Path(docx_path)
    if not docx_path.exists():
        raise FileNotFoundError(docx_path)

    with zipfile.ZipFile(docx_path, "r") as zf:
        names = set(zf.namelist())
        document_root = read_xml_part(zf, "word/document.xml")
        comments_root = (
            read_xml_part(zf, "word/comments.xml")
            if "word/comments.xml" in names
            else None
        )
        settings_root = (
            read_xml_part(zf, "word/settings.xml")
            if "word/settings.xml" in names
            else None
        )

    paragraphs = []
    for idx, paragraph in enumerate(body_paragraphs(document_root)):
        text = paragraph_text(paragraph)
        paragraphs.append(
            {
                "index": idx,
                "style": paragraph_style(paragraph),
                "text": text,
                "text_preview": text[:240],
            }
        )

    anchors = extract_comment_anchors(document_root)
    comments = comments_to_list(comments_root, anchors)
    revisions = tracked_revision_counts(document_root)
    table_count = len(body_tables(document_root))

    return {
        "source_docx": str(docx_path),
        "review_summary": {
            "comment_count": len(comments),
            "paragraph_count": len(paragraphs),
            "table_count": table_count,
            "track_revisions_enabled": settings_has_track_revisions(settings_root),
            "inserted_revision_count": revisions["insertions"],
            "deleted_revision_count": revisions["deletions"],
        },
        "comments": comments,
        "paragraphs": paragraphs,
    }


def main() -> int:
    emit_skill_identity()
    parser = argparse.ArgumentParser(
        description="Extract reviewer comments, anchors, paragraphs, and tracked-change state from a DOCX."
    )
    parser.add_argument("--input", required=True, help="Path to the pink/reviewed DOCX.")
    parser.add_argument(
        "--output",
        help="Path to write review context JSON. If omitted, writes to stdout.",
    )
    args = parser.parse_args()

    try:
        context = extract_review_context(args.input)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    output = json.dumps(context, indent=2, ensure_ascii=False)
    if args.output:
        Path(args.output).write_text(output + "\n", encoding="utf-8")
        print(
            f"Extracted {context['review_summary']['comment_count']} comments and "
            f"{context['review_summary']['paragraph_count']} paragraphs to {args.output}",
            file=sys.stderr,
        )
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
