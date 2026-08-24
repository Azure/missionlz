from __future__ import annotations

import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[4]
SCRIPT_DIR = REPO_ROOT / "Skills" / "ais-proposal-redline-docx" / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))

from apply_merge_plan import apply_merge_plan  # noqa: E402
from apply_merge_plan_with_word_replies import (  # noqa: E402
    actionable_replies,
    apply_merge_plan_with_word_replies,
    missing_threaded_reply_ids,
    ordered_comment_ids,
    replies_by_comment_id,
    required_reply_comment_ids,
    validate_reply_coverage,
)
from build_merge_plan import build_merge_plan  # noqa: E402
from docx_redline_lib import (  # noqa: E402
    DEFAULT_RESPONSE_AUTHOR,
    DEFAULT_RESPONSE_INITIALS,
)
from validate_redline_docx import validate_docx  # noqa: E402

WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
CONTENT_TYPES_NS = "http://schemas.openxmlformats.org/package/2006/content-types"


def w_attr(name: str) -> str:
    return f"{{{WORD_NS}}}{name}"


def make_docx_with_comments(
    path: Path,
    comments: list[dict[str, str]],
    *,
    document_reference_order: list[str] | None = None,
) -> None:
    ET.register_namespace("w", WORD_NS)
    body_parts: list[str] = []
    reference_order = document_reference_order or [comment["id"] for comment in comments]
    comment_lookup = {comment["id"]: comment for comment in comments}
    for comment_id in reference_order:
        text = comment_lookup[comment_id].get("anchor_text", f"Paragraph {comment_id}")
        body_parts.append(
            f'<w:p><w:commentRangeStart w:id="{comment_id}"/>'
            f"<w:r><w:t>{text}</w:t></w:r>"
            f'<w:commentRangeEnd w:id="{comment_id}"/>'
            f'<w:r><w:commentReference w:id="{comment_id}"/></w:r></w:p>'
        )

    document = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:document xmlns:w="{WORD_NS}"><w:body>'
        + "".join(body_parts)
        + "<w:sectPr/></w:body></w:document>"
    )

    comment_parts = []
    for comment in comments:
        comment_parts.append(
            f'<w:comment w:id="{comment["id"]}" '
            f'w:author="{comment["author"]}" '
            f'w:initials="{comment.get("initials", "RV")}" '
            'w:date="2026-06-10T12:00:00Z">'
            f'<w:p><w:r><w:t>{comment["text"]}</w:t></w:r></w:p>'
            "</w:comment>"
        )
    comments_xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:comments xmlns:w="{WORD_NS}">'
        + "".join(comment_parts)
        + "</w:comments>"
    )

    content_types = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<Types xmlns="{CONTENT_TYPES_NS}">'
        '<Default Extension="rels" '
        'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/comments.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'wordprocessingml.comments+xml"/>'
        '<Override PartName="/word/settings.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'wordprocessingml.settings+xml"/>'
        "</Types>"
    )
    rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<Relationships xmlns="{REL_NS}">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
        'relationships/officeDocument" Target="word/document.xml"/>'
        "</Relationships>"
    )
    doc_rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<Relationships xmlns="{REL_NS}">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
        'relationships/comments" Target="comments.xml"/>'
        "</Relationships>"
    )
    settings = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:settings xmlns:w="{WORD_NS}"/>'
    )

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types)
        zf.writestr("_rels/.rels", rels)
        zf.writestr("word/_rels/document.xml.rels", doc_rels)
        zf.writestr("word/document.xml", document)
        zf.writestr("word/comments.xml", comments_xml)
        zf.writestr("word/settings.xml", settings)


def read_comments(path: Path) -> list[dict[str, str]]:
    with zipfile.ZipFile(path) as zf:
        root = ET.fromstring(zf.read("word/comments.xml"))
    comments = []
    for comment in root.findall(f"{{{WORD_NS}}}comment"):
        comments.append(
            {
                "id": comment.attrib.get(w_attr("id"), ""),
                "author": comment.attrib.get(w_attr("author"), ""),
                "text": "".join(
                    node.text or "" for node in comment.findall(f".//{{{WORD_NS}}}t")
                ),
            }
        )
    return comments


class RedlineCommentHardeningTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)
        self.input_docx = self.workdir / "pink.docx"
        make_docx_with_comments(
            self.input_docx,
            [
                {
                    "id": "0",
                    "author": "Reviewer One",
                    "text": "Clarify alpha.",
                    "anchor_text": "Alpha paragraph",
                },
                {
                    "id": "1",
                    "author": "Reviewer Two",
                    "text": "Clarify beta.",
                    "anchor_text": "Beta paragraph",
                },
            ],
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_plan(self, plan: dict) -> Path:
        plan_path = self.workdir / "merge-plan.json"
        plan_path.write_text(json.dumps(plan), encoding="utf-8")
        return plan_path

    def test_build_merge_plan_defaults_to_ais_specify_identity(self) -> None:
        plan = build_merge_plan(
            {
                "comments": [
                    {
                        "id": "0",
                        "text": "Clarify alpha.",
                        "anchor_paragraph_index": 0,
                        "anchor_text": "Alpha paragraph",
                    }
                ]
            }
        )

        self.assertEqual(DEFAULT_RESPONSE_AUTHOR, "AIS Specify")
        self.assertEqual(DEFAULT_RESPONSE_INITIALS, "AIS")
        self.assertEqual(plan["settings"]["author"], "AIS Specify")
        self.assertEqual(plan["settings"]["initials"], "AIS")

    def test_apply_merge_plan_blocks_implicit_root_response_comments(self) -> None:
        plan_path = self.write_plan(
            {
                "operations": [],
                "comment_replies": [
                    {
                        "comment_id": "0",
                        "status": "addressed",
                        "reply": "Added alpha clarification.",
                    }
                ],
            }
        )

        with self.assertRaisesRegex(ValueError, "threaded replies"):
            apply_merge_plan(self.input_docx, plan_path, self.workdir / "redline.docx")

    def test_apply_merge_plan_explicit_root_fallback_uses_ais_author(self) -> None:
        plan_path = self.write_plan(
            {
                "operations": [],
                "comment_replies": [
                    {
                        "comment_id": "0",
                        "status": "addressed",
                        "reply": "Added alpha clarification.",
                    }
                ],
            }
        )
        output_docx = self.workdir / "redline.docx"

        result = apply_merge_plan(
            self.input_docx,
            plan_path,
            output_docx,
            allow_root_response_comments=True,
        )

        self.assertEqual(result["response_comments_added"], 1)
        self.assertEqual(result["response_comment_mode"], "draft_root_comments")
        comments = read_comments(output_docx)
        self.assertEqual(comments[-1]["author"], "AIS Specify")
        self.assertEqual(comments[-1]["text"], "Added alpha clarification.")

    def test_validate_docx_defaults_resolution_author_to_ais_specify(self) -> None:
        plan_path = self.write_plan(
            {
                "operations": [],
                "comment_replies": [
                    {
                        "comment_id": "0",
                        "status": "addressed",
                        "reply": "Added alpha clarification.",
                    }
                ],
            }
        )
        output_docx = self.workdir / "redline.docx"
        apply_merge_plan(
            self.input_docx,
            plan_path,
            output_docx,
            allow_root_response_comments=True,
        )

        summary, issues = validate_docx(output_docx, expect_resolution_comments=1)

        self.assertEqual(issues, [])
        self.assertEqual(summary["resolution_author"], "AIS Specify")
        self.assertEqual(summary["resolution_comment_count"], 1)
        self.assertEqual(
            summary["threaded_reply_readiness"],
            "not_validated_by_structural_check",
        )

    def test_reply_helpers_validate_duplicate_missing_and_unknown_ids(self) -> None:
        duplicate_replies = [
            {"comment_id": "0", "status": "addressed", "reply": "First."},
            {"comment_id": "0", "status": "addressed", "reply": "Second."},
        ]
        with self.assertRaisesRegex(ValueError, "duplicate replies"):
            replies_by_comment_id(duplicate_replies)

        replies_by_id = replies_by_comment_id(
            [{"comment_id": "0", "status": "addressed", "reply": "First."}]
        )
        with self.assertRaisesRegex(ValueError, "missing replies.*1"):
            validate_reply_coverage(["0", "1"], ["0", "1"], replies_by_id)

        unknown_by_id = replies_by_comment_id(
            [{"comment_id": "9", "status": "addressed", "reply": "Unknown."}]
        )
        with self.assertRaisesRegex(ValueError, "not found.*9"):
            validate_reply_coverage(["0", "1"], ["9"], unknown_by_id)

    def test_ordered_comment_ids_uses_document_order_and_includes_ais_sources(self) -> None:
        docx_path = self.workdir / "mixed-author.docx"
        make_docx_with_comments(
            docx_path,
            [
                {"id": "0", "author": "Reviewer One", "text": "First."},
                {"id": "1", "author": "AIS Specify", "text": "Existing AIS note."},
                {"id": "2", "author": "Reviewer Two", "text": "Second."},
            ],
            document_reference_order=["2", "1", "0"],
        )

        self.assertEqual(ordered_comment_ids(docx_path), ["2", "1", "0"])

    def test_required_reply_comment_ids_include_empty_non_skipped_entries(self) -> None:
        plan = {
            "comment_replies": [
                {"comment_id": "0", "status": "addressed", "reply": ""},
                {"comment_id": "1", "status": "skip", "reply": ""},
                {"comment_id": "2", "status": "no_change", "reply": "No change."},
            ]
        }

        self.assertEqual(required_reply_comment_ids(plan), ["0", "2"])
        self.assertEqual(
            [reply["comment_id"] for reply in actionable_replies(plan)],
            ["2"],
        )

    def test_word_wrapper_reports_empty_required_reply_ids_before_word(self) -> None:
        plan_path = self.write_plan(
            {
                "operations": [],
                "comment_replies": [
                    {"comment_id": "0", "status": "addressed", "reply": ""}
                ],
            }
        )

        with self.assertRaisesRegex(ValueError, "missing replies.*0"):
            apply_merge_plan_with_word_replies(
                self.input_docx,
                plan_path,
                self.workdir / "redline.docx",
            )

    def test_missing_threaded_reply_ids_uses_comments_extended_parent_links(self) -> None:
        output_docx = self.workdir / "word-output.docx"
        make_docx_with_comments(
            output_docx,
            [
                {"id": "0", "author": "Reviewer One", "text": "Clarify alpha."},
                {"id": "1", "author": "AIS Specify", "text": "Added alpha clarification."},
                {"id": "2", "author": "Reviewer Two", "text": "Clarify beta."},
                {"id": "3", "author": "AIS Specify", "text": "Added beta clarification."},
            ],
            document_reference_order=["0", "2"],
        )
        comments_extended = (
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<w15:commentsEx xmlns:w15="http://schemas.microsoft.com/office/'
            'word/2012/wordml">'
            '<w15:commentEx w15:paraId="AAAA0001" w15:done="0"/>'
            '<w15:commentEx w15:paraId="BBBB0001" '
            'w15:paraIdParent="AAAA0001" w15:done="0"/>'
            '<w15:commentEx w15:paraId="CCCC0001" w15:done="0"/>'
            '<w15:commentEx w15:paraId="DDDD0001" '
            'w15:paraIdParent="CCCC0001" w15:done="0"/>'
            "</w15:commentsEx>"
        )
        with zipfile.ZipFile(output_docx, "a", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("word/commentsExtended.xml", comments_extended)

        self.assertEqual(
            missing_threaded_reply_ids(output_docx, ["0", "1"], ["0", "1"]),
            [],
        )


if __name__ == "__main__":
    unittest.main()
