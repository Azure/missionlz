"""Shared OOXML helpers for the AIS proposal redline DOCX skill."""

from __future__ import annotations

import copy
import re
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from lxml import etree

NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
}

XML_NS = "http://www.w3.org/XML/1998/namespace"
REL_NS = NS["pr"]
COMMENTS_REL_TYPE = (
    "http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments"
)
COMMENTS_CONTENT_TYPE = (
    "application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"
)
DEFAULT_RESPONSE_AUTHOR = "AIS Specify"
DEFAULT_RESPONSE_INITIALS = "AIS"
SKIP_REPLY_STATUSES = {"skip", "skipped", "not_applicable"}

SKILL_NAME = "ais-proposal-redline-docx"
SKILL_VERSION = "2.0"

# Provenance grammar for merge-plan operations and themes. Kinds ending in ":"
# require an identifier; bare kinds stand alone.
PROVENANCE_SOURCE_KINDS = (
    "reviewer_comment:",
    "review_call:",
    "compliance:",
    "internal_qa",
)
PROVENANCE_SOURCE_PATTERN = (
    r"^(?:reviewer_comment:[A-Za-z0-9._-]+"
    r"|review_call:[A-Za-z0-9._-]+"
    r"|compliance:[A-Za-z0-9._-]+"
    r"|internal_qa)$"
)
_PROVENANCE_SOURCE_RE = re.compile(PROVENANCE_SOURCE_PATTERN)

MIN_RATIONALE_WORDS = 4


def qn(prefix: str, name: str) -> str:
    return f"{{{NS[prefix]}}}{name}"


def local_name(node: etree._Element) -> str:
    return etree.QName(node).localname


def parse_xml(data: bytes) -> etree._Element:
    parser = etree.XMLParser(remove_blank_text=False, resolve_entities=False)
    return etree.fromstring(data, parser=parser)


def serialize_xml(root: etree._Element) -> bytes:
    return etree.tostring(root, encoding="UTF-8", xml_declaration=True)


def require_part(zf: zipfile.ZipFile, part_name: str) -> bytes:
    try:
        return zf.read(part_name)
    except KeyError as exc:
        raise ValueError(f"Missing required DOCX part: {part_name}") from exc


def read_xml_part(zf: zipfile.ZipFile, part_name: str) -> etree._Element:
    return parse_xml(require_part(zf, part_name))


def write_docx_with_replacements(
    source_docx: str | Path,
    output_docx: str | Path,
    replacements: dict[str, bytes],
) -> None:
    source_docx = Path(source_docx)
    output_docx = Path(output_docx)
    existing: set[str] = set()

    with zipfile.ZipFile(source_docx, "r") as zin, zipfile.ZipFile(
        output_docx, "w", zipfile.ZIP_DEFLATED
    ) as zout:
        for item in zin.infolist():
            existing.add(item.filename)
            if item.filename in replacements:
                zout.writestr(item, replacements[item.filename])
            else:
                zout.writestr(item, zin.read(item.filename))

        for part_name, data in replacements.items():
            if part_name not in existing:
                zout.writestr(part_name, data)


def body_paragraphs(document_root: etree._Element) -> list[etree._Element]:
    body = document_root.find(".//w:body", namespaces=NS)
    if body is None:
        return []
    return body.xpath(".//w:p", namespaces=NS)


def body_tables(document_root: etree._Element) -> list[etree._Element]:
    body = document_root.find(".//w:body", namespaces=NS)
    if body is None:
        return []
    return body.xpath(".//w:tbl", namespaces=NS)


def paragraph_text(paragraph: etree._Element) -> str:
    pieces: list[str] = []
    for node in paragraph.xpath(".//w:t | .//w:delText", namespaces=NS):
        if node.text:
            pieces.append(node.text)
    return "".join(pieces)


def paragraph_style(paragraph: etree._Element) -> str:
    style = paragraph.find("./w:pPr/w:pStyle", namespaces=NS)
    if style is None:
        return ""
    return style.get(qn("w", "val"), "")


def set_paragraph_style(paragraph: etree._Element, style_id: str) -> None:
    if not style_id:
        return
    p_pr = paragraph.find("./w:pPr", namespaces=NS)
    if p_pr is None:
        p_pr = etree.Element(qn("w", "pPr"))
        paragraph.insert(0, p_pr)
    p_style = p_pr.find("./w:pStyle", namespaces=NS)
    if p_style is None:
        p_style = etree.SubElement(p_pr, qn("w", "pStyle"))
    p_style.set(qn("w", "val"), style_id)


