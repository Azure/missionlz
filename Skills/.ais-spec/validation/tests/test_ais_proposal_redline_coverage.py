from __future__ import annotations

import contextlib
import io
import json
import runpy
import shutil
import sys
import tempfile
import types
import unittest
import unittest.mock as mock
import zipfile
from pathlib import Path

from lxml import etree

REPO_ROOT = Path(__file__).resolve().parents[4]
SCRIPT_DIR = REPO_ROOT / "Skills" / "ais-proposal-redline-docx" / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))

import apply_merge_plan as apply_module  # noqa: E402
import apply_merge_plan_with_word_replies as word_module  # noqa: E402
import build_merge_plan as build_module  # noqa: E402
import extract_review_context as extract_module  # noqa: E402
import validate_redline_docx as validate_module  # noqa: E402
from docx_redline_lib import (  # noqa: E402
    COMMENTS_CONTENT_TYPE,
    COMMENTS_REL_TYPE,
    DEFAULT_RESPONSE_AUTHOR,
    NS,
    PROVENANCE_SOURCE_PATTERN,
    REL_NS,
    SKILL_NAME,
    SKILL_VERSION,
    add_comment,
    anchor_comment_to_paragraph,
    body_paragraphs,
    body_tables,
    comment_text,
    comments_to_list,
    create_comments_root,
    create_rels_root,
    create_settings_root,
    declared_themes,
    emit_skill_identity,
    enabled_operations,
    ensure_comments_relationship,
    ensure_content_type_override,
    ensure_track_revisions,
    extract_comment_anchors,
    insert_after,
    is_generic_rationale,
    is_generic_reply,
    is_valid_provenance_source,
    local_name,
    make_inserted_paragraph,
    make_inserted_table,
    make_revision,
    make_text_element,
    max_numeric_attr,
    next_comment_id,
    normalize_rows,
    paragraph_style,
    paragraph_text,
    parse_xml,
    provenance_source_kind,
    qn,
    replace_paragraph_text,
    require_part,
    serialize_xml,
    set_paragraph_style,
    settings_has_track_revisions,
    skill_home,
    summarize_provenance,
    tracked_revision_counts,
    utc_now,
    validate_merge_plan,
    write_docx_with_replacements,
)
from test_ais_proposal_redline_docx import (  # noqa: E402
    CONTENT_TYPES_NS,
    REL_NS as TEST_REL_NS,
    WORD_NS,
    make_docx_with_comments,
)


def content_types_xml(*, include_comments: bool = False) -> str:
    comments_override = ""
    if include_comments:
        comments_override = (
            '<Override PartName="/word/comments.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.'
            'wordprocessingml.comments+xml"/>'
        )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<Types xmlns="{CONTENT_TYPES_NS}">'
        '<Default Extension="rels" '
        'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/settings.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'wordprocessingml.settings+xml"/>'
        f"{comments_override}</Types>"
    )


def settings_xml(*, track_revisions: bool = False) -> str:
    tracking = "<w:trackRevisions/>" if track_revisions else ""
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:settings xmlns:w="{WORD_NS}">{tracking}</w:settings>'
    )


def comments_xml(comments: list[dict[str, str]]) -> str:
    parts = []
    for comment in comments:
        initials = comment.get("initials", "")
        initials_attr = f' w:initials="{initials}"' if "initials" in comment else ""
        parts.append(
            f'<w:comment w:id="{comment.get("id", "")}" '
            f'w:author="{comment.get("author", "")}"{initials_attr} '
            'w:date="2026-06-16T12:00:00Z">'
            f'<w:p><w:r><w:t>{comment.get("text", "")}</w:t></w:r></w:p>'
            "</w:comment>"
        )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:comments xmlns:w="{WORD_NS}">{"".join(parts)}</w:comments>'
    )


def document_xml(body: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<w:document xmlns:w="{WORD_NS}"><w:body>{body}<w:sectPr/></w:body></w:document>'
    )


def write_docx(
    path: Path,
    body: str,
    *,
    comments: list[dict[str, str]] | None = None,
    include_settings: bool = True,
    include_content_types: bool = True,
    include_doc_rels: bool = True,
    track_revisions: bool = False,
) -> None:
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        if include_content_types:
            zf.writestr("[Content_Types].xml", content_types_xml(include_comments=bool(comments)))
        zf.writestr("word/document.xml", document_xml(body))
        if include_settings:
            zf.writestr("word/settings.xml", settings_xml(track_revisions=track_revisions))
        if comments is not None:
            zf.writestr("word/comments.xml", comments_xml(comments))
        if include_doc_rels:
            target = (
                '<Relationship Id="rId1" Type="'
                f'{COMMENTS_REL_TYPE}" Target="comments.xml"/>'
                if comments is not None
                else ""
            )
            zf.writestr(
                "word/_rels/document.xml.rels",
                f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                f'<Relationships xmlns="{TEST_REL_NS}">{target}</Relationships>',
            )


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def xml_part(path: Path, part_name: str) -> etree._Element:
    with zipfile.ZipFile(path) as zf:
        return parse_xml(zf.read(part_name))


def comment_texts(path: Path) -> list[str]:
    root = xml_part(path, "word/comments.xml")
    return [comment_text(comment) for comment in root.findall(qn("w", "comment"))]


def run_main(main_func, argv: list[str]) -> tuple[int, str, str]:
    stdout = io.StringIO()
    stderr = io.StringIO()
    with mock.patch.object(sys, "argv", [main_func.__module__] + argv):
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            code = main_func()
    return code, stdout.getvalue(), stderr.getvalue()


def run_script_help(script_name: str) -> int | str | None:
    stdout = io.StringIO()
    stderr = io.StringIO()
    script_path = SCRIPT_DIR / script_name
    with mock.patch.object(sys, "argv", [str(script_path), "--help"]):
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            with unittest.TestCase().assertRaises(SystemExit) as caught:
                runpy.run_path(str(script_path), run_name="__main__")
    return caught.exception.code


class DocxRedlineLibCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_xml_parts_and_package_replacements(self) -> None:
        root = parse_xml(f'<w:root xmlns:w="{WORD_NS}"><w:p/></w:root>'.encode())
        self.assertEqual(local_name(root[0]), "p")
        self.assertIn(b"<?xml", serialize_xml(root))

        source = self.workdir / "source.docx"
        output = self.workdir / "output.docx"
        with zipfile.ZipFile(source, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("replace.txt", b"old")
            zf.writestr("keep.txt", b"keep")

        with zipfile.ZipFile(source) as zf:
            self.assertEqual(require_part(zf, "replace.txt"), b"old")
            with self.assertRaisesRegex(ValueError, "Missing required DOCX part"):
                require_part(zf, "missing.txt")

        write_docx_with_replacements(
            source,
            output,
            {"replace.txt": b"new", "added.txt": b"added"},
        )
        with zipfile.ZipFile(output) as zf:
            self.assertEqual(zf.read("replace.txt"), b"new")
            self.assertEqual(zf.read("keep.txt"), b"keep")
            self.assertEqual(zf.read("added.txt"), b"added")

    def test_document_query_and_comment_helpers(self) -> None:
        empty = parse_xml(f'<w:document xmlns:w="{WORD_NS}"/>'.encode())
        self.assertEqual(body_paragraphs(empty), [])
        self.assertEqual(body_tables(empty), [])

        document = parse_xml(
            (
                f'<w:document xmlns:w="{WORD_NS}"><w:body>'
                '<w:p><w:pPr><w:pStyle w:val="Body"/></w:pPr>'
                '<w:commentRangeStart w:id="9"/>'
                '<w:r><w:t>Keep</w:t></w:r>'
                '<w:r><w:delText>Gone</w:delText></w:r>'
                '<w:commentRangeEnd w:id="9"/>'
                '<w:r><w:commentReference w:id="9"/></w:r></w:p>'
                '<w:p><w:r><w:t>No comment</w:t></w:r></w:p>'
                '<w:tbl/>'
                '<w:ins/><w:del/>'
                '</w:body></w:document>'
            ).encode()
        )
        first = body_paragraphs(document)[0]
        second = body_paragraphs(document)[1]
        self.assertEqual(paragraph_text(first), "KeepGone")
        self.assertEqual(paragraph_style(first), "Body")
        self.assertEqual(paragraph_style(second), "")
        set_paragraph_style(second, "")
        set_paragraph_style(second, "Quote")
        set_paragraph_style(second, "Body")
        self.assertEqual(paragraph_style(second), "Body")
        self.assertEqual(len(body_tables(document)), 1)
        self.assertEqual(tracked_revision_counts(document), {"insertions": 1, "deletions": 1})

        anchors = extract_comment_anchors(document)
        self.assertEqual(anchors["9"]["anchor_paragraph_index"], 0)
        comments_root = parse_xml(
            (
                f'<w:comments xmlns:w="{WORD_NS}">'
                '<w:comment w:id="x" w:author="R" w:date="d"><w:p><w:r><w:t>  A </w:t></w:r></w:p></w:comment>'
                '<w:comment w:id="2" w:author="R" w:initials="RV" w:date="d"><w:p><w:r><w:t>B</w:t></w:r></w:p></w:comment>'
                '<w:comment w:id="9" w:author="R" w:date="d"><w:p><w:r><w:t>C</w:t></w:r></w:p></w:comment>'
                '</w:comments>'
            ).encode()
        )
        self.assertEqual(comment_text(comments_root[0]), "A")
        self.assertEqual(comments_to_list(None, anchors), [])
        listed = comments_to_list(comments_root, anchors)
        self.assertEqual([item["id"] for item in listed], ["2", "9", "x"])
        self.assertEqual(listed[0]["anchor_paragraph_index"], -1)
        self.assertEqual(listed[1]["anchor_paragraph_index"], 0)

        settings = create_settings_root()
        self.assertFalse(settings_has_track_revisions(None))
        self.assertFalse(settings_has_track_revisions(settings))
        ensure_track_revisions(settings)
        ensure_track_revisions(settings)
        self.assertTrue(settings_has_track_revisions(settings))
        self.assertEqual(create_comments_root().tag, qn("w", "comments"))
        self.assertEqual(max_numeric_attr(document, "id"), 9)
        self.assertEqual(next_comment_id(None), 200)
        self.assertEqual(next_comment_id(comments_root), 200)
        self.assertRegex(utc_now(), r"^\d{4}-\d{2}-\d{2}T")

    def test_mutation_helpers_cover_revisions_tables_comments_and_relationships(self) -> None:
        paragraph = parse_xml(
            (
                f'<w:p xmlns:w="{WORD_NS}"><w:pPr><w:pStyle w:val="Body"/></w:pPr>'
                '<w:commentRangeStart w:id="5"/>'
                '<w:r><w:t>Old text</w:t></w:r>'
                '<w:commentRangeEnd w:id="5"/>'
                '<w:r><w:commentReference w:id="5"/></w:r></w:p>'
            ).encode()
        )
        next_id = replace_paragraph_text(
            paragraph,
            " New text ",
            10,
            "Author",
            "2026-06-16T00:00:00Z",
            style_id="Quote",
        )
        self.assertEqual(next_id, 12)
        self.assertEqual(paragraph_style(paragraph), "Quote")
        self.assertIn("Old text", paragraph_text(paragraph))
        self.assertIn(" New text ", paragraph_text(paragraph))

        empty_paragraph = etree.Element(qn("w", "p"))
        self.assertEqual(
            replace_paragraph_text(
                empty_paragraph,
                "Inserted only",
                20,
                "Author",
                "2026-06-16T00:00:00Z",
            ),
            21,
        )

        inserted = make_inserted_paragraph(
            "Inserted paragraph",
            30,
            "Author",
            "2026-06-16T00:00:00Z",
            base_paragraph=paragraph,
            style_id="Body",
        )
        plain_inserted = make_inserted_paragraph(
            "Plain",
            31,
            "Author",
            "2026-06-16T00:00:00Z",
        )
        self.assertEqual(paragraph_style(inserted), "Body")
        self.assertEqual(paragraph_text(plain_inserted), "Plain")

        table = make_inserted_table(
            [["A", "B"], ["C", "D"]],
            40,
            "Author",
            "2026-06-16T00:00:00Z",
        )
        empty_table = make_inserted_table([], 50, "Author", "2026-06-16T00:00:00Z", style_id="")
        self.assertEqual(local_name(table), "tbl")
        self.assertEqual(len(empty_table.xpath(".//w:gridCol", namespaces=NS)), 1)

        container = parse_xml(f'<w:body xmlns:w="{WORD_NS}"><w:p/></w:body>'.encode())
        insert_after(container[0], inserted)
        self.assertEqual(len(container), 2)
        with self.assertRaisesRegex(ValueError, "no parent"):
            insert_after(etree.Element(qn("w", "p")), etree.Element(qn("w", "p")))

        comments_root = create_comments_root()
        first_comment = add_comment(
            comments_root,
            200,
            "Author",
            "AU",
            "2026-06-16T00:00:00Z",
            "Reply",
        )
        second_comment = add_comment(
            comments_root,
            201,
            "Author",
            "",
            "2026-06-16T00:00:00Z",
            "Reply without initials",
        )
        self.assertEqual(first_comment.get(qn("w", "initials")), "AU")
        self.assertIsNone(second_comment.get(qn("w", "initials")))
        anchor_comment_to_paragraph(paragraph, 200)
        anchor_comment_to_paragraph(plain_inserted, 201)
        self.assertGreater(len(paragraph.xpath(".//w:commentReference", namespaces=NS)), 0)

        rels = create_rels_root()
        existing = etree.SubElement(rels, f"{{{REL_NS}}}Relationship")
        existing.set("Id", "rId1")
        existing.set("Type", "other")
        existing.set("Target", "other.xml")
        ensure_comments_relationship(rels)
        ensure_comments_relationship(rels)
        rel_ids = [rel.get("Id") for rel in rels.xpath("./pr:Relationship", namespaces=NS)]
        self.assertIn("rId2", rel_ids)

        content_types = parse_xml(content_types_xml().encode())
        ensure_content_type_override(content_types, "/word/comments.xml", COMMENTS_CONTENT_TYPE)
        ensure_content_type_override(content_types, "/word/comments.xml", "updated")
        override = content_types.xpath("./ct:Override[@PartName='/word/comments.xml']", namespaces=NS)[0]
        self.assertEqual(override.get("ContentType"), "updated")

        self.assertEqual(normalize_rows([{"a": 1, "b": 2}, ["c"], "d"]), [[1, 2], ["c"], ["d"]])
        with self.assertRaisesRegex(ValueError, "rows must be a list"):
            normalize_rows("not rows")
        self.assertEqual(make_text_element("t", " spaced ").get(f"{{{NS['w']}}}space"), None)
        self.assertEqual(make_text_element("t", " spaced ").get("{http://www.w3.org/XML/1998/namespace}space"), "preserve")
        self.assertEqual(local_name(make_revision("del", 60, "Author", "date", "gone")), "del")
        with self.assertRaisesRegex(ValueError, "Unsupported revision kind"):
            make_revision("move", 61, "Author", "date", "text")
        self.assertTrue(is_generic_reply("Addressed."))
        self.assertTrue(is_generic_reply("Done"))
        self.assertTrue(is_generic_reply("resolved"))
        self.assertTrue(is_generic_reply("addressed in the red draft"))
        self.assertFalse(is_generic_reply("Detailed explanation."))


class ApplyMergePlanCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)
        self.input_docx = self.workdir / "input.docx"
        body = (
            '<w:p><w:pPr><w:pStyle w:val="Body"/></w:pPr><w:r><w:t>Alpha</w:t></w:r></w:p>'
            '<w:p><w:r><w:t>Beta</w:t></w:r></w:p>'
        )
        write_docx(
            self.input_docx,
            body,
            include_settings=False,
            include_doc_rels=False,
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def plan_path(self, payload: dict) -> Path:
        return write_json(self.workdir / f"plan-{len(list(self.workdir.glob('plan-*.json')))}.json", payload)

    def test_load_part_or_none_and_all_operation_types(self) -> None:
        with zipfile.ZipFile(self.input_docx) as zf:
            self.assertIsNotNone(apply_module._load_part_or_none(zf, "word/document.xml"))
            self.assertIsNone(apply_module._load_part_or_none(zf, "word/comments.xml"))

        plan = self.plan_path(
            {
                "settings": {"author": "AIS Specify", "initials": "AIS", "date": "2026-06-16T00:00:00Z"},
                "operations": [
                    {"enabled": False, "type": "replace_paragraph_text", "paragraph_index": 0, "text": "Skipped"},
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "style": "Quote",
                        "text": "Alpha revised",
                        "rationale": "Reworded the opening claim so it matches the cited evidence.",
                        "source": "reviewer_comment:0",
                    },
                    {
                        "type": "insert_paragraph_after",
                        "paragraph_index": 0,
                        "style": "Body",
                        "text": "Inserted",
                        "rationale": "Added the transition the review call asked for.",
                        "source": "review_call:RC-02",
                    },
                    {
                        "type": "insert_table_after",
                        "paragraph_index": 1,
                        "style": "",
                        "rows": [{"A": "B"}, ["C", "D"], "E"],
                        "rationale": "Summarised the phase model to hold the section page budget.",
                        "source": "compliance:F-1",
                    },
                ],
                "comment_replies": [],
            }
        )
        output = self.workdir / "output.docx"
        result = apply_module.apply_merge_plan(self.input_docx, plan, output)
        self.assertEqual(result["operations_applied"], 3)
        self.assertEqual(result["response_comment_mode"], "none")
        self.assertEqual(result["explanation_comments_added"], 3)
        self.assertEqual(result["theme_comments_added"], 0)
        self.assertEqual(
            result["provenance_counts"],
            {"reviewer_comment": 1, "review_call": 1, "compliance": 1},
        )
        self.assertFalse(result["author_override"])
        document = xml_part(output, "word/document.xml")
        self.assertIn("Alpha revised", paragraph_text(body_paragraphs(document)[0]))
        self.assertEqual(len(body_tables(document)), 1)
        settings = xml_part(output, "word/settings.xml")
        self.assertTrue(settings_has_track_revisions(settings))
        with zipfile.ZipFile(output) as zf:
            self.assertIn("word/comments.xml", set(zf.namelist()))

    def test_reply_modes_warning_and_created_comment_parts(self) -> None:
        skipped_plan = self.plan_path(
            {
                "operations": [],
                "comment_replies": [{"comment_id": "0", "status": "addressed", "reply": "Done"}],
            }
        )
        skipped = apply_module.apply_merge_plan(
            self.input_docx,
            skipped_plan,
            self.workdir / "skipped.docx",
            skip_comment_replies=True,
        )
        self.assertEqual(skipped["response_comment_mode"], "skipped")

        unanchored_plan = self.plan_path(
            {
                "operations": [],
                "comment_replies": [
                    {"comment_id": "0", "anchor_paragraph_index": 99, "status": "addressed", "reply": "Done"}
                ],
            }
        )
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            warned = apply_module.apply_merge_plan(
                self.input_docx,
                unanchored_plan,
                self.workdir / "warned.docx",
                allow_root_response_comments=True,
            )
        self.assertIn("could not anchor", stderr.getvalue())
        self.assertEqual(warned["response_comments_added"], 0)
        self.assertEqual(warned["response_comment_mode"], "draft_root_comments")

        anchored = self.workdir / "anchored.docx"
        make_docx_with_comments(
            anchored,
            [{"id": "0", "author": "Reviewer", "text": "Question", "anchor_text": "Alpha"}],
        )
        anchored_plan = self.plan_path(
            {
                "operations": [],
                "comment_replies": [{"comment_id": "0", "status": "addressed", "reply": "Answered"}],
            }
        )
        output = self.workdir / "anchored-output.docx"
        result = apply_module.apply_merge_plan(
            anchored,
            anchored_plan,
            output,
            allow_root_response_comments=True,
        )
        self.assertEqual(result["response_comments_added"], 1)
        self.assertEqual(next_comment_id(xml_part(output, "word/comments.xml")), 201)

    def test_operation_validation_errors(self) -> None:
        provenance = {
            "rationale": "Applied the correction the reviewer asked for in this section.",
            "source": "internal_qa",
        }
        cases = [
            ({"type": "replace_paragraph_text", "text": "Missing index"}, "missing integer paragraph_index"),
            ({"type": "replace_paragraph_text", "paragraph_index": 9, "text": "Out"}, "out of range"),
            ({"type": "unknown", "paragraph_index": 0}, "Unsupported operation type"),
            ({"type": "insert_table_after", "paragraph_index": 0, "rows": "bad"}, "rows must be a list"),
        ]
        for operation, pattern in cases:
            with self.subTest(pattern=pattern):
                plan = self.plan_path(
                    {"operations": [{**operation, **provenance}], "comment_replies": []}
                )
                with self.assertRaisesRegex(ValueError, pattern):
                    apply_module.apply_merge_plan(self.input_docx, plan, self.workdir / f"{pattern[:4]}.docx")

    def test_apply_merge_plan_main_success_failure_and_launcher(self) -> None:
        plan = self.plan_path({"operations": [], "comment_replies": []})
        output = self.workdir / "main-output.docx"
        code, stdout, stderr = run_main(
            apply_module.main,
            ["--input", str(self.input_docx), "--plan", str(plan), "--output", str(output)],
        )
        self.assertEqual(code, 0, stderr)
        self.assertEqual(json.loads(stdout)["operations_applied"], 0)

        code, stdout, stderr = run_main(
            apply_module.main,
            ["--input", str(self.workdir / "missing.docx"), "--plan", str(plan), "--output", str(output)],
        )
        self.assertEqual(code, 1)
        self.assertIn("Error:", stderr)
        self.assertEqual(run_script_help("apply_merge_plan.py"), 0)


class CliAndValidationCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)
        self.review_docx = self.workdir / "review.docx"
        make_docx_with_comments(
            self.review_docx,
            [{"id": "0", "author": "Reviewer", "text": "Clarify", "anchor_text": "Alpha"}],
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_extract_review_context_function_and_main_paths(self) -> None:
        context = extract_module.extract_review_context(self.review_docx)
        self.assertEqual(context["review_summary"]["comment_count"], 1)
        self.assertEqual(context["review_summary"]["paragraph_count"], 1)
        self.assertFalse(context["review_summary"]["track_revisions_enabled"])

        code, stdout, stderr = run_main(extract_module.main, ["--input", str(self.review_docx)])
        self.assertEqual(code, 0, stderr)
        self.assertEqual(json.loads(stdout)["comments"][0]["id"], "0")

        output = self.workdir / "context.json"
        code, stdout, stderr = run_main(
            extract_module.main,
            ["--input", str(self.review_docx), "--output", str(output)],
        )
        self.assertEqual(code, 0, stdout)
        self.assertIn("Extracted 1 comments", stderr)

        code, stdout, stderr = run_main(extract_module.main, ["--input", str(self.workdir / "missing.docx")])
        self.assertEqual(code, 1)
        self.assertIn("Error:", stderr)
        self.assertEqual(run_script_help("extract_review_context.py"), 0)

    def test_build_merge_plan_main_stdout_file_and_error(self) -> None:
        context_path = self.workdir / "context.json"
        write_json(
            context_path,
            {
                "source_docx": "source.docx",
                "comments": [
                    {
                        "id": "0",
                        "text": "Clarify",
                        "anchor_paragraph_index": 0,
                        "anchor_text": "Alpha",
                    }
                ],
            },
        )
        code, stdout, stderr = run_main(
            build_module.main,
            ["--review-context", str(context_path), "--source-docx", "override.docx", "--output-docx", "out.docx"],
        )
        self.assertEqual(code, 0, stderr)
        plan = json.loads(stdout)
        self.assertEqual(plan["source_docx"], "override.docx")
        self.assertEqual(plan["comment_replies"][0]["status"], "needs_response")

        output = self.workdir / "plan.json"
        code, stdout, stderr = run_main(
            build_module.main,
            ["--review-context", str(context_path), "--author", "Author", "--initials", "AU", "--output", str(output)],
        )
        self.assertEqual(code, 0, stdout)
        self.assertIn("Wrote merge plan", stderr)
        self.assertEqual(json.loads(output.read_text(encoding="utf-8"))["settings"]["initials"], "AU")

        code, stdout, stderr = run_main(build_module.main, ["--review-context", str(self.workdir / "missing.json")])
        self.assertEqual(code, 1)
        self.assertIn("Error:", stderr)
        self.assertEqual(run_script_help("build_merge_plan.py"), 0)

    def test_end_to_end_extract_build_apply_validate_pipeline(self) -> None:
        review_context_path = self.workdir / "review-context.json"
        merge_plan_path = self.workdir / "merge-plan.json"
        output_docx = self.workdir / "pipeline-output.docx"

        extract_code, _, extract_stderr = run_main(
            extract_module.main,
            ["--input", str(self.review_docx), "--output", str(review_context_path)],
        )
        self.assertEqual(extract_code, 0, extract_stderr)

        build_code, _, build_stderr = run_main(
            build_module.main,
            [
                "--review-context",
                str(review_context_path),
                "--output",
                str(merge_plan_path),
                "--author",
                "AIS Specify",
                "--initials",
                "AIS",
            ],
        )
        self.assertEqual(build_code, 0, build_stderr)

        merge_plan = json.loads(merge_plan_path.read_text(encoding="utf-8"))
        merge_plan["settings"]["date"] = "2026-06-16T00:00:00Z"
        merge_plan["operations"] = [
            {
                "type": "replace_paragraph_text",
                "paragraph_index": 0,
                "style": "Body",
                "text": "Alpha revised",
                "rationale": "Tightened the opening claim so it matches the approach section.",
                "source": "internal_qa",
            }
        ]
        merge_plan_path.write_text(json.dumps(merge_plan), encoding="utf-8")

        apply_result = apply_module.apply_merge_plan(
            self.review_docx,
            merge_plan_path,
            output_docx,
            skip_comment_replies=True,
        )
        self.assertEqual(apply_result["operations_applied"], 1)
        self.assertEqual(apply_result["response_comment_mode"], "skipped")

        output_document = xml_part(output_docx, "word/document.xml")
        self.assertIn("Alpha revised", paragraph_text(body_paragraphs(output_document)[0]))

        summary, issues = validate_module.validate_docx(
            output_docx,
            expect_reviewer_comments=1,
            require_track_revisions=True,
        )
        self.assertTrue(summary["readable"])
        self.assertEqual(issues, [])

    def test_validate_docx_issue_paths_and_main_outputs(self) -> None:
        summary, issues = validate_module.validate_docx(
            self.review_docx,
            expect_reviewer_comments=2,
            expect_resolution_comments=1,
            require_track_revisions=True,
            fail_generic_replies=True,
        )
        self.assertTrue(summary["readable"])
        self.assertIn("Tracked revisions are not enabled", "\n".join(issues))
        self.assertIn("Expected at least 2 reviewer", "\n".join(issues))
        self.assertIn("Expected at least 1 resolution", "\n".join(issues))

        generic_docx = self.workdir / "generic.docx"
        make_docx_with_comments(
            generic_docx,
            [
                {"id": "0", "author": "Reviewer", "text": "Question"},
                {"id": "1", "author": "AIS Specify", "text": "Done."},
            ],
        )
        _, generic_issues = validate_module.validate_docx(
            generic_docx,
            expect_reviewer_comments=1,
            expect_resolution_comments=1,
            fail_generic_replies=True,
        )
        self.assertIn("Generic resolution comments", "\n".join(generic_issues))

        missing_definition_docx = self.workdir / "missing-definition.docx"
        write_docx(
            missing_definition_docx,
            '<w:p><w:commentRangeStart w:id="9"/><w:r><w:t>Alpha</w:t></w:r></w:p>',
            comments=[{"id": "0", "author": "Reviewer", "text": "Question"}],
        )
        _, definition_issues = validate_module.validate_docx(missing_definition_docx)
        self.assertIn("anchors without matching", "\n".join(definition_issues))

        missing_content_types = self.workdir / "missing-content-types.docx"
        write_docx(
            missing_content_types,
            '<w:p><w:r><w:t>Alpha</w:t></w:r></w:p>',
            include_content_types=False,
            include_settings=False,
            include_doc_rels=False,
        )
        _, required_issues = validate_module.validate_docx(missing_content_types)
        self.assertIn("Missing required part: [Content_Types].xml", required_issues)

        unreadable = self.workdir / "unreadable.docx"
        with zipfile.ZipFile(unreadable, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("[Content_Types].xml", content_types_xml())
        unreadable_summary, unreadable_issues = validate_module.validate_docx(unreadable)
        self.assertFalse(unreadable_summary["readable"])
        self.assertTrue(unreadable_issues)

        code, stdout, stderr = run_main(
            validate_module.main,
            ["--input", str(generic_docx), "--json", "--fail-generic-replies"],
        )
        self.assertEqual(code, 1)
        self.assertIn("ais-proposal-redline-docx", stderr)
        self.assertIn("Generic resolution", stdout)

        code, stdout, stderr = run_main(validate_module.main, ["--input", str(self.review_docx)])
        self.assertEqual(code, 0, stderr)
        self.assertIn("Validation PASSED", stdout)
        self.assertEqual(run_script_help("validate_redline_docx.py"), 0)


class WordReplyWrapperCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)
        self.input_docx = self.workdir / "input.docx"
        make_docx_with_comments(
            self.input_docx,
            [{"id": "0", "author": "Reviewer", "text": "Clarify", "anchor_text": "Alpha"}],
        )
        self.plan = self.workdir / "plan.json"
        write_json(
            self.plan,
            {
                "settings": {"author": "AIS Specify", "initials": "AIS"},
                "operations": [],
                "comment_replies": [{"comment_id": "0", "status": "addressed", "reply": "Answered."}],
            },
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_path_platform_xml_and_comment_id_helpers(self) -> None:
        self.assertEqual(word_module.word_attr("id"), f"{{{WORD_NS}}}id")
        self.assertEqual(word_module.word15_attr("paraId"), f"{{{word_module.WORD15_NS}}}paraId")
        self.assertEqual(word_module.local_name(f"{{{WORD_NS}}}comment"), "comment")
        self.assertEqual(word_module.require_existing_path(self.input_docx, "Input"), self.input_docx.resolve())
        with self.assertRaisesRegex(FileNotFoundError, "Missing does not exist"):
            word_module.require_existing_path(self.workdir / "missing.docx", "Missing")

        with mock.patch.object(word_module.platform, "system", return_value="Linux"):
            with self.assertRaisesRegex(RuntimeError, "requires Windows"):
                word_module.require_word_com()
        with mock.patch.object(word_module.platform, "system", return_value="Windows"):
            with mock.patch.dict(sys.modules, {"win32com": None, "win32com.client": None}):
                with self.assertRaisesRegex(RuntimeError, "requires pywin32"):
                    word_module.require_word_com()
        fake_win32com = types.ModuleType("win32com")
        fake_client = types.ModuleType("win32com.client")
        fake_win32com.client = fake_client
        with mock.patch.object(word_module.platform, "system", return_value="Windows"):
            with mock.patch.dict(sys.modules, {"win32com": fake_win32com, "win32com.client": fake_client}):
                self.assertIs(word_module.require_word_com(), fake_client)

        self.assertIsNone(word_module.read_xml_from_docx(self.input_docx, "word/missing.xml"))
        comments_only = self.workdir / "comments-only.docx"
        with zipfile.ZipFile(comments_only, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("word/comments.xml", comments_xml([{"id": "2", "author": "R", "text": "Two"}]))
        self.assertEqual(word_module.ordered_comment_ids(comments_only), ["2"])
        self.assertEqual(word_module.reviewer_comment_ids(comments_only, "AIS Specify"), ["2"])

        trailing_comment = self.workdir / "trailing-comment.docx"
        make_docx_with_comments(
            trailing_comment,
            [
                {"id": "0", "author": "Reviewer", "text": "First"},
                {"id": "1", "author": "Reviewer", "text": "Unanchored"},
            ],
            document_reference_order=["0"],
        )
        self.assertEqual(word_module.ordered_comment_ids(trailing_comment), ["0", "1"])

        no_comments = self.workdir / "no-comments.docx"
        write_docx(no_comments, '<w:p><w:r><w:t>Alpha</w:t></w:r></w:p>')
        self.assertEqual(word_module.comment_ids_in_docx(no_comments), [])

        missing_id = self.workdir / "missing-id.docx"
        with zipfile.ZipFile(missing_id, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("word/comments.xml", f'<w:comments xmlns:w="{WORD_NS}"><w:comment/></w:comments>')
        with self.assertRaisesRegex(ValueError, "without a comments.xml ID"):
            word_module.comment_ids_in_docx(missing_id)

        duplicate_id = self.workdir / "duplicate-id.docx"
        with zipfile.ZipFile(duplicate_id, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr(
                "word/comments.xml",
                comments_xml(
                    [
                        {"id": "1", "author": "R", "text": "One"},
                        {"id": "1", "author": "R", "text": "Duplicate"},
                    ]
                ),
            )
        with self.assertRaisesRegex(ValueError, "Duplicate comment ID"):
            word_module.comment_ids_in_docx(duplicate_id)

        self.assertEqual(word_module.missing_threaded_reply_ids(self.input_docx, ["0"], ["0"]), ["0"])
        extended = self.workdir / "extended.docx"
        shutil.copyfile(self.input_docx, extended)
        with zipfile.ZipFile(extended, "a", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr(
                "word/commentsExtended.xml",
                (
                    '<w15:commentsEx xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml">'
                    '<w15:commentEx w15:paraId="AAAA"/>'
                    "</w15:commentsEx>"
                ),
            )
        self.assertEqual(word_module.missing_threaded_reply_ids(extended, ["0"], ["9"]), ["9"])
        self.assertEqual(word_module.missing_threaded_reply_ids(extended, ["0"], ["0"]), ["0"])
        self.assertEqual(word_module.missing_threaded_reply_ids(extended, ["0", "1"], ["1"]), ["1"])

    def test_reply_plan_validation_helpers(self) -> None:
        with self.assertRaisesRegex(ValueError, "missing comment_id"):
            word_module.required_reply_comment_ids({"comment_replies": [{"status": "addressed", "reply": ""}]})
        with self.assertRaisesRegex(ValueError, "missing comment_id"):
            word_module.replies_by_comment_id([{"status": "addressed", "reply": "Done"}])
        plan = {
            "comment_replies": [
                {"comment_id": "0", "status": "addressed", "reply": "Done"},
                {"comment_id": "1", "status": "not_applicable", "reply": "Skipped"},
            ]
        }
        replies = word_module.actionable_replies(plan)
        by_id = word_module.replies_by_comment_id(replies)
        self.assertEqual(word_module.required_reply_comment_ids(plan), ["0"])
        word_module.validate_reply_coverage(["0"], ["0"], by_id)

    def test_add_word_reply_threads_success_and_error_paths(self) -> None:
        class FakeReply:
            Author = ""
            Initial = ""

        class FakeReplies:
            def __init__(self, *, increment: bool = True) -> None:
                self.Count = 0
                self.increment = increment

            def Add(self, _range, _text):
                if self.increment:
                    self.Count += 1
                return FakeReply()

        class FakeComment:
            def __init__(self, *, increment: bool = True) -> None:
                self.Range = object()
                self.Replies = FakeReplies(increment=increment)

        class FakeComments:
            def __init__(self, comments: list[FakeComment]) -> None:
                self._comments = comments
                self.Count = len(comments)

            def Item(self, index: int) -> FakeComment:
                return self._comments[index - 1]

        class FakeDoc:
            def __init__(self, source: Path, comments: list[FakeComment]) -> None:
                self.source = source
                self.Comments = FakeComments(comments)
                self.closed = False

            def SaveAs2(self, output: str, _format: int) -> None:
                shutil.copyfile(self.source, output)

            def Close(self, _save_changes: bool) -> None:
                self.closed = True

        class FakeDocuments:
            def __init__(self, doc: FakeDoc) -> None:
                self.doc = doc

            def Open(self, *_args):
                return self.doc

        class FakeWord:
            def __init__(self, doc: FakeDoc) -> None:
                self.Visible = True
                self.DisplayAlerts = 1
                self.UserName = "Old Name"
                self.UserInitials = "ON"
                self.Documents = FakeDocuments(doc)
                self.quit_called = False

            def Quit(self) -> None:
                self.quit_called = True

        class FakeClient:
            def __init__(self, word: FakeWord) -> None:
                self.word = word

            def Dispatch(self, _name: str) -> FakeWord:
                return self.word

        def call_with(comments: list[FakeComment], all_ids: list[str], targets: list[str], missing: list[str] | None = None):
            output = self.workdir / f"word-{len(list(self.workdir.glob('word-*.docx')))}.docx"
            output.write_text("existing", encoding="utf-8")
            doc = FakeDoc(self.input_docx, comments)
            word = FakeWord(doc)
            with mock.patch.object(word_module, "require_word_com", return_value=FakeClient(word)):
                with mock.patch.object(word_module, "missing_threaded_reply_ids", return_value=missing or []):
                    result = word_module.add_word_reply_threads(
                        self.input_docx,
                        output,
                        all_ids,
                        targets,
                        {"0": {"reply": "Answered."}},
                        author="AIS Specify",
                        initials="AIS",
                    )
            return result, word, output

        result, word, output = call_with([FakeComment()], ["0"], ["0"])
        self.assertEqual(result["threaded_replies_added"], 1)
        self.assertEqual(result["output_docx"], str(output))
        self.assertTrue(word.quit_called)
        self.assertEqual(word.UserName, "Old Name")
        self.assertEqual(word.UserInitials, "ON")

        with self.assertRaisesRegex(RuntimeError, "does not match"):
            call_with([], ["0"], ["0"])
        with self.assertRaisesRegex(RuntimeError, "did not attach reply"):
            call_with([FakeComment(increment=False)], ["0"], ["0"])
        with self.assertRaisesRegex(RuntimeError, "Missing threaded replies"):
            call_with([FakeComment()], ["0"], ["0"], missing=["0"])

    def test_apply_merge_plan_with_word_replies_paths_cleanup_and_main(self) -> None:
        with self.assertRaisesRegex(FileNotFoundError, "Output directory"):
            word_module.apply_merge_plan_with_word_replies(
                self.input_docx,
                self.plan,
                self.workdir / "missing-dir" / "out.docx",
            )

        no_reply_plan = self.workdir / "no-reply.json"
        write_json(no_reply_plan, {"operations": [], "comment_replies": []})
        with self.assertRaisesRegex(ValueError, "no non-empty comment replies"):
            word_module.apply_merge_plan_with_word_replies(self.input_docx, no_reply_plan, self.workdir / "out.docx")

        with mock.patch.object(
            word_module,
            "add_word_reply_threads",
            return_value={"output_docx": str(self.workdir / "out.docx"), "threaded_replies_added": 1},
        ):
            result = word_module.apply_merge_plan_with_word_replies(self.input_docx, self.plan, self.workdir / "out.docx")
        self.assertEqual(result["threaded_replies_added"], 1)
        self.assertEqual(result["response_comment_mode"], "skipped")

        stderr = io.StringIO()
        with mock.patch.object(
            word_module,
            "add_word_reply_threads",
            return_value={"output_docx": str(self.workdir / "locked.docx"), "threaded_replies_added": 1},
        ):
            with mock.patch.object(word_module.os, "remove", side_effect=PermissionError):
                with contextlib.redirect_stderr(stderr):
                    word_module.apply_merge_plan_with_word_replies(
                        self.input_docx,
                        self.plan,
                        self.workdir / "locked.docx",
                    )
        self.assertIn("temporary DOCX is still locked", stderr.getvalue())

        with mock.patch.object(
            word_module,
            "add_word_reply_threads",
            return_value={"output_docx": str(self.workdir / "gone.docx"), "threaded_replies_added": 1},
        ):
            with mock.patch.object(word_module.os, "remove", side_effect=FileNotFoundError):
                result = word_module.apply_merge_plan_with_word_replies(
                    self.input_docx,
                    self.plan,
                    self.workdir / "gone.docx",
                )
        self.assertEqual(result["threaded_replies_added"], 1)

        with mock.patch.object(word_module, "apply_merge_plan_with_word_replies", return_value={"ok": True}):
            code, stdout, stderr = run_main(
                word_module.main,
                ["--input", "in.docx", "--plan", "plan.json", "--output", "out.docx"],
            )
        self.assertEqual(code, 0, stderr)
        self.assertEqual(json.loads(stdout), {"ok": True})

        with mock.patch.object(word_module, "apply_merge_plan_with_word_replies", side_effect=RuntimeError("boom")):
            code, stdout, stderr = run_main(
                word_module.main,
                ["--input", "in.docx", "--plan", "plan.json", "--output", "out.docx"],
            )
        self.assertEqual(code, 1)
        self.assertIn("boom", stderr)
        self.assertEqual(run_script_help("apply_merge_plan_with_word_replies.py"), 0)


class ChangeProvenanceLibraryTests(unittest.TestCase):
    """Covers the contract enforced by docx_redline_lib for merge plans."""

    def test_skill_identity_banner_reports_name_version_and_load_path(self) -> None:
        stream = io.StringIO()
        banner = emit_skill_identity(stream)
        self.assertEqual(banner, f"[skill] {SKILL_NAME} v{SKILL_VERSION} ({skill_home()})")
        self.assertEqual(stream.getvalue().strip(), banner)

        # The path is the whole point: a stale copy declares the same name and
        # can declare the same version, so only the location separates them.
        self.assertEqual(
            Path(skill_home()),
            REPO_ROOT / "Skills" / "ais-proposal-redline-docx" / "scripts",
        )

        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            emit_skill_identity()
        self.assertIn(SKILL_NAME, stderr.getvalue())

    def test_skill_version_matches_skill_md_metadata(self) -> None:
        skill_md = (REPO_ROOT / "Skills" / "ais-proposal-redline-docx" / "SKILL.md").read_text(
            encoding="utf-8"
        )
        self.assertIn(f'version: "{SKILL_VERSION}"', skill_md)

    def test_published_schema_stays_in_step_with_library_constants(self) -> None:
        schema = json.loads(
            (
                REPO_ROOT
                / "Skills"
                / "ais-proposal-redline-docx"
                / "schemas"
                / "merge-plan.schema.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(schema["x-skill-name"], SKILL_NAME)
        self.assertEqual(schema["x-skill-version"], SKILL_VERSION)
        self.assertIn("Structural subset", schema["description"])
        self.assertEqual(schema["required"], ["operations"])
        self.assertEqual(
            schema["$defs"]["provenanceSource"]["pattern"], PROVENANCE_SOURCE_PATTERN
        )
        self.assertEqual(
            schema["$defs"]["settings"]["properties"]["author"]["const"],
            DEFAULT_RESPONSE_AUTHOR,
        )
        self.assertEqual(
            schema["$defs"]["operation"]["allOf"][0]["then"]["required"],
            ["rationale", "source"],
        )
        self.assertEqual(
            schema["$defs"]["theme"]["required"],
            ["id", "rationale", "source", "anchor_paragraph_index"],
        )

    def test_shipped_sample_plan_satisfies_the_contract(self) -> None:
        sample = json.loads(
            (
                REPO_ROOT
                / "Skills"
                / "ais-proposal-redline-docx"
                / "examples"
                / "merge-plan.sample.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(validate_merge_plan(sample), [])

    def test_provenance_source_grammar(self) -> None:
        for source, kind in [
            ("reviewer_comment:12", "reviewer_comment"),
            ("review_call:2026-06-12", "review_call"),
            ("compliance:F-1", "compliance"),
            ("internal_qa", "internal_qa"),
        ]:
            with self.subTest(source=source):
                self.assertTrue(is_valid_provenance_source(source))
                self.assertEqual(provenance_source_kind(source), kind)

        for source in ["", "reviewer_comment:", "call notes", "internal_qa:1", None]:
            with self.subTest(source=source):
                self.assertFalse(is_valid_provenance_source(source))
                self.assertEqual(provenance_source_kind(source), "unknown")

    def test_generic_rationale_rejects_stock_phrases_and_short_text(self) -> None:
        self.assertTrue(is_generic_rationale("Addressed."))
        self.assertTrue(is_generic_rationale("Tightened"))
        self.assertTrue(is_generic_rationale(""))
        self.assertFalse(
            is_generic_rationale("Reframed the opening claim to match the evidence.")
        )
        self.assertFalse(
            is_generic_rationale(
                "The page-limit concern is addressed in the revision by tabulating the phase detail."
            )
        )

    def test_enabled_operations_and_declared_themes_ignore_malformed_entries(self) -> None:
        plan = {
            "operations": [
                {"type": "replace_paragraph_text"},
                {"type": "replace_paragraph_text", "enabled": False},
                "not-an-operation",
            ],
            "themes": [
                {"id": "kept", "rationale": "x", "source": "internal_qa"},
                {"id": "  ", "rationale": "y", "source": "internal_qa"},
                "not-a-theme",
            ],
        }
        self.assertEqual(len(enabled_operations(plan)), 1)
        self.assertEqual(list(declared_themes(plan)), ["kept"])

    def test_validate_merge_plan_accepts_a_well_formed_plan(self) -> None:
        plan = {
            "settings": {"author": DEFAULT_RESPONSE_AUTHOR},
            "themes": [
                {
                    "id": "compression",
                    "rationale": "Compressed the phase narrative to hold the page limit.",
                    "source": "compliance:F-1",
                    "anchor_paragraph_index": 0,
                }
            ],
            "operations": [
                {
                    "type": "replace_paragraph_text",
                    "paragraph_index": 0,
                    "rationale": "Replaced the phase prose with the summary table.",
                    "source": "compliance:F-1",
                    "theme": "compression",
                },
                {
                    "type": "insert_paragraph_after",
                    "paragraph_index": 1,
                    "rationale": "Added the transition the reviewer asked for.",
                    "source": "reviewer_comment:4",
                },
                {"enabled": False, "type": "replace_paragraph_text", "paragraph_index": 0},
            ],
        }
        self.assertEqual(validate_merge_plan(plan, paragraph_count=2), [])
        self.assertEqual(
            summarize_provenance(plan), {"compliance": 1, "reviewer_comment": 1}
        )

    def test_validate_merge_plan_rejects_missing_and_weak_provenance(self) -> None:
        plan = {
            "operations": [
                {"type": "replace_paragraph_text", "paragraph_index": 0, "source": "internal_qa"},
                {
                    "type": "replace_paragraph_text",
                    "paragraph_index": 0,
                    "rationale": "Addressed.",
                    "source": "internal_qa",
                },
                {
                    "type": "replace_paragraph_text",
                    "paragraph_index": 0,
                    "rationale": "Tightened",
                    "source": "internal_qa",
                },
                {
                    "type": "replace_paragraph_text",
                    "paragraph_index": 0,
                    "rationale": "Reworded the claim to match the evidence.",
                },
                {
                    "type": "replace_paragraph_text",
                    "paragraph_index": 0,
                    "rationale": "Reworded the closing claim to match the evidence.",
                    "source": "because the reviewer said so",
                },
            ]
        }
        errors = validate_merge_plan(plan)
        joined = "\n".join(errors)
        self.assertEqual(len(errors), 5)
        self.assertIn("Operation 0 (replace_paragraph_text) is missing a rationale", joined)
        self.assertIn("rationale is a stock phrase ('Addressed.')", joined)
        self.assertIn("rationale is 1 words; at least 4 are needed", joined)
        self.assertIn("is missing a provenance source", joined)
        self.assertIn("unrecognised provenance source", joined)

    def test_validate_merge_plan_skips_provenance_when_explicitly_waived(self) -> None:
        plan = {"operations": [{"type": "replace_paragraph_text", "paragraph_index": 0}]}
        self.assertEqual(validate_merge_plan(plan, require_provenance=False), [])

    def test_validate_merge_plan_pins_the_response_author(self) -> None:
        plan = {"settings": {"author": "AIS Proposal Team"}, "operations": []}
        errors = validate_merge_plan(plan)
        self.assertEqual(len(errors), 1)
        self.assertIn("AIS Proposal Team", errors[0])
        self.assertIn(DEFAULT_RESPONSE_AUTHOR, errors[0])
        self.assertEqual(validate_merge_plan(plan, allow_author_override=True), [])
        self.assertEqual(validate_merge_plan({"operations": []}), [])

    def test_validate_merge_plan_checks_theme_wiring(self) -> None:
        errors = validate_merge_plan(
            {
                "themes": [
                    {
                        "id": "orphan",
                        "rationale": "Nothing references this theme any more.",
                        "source": "internal_qa",
                        "anchor_paragraph_index": 0,
                    },
                    {
                        "id": "unanchored",
                        "rationale": "This theme has nowhere to put its comment.",
                        "source": "internal_qa",
                    },
                    {
                        "id": "far",
                        "rationale": "This theme points past the end of the document.",
                        "source": "internal_qa",
                        "anchor_paragraph_index": 99,
                    },
                ],
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "rationale": "Applied the agreed terminology change here.",
                        "source": "internal_qa",
                        "theme": "unanchored",
                    },
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 1,
                        "rationale": "Applied the agreed terminology change here too.",
                        "source": "internal_qa",
                        "theme": "far",
                    },
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 1,
                        "rationale": "Applied the agreed terminology change once more.",
                        "source": "internal_qa",
                        "theme": "undeclared",
                    },
                ],
            },
            paragraph_count=2,
        )
        joined = "\n".join(errors)
        self.assertIn("Theme 'unanchored' needs an integer anchor_paragraph_index", joined)
        self.assertIn("Theme 'far' anchor_paragraph_index 99 is out of range", joined)
        self.assertIn("references theme 'undeclared', which is not declared", joined)
        self.assertIn("Theme 'orphan' is declared but no enabled operation references it", joined)

    def test_validate_merge_plan_requires_duplicate_rationales_to_be_a_theme(self) -> None:
        errors = validate_merge_plan(
            {
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "rationale": "Applied the terminology decision across this paragraph.",
                        "source": "internal_qa",
                    },
                    {
                        "type": "insert_paragraph_after",
                        "paragraph_index": 1,
                        "rationale": "  APPLIED THE TERMINOLOGY DECISION ACROSS THIS PARAGRAPH. ",
                        "source": "internal_qa",
                    },
                    {
                        "enabled": False,
                        "type": "replace_paragraph_text",
                        "paragraph_index": 2,
                        "rationale": "Applied the terminology decision across this paragraph.",
                        "source": "internal_qa",
                    },
                ]
            }
        )
        self.assertEqual(len(errors), 1)
        self.assertIn("Operations 0, 1 share an identical rationale", errors[0])
        self.assertIn("one explanation instead of 2", errors[0])
        self.assertEqual(
            validate_merge_plan(
                {
                    "operations": [
                        {
                            "type": "replace_paragraph_text",
                            "paragraph_index": 0,
                            "rationale": "Repeated waiver text",
                        },
                        {
                            "type": "replace_paragraph_text",
                            "paragraph_index": 1,
                            "rationale": "Repeated waiver text",
                        },
                    ]
                },
                require_provenance=False,
            ),
            [],
        )

    def test_validate_merge_plan_reports_malformed_input_instead_of_raising(self) -> None:
        # A validator that raises hands back a stack trace where the caller
        # asked for a list of problems, so structure is reported like any
        # other violation.
        self.assertEqual(validate_merge_plan("not a plan"), ["Merge plan must be a JSON object"])

        errors = validate_merge_plan(
            {"settings": "AIS Specify", "operations": "replace everything", "themes": 7}
        )
        joined = "\n".join(errors)
        self.assertIn("settings must be an object", joined)
        self.assertIn("operations must be an array", joined)
        self.assertIn("themes must be an array", joined)

        errors = validate_merge_plan({"operations": ["nope"], "themes": [42]})
        joined = "\n".join(errors)
        self.assertIn("operations[0] must be an object", joined)
        self.assertIn("themes[0] must be an object", joined)

    def test_validate_merge_plan_rejects_duplicate_and_unnamed_theme_ids(self) -> None:
        errors = validate_merge_plan(
            {
                "themes": [
                    {
                        "id": "terminology",
                        "rationale": "Standardised the terminology across the section.",
                        "source": "internal_qa",
                        "anchor_paragraph_index": 0,
                    },
                    {
                        "id": "terminology",
                        "rationale": "A second declaration that quietly wins.",
                        "source": "internal_qa",
                        "anchor_paragraph_index": 0,
                    },
                    {"rationale": "No id at all.", "source": "internal_qa"},
                ],
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "rationale": "Applied the agreed terminology change here.",
                        "source": "internal_qa",
                        "theme": "terminology",
                    }
                ],
            },
            paragraph_count=1,
        )
        joined = "\n".join(errors)
        self.assertIn("Theme 'terminology' is declared more than once", joined)
        self.assertIn("themes[2] is missing an id", joined)

    def test_operation_errors_quote_the_authored_index(self) -> None:
        # Counting only enabled operations would point the operator at the
        # wrong entry as soon as anything in the plan is switched off.
        errors = validate_merge_plan(
            {
                "operations": [
                    {"type": "replace_paragraph_text", "paragraph_index": 0, "enabled": False},
                    {"type": "insert_paragraph_after", "paragraph_index": 1},
                ]
            }
        )
        joined = "\n".join(errors)
        self.assertIn("Operation 1 (insert_paragraph_after)", joined)
        self.assertNotIn("Operation 0", joined)

    def test_collection_helpers_ignore_wrong_types(self) -> None:
        self.assertEqual(enabled_operations({"operations": "nope"}), [])
        self.assertEqual(enabled_operations("not a plan"), [])
        self.assertEqual(declared_themes({"themes": {"id": "x"}}), {})
        self.assertEqual(summarize_provenance({"operations": None}), {})


class ChangeProvenanceApplyTests(unittest.TestCase):
    """Covers explanation comments, theme rollup, and validate-before-mutate."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)
        self.input_docx = self.workdir / "input.docx"
        write_docx(
            self.input_docx,
            '<w:p><w:r><w:t>Alpha</w:t></w:r></w:p><w:p><w:r><w:t>Beta</w:t></w:r></w:p>',
            include_settings=False,
            include_doc_rels=False,
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def plan_path(self, payload: dict) -> Path:
        return write_json(self.workdir / "plan.json", payload)

    def test_theme_rollup_emits_one_comment_for_the_whole_group(self) -> None:
        plan = self.plan_path(
            {
                "themes": [
                    {
                        "id": "terminology",
                        "rationale": "Standardised on 'operating model' across the section.",
                        "source": "review_call:2026-06-12",
                        "anchor_paragraph_index": 0,
                    }
                ],
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "text": "Alpha operating model",
                        "rationale": "Renamed the framework in the opening paragraph.",
                        "source": "review_call:2026-06-12",
                        "theme": "terminology",
                    },
                    {
                        "type": "insert_paragraph_after",
                        "paragraph_index": 1,
                        "text": "Beta operating model",
                        "rationale": "Renamed the framework in the closing paragraph.",
                        "source": "review_call:2026-06-12",
                        "theme": "terminology",
                    },
                    {
                        "type": "insert_table_after",
                        "paragraph_index": 1,
                        "rows": [["Phase", "Purpose"]],
                        "rationale": "Summarised the phases to hold the page limit.",
                        "source": "compliance:F-1",
                    },
                ],
                "comment_replies": [],
            }
        )
        output = self.workdir / "themed.docx"
        result = apply_module.apply_merge_plan(self.input_docx, plan, output)

        self.assertEqual(result["operations_applied"], 3)
        self.assertEqual(result["theme_comments_added"], 1)
        self.assertEqual(result["explanation_comments_added"], 1)
        self.assertEqual(
            result["provenance_counts"], {"review_call": 2, "compliance": 1}
        )

        texts = comment_texts(output)
        self.assertEqual(len(texts), 2)
        self.assertTrue(
            any("applies to 2 changes" in text for text in texts), texts
        )
        self.assertTrue(any("source: compliance:F-1" in text for text in texts), texts)

    def test_explanation_anchor_matches_each_operation_type(self) -> None:
        plan = self.plan_path(
            {
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "text": "Alpha revised",
                        "rationale": "Reframed the opening paragraph around the evidence.",
                        "source": "internal_qa",
                    },
                    {
                        "type": "insert_paragraph_after",
                        "paragraph_index": 1,
                        "text": "Inserted transition",
                        "rationale": "Added the transition requested during the review call.",
                        "source": "review_call:anchor-test",
                    },
                    {
                        "type": "insert_table_after",
                        "paragraph_index": 1,
                        "rows": [["Phase", "Purpose"]],
                        "rationale": "Tabulated the phase detail to protect the page limit.",
                        "source": "compliance:anchor-test",
                    },
                ],
                "comment_replies": [],
            }
        )
        output = self.workdir / "anchors.docx"
        apply_module.apply_merge_plan(self.input_docx, plan, output)

        document = xml_part(output, "word/document.xml")
        comments = comments_to_list(
            xml_part(output, "word/comments.xml"), extract_comment_anchors(document)
        )
        by_source = {
            comment["text"].split("source: ", 1)[1].rstrip(")"): comment
            for comment in comments
        }
        self.assertIn("Alpha revised", by_source["internal_qa"]["anchor_text"])
        self.assertEqual(
            by_source["review_call:anchor-test"]["anchor_text"], "Inserted transition"
        )
        self.assertEqual(by_source["compliance:anchor-test"]["anchor_text"], "Beta")

    def test_single_change_theme_reads_as_one_change(self) -> None:
        plan = self.plan_path(
            {
                "themes": [
                    {
                        "id": "solo",
                        "rationale": "One instance of the agreed reframing.",
                        "source": "internal_qa",
                        "anchor_paragraph_index": 1,
                    }
                ],
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "text": "Alpha reframed",
                        "rationale": "Applied the reframing to the opening paragraph.",
                        "source": "internal_qa",
                        "theme": "solo",
                    }
                ],
                "comment_replies": [],
            }
        )
        output = self.workdir / "solo.docx"
        result = apply_module.apply_merge_plan(self.input_docx, plan, output)
        self.assertEqual(result["theme_comments_added"], 1)
        texts = comment_texts(output)
        self.assertIn("applies to 1 change)", texts[0])

    def test_invalid_plan_is_rejected_before_any_output_is_written(self) -> None:
        plan = self.plan_path(
            {
                "settings": {"author": "AIS Proposal Team"},
                "operations": [
                    {"type": "replace_paragraph_text", "paragraph_index": 0, "text": "One"},
                    {"type": "replace_paragraph_text", "paragraph_index": 1, "text": "Two"},
                ],
                "comment_replies": [],
            }
        )
        output = self.workdir / "never-written.docx"
        with self.assertRaises(ValueError) as ctx:
            apply_module.apply_merge_plan(self.input_docx, plan, output)

        message = str(ctx.exception)
        self.assertIn("change-provenance contract", message)
        # Every violation is reported at once so the operator fixes the plan in
        # one pass rather than discovering problems one run at a time.
        self.assertEqual(message.count("is missing a rationale"), 2)
        self.assertIn("settings.author", message)
        self.assertFalse(output.exists())

    def test_author_and_provenance_gates_can_be_waived_explicitly(self) -> None:
        plan = self.plan_path(
            {
                "settings": {"author": "Someone Else", "initials": "SE"},
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "text": "One",
                        "rationale": "Draft explanation without a source token.",
                    }
                ],
                "comment_replies": [],
            }
        )
        result = apply_module.apply_merge_plan(
            self.input_docx,
            plan,
            self.workdir / "waived.docx",
            allow_author_override=True,
            allow_unexplained_changes=True,
        )
        self.assertEqual(result["author"], "Someone Else")
        self.assertTrue(result["author_override"])
        self.assertEqual(result["explanation_comments_added"], 1)
        self.assertEqual(comment_texts(self.workdir / "waived.docx"), [
            "Draft explanation without a source token."
        ])

    def test_cli_exposes_the_override_flags_and_prints_the_banner(self) -> None:
        plan = self.plan_path(
            {
                "settings": {"author": "Someone Else"},
                "operations": [
                    {"type": "replace_paragraph_text", "paragraph_index": 0, "text": "One"}
                ],
                "comment_replies": [],
            }
        )
        output = self.workdir / "cli.docx"
        code, stdout, stderr = run_main(
            apply_module.main,
            [
                "--input",
                str(self.input_docx),
                "--plan",
                str(plan),
                "--output",
                str(output),
                "--allow-author-override",
                "--allow-unexplained-changes",
            ],
        )
        self.assertEqual(code, 0, stderr)
        self.assertIn(f"[skill] {SKILL_NAME} v{SKILL_VERSION}", stderr)
        self.assertTrue(json.loads(stdout)["author_override"])

    def test_every_cli_announces_the_running_skill(self) -> None:
        for module in (
            apply_module,
            build_module,
            extract_module,
            validate_module,
            word_module,
        ):
            with self.subTest(module=module.__name__):
                stderr = io.StringIO()
                with mock.patch.object(sys, "argv", [module.__name__, "--help"]):
                    with contextlib.redirect_stdout(io.StringIO()):
                        with contextlib.redirect_stderr(stderr):
                            # --help exits the parser, so the banner must be
                            # emitted before argument parsing to be reliable.
                            with self.assertRaises(SystemExit):
                                module.main()
                self.assertIn(f"[skill] {SKILL_NAME} v{SKILL_VERSION}", stderr.getvalue())


class ChangeProvenanceValidateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.workdir = Path(self.tmp.name)
        self.docx = self.workdir / "redline.docx"
        write_docx(self.docx, '<w:p><w:r><w:t>Alpha</w:t></w:r></w:p>')

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_validator_reports_provenance_counts_from_the_plan(self) -> None:
        plan = write_json(
            self.workdir / "plan.json",
            {
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "rationale": "Reworded the claim to match the cited evidence.",
                        "source": "reviewer_comment:3",
                    }
                ]
            },
        )
        summary, issues = validate_module.validate_docx(self.docx, plan_path=plan)
        self.assertEqual(issues, [])
        self.assertEqual(summary["provenance_counts"], {"reviewer_comment": 1})
        self.assertFalse(summary["resolution_author_override"])

    def test_validator_checks_anchor_ranges_and_supports_the_draft_waiver(self) -> None:
        ranged_plan = write_json(
            self.workdir / "ranged-plan.json",
            {
                "themes": [
                    {
                        "id": "past-end",
                        "rationale": "Applied one decision across the draft section.",
                        "source": "internal_qa",
                        "anchor_paragraph_index": 1,
                    }
                ],
                "operations": [
                    {
                        "type": "replace_paragraph_text",
                        "paragraph_index": 0,
                        "rationale": "Applied the decision to the opening paragraph.",
                        "source": "internal_qa",
                        "theme": "past-end",
                    }
                ],
            },
        )
        _, ranged_issues = validate_module.validate_docx(self.docx, plan_path=ranged_plan)
        self.assertIn("anchor_paragraph_index 1 is out of range", "\n".join(ranged_issues))

        waived_plan = write_json(
            self.workdir / "waived-plan.json",
            {"operations": [{"type": "replace_paragraph_text", "paragraph_index": 0}]},
        )
        _, strict_issues = validate_module.validate_docx(self.docx, plan_path=waived_plan)
        self.assertIn("is missing a rationale", "\n".join(strict_issues))
        _, waived_issues = validate_module.validate_docx(
            self.docx, plan_path=waived_plan, allow_unexplained_changes=True
        )
        self.assertEqual(waived_issues, [])

    def test_validator_reports_an_unreadable_plan_as_an_issue(self) -> None:
        invalid_plan = self.workdir / "invalid-plan.json"
        invalid_plan.write_text("{", encoding="utf-8")
        summary, issues = validate_module.validate_docx(self.docx, plan_path=invalid_plan)
        self.assertEqual(summary["provenance_counts"], {})
        self.assertIn("Could not load merge plan", issues[0])

    def test_validator_surfaces_plan_contract_violations(self) -> None:
        plan = write_json(
            self.workdir / "bad-plan.json",
            {
                "settings": {"author": "AIS Proposal Team"},
                "operations": [{"type": "replace_paragraph_text", "paragraph_index": 0}],
            },
        )
        _, issues = validate_module.validate_docx(self.docx, plan_path=plan)
        joined = "\n".join(issues)
        self.assertIn("settings.author", joined)
        self.assertIn("is missing a rationale", joined)

        _, allowed = validate_module.validate_docx(
            self.docx, plan_path=plan, allow_author_override=True
        )
        self.assertNotIn("settings.author", "\n".join(allowed))

    def test_validator_cli_accepts_the_plan_flag(self) -> None:
        plan = write_json(
            self.workdir / "cli-plan.json",
            {"settings": {"author": "AIS Proposal Team"}, "operations": []},
        )
        code, stdout, _ = run_main(
            validate_module.main,
            ["--input", str(self.docx), "--plan", str(plan), "--json"],
        )
        self.assertEqual(code, 1)
        self.assertIn("settings.author", stdout)

        code, stdout, _ = run_main(
            validate_module.main,
            [
                "--input",
                str(self.docx),
                "--plan",
                str(plan),
                "--allow-author-override",
                "--json",
            ],
        )
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(stdout)["provenance_counts"], {})

        waived_plan = write_json(
            self.workdir / "cli-waived-plan.json",
            {"operations": [{"type": "replace_paragraph_text", "paragraph_index": 0}]},
        )
        code, stdout, _ = run_main(
            validate_module.main,
            [
                "--input",
                str(self.docx),
                "--plan",
                str(waived_plan),
                "--allow-unexplained-changes",
                "--json",
            ],
        )
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(stdout)["issues"], [])

    def test_resolution_author_override_is_reported(self) -> None:
        summary, _ = validate_module.validate_docx(self.docx, resolution_author="Someone Else")
        self.assertTrue(summary["resolution_author_override"])


class MergePlanSkeletonTests(unittest.TestCase):
    def test_skeleton_teaches_the_provenance_shape(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            workdir = Path(tmp)
            context = write_json(
                workdir / "context.json",
                {"comments": [], "paragraphs": [], "table_count": 0},
            )
            output = workdir / "plan.json"
            code, _, stderr = run_main(
                build_module.main,
                ["--review-context", str(context), "--output", str(output)],
            )
            self.assertEqual(code, 0, stderr)
            plan = json.loads(output.read_text(encoding="utf-8"))

        self.assertEqual(plan["themes"], [])
        self.assertTrue(plan["operation_examples"])
        self.assertTrue(plan["theme_examples"])
        for example in plan["operation_examples"]:
            self.assertFalse(is_generic_rationale(example["rationale"]))
            self.assertTrue(is_valid_provenance_source(example["source"]))
        for example in plan["theme_examples"]:
            self.assertFalse(is_generic_rationale(example["rationale"]))
            self.assertTrue(is_valid_provenance_source(example["source"]))
            self.assertIsInstance(example["anchor_paragraph_index"], int)


if __name__ == "__main__":
    unittest.main()
