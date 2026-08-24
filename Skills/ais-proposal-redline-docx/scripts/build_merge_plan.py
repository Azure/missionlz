# /// script
# dependencies = [
#   "lxml>=5.0.0",
# ]
# requires-python = ">=3.10"
# ///

"""Build a merge-plan skeleton from extracted proposal review context."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from docx_redline_lib import (
    DEFAULT_RESPONSE_AUTHOR,
    DEFAULT_RESPONSE_INITIALS,
    emit_skill_identity,
)


def build_merge_plan(
    review_context: dict,
    source_docx: str = "",
    output_docx: str = "",
    author: str = DEFAULT_RESPONSE_AUTHOR,
    initials: str = DEFAULT_RESPONSE_INITIALS,
) -> dict:
    comments = review_context.get("comments", [])
    source = source_docx or review_context.get("source_docx", "")

    return {
        "source_docx": source,
        "output_docx": output_docx,
        "settings": {
            "author": author,
            "initials": initials,
            "enable_track_revisions": True,
            "preserve_comments": True,
        },
        "themes": [],
        "operations": [],
        "comment_replies": [
            {
                "comment_id": str(comment.get("id", "")),
                "anchor_paragraph_index": comment.get("anchor_paragraph_index", -1),
                "anchor_text": comment.get("anchor_text", ""),
                "reviewer_comment": comment.get("text", ""),
                "status": "needs_response",
                "reply": "",
            }
            for comment in comments
        ],
        "validation": {
            "expect_reviewer_comments": len(comments),
            "expect_resolution_comments": 0,
            "fail_generic_replies": True,
        },
        "operation_examples": [
            {
                "type": "replace_paragraph_text",
                "paragraph_index": 12,
                "style": "_Body",
                "text": "Replacement paragraph text.",
                "rationale": "Reworded the capability claim so it matches the evidence cited in the past-performance table.",
                "source": "reviewer_comment:4",
            },
            {
                "type": "insert_paragraph_after",
                "paragraph_index": 12,
                "style": "_Body",
                "text": "Inserted paragraph text.",
                "rationale": "Added the transition the review call asked for between the approach and the staffing narrative.",
                "source": "review_call:RC-02",
            },
            {
                "type": "insert_table_after",
                "paragraph_index": 12,
                "style": "TableGrid",
                "rows": [["Column 1", "Column 2"], ["Value 1", "Value 2"]],
                "rationale": "Summarised the phase model in a table because the narrative form exceeded the section page budget.",
                "source": "compliance:F-1",
            },
        ],
        "theme_examples": [
            {
                "id": "editorial-voice",
                "rationale": "Applied the active-voice and plain-language pass agreed on the review call across the response.",
                "source": "review_call:RC-12",
                "anchor_paragraph_index": 12,
            }
        ],
    }


def main() -> int:
    emit_skill_identity()
    parser = argparse.ArgumentParser(
        description="Create a human-reviewable redline merge-plan JSON skeleton."
    )
    parser.add_argument(
        "--review-context",
        required=True,
        help="Path to JSON produced by extract_review_context.py.",
    )
    parser.add_argument(
        "--source-docx",
        default="",
        help="Optional source DOCX path to place in the merge plan.",
    )
    parser.add_argument(
        "--output-docx",
        default="",
        help="Optional output DOCX path to place in the merge plan.",
    )
    parser.add_argument(
        "--author",
        default=DEFAULT_RESPONSE_AUTHOR,
        help="Author used for tracked revisions and response comments.",
    )
    parser.add_argument(
        "--initials",
        default=DEFAULT_RESPONSE_INITIALS,
        help="Initials used for response comments.",
    )
    parser.add_argument(
        "--output",
        help="Path to write the merge plan. If omitted, writes to stdout.",
    )
    args = parser.parse_args()

    try:
        context = json.loads(Path(args.review_context).read_text(encoding="utf-8"))
        plan = build_merge_plan(
            context,
            source_docx=args.source_docx,
            output_docx=args.output_docx,
            author=args.author,
            initials=args.initials,
        )
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    output = json.dumps(plan, indent=2, ensure_ascii=False)
    if args.output:
        Path(args.output).write_text(output + "\n", encoding="utf-8")
        print(f"Wrote merge plan skeleton to {args.output}", file=sys.stderr)
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
