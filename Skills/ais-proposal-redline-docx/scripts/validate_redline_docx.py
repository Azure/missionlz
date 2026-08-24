# /// script
# dependencies = [
#   "lxml>=5.0.0",
# ]
# requires-python = ">=3.10"
# ///

"""Validate a proposal redline DOCX after merge-plan application."""

from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path

from docx_redline_lib import (
    NS,
    body_paragraphs,
    comments_to_list,
    emit_skill_identity,
    extract_comment_anchors,
    is_generic_reply,
    qn,
    read_xml_part,
    settings_has_track_revisions,
    summarize_provenance,
    tracked_revision_counts,
    validate_merge_plan,
    DEFAULT_RESPONSE_AUTHOR,
)


def _comment_ids_in_document(document_root) -> set[str]:
    ids: set[str] = set()
    for node in document_root.xpath(
        ".//w:commentRangeStart | .//w:commentRangeEnd | .//w:commentReference",
        namespaces=NS,
    ):
        cid = node.get(qn("w", "id"))
        if cid is not None:
            ids.add(cid)
    return ids


def validate_docx(
    input_docx: str | Path,
    expect_reviewer_comments: int | None = None,
    expect_resolution_comments: int | None = None,
    resolution_author: str = DEFAULT_RESPONSE_AUTHOR,
    require_track_revisions: bool = False,
    fail_generic_replies: bool = False,
    plan_path: str | Path | None = None,
    allow_author_override: bool = False,
    allow_unexplained_changes: bool = False,
) -> tuple[dict, list[str]]:
    input_docx = Path(input_docx)
    issues: list[str] = []

    try:
        with zipfile.ZipFile(input_docx, "r") as zf:
            names = set(zf.namelist())
            for required in ("[Content_Types].xml", "word/document.xml"):
                if required not in names:
                    issues.append(f"Missing required part: {required}")

            document_root = read_xml_part(zf, "word/document.xml")
            settings_root = (
                read_xml_part(zf, "word/settings.xml")
                if "word/settings.xml" in names
                else None
            )
            comments_root = (
                read_xml_part(zf, "word/comments.xml")
                if "word/comments.xml" in names
                else None
            )
    except Exception as exc:
        return {"input_docx": str(input_docx), "readable": False}, [str(exc)]

    anchors = extract_comment_anchors(document_root)
    comments = comments_to_list(comments_root, anchors)
    reviewer_comments = [
        comment for comment in comments if comment.get("author") != resolution_author
    ]
    resolution_comments = [
        comment for comment in comments if comment.get("author") == resolution_author
    ]
    revisions = tracked_revision_counts(document_root)
    track_revisions = settings_has_track_revisions(settings_root)

    if require_track_revisions and not track_revisions:
        issues.append("Tracked revisions are not enabled in word/settings.xml")

    if expect_reviewer_comments is not None and len(reviewer_comments) < expect_reviewer_comments:
        issues.append(
            f"Expected at least {expect_reviewer_comments} reviewer comments; "
            f"found {len(reviewer_comments)}"
        )

    if expect_resolution_comments is not None and len(resolution_comments) < expect_resolution_comments:
        issues.append(
            f"Expected at least {expect_resolution_comments} resolution comments; "
            f"found {len(resolution_comments)}"
        )

    if fail_generic_replies:
        generic = [
            comment.get("id", "")
            for comment in resolution_comments
            if is_generic_reply(str(comment.get("text", "")))
        ]
        if generic:
            issues.append(
                "Generic resolution comments found: " + ", ".join(str(cid) for cid in generic)
            )

    defined_comment_ids = {str(comment.get("id", "")) for comment in comments}
    anchored_ids = _comment_ids_in_document(document_root)
    missing_definitions = sorted(anchored_ids - defined_comment_ids)
    if missing_definitions:
        issues.append(
            "Comment anchors without matching comments.xml definitions: "
            + ", ".join(missing_definitions)
        )

    provenance_counts: dict[str, int] = {}
    if plan_path is not None:
        try:
            plan = json.loads(Path(plan_path).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            issues.append(f"Could not load merge plan {plan_path}: {exc}")
        else:
            plan_errors = validate_merge_plan(
                plan,
                paragraph_count=len(body_paragraphs(document_root)),
                allow_author_override=allow_author_override,
                require_provenance=not allow_unexplained_changes,
            )
            issues.extend(plan_errors)
            provenance_counts = summarize_provenance(plan)

    summary = {
        "input_docx": str(input_docx),
        "readable": True,
        "resolution_author": resolution_author,
        "resolution_author_override": resolution_author != DEFAULT_RESPONSE_AUTHOR,
        "track_revisions_enabled": track_revisions,
        "comment_count": len(comments),
        "reviewer_comment_count": len(reviewer_comments),
        "resolution_comment_count": len(resolution_comments),
        "threaded_reply_readiness": "not_validated_by_structural_check",
        "inserted_revision_count": revisions["insertions"],
        "deleted_revision_count": revisions["deletions"],
        "provenance_counts": provenance_counts,
        "issues": issues,
    }
    return summary, issues


def main() -> int:
    emit_skill_identity()
    parser = argparse.ArgumentParser(
        description="Validate DOCX package, comments, response comments, and tracked-change indicators."
    )
    parser.add_argument("--input", required=True, help="Path to redline DOCX.")
    parser.add_argument("--expect-reviewer-comments", type=int)
    parser.add_argument("--expect-resolution-comments", type=int)
    parser.add_argument(
        "--resolution-author",
        default=DEFAULT_RESPONSE_AUTHOR,
        help=(
            "Author name used for response comments. Supplying this suppresses the "
            "mismatch signal, so leave it unset unless the deliverable genuinely "
            "uses a different identity."
        ),
    )
    parser.add_argument("--require-track-revisions", action="store_true")
    parser.add_argument("--fail-generic-replies", action="store_true")
    parser.add_argument(
        "--plan",
        help="Optional merge-plan JSON to validate against the change-provenance contract.",
    )
    parser.add_argument(
        "--allow-author-override",
        action="store_true",
        help="Accept a merge-plan settings.author that differs from the skill default.",
    )
    parser.add_argument(
        "--allow-unexplained-changes",
        action="store_true",
        help=(
            "Validate a draft produced with the applier's provenance waiver. "
            "Do not use for a deliverable-ready redline."
        ),
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    args = parser.parse_args()

    summary, issues = validate_docx(
        args.input,
        expect_reviewer_comments=args.expect_reviewer_comments,
        expect_resolution_comments=args.expect_resolution_comments,
        resolution_author=args.resolution_author,
        require_track_revisions=args.require_track_revisions,
        fail_generic_replies=args.fail_generic_replies,
        plan_path=args.plan,
        allow_author_override=args.allow_author_override,
        allow_unexplained_changes=args.allow_unexplained_changes,
    )

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        status = "FAILED" if issues else "PASSED"
        print(f"Validation {status}: {args.input}")
        print(json.dumps(summary, indent=2))

    return 1 if issues else 0


if __name__ == "__main__":
    raise SystemExit(main())
