# /// script
# dependencies = [
#   "lxml>=5.0.0",
#   "pywin32>=306; platform_system == 'Windows'",
# ]
# requires-python = ">=3.10"
# ///

"""Apply a merge plan, then add true Word reply threads with Word COM."""

from __future__ import annotations

import argparse
import json
import os
import platform
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET

from apply_merge_plan import apply_merge_plan
from docx_redline_lib import (
    DEFAULT_RESPONSE_AUTHOR,
    DEFAULT_RESPONSE_INITIALS,
    SKIP_REPLY_STATUSES,
    emit_skill_identity,
)

WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
WORD15_NS = "http://schemas.microsoft.com/office/word/2012/wordml"
SKIP_STATUSES = SKIP_REPLY_STATUSES


def word_attr(name: str) -> str:
    return f"{{{WORD_NS}}}{name}"


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def require_existing_path(path: str | Path, name: str) -> Path:
    resolved = Path(path).expanduser().resolve()
    if not resolved.exists():
        raise FileNotFoundError(f"{name} does not exist: {resolved}")
    return resolved


def require_word_com():
    if platform.system() != "Windows":
        raise RuntimeError(
            "Word-native reply threading requires Windows with Microsoft Word installed."
        )
    try:
        import win32com.client  # type: ignore[import-not-found]
    except ImportError as exc:
        raise RuntimeError(
            "Word-native reply threading requires pywin32. Install it or run this "
            "script with uv so the declared script dependency can be installed."
        ) from exc
    return win32com.client


def read_xml_from_docx(docx_path: Path, part_name: str) -> ET.Element | None:
    with zipfile.ZipFile(docx_path, "r") as zf:
        try:
            data = zf.read(part_name)
        except KeyError:
            return None
    return ET.fromstring(data)


def word15_attr(name: str) -> str:
    return f"{{{WORD15_NS}}}{name}"


def comment_ids_in_docx(docx_path: Path) -> list[str]:
    comments_root = read_xml_from_docx(docx_path, "word/comments.xml")
    if comments_root is None:
        return []

    comment_ids: list[str] = []
    comment_id_set: set[str] = set()
    for index, comment in enumerate(
        comments_root.findall(f"{{{WORD_NS}}}comment"),
        start=1,
    ):
        comment_id = comment.get(word_attr("id"), "")
        if not comment_id.strip():
            raise ValueError(f"Encountered a comment without a comments.xml ID at index {index}.")
        if comment_id in comment_id_set:
            raise ValueError(f"Duplicate comment ID in comments.xml: {comment_id}.")
        comment_ids.append(comment_id)
        comment_id_set.add(comment_id)

    return comment_ids


def ordered_comment_ids(
    docx_path: Path,
    restrict_to_ids: set[str] | None = None,
) -> list[str]:
    comments_xml_ids = comment_ids_in_docx(docx_path)
    comment_id_set = set(comments_xml_ids)
    if restrict_to_ids is not None:
        comment_id_set &= restrict_to_ids

    document_root = read_xml_from_docx(docx_path, "word/document.xml")
    if document_root is None:
        return [comment_id for comment_id in comments_xml_ids if comment_id in comment_id_set]

    ordered: list[str] = []
    seen: set[str] = set()
    for node in document_root.iter():
        if local_name(node.tag) not in {"commentRangeStart", "commentReference"}:
            continue
        comment_id = node.get(word_attr("id"), "")
        if comment_id in comment_id_set and comment_id not in seen:
            ordered.append(comment_id)
            seen.add(comment_id)

    for comment_id in comments_xml_ids:
        if comment_id not in seen:
            ordered.append(comment_id)

    return ordered


def reviewer_comment_ids(docx_path: Path, response_author: str) -> list[str]:
    return ordered_comment_ids(docx_path)


def missing_threaded_reply_ids(
    docx_path: Path,
    source_comment_ids: list[str],
    target_comment_ids: list[str],
) -> list[str]:
    comments_extended_root = read_xml_from_docx(docx_path, "word/commentsExtended.xml")
    if comments_extended_root is None:
        return target_comment_ids

    comment_ex_entries = list(comments_extended_root)
    original_para_ids = [
        entry.get(word15_attr("paraId"), "")
        for entry in comment_ex_entries
        if not entry.get(word15_attr("paraIdParent"))
    ]
    reply_parent_para_ids = {
        entry.get(word15_attr("paraIdParent"), "")
        for entry in comment_ex_entries
        if entry.get(word15_attr("paraIdParent"))
    }

    missing: list[str] = []
    for comment_id in target_comment_ids:
        try:
            source_index = source_comment_ids.index(comment_id)
        except ValueError:
            missing.append(comment_id)
            continue
        if source_index >= len(original_para_ids):
            missing.append(comment_id)
            continue
        if original_para_ids[source_index] not in reply_parent_para_ids:
            missing.append(comment_id)
    return missing