def comment_text(comment: etree._Element) -> str:
    pieces: list[str] = []
    for node in comment.xpath(".//w:t", namespaces=NS):
        if node.text:
            pieces.append(node.text)
    return " ".join(" ".join(pieces).split())


def extract_comment_anchors(
    document_root: etree._Element,
) -> dict[str, dict[str, Any]]:
    anchors: dict[str, dict[str, Any]] = {}
    for idx, paragraph in enumerate(body_paragraphs(document_root)):
        cids: set[str] = set()
        for node in paragraph.xpath(
            ".//w:commentRangeStart | .//w:commentReference", namespaces=NS
        ):
            cid = node.get(qn("w", "id"))
            if cid is not None:
                cids.add(cid)
        if not cids:
            continue

        text = paragraph_text(paragraph)
        style = paragraph_style(paragraph)
        for cid in cids:
            anchors.setdefault(
                cid,
                {
                    "anchor_paragraph_index": idx,
                    "anchor_text": text[:240],
                    "anchor_style": style,
                },
            )
    return anchors


def comments_to_list(
    comments_root: etree._Element | None,
    anchors: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    if comments_root is None:
        return []

    comments: list[dict[str, Any]] = []
    for comment in comments_root.xpath("./w:comment", namespaces=NS):
        cid = comment.get(qn("w", "id"), "")
        item = {
            "id": cid,
            "author": comment.get(qn("w", "author"), ""),
            "initials": comment.get(qn("w", "initials"), ""),
            "date": comment.get(qn("w", "date"), ""),
            "text": comment_text(comment),
        }
        item.update(
            anchors.get(
                cid,
                {
                    "anchor_paragraph_index": -1,
                    "anchor_text": "",
                    "anchor_style": "",
                },
            )
        )
        comments.append(item)

    def sort_key(item: dict[str, Any]) -> tuple[int, str]:
        cid = str(item.get("id", ""))
        return (int(cid) if cid.isdigit() else 10**9, cid)

    return sorted(comments, key=sort_key)


def tracked_revision_counts(document_root: etree._Element) -> dict[str, int]:
    return {
        "insertions": len(document_root.xpath(".//w:ins", namespaces=NS)),
        "deletions": len(document_root.xpath(".//w:del", namespaces=NS)),
    }


def settings_has_track_revisions(settings_root: etree._Element | None) -> bool:
    if settings_root is None:
        return False
    return settings_root.find("./w:trackRevisions", namespaces=NS) is not None


def ensure_track_revisions(settings_root: etree._Element) -> None:
    if settings_has_track_revisions(settings_root):
        return
    settings_root.append(etree.Element(qn("w", "trackRevisions")))


def create_settings_root() -> etree._Element:
    return etree.Element(qn("w", "settings"), nsmap={"w": NS["w"]})


def create_comments_root() -> etree._Element:
    return etree.Element(qn("w", "comments"), nsmap={"w": NS["w"]})


def max_numeric_attr(root: etree._Element, attr_name: str) -> int:
    max_id = -1
    for node in root.xpath(f".//*[@w:{attr_name}]", namespaces=NS):
        value = node.get(qn("w", attr_name), "")
        if value.isdigit():
            max_id = max(max_id, int(value))
    return max_id


def next_comment_id(comments_root: etree._Element | None) -> int:
    if comments_root is None:
        return 200
    max_id = -1
    for comment in comments_root.xpath("./w:comment", namespaces=NS):
        cid = comment.get(qn("w", "id"), "")
        if cid.isdigit():
            max_id = max(max_id, int(cid))
    return max(max_id + 1, 200)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def make_text_element(tag_name: str, text: str) -> etree._Element:
    node = etree.Element(qn("w", tag_name))
    if text.startswith(" ") or text.endswith(" "):
        node.set(f"{{{XML_NS}}}space", "preserve")
    node.text = text
    return node


def make_revision(
    kind: str,
    revision_id: int,
    author: str,
    date: str,
    text: str,
) -> etree._Element:
    if kind not in {"ins", "del"}:
        raise ValueError(f"Unsupported revision kind: {kind}")

    revision = etree.Element(qn("w", kind))
    revision.set(qn("w", "id"), str(revision_id))
    revision.set(qn("w", "author"), author)
    revision.set(qn("w", "date"), date)

    run = etree.SubElement(revision, qn("w", "r"))
    run.append(make_text_element("delText" if kind == "del" else "t", text))
    return revision


def _split_comment_children(
    paragraph: etree._Element,
) -> tuple[list[etree._Element], list[etree._Element]]:
    starts: list[etree._Element] = []
    ends_and_refs: list[etree._Element] = []
    for child in paragraph:
        name = local_name(child)
        if name == "commentRangeStart":
            starts.append(copy.deepcopy(child))
        elif name == "commentRangeEnd":
            ends_and_refs.append(copy.deepcopy(child))
        elif name == "r" and child.find(".//w:commentReference", namespaces=NS) is not None:
            ends_and_refs.append(copy.deepcopy(child))
    return starts, ends_and_refs


def replace_paragraph_text(
    paragraph: etree._Element,
    text: str,
    revision_id: int,
    author: str,
    date: str,
    style_id: str = "",
) -> int:
    old_text = paragraph_text(paragraph)
    p_pr = paragraph.find("./w:pPr", namespaces=NS)
    p_pr_copy = copy.deepcopy(p_pr) if p_pr is not None else None
    starts, ends_and_refs = _split_comment_children(paragraph)

    paragraph.clear()
    if p_pr_copy is not None:
        paragraph.append(p_pr_copy)
    if style_id:
        set_paragraph_style(paragraph, style_id)

    for node in starts:
        paragraph.append(node)
    next_revision = revision_id
    if old_text:
        paragraph.append(make_revision("del", next_revision, author, date, old_text))
        next_revision += 1
    paragraph.append(make_revision("ins", next_revision, author, date, text))
    next_revision += 1
    for node in ends_and_refs:
        paragraph.append(node)
    return next_revision


def make_inserted_paragraph(
    text: str,
    revision_id: int,
    author: str,
    date: str,
    base_paragraph: etree._Element | None = None,
    style_id: str = "",
) -> etree._Element:
    paragraph = etree.Element(qn("w", "p"))
    if base_paragraph is not None:
        p_pr = base_paragraph.find("./w:pPr", namespaces=NS)
        if p_pr is not None:
            paragraph.append(copy.deepcopy(p_pr))
    if style_id:
        set_paragraph_style(paragraph, style_id)
    paragraph.append(make_revision("ins", revision_id, author, date, text))
    return paragraph


def make_inserted_table(
    rows: list[list[Any]],
    revision_id: int,
    author: str,
    date: str,
    style_id: str = "TableGrid",
) -> etree._Element:
    table = etree.Element(qn("w", "tbl"))
    tbl_pr = etree.SubElement(table, qn("w", "tblPr"))
    if style_id:
        tbl_style = etree.SubElement(tbl_pr, qn("w", "tblStyle"))
        tbl_style.set(qn("w", "val"), style_id)
    tbl_w = etree.SubElement(tbl_pr, qn("w", "tblW"))
    tbl_w.set(qn("w", "w"), "0")
    tbl_w.set(qn("w", "type"), "auto")

    col_count = max((len(row) for row in rows), default=1)
    tbl_grid = etree.SubElement(table, qn("w", "tblGrid"))
    for _ in range(col_count):
        grid_col = etree.SubElement(tbl_grid, qn("w", "gridCol"))
        grid_col.set(qn("w", "w"), str(max(1200, int(9000 / max(col_count, 1)))))

    next_revision = revision_id
    for row in rows:
        tr = etree.SubElement(table, qn("w", "tr"))
        for cell_value in row:
            tc = etree.SubElement(tr, qn("w", "tc"))
            tc_pr = etree.SubElement(tc, qn("w", "tcPr"))
            tc_w = etree.SubElement(tc_pr, qn("w", "tcW"))
            tc_w.set(qn("w", "w"), str(max(1200, int(9000 / max(col_count, 1)))))
            tc_w.set(qn("w", "type"), "dxa")
            p = etree.SubElement(tc, qn("w", "p"))
            p.append(make_revision("ins", next_revision, author, date, str(cell_value)))
            next_revision += 1
    return table


def insert_after(target: etree._Element, new_node: etree._Element) -> None:
    parent = target.getparent()
    if parent is None:
        raise ValueError("Target node has no parent")
    parent.insert(parent.index(target) + 1, new_node)


def add_comment(
    comments_root: etree._Element,
    comment_id: int,
    author: str,
    initials: str,
    date: str,
    text: str,
) -> etree._Element:
    comment = etree.SubElement(comments_root, qn("w", "comment"))
    comment.set(qn("w", "id"), str(comment_id))
    comment.set(qn("w", "author"), author)
    if initials:
        comment.set(qn("w", "initials"), initials)
    comment.set(qn("w", "date"), date)

    paragraph = etree.SubElement(comment, qn("w", "p"))
    run = etree.SubElement(paragraph, qn("w", "r"))
    run.append(make_text_element("t", text))
    return comment


def anchor_comment_to_paragraph(paragraph: etree._Element, comment_id: int) -> None:
    start = etree.Element(qn("w", "commentRangeStart"))
    start.set(qn("w", "id"), str(comment_id))
    end = etree.Element(qn("w", "commentRangeEnd"))
    end.set(qn("w", "id"), str(comment_id))

    ref_run = etree.Element(qn("w", "r"))
    ref_pr = etree.SubElement(ref_run, qn("w", "rPr"))
    ref_style = etree.SubElement(ref_pr, qn("w", "rStyle"))
    ref_style.set(qn("w", "val"), "CommentReference")
    ref = etree.SubElement(ref_run, qn("w", "commentReference"))
    ref.set(qn("w", "id"), str(comment_id))

    insert_index = 1 if paragraph.find("./w:pPr", namespaces=NS) is not None else 0
    paragraph.insert(insert_index, start)
    paragraph.append(end)
    paragraph.append(ref_run)


def ensure_comments_relationship(rels_root: etree._Element) -> None:
    for rel in rels_root.xpath("./pr:Relationship", namespaces=NS):
        if (
            rel.get("Type") == COMMENTS_REL_TYPE
            and rel.get("Target", "").lstrip("/") == "comments.xml"
        ):
            return

    used_ids = {
        rel.get("Id", "")
        for rel in rels_root.xpath("./pr:Relationship", namespaces=NS)
        if rel.get("Id")
    }
    next_num = 1
    while f"rId{next_num}" in used_ids:
        next_num += 1

    rel = etree.SubElement(rels_root, f"{{{REL_NS}}}Relationship")
    rel.set("Id", f"rId{next_num}")
    rel.set("Type", COMMENTS_REL_TYPE)
    rel.set("Target", "comments.xml")


def ensure_content_type_override(
    content_types_root: etree._Element,
    part_name: str,
    content_type: str,
) -> None:
    for override in content_types_root.xpath("./ct:Override", namespaces=NS):
        if override.get("PartName") == part_name:
            override.set("ContentType", content_type)
            return

    override = etree.SubElement(content_types_root, f"{{{NS['ct']}}}Override")
    override.set("PartName", part_name)
    override.set("ContentType", content_type)


def create_rels_root() -> etree._Element:
    return etree.Element(f"{{{REL_NS}}}Relationships", nsmap={None: REL_NS})


def normalize_rows(rows: Any) -> list[list[Any]]:
    if not isinstance(rows, list):
        raise ValueError("Table operation rows must be a list")
    normalized: list[list[Any]] = []
    for row in rows:
        if isinstance(row, dict):
            normalized.append(list(row.values()))
        elif isinstance(row, list):
            normalized.append(row)
        else:
            normalized.append([row])
    return normalized


GENERIC_REPLY_PATTERNS = [
    re.compile(r"^\s*addressed\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*done\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*resolved\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"addressed in (the )?(red|revision|draft)", re.IGNORECASE),
]

# Rationales are prose, so only whole-string reply stubs apply. The final
# generic-reply pattern intentionally searches within short reviewer replies;
# reusing it here would reject useful explanations that merely contain the
# phrase "addressed in the revision".
RATIONALE_STOCK_PHRASE_PATTERNS = GENERIC_REPLY_PATTERNS[:3]


def is_generic_reply(text: str) -> bool:
    return any(pattern.search(text or "") for pattern in GENERIC_REPLY_PATTERNS)


# --- Skill identity -------------------------------------------------------
#
# Every other control in this module lives inside the skill payload, so it can
# only protect a session that already loaded the correct copy. The identity
# banner is emitted by whatever code is actually running, which makes a stale
# hand-installed copy visible in the failure case itself.


def skill_home() -> str:
    """Absolute directory of the scripts actually executing."""
    return str(Path(__file__).resolve().parent)


def skill_identity() -> str:
    """Name, version, and load path of the running copy.

    The path is the part that matters. Two copies can declare the same version
    while only one of them is the repository copy, so a banner without a
    location cannot distinguish the exact failure this is here to expose.
    """
    return f"{SKILL_NAME} v{SKILL_VERSION} ({skill_home()})"


def emit_skill_identity(stream: Any = None) -> str:
    """Write the running skill identity to stderr and return the banner text."""
    banner = f"[skill] {skill_identity()}"
    target = sys.stderr if stream is None else stream
    print(banner, file=target)
    return banner


# --- Change provenance ----------------------------------------------------


def is_valid_provenance_source(source: str) -> bool:
    return bool(_PROVENANCE_SOURCE_RE.match(str(source or "").strip()))


def provenance_source_kind(source: str) -> str:
    """Return the grammar kind for a source token, or 'unknown'."""
    value = str(source or "").strip()
    if not is_valid_provenance_source(value):
        return "unknown"
    for kind in PROVENANCE_SOURCE_KINDS:
        if kind.endswith(":") and value.startswith(kind):
            return kind.rstrip(":")
    return value


def is_generic_rationale(text: str) -> bool:
    """Return whether a rationale fails a mechanical explanation check."""
    value = str(text or "").strip()
    if _is_stock_rationale(value):
        return True
    return len(value.split()) < MIN_RATIONALE_WORDS


def _is_stock_rationale(value: str) -> bool:
    return any(pattern.search(value) for pattern in RATIONALE_STOCK_PHRASE_PATTERNS)


def enabled_operations(plan: dict) -> list[dict]:
    return [op for _, op in _enabled_operations_indexed(plan)]


def _enabled_operations_indexed(plan: dict) -> list[tuple[int, dict]]:
    """Enabled operations paired with their index in the plan as authored.

    Error messages quote this index, so it has to survive disabled entries. A
    position counted only across enabled operations points an operator at the
    wrong line the moment anything in the plan is switched off.
    """
    return [
        (index, op)
        for index, op in enumerate(_plan_list(plan, "operations"))
        if isinstance(op, dict) and op.get("enabled") is not False
    ]


def _plan_list(plan: dict, key: str) -> list:
    if not isinstance(plan, dict):
        return []
    value = plan.get(key, [])
    return value if isinstance(value, list) else []


def declared_themes(plan: dict) -> dict[str, dict]:
    themes: dict[str, dict] = {}
    for theme in _plan_list(plan, "themes"):
        if not isinstance(theme, dict):
            continue
        theme_id = str(theme.get("id", "")).strip()
        if theme_id:
            themes[theme_id] = theme
    return themes


def _validate_provenance_fields(label: str, entry: dict, errors: list[str]) -> None:
    rationale = str(entry.get("rationale", "")).strip()
    if not rationale:
        errors.append(f"{label} is missing a rationale")
    elif _is_stock_rationale(rationale):
        errors.append(
            f"{label} rationale is a stock phrase ({rationale!r}) and explains nothing"
        )
    elif len(rationale.split()) < MIN_RATIONALE_WORDS:
        errors.append(
            f"{label} rationale is {len(rationale.split())} words; at least "
            f"{MIN_RATIONALE_WORDS} are needed to say what changed and why"
        )

    source = str(entry.get("source", "")).strip()
    if not source:
        errors.append(f"{label} is missing a provenance source")
    elif not is_valid_provenance_source(source):
        errors.append(
            f"{label} has an unrecognised provenance source {source!r}; expected one of "
            + ", ".join(PROVENANCE_SOURCE_KINDS)
        )


def validate_merge_plan(
    plan: dict,
    *,
    paragraph_count: int | None = None,
    allow_author_override: bool = False,
    require_provenance: bool = True,
) -> list[str]:
    """Return every contract violation in a merge plan.

    All errors are collected rather than raised on the first failure so an
    operator fixes the plan once instead of iterating through them one at a
    time. Malformed structure is reported the same way, because a validator
    that raises on bad input hands back a stack trace where the caller expected
    a list of problems.
    """
    errors: list[str] = []

    if not isinstance(plan, dict):
        return ["Merge plan must be a JSON object"]

    settings = plan.get("settings", {})
    if not isinstance(settings, dict):
        errors.append("settings must be an object")
        settings = {}
    author = str(settings.get("author", "")).strip()
    if author and author != DEFAULT_RESPONSE_AUTHOR and not allow_author_override:
        errors.append(
            f"settings.author is {author!r} but this skill writes responses as "
            f"{DEFAULT_RESPONSE_AUTHOR!r}. A merge plan carries the author into "
            "the deliverable, so a stale plan silently reintroduces the wrong "
            "identity. Correct the plan, or pass the documented author override."
        )

    errors.extend(_structural_errors(plan))

    themes = declared_themes(plan)
    for theme_id, theme in themes.items():
        _validate_provenance_fields(f"Theme {theme_id!r}", theme, errors)
        anchor = theme.get("anchor_paragraph_index")
        if not isinstance(anchor, int) or isinstance(anchor, bool) or anchor < 0:
            errors.append(
                f"Theme {theme_id!r} needs an integer anchor_paragraph_index so its "
                "single explanation comment has somewhere to live"
            )
        elif paragraph_count is not None and anchor >= paragraph_count:
            errors.append(
                f"Theme {theme_id!r} anchor_paragraph_index {anchor} is out of range "
                f"(0-{paragraph_count - 1})"
            )

    referenced_themes: set[str] = set()
    unthemed_rationales: dict[str, list[int]] = {}
    for index, op in _enabled_operations_indexed(plan):
        label = f"Operation {index} ({op.get('type', 'unknown')})"
        theme_id = str(op.get("theme", "")).strip()
        if theme_id:
            referenced_themes.add(theme_id)
            if theme_id not in themes:
                errors.append(
                    f"{label} references theme {theme_id!r}, which is not declared in themes[]"
                )
        if require_provenance:
            _validate_provenance_fields(label, op, errors)
            if not theme_id:
                rationale_key = str(op.get("rationale", "")).strip().casefold()
                if rationale_key:
                    unthemed_rationales.setdefault(rationale_key, []).append(index)

    for indexes in unthemed_rationales.values():
        if len(indexes) > 1:
            errors.append(
                "Operations "
                + ", ".join(str(index) for index in indexes)
                + " share an identical rationale. A decision applied more than once "
                "is a theme; declare it in themes[] so the reviewer sees one "
                f"explanation instead of {len(indexes)}."
            )

    for theme_id in sorted(set(themes) - referenced_themes):
        errors.append(
            f"Theme {theme_id!r} is declared but no enabled operation references it"
        )

    return errors


def _structural_errors(plan: dict) -> list[str]:
    """Report shape problems that would otherwise be silently skipped.

    The collection helpers drop anything of the wrong type so callers never
    crash mid-apply. That safety would hide an authoring mistake unless the
    validator names it, so the two behaviours are kept deliberately separate.
    """
    errors: list[str] = []

    for key in ("operations", "themes"):
        value = plan.get(key, [])
        if not isinstance(value, list):
            errors.append(f"{key} must be an array")
            continue
        for index, entry in enumerate(value):
            if not isinstance(entry, dict):
                errors.append(f"{key}[{index}] must be an object")

    seen: set[str] = set()
    for index, theme in enumerate(_plan_list(plan, "themes")):
        if not isinstance(theme, dict):
            continue
        theme_id = str(theme.get("id", "")).strip()
        if not theme_id:
            errors.append(f"themes[{index}] is missing an id")
        elif theme_id in seen:
            errors.append(
                f"Theme {theme_id!r} is declared more than once. A duplicate id "
                "replaces the earlier declaration, so every operation in that "
                "theme would be explained by the wrong rationale."
            )
        else:
            seen.add(theme_id)

    return errors


def summarize_provenance(plan: dict) -> dict[str, int]:
    """Count enabled operations by provenance kind.

    Reported after every apply so a class of unexplained changes is visible
    rather than something a reviewer has to notice by absence.
    """
    counts: dict[str, int] = {}
    for op in enabled_operations(plan):
        kind = provenance_source_kind(str(op.get("source", "")))
        counts[kind] = counts.get(kind, 0) + 1
    return counts