def actionable_replies(plan: dict[str, Any]) -> list[dict[str, Any]]:
    replies: list[dict[str, Any]] = []
    for reply in plan.get("comment_replies", []):
        reply_text = str(reply.get("reply", "")).strip()
        status = str(reply.get("status", "")).strip().lower()
        if reply_text and status not in SKIP_STATUSES:
            replies.append(reply)
    return replies


def required_reply_comment_ids(plan: dict[str, Any]) -> list[str]:
    required: list[str] = []
    seen: set[str] = set()
    for reply in plan.get("comment_replies", []):
        status = str(reply.get("status", "")).strip().lower()
        if status in SKIP_STATUSES:
            continue
        comment_id = str(reply.get("comment_id", "")).strip()
        if not comment_id:
            raise ValueError("A merge-plan reply is missing comment_id.")
        if comment_id not in seen:
            required.append(comment_id)
            seen.add(comment_id)
    return required


def replies_by_comment_id(replies: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    by_id: dict[str, dict[str, Any]] = {}
    for reply in replies:
        comment_id = str(reply.get("comment_id", "")).strip()
        if not comment_id:
            raise ValueError("A merge-plan reply is missing comment_id.")
        if comment_id in by_id:
            raise ValueError(f"Merge plan contains duplicate replies for comment_id {comment_id}.")
        by_id[comment_id] = reply
    return by_id


def validate_reply_coverage(
    available_comment_ids: list[str],
    required_comment_ids: list[str],
    replies_by_id: dict[str, dict[str, Any]],
) -> None:
    available_id_set = set(available_comment_ids)
    missing_reply_ids = [
        comment_id for comment_id in required_comment_ids if comment_id not in replies_by_id
    ]
    if missing_reply_ids:
        raise ValueError(
            "Merge plan is missing replies for reviewer comment IDs: "
            + ", ".join(missing_reply_ids)
        )

    unknown_reply_ids = [
        comment_id for comment_id in replies_by_id if comment_id not in available_id_set
    ]
    if unknown_reply_ids:
        raise ValueError(
            "Merge plan references comment IDs not found in the document: "
            + ", ".join(unknown_reply_ids)
        )


def add_word_reply_threads(
    base_docx: Path,
    output_docx: Path,
    all_comment_ids: list[str],
    target_comment_ids: list[str],
    replies_by_id: dict[str, dict[str, Any]],
    *,
    author: str,
    initials: str,
) -> dict[str, Any]:
    win32_client = require_word_com()
    word = None
    doc = None
    old_user_name = None
    old_initials = None

    if output_docx.exists():
        output_docx.unlink()

    try:
        word = win32_client.Dispatch("Word.Application")
        word.Visible = False
        word.DisplayAlerts = 0

        old_user_name = word.UserName
        old_initials = word.UserInitials
        word.UserName = author
        word.UserInitials = initials

        doc = word.Documents.Open(str(base_docx), False, False)
        word_comments = []
        for index in range(1, doc.Comments.Count + 1):
            word_comments.append(doc.Comments.Item(index))

        if len(word_comments) != len(all_comment_ids):
            raise RuntimeError(
                f"Word comment count ({len(word_comments)}) does not match "
                f"comments.xml comment count ({len(all_comment_ids)})."
            )

        comments_by_id = dict(zip(all_comment_ids, word_comments))

        for comment_id in target_comment_ids:
            parent = comments_by_id[comment_id]
            before_count = parent.Replies.Count
            reply_text = str(replies_by_id[comment_id].get("reply", "")).strip()
            reply = parent.Replies.Add(parent.Range, reply_text)
            reply.Author = author
            reply.Initial = initials

            if parent.Replies.Count < before_count + 1:
                raise RuntimeError(
                    f"Word did not attach reply to reviewer comment ID {comment_id}."
                )

        doc.SaveAs2(str(output_docx), 16)
        doc.Close(False)
        doc = None

        missing_ids = missing_threaded_reply_ids(
            output_docx,
            all_comment_ids,
            target_comment_ids,
        )
        if missing_ids:
            raise RuntimeError(
                "Missing threaded replies for reviewer comment IDs: "
                + ", ".join(missing_ids)
            )

        word.UserName = old_user_name
        word.UserInitials = old_initials
        word.Quit()
        word = None

        return {
            "output_docx": str(output_docx),
            "reviewer_comments": len(target_comment_ids),
            "threaded_replies_added": len(replies_by_id),
            "validation": (
                "Word COM validation passed: every required original reviewer "
                f"comment has a {author} reply thread."
            ),
        }
    finally:
        if doc is not None:
            doc.Close(False)
        if word is not None:
            if old_user_name is not None:
                word.UserName = old_user_name
            if old_initials is not None:
                word.UserInitials = old_initials
            word.Quit()


def apply_merge_plan_with_word_replies(
    input_docx: str | Path,
    plan_path: str | Path,
    output_docx: str | Path,
    *,
    allow_author_override: bool = False,
    allow_unexplained_changes: bool = False,
) -> dict[str, Any]:
    input_path = require_existing_path(input_docx, "Input DOCX")
    plan_file = require_existing_path(plan_path, "Merge plan")
    output_path = Path(output_docx).expanduser().resolve()
    if not output_path.parent.exists():
        raise FileNotFoundError(f"Output directory does not exist: {output_path.parent}")

    plan = json.loads(plan_file.read_text(encoding="utf-8"))
    settings = plan.get("settings", {})
    author = str(settings.get("author") or DEFAULT_RESPONSE_AUTHOR)
    initials = str(settings.get("initials") or DEFAULT_RESPONSE_INITIALS)
    required_comment_ids = required_reply_comment_ids(plan)
    replies = actionable_replies(plan)
    if not replies:
        if required_comment_ids:
            raise ValueError(
                "Merge plan is missing replies for reviewer comment IDs: "
                + ", ".join(required_comment_ids)
            )
        raise ValueError("Merge plan has no non-empty comment replies.")

    replies_by_id = replies_by_comment_id(replies)
    fd, base_docx_name = tempfile.mkstemp(prefix="ais-redline-base-", suffix=".docx")
    os.close(fd)
    base_docx = Path(base_docx_name)
    try:
        apply_result = apply_merge_plan(
            input_path,
            plan_file,
            base_docx,
            skip_comment_replies=True,
            allow_author_override=allow_author_override,
            allow_unexplained_changes=allow_unexplained_changes,
        )
        all_comment_ids = ordered_comment_ids(base_docx)
        validate_reply_coverage(all_comment_ids, required_comment_ids, replies_by_id)
        target_comment_ids = ordered_comment_ids(base_docx, set(replies_by_id))
        word_result = add_word_reply_threads(
            base_docx,
            output_path,
            all_comment_ids,
            target_comment_ids,
            replies_by_id,
            author=author,
            initials=initials,
        )
        return {**apply_result, **word_result}
    finally:
        try:
            os.remove(base_docx)
        except FileNotFoundError:
            pass
        except PermissionError:
            print(
                f"Warning: temporary DOCX is still locked and could not be removed: {base_docx}",
                file=sys.stderr,
            )


def main() -> int:
    emit_skill_identity()
    parser = argparse.ArgumentParser(
        description=(
            "Apply targeted redline edits, then create true Word reply threads "
            "for reviewer comments."
        )
    )
    parser.add_argument("--input", required=True, help="Path to source pink DOCX.")
    parser.add_argument("--plan", required=True, help="Path to merge-plan JSON.")
    parser.add_argument("--output", required=True, help="Path for output redline DOCX.")
    parser.add_argument(
        "--allow-author-override",
        action="store_true",
        help=(
            "Accept a settings.author that differs from the skill default. Use "
            "only when the deliverable genuinely requires a different identity."
        ),
    )
    parser.add_argument(
        "--allow-unexplained-changes",
        action="store_true",
        help=(
            "Draft-only fallback: apply operations that carry no rationale or "
            "provenance source. Not acceptable for a delivered redline."
        ),
    )
    args = parser.parse_args()

    try:
        result = apply_merge_plan_with_word_replies(
            args.input,
            args.plan,
            args.output,
            allow_author_override=args.allow_author_override,
            allow_unexplained_changes=args.allow_unexplained_changes,
        )
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
