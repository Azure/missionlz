#!/usr/bin/env python3
"""Template-preserving generation and validation for AIS SOW DOCX files."""

from __future__ import annotations

from copy import deepcopy
from datetime import date
import hashlib
import json
import os
from pathlib import Path
import posixpath
import re
import tempfile
from typing import Any, Iterable
from urllib.parse import unquote
import zipfile

from lxml import etree


W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
XML = "http://www.w3.org/XML/1998/namespace"
CP = "http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"
VT = "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
PKG_REL = "http://schemas.openxmlformats.org/package/2006/relationships"
CONTENT_TYPES = "http://schemas.openxmlformats.org/package/2006/content-types"
CUSTOM_REL_TYPE = (
    "http://schemas.openxmlformats.org/officeDocument/2006/relationships/"
    "custom-properties"
)
CUSTOM_CONTENT_TYPE = (
    "application/vnd.openxmlformats-officedocument.custom-properties+xml"
)
NS = {"w": W, "cp": CP, "vt": VT}
COMMERCIAL_PLACEHOLDER = "TBD - Commercial Review"
INSTRUCTION_STYLE = "SOWInstructions"
ALLOWED_CHANGED_PARTS = {
    "[Content_Types].xml",
    "_rels/.rels",
    "docProps/custom.xml",
    "word/document.xml",
    "word/settings.xml",
}

CLIENT_LANGUAGE_RULES = (
    (
        "INTERNAL_WORKFLOW",
        re.compile(
            r"(?<![\w])/(?:ais|spec)\.[a-z][\w.-]*|"
            r"(?:^|[\\/])(?:specs|\.project-context)(?=[\\/])|"
            r"\bsource[_ -]?id\b|\b(?:QA|QC)\s*[-:]|\bgreen[- ]sheet\b|"
            r"\bT-shirt size\b|\b(?:pull request|git branch)\b|"
            r"\b(?:agent|model) instructions?\b",
            re.IGNORECASE,
        ),
    ),
    (
        "DRAFTING_MARKER",
        re.compile(
            r"\b(?:TODO|FIXME|TKTK|DRAFTING NOTE|INTERNAL ONLY|"
            r"FOR INTERNAL USE)\b|\[\s*insert\b",
            re.IGNORECASE,
        ),
    ),
    (
        "PROMOTIONAL_CLAIM",
        re.compile(
            r"\b(?:best[- ]in[- ]class|world[- ]class|game[- ]changing|"
            r"revolutionary|cutting[- ]edge)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "UNSUPPORTED_GUARANTEE",
        re.compile(
            r"\bguarantee(?:d|s)?\b.{0,64}\b(?:success(?:ful)?|results?|"
            r"outcomes?|compliance|availability|performance|savings)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "OPEN_ENDED_COMMITMENT",
        re.compile(
            r"\bunlimited\b|\bwhatever it takes\b|\bsupport as needed\b|"
            r"\band (?:any|all) other (?:work|tasks|services)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "BLAME_LANGUAGE",
        re.compile(
            r"\bclient(?:'s|’s)?\s+(?:failure|fault|delay|inability|refusal)\b|"
            r"\bclient[- ]caused\b|\bdue to the client\b",
            re.IGNORECASE,
        ),
    ),
    (
        "CONTRACTION",
        re.compile(
            r"\b(?:can't|can’t|won't|won’t|don't|don’t|doesn't|doesn’t|"
            r"isn't|isn’t|aren't|aren’t|we'll|we’ll|we're|we’re|we've|we’ve|"
            r"you'll|you’ll|you're|you’re|you've|you’ve|it's|it’s)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "VAGUE_CATCH_ALL",
        re.compile(r"\betc\.(?=\s|$)|\band so on\b", re.IGNORECASE),
    ),
)


def _is_allowed_changed_part(name: str) -> bool:
    return name in ALLOWED_CHANGED_PARTS or bool(
        re.fullmatch(r"word/(?:header\d+|footer\d+)\.xml", name)
    )


class SowDocxError(RuntimeError):
    """Raised when generation cannot safely produce a SOW."""


def _qn(namespace: str, local: str) -> str:
    return f"{{{namespace}}}{local}"


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_manifest(path: Path | str) -> dict[str, Any]:
    manifest_path = Path(path)
    try:
        return json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SowDocxError(f"Unable to load template manifest: {exc}") from exc


def _asset_path(skill_root: Path, relative_asset: str) -> Path:
    root = skill_root.resolve()
    candidate = (root / relative_asset).resolve()
    if root != candidate and root not in candidate.parents:
        raise SowDocxError(f"Template asset escapes the skill root: {relative_asset}")
    return candidate


def _read_package(path: Path) -> tuple[dict[str, bytes], list[zipfile.ZipInfo]]:
    try:
        with zipfile.ZipFile(path, "r") as archive:
            if archive.testzip() is not None:
                raise SowDocxError(f"Corrupt DOCX ZIP member in {path}")
            infos = archive.infolist()
            parts = {info.filename: archive.read(info.filename) for info in infos}
    except (OSError, zipfile.BadZipFile) as exc:
        raise SowDocxError(f"Unable to read DOCX package {path}: {exc}") from exc
    return parts, infos


def _parse_xml(value: bytes, part_name: str) -> etree._Element:
    try:
        return etree.fromstring(value)
    except etree.XMLSyntaxError as exc:
        raise SowDocxError(f"Invalid XML in {part_name}: {exc}") from exc


def _xml_bytes(root: etree._Element) -> bytes:
    return etree.tostring(
        root, encoding="UTF-8", xml_declaration=True, standalone=True
    )


def _paragraph_style(paragraph: etree._Element) -> str:
    style = paragraph.find("./w:pPr/w:pStyle", namespaces=NS)
    return style.get(_qn(W, "val"), "") if style is not None else ""


def _text(node: etree._Element) -> str:
    return "".join(node.xpath(".//w:t/text()", namespaces=NS)).strip()


def _find_heading_child(
    body: etree._Element, heading: str, *, style: str = "Heading1"
) -> int:
    wanted = heading.strip().casefold()
    for index, child in enumerate(body):
        if child.tag != _qn(W, "p"):
            continue
        if _paragraph_style(child) != style:
            continue
        if _text(child).strip().casefold() == wanted:
            return index
    raise SowDocxError(f"Template heading not found: {heading}")


def _required_parts_for(manifest: dict[str, Any], parts: dict[str, bytes]) -> None:
    missing = sorted(set(manifest["required_package_parts"]) - set(parts))
    if missing:
        raise SowDocxError(f"Template is missing required package parts: {missing}")


def validate_manifest(
    manifest: dict[str, Any], skill_root: Path | str
) -> dict[str, Any]:
    root = Path(skill_root)
    if manifest.get("schema_version") != 1:
        raise SowDocxError("Unsupported template manifest schema version")
    if manifest.get("commercial_placeholder") != COMMERCIAL_PLACEHOLDER:
        raise SowDocxError("Manifest commercial placeholder policy is inconsistent")
    profiles = manifest.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        raise SowDocxError("Template manifest must define profiles")

    seen_profiles: set[str] = set()
    seen_selectors: set[str] = set()
    for profile in profiles:
        profile_id = profile.get("id")
        if not profile_id or profile_id in seen_profiles:
            raise SowDocxError(f"Template manifest contains duplicate profile: {profile_id}")
        seen_profiles.add(profile_id)
        selector_key = json.dumps(profile.get("selectors"), sort_keys=True)
        if selector_key in seen_selectors:
            raise SowDocxError(f"Template manifest contains duplicate selectors: {profile_id}")
        seen_selectors.add(selector_key)

        versions = profile.get("versions")
        if not isinstance(versions, list) or not versions:
            raise SowDocxError(f"Profile {profile_id} has no template versions")
        version_ids = [item.get("version") for item in versions]
        if len(set(version_ids)) != len(version_ids):
            raise SowDocxError(f"Profile {profile_id} contains duplicate versions")
        if profile.get("active_version") not in version_ids:
            raise SowDocxError(f"Profile {profile_id} active version is unavailable")

        for version in versions:
            if not re.fullmatch(r"\d{4}-\d{2}", str(version.get("version", ""))):
                raise SowDocxError(f"Profile {profile_id} has an invalid version")
            asset = _asset_path(root, str(version.get("asset", "")))
            if not asset.is_file():
                raise SowDocxError(f"Template asset does not exist: {asset}")
            actual_digest = sha256_file(asset)
            if actual_digest != version.get("sha256"):
                raise SowDocxError(
                    f"Template digest mismatch for {profile_id} {version['version']}"
                )
            parts, _ = _read_package(asset)
            _required_parts_for(manifest, parts)
            document = _parse_xml(parts["word/document.xml"], "word/document.xml")
            body = document.find("w:body", namespaces=NS)
            if body is None:
                raise SowDocxError(f"Template {profile_id} has no document body")
            _find_heading_child(body, "Introduction")
            _find_heading_child(body, version["fixed_boundary_heading"])
    return manifest


def resolve_template(
    manifest: dict[str, Any],
    classification: dict[str, Any],
    requested_version: str | None,
    skill_root: Path | str,
) -> tuple[dict[str, Any], dict[str, Any]]:
    validate_manifest(manifest, skill_root)
    matches = [
        profile
        for profile in manifest["profiles"]
        if profile.get("selectors") == classification
    ]
    if len(matches) != 1:
        raise SowDocxError(
            "SOW classification must match exactly one approved template profile"
        )
    profile = matches[0]
    selected_version = requested_version or profile["active_version"]
    versions = [
        item for item in profile["versions"] if item["version"] == selected_version
    ]
    if len(versions) != 1:
        raise SowDocxError(
            f"Template version {selected_version!r} is unavailable for {profile['id']}"
        )
    return profile, versions[0]


def _require_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise SowDocxError(f"Required SOW value is missing: {label}")
    return value.strip()


def _validate_date(value: Any, label: str) -> str:
    text = _require_string(value, label)
    try:
        date.fromisoformat(text)
    except ValueError as exc:
        raise SowDocxError(f"{label} must use ISO date format YYYY-MM-DD") from exc
    return text


def _validate_traced_items(
    value: Any, label: str, *, deliverables: bool = False
) -> list[dict[str, Any]]:
    if not isinstance(value, list) or not value:
        raise SowDocxError(f"{label} must contain at least one item")
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            raise SowDocxError(f"{label}[{index}] must be an object")
        for key in ("source_id", "title", "description"):
            _require_string(item.get(key), f"{label}[{index}].{key}")
        if not re.fullmatch(r"[A-Z][A-Z0-9-]{1,31}", item["source_id"]):
            raise SowDocxError(f"Invalid source_id: {item['source_id']}")
        if deliverables:
            criteria = item.get("acceptance_criteria")
            if not isinstance(criteria, list) or not criteria:
                raise SowDocxError(
                    f"{label}[{index}].acceptance_criteria must not be empty"
                )
            for criterion in criteria:
                _require_string(criterion, f"{label}[{index}].acceptance_criteria")
    return value


def _contains_numeric_commercial(value: Any) -> bool:
    if isinstance(value, bool) or value is None:
        return False
    if isinstance(value, (int, float)):
        return True
    if isinstance(value, str):
        return bool(re.search(r"\d|[$€£¥]|\bUSD\b|\bper\s+hour\b", value, re.I))
    if isinstance(value, dict):
        return any(_contains_numeric_commercial(item) for item in value.values())
    if isinstance(value, list):
        return any(_contains_numeric_commercial(item) for item in value)
    return False


def _indexed_strings(value: Any, path: str) -> Iterable[tuple[str, str]]:
    if not isinstance(value, list):
        return
    for index, item in enumerate(value):
        if isinstance(item, str):
            yield f"{path}[{index}]", item


def _traced_item_strings(
    value: Any, path: str, *, include_acceptance: bool = False
) -> Iterable[tuple[str, str]]:
    if not isinstance(value, list):
        return
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            continue
        for key in ("title", "description"):
            candidate = item.get(key)
            if isinstance(candidate, str):
                yield f"{path}[{index}].{key}", candidate
        if include_acceptance:
            yield from _indexed_strings(
                item.get("acceptance_criteria"),
                f"{path}[{index}].acceptance_criteria",
            )


def client_visible_fields(data: dict[str, Any]) -> Iterable[tuple[str, str]]:
    """Yield authored strings that can appear in the generated client DOCX."""

    document = data.get("document")
    if isinstance(document, dict):
        for key in ("title", "project_name", "place_of_performance"):
            value = document.get(key)
            if isinstance(value, str):
                yield f"document.{key}", value

    yield from _indexed_strings(data.get("background"), "background")
    yield from _indexed_strings(data.get("objectives"), "objectives")

    scope = data.get("scope")
    if isinstance(scope, dict):
        yield from _traced_item_strings(scope.get("in_scope"), "scope.in_scope")
        yield from _traced_item_strings(
            scope.get("out_of_scope"), "scope.out_of_scope"
        )

    yield from _traced_item_strings(
        data.get("deliverables"), "deliverables", include_acceptance=True
    )
    yield from _traced_item_strings(data.get("milestones"), "milestones")

    responsibilities = data.get("responsibilities")
    if isinstance(responsibilities, dict):
        yield from _traced_item_strings(
            responsibilities.get("ais"), "responsibilities.ais"
        )
        yield from _traced_item_strings(
            responsibilities.get("client"), "responsibilities.client"
        )

    yield from _traced_item_strings(data.get("assumptions"), "assumptions")
    commercial = data.get("commercial")
    if isinstance(commercial, dict):
        yield from _indexed_strings(commercial.get("notes"), "commercial.notes")


def review_client_language(data: dict[str, Any]) -> list[dict[str, str]]:
    """Return privacy-minimized high-confidence client-language findings."""

    issues: list[dict[str, str]] = []
    for path, value in client_visible_fields(data):
        for code, pattern in CLIENT_LANGUAGE_RULES:
            match = pattern.search(value)
            if match is None:
                continue
            token = re.sub(r"\s+", " ", match.group(0)).strip()
            issues.append(
                {
                    "code": code,
                    "path": path,
                    "token": token[:64],
                }
            )
    return issues


def _raise_client_language_issues(issues: list[dict[str, str]]) -> None:
    if not issues:
        return
    shown = issues[:5]
    details = "; ".join(
        f"{issue['code']} at {issue['path']} "
        f"(token={issue['token']!r})"
        for issue in shown
    )
    remaining = len(issues) - len(shown)
    if remaining:
        details += f"; plus {remaining} additional issue(s)"
    raise SowDocxError(
        "Client-visible SOW language failed policy screening: " + details
    )


def validate_input(data: dict[str, Any], manifest: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(data, dict):
        raise SowDocxError("SOW input must be a JSON object")
    required_top = {
        "classification",
        "document",
        "background",
        "objectives",
        "scope",
        "deliverables",
        "milestones",
        "responsibilities",
        "assumptions",
        "commercial",
    }
    missing = sorted(required_top - set(data))
    if missing:
        raise SowDocxError(f"SOW input is missing required fields: {missing}")

    classification = data.get("classification")
    classification_keys = {
        "agreement_family",
        "contract_form",
        "delivery_organization",
        "delivery_pattern",
        "document_type",
    }
    if not isinstance(classification, dict) or set(classification) != classification_keys:
        raise SowDocxError("SOW classification must contain exactly five selection axes")
    if classification.get("document_type") != "original-sow":
        raise SowDocxError("Only original-sow document types are supported")
    for key in classification_keys:
        _require_string(classification.get(key), f"classification.{key}")

    document = data.get("document")
    if not isinstance(document, dict):
        raise SowDocxError("document must be an object")
    for key in (
        "title",
        "client_name",
        "project_name",
        "opportunity_id",
        "place_of_performance",
    ):
        _require_string(document.get(key), f"document.{key}")
    for key in ("effective_date", "expiration_date", "msa_date"):
        _validate_date(document.get(key), f"document.{key}")
    contacts = document.get("contacts")
    if not isinstance(contacts, list) or len(contacts) < 2:
        raise SowDocxError("document.contacts must contain client and AIS contacts")
    for index, contact in enumerate(contacts):
        if not isinstance(contact, dict):
            raise SowDocxError(f"document.contacts[{index}] must be an object")
        for key in (
            "organization",
            "name",
            "role",
            "mailing_address",
            "email",
            "phone",
        ):
            _require_string(contact.get(key), f"document.contacts[{index}].{key}")

    for label in ("background", "objectives"):
        values = data.get(label)
        if not isinstance(values, list) or not values:
            raise SowDocxError(f"{label} must contain at least one item")
        for value in values:
            _require_string(value, label)

    scope = data.get("scope")
    if not isinstance(scope, dict):
        raise SowDocxError("scope must be an object")
    traced_groups = [
        _validate_traced_items(scope.get("in_scope"), "scope.in_scope"),
        _validate_traced_items(scope.get("out_of_scope"), "scope.out_of_scope"),
        _validate_traced_items(data.get("deliverables"), "deliverables", deliverables=True),
        _validate_traced_items(data.get("milestones"), "milestones"),
        _validate_traced_items(data.get("assumptions"), "assumptions"),
    ]
    responsibilities = data.get("responsibilities")
    if not isinstance(responsibilities, dict):
        raise SowDocxError("responsibilities must be an object")
    traced_groups.extend(
        [
            _validate_traced_items(responsibilities.get("ais"), "responsibilities.ais"),
            _validate_traced_items(
                responsibilities.get("client"), "responsibilities.client"
            ),
        ]
    )
    source_ids = [item["source_id"] for group in traced_groups for item in group]
    if len(source_ids) != len(set(source_ids)):
        raise SowDocxError("SOW source_id values must be unique")

    commercial = data.get("commercial")
    if not isinstance(commercial, dict) or set(commercial) - {"placeholder", "notes"}:
        raise SowDocxError("commercial contains unsupported fields")
    if commercial.get("placeholder") != manifest.get("commercial_placeholder"):
        raise SowDocxError("commercial placeholder must use the controlled value")
    if _contains_numeric_commercial(commercial):
        raise SowDocxError("numeric commercial values are not permitted")
    notes = commercial.get("notes", [])
    if not isinstance(notes, list):
        raise SowDocxError("commercial.notes must be an array")
    for note in notes:
        _require_string(note, "commercial.notes")
    _raise_client_language_issues(review_client_language(data))
    return data


def _long_date(value: str) -> str:
    parsed = date.fromisoformat(value)
    return f"{parsed.strftime('%B')} {parsed.day}, {parsed.year}"


def _client_contact(data: dict[str, Any]) -> dict[str, Any]:
    client_name = data["document"]["client_name"].casefold()
    for contact in data["document"]["contacts"]:
        if contact["organization"].casefold() == client_name:
            return contact
    return data["document"]["contacts"][0]


def _replace_sdt_values(
    document: etree._Element, values: dict[str, str]
) -> set[str]:
    replaced: set[str] = set()
    for sdt in document.xpath("//w:sdt", namespaces=NS):
        tag = sdt.find("./w:sdtPr/w:tag", namespaces=NS)
        if tag is None:
            continue
        name = tag.get(_qn(W, "val"), "")
        if name not in values:
            continue
        properties = sdt.find("./w:sdtPr", namespaces=NS)
        if properties is not None:
            for editable_state in (
                properties.find("w:dataBinding", namespaces=NS),
                properties.find("w:showingPlcHdr", namespaces=NS),
            ):
                if editable_state is not None:
                    properties.remove(editable_state)
        text_nodes = sdt.xpath("./w:sdtContent//w:t", namespaces=NS)
        if not text_nodes:
            raise SowDocxError(f"Editable content control has no text node: {name}")
        text_nodes[0].text = values[name]
        text_nodes[0].set(_qn(XML, "space"), "preserve")
        for node in text_nodes[1:]:
            node.text = ""
        replaced.add(name)
    return replaced


def _replace_exact_text_nodes(
    root: etree._Element, replacements: dict[str, str]
) -> None:
    for old, new in replacements.items():
        for paragraph in root.xpath("//w:p", namespaces=NS):
            text_nodes = paragraph.xpath(".//w:t", namespaces=NS)
            while text_nodes:
                values = [node.text or "" for node in text_nodes]
                combined = "".join(values)
                match_start = combined.find(old)
                if match_start < 0:
                    break
                match_end = match_start + len(old)
                offsets: list[tuple[int, int]] = []
                cursor = 0
                for value in values:
                    offsets.append((cursor, cursor + len(value)))
                    cursor += len(value)
                start_index = next(
                    index
                    for index, (_, end) in enumerate(offsets)
                    if match_start < end
                )
                end_index = next(
                    index
                    for index, (_, end) in enumerate(offsets)
                    if match_end <= end
                )
                start_offset = match_start - offsets[start_index][0]
                end_offset = match_end - offsets[end_index][0]
                prefix = values[start_index][:start_offset]
                suffix = values[end_index][end_offset:]
                if start_index == end_index:
                    text_nodes[start_index].text = prefix + new + suffix
                else:
                    text_nodes[start_index].text = prefix + new
                    for node in text_nodes[start_index + 1 : end_index]:
                        node.text = ""
                    text_nodes[end_index].text = suffix


def _remove_instruction_paragraphs(root: etree._Element) -> int:
    removed = 0
    for paragraph in list(root.xpath("//w:p", namespaces=NS)):
        if _paragraph_style(paragraph) == INSTRUCTION_STYLE:
            parent = paragraph.getparent()
            if parent is not None:
                parent.remove(paragraph)
                removed += 1
    return removed


def _remove_authoring_highlights(root: etree._Element) -> int:
    removed = 0
    for highlight in list(root.xpath("//w:highlight", namespaces=NS)):
        parent = highlight.getparent()
        if parent is not None:
            parent.remove(highlight)
            removed += 1
    return removed


def _bookmark_name(source_id: str) -> str:
    return "AIS_" + re.sub(r"[^A-Za-z0-9_]", "_", source_id)


def _paragraph(
    text: str,
    style: str | None = None,
    *,
    source_id: str | None = None,
    bookmark_id: int | None = None,
    bold: bool = False,
) -> etree._Element:
    paragraph = etree.Element(_qn(W, "p"))
    if style:
        properties = etree.SubElement(paragraph, _qn(W, "pPr"))
        style_node = etree.SubElement(properties, _qn(W, "pStyle"))
        style_node.set(_qn(W, "val"), style)
    if source_id is not None:
        start = etree.SubElement(paragraph, _qn(W, "bookmarkStart"))
        start.set(_qn(W, "id"), str(bookmark_id))
        start.set(_qn(W, "name"), _bookmark_name(source_id))
    run = etree.SubElement(paragraph, _qn(W, "r"))
    if bold:
        run_properties = etree.SubElement(run, _qn(W, "rPr"))
        etree.SubElement(run_properties, _qn(W, "b"))
    text_node = etree.SubElement(run, _qn(W, "t"))
    text_node.set(_qn(XML, "space"), "preserve")
    text_node.text = text
    if source_id is not None:
        end = etree.SubElement(paragraph, _qn(W, "bookmarkEnd"))
        end.set(_qn(W, "id"), str(bookmark_id))
    return paragraph


def _table(
    headers: list[str], rows: list[list[tuple[str, str | None]]], bookmark_start: int
) -> tuple[etree._Element, int]:
    table = etree.Element(_qn(W, "tbl"))
    properties = etree.SubElement(table, _qn(W, "tblPr"))
    style = etree.SubElement(properties, _qn(W, "tblStyle"))
    style.set(_qn(W, "val"), "GridTable4-Accent1")
    width = etree.SubElement(properties, _qn(W, "tblW"))
    width.set(_qn(W, "w"), "0")
    width.set(_qn(W, "type"), "auto")

    header_row = etree.SubElement(table, _qn(W, "tr"))
    row_properties = etree.SubElement(header_row, _qn(W, "trPr"))
    etree.SubElement(row_properties, _qn(W, "tblHeader"))
    for header in headers:
        cell = etree.SubElement(header_row, _qn(W, "tc"))
        header_paragraph = _paragraph(header, bold=True)
        run_properties = header_paragraph.find("./w:r/w:rPr", namespaces=NS)
        if run_properties is not None:
            color = etree.SubElement(run_properties, _qn(W, "color"))
            color.set(_qn(W, "val"), "FFFFFF")
        cell.append(header_paragraph)

    bookmark_id = bookmark_start
    for row in rows:
        row_node = etree.SubElement(table, _qn(W, "tr"))
        row_properties = etree.SubElement(row_node, _qn(W, "trPr"))
        etree.SubElement(row_properties, _qn(W, "cantSplit"))
        for value, source_id in row:
            cell = etree.SubElement(row_node, _qn(W, "tc"))
            if source_id:
                cell.append(
                    _paragraph(
                        value,
                        source_id=source_id,
                        bookmark_id=bookmark_id,
                    )
                )
                bookmark_id += 1
            else:
                cell.append(_paragraph(value))
    return table, bookmark_id


def _profile_delivery_text(profile_id: str) -> str:
    descriptions = {
        "ais-client-ffp": (
            "AIS will execute the defined scope through deliverable-oriented "
            "phases and milestone governance."
        ),
        "msc-ffp": (
            "The AIS Microsoft Solution Center delivery team will execute the "
            "defined scope through focused design and implementation sprints."
        ),
        "ais-client-tm": (
            "AIS will provide client-directed managed capacity, with work "
            "prioritized through the agreed backlog and governance cadence."
        ),
        "staff-augmentation-retainer": (
            "AIS will provide client-directed staff augmentation support within "
            "the agreed service boundaries and support governance process."
        ),
        "ecif-generic": (
            "AIS will deliver the defined engagement and coordinate the "
            "Microsoft program activities identified in this SOW."
        ),
    }
    return descriptions[profile_id]


def _commercial_table(
    profile_id: str, data: dict[str, Any], bookmark_start: int
) -> tuple[etree._Element, int]:
    placeholder = COMMERCIAL_PLACEHOLDER
    if profile_id in {"ais-client-ffp", "msc-ffp"}:
        headers = ["Milestone", "Commercial Value"]
        rows = [
            [(item["title"], None), (placeholder, None)]
            for item in data["milestones"]
        ]
    elif profile_id == "ecif-generic":
        headers = ["Milestone", "Hours", "Amount"]
        rows = [
            [(item["title"], None), (placeholder, None), (placeholder, None)]
            for item in data["milestones"]
        ]
    elif profile_id == "ais-client-tm":
        headers = ["Service Category", "Rate", "Estimated Investment"]
        rows = [[("Professional services capacity", None), (placeholder, None), (placeholder, None)]]
    else:
        headers = ["Service Category", "Retainer Fee", "Overage Rate", "Estimated Investment"]
        rows = [[("Staff augmentation support", None), (placeholder, None), (placeholder, None), (placeholder, None)]]
    return _table(headers, rows, bookmark_start)


def _build_narrative(
    data: dict[str, Any], profile_id: str
) -> list[etree._Element]:
    elements: list[etree._Element] = []
    bookmark_id = 5000

    elements.append(_paragraph("Background and Objectives", "Heading2"))
    for value in data["background"]:
        elements.append(_paragraph(value))
    for value in data["objectives"]:
        elements.append(_paragraph(f"• {value}"))

    elements.append(_paragraph("Scope of Engagement", "Heading1"))
    elements.append(_paragraph("In Scope", "Heading2"))
    for item in data["scope"]["in_scope"]:
        elements.append(
            _paragraph(
                f"• {item['title']}: {item['description']}",
                source_id=item["source_id"],
                bookmark_id=bookmark_id,
            )
        )
        bookmark_id += 1
    elements.append(_paragraph("Out of Scope", "Heading2"))
    for item in data["scope"]["out_of_scope"]:
        elements.append(
            _paragraph(
                f"• {item['title']}: {item['description']}",
                source_id=item["source_id"],
                bookmark_id=bookmark_id,
            )
        )
        bookmark_id += 1

    elements.append(_paragraph("Delivery Approach", "Heading1"))
    elements.append(_paragraph(_profile_delivery_text(profile_id)))
    elements.append(_paragraph("Milestones", "Heading2"))
    milestone_rows = [
        [
            (item["title"], item["source_id"]),
            (item["description"], None),
        ]
        for item in data["milestones"]
    ]
    table, bookmark_id = _table(
        ["Milestone", "Description"], milestone_rows, bookmark_id
    )
    elements.append(table)

    elements.append(_paragraph("Deliverables and Acceptance", "Heading1"))
    deliverable_rows = [
        [
            (item["title"], item["source_id"]),
            (item["description"], None),
            ("; ".join(item["acceptance_criteria"]), None),
        ]
        for item in data["deliverables"]
    ]
    table, bookmark_id = _table(
        ["Deliverable", "Description", "Acceptance Criteria"],
        deliverable_rows,
        bookmark_id,
    )
    elements.append(table)

    elements.append(_paragraph("Responsibilities and Assumptions", "Heading1"))
    for heading, items in (
        ("AIS Responsibilities", data["responsibilities"]["ais"]),
        ("Client Responsibilities", data["responsibilities"]["client"]),
        ("Material Assumptions", data["assumptions"]),
    ):
        elements.append(_paragraph(heading, "Heading2"))
        for item in items:
            elements.append(
                _paragraph(
                    f"• {item['title']}: {item['description']}",
                    source_id=item["source_id"],
                    bookmark_id=bookmark_id,
                )
            )
            bookmark_id += 1

    elements.append(_paragraph("Place of Performance", "Heading1"))
    elements.append(_paragraph(data["document"]["place_of_performance"]))
    elements.append(_paragraph("Performance Period", "Heading1"))
    elements.append(
        _paragraph(
            "AIS anticipates an overall period of performance from "
            f"{_long_date(data['document']['effective_date'])} through "
            f"{_long_date(data['document']['expiration_date'])}."
        )
    )

    elements.append(_paragraph("Commercial Review", "Heading1"))
    elements.append(
        _paragraph(
            "Commercial values will be documented in the final agreement."
        )
    )
    table, bookmark_id = _commercial_table(profile_id, data, bookmark_id)
    elements.append(table)
    for note in data["commercial"].get("notes", []):
        elements.append(_paragraph(f"• {note}"))
    return elements


def _refresh_static_toc(body: etree._Element) -> None:
    toc_heading = None
    for index, child in enumerate(body):
        if child.tag == _qn(W, "p") and _paragraph_style(child) == "TOCHeading":
            toc_heading = index
            break
    if toc_heading is None:
        raise SowDocxError("Template Table of Contents heading is missing")
    introduction = _find_heading_child(body, "Introduction")
    entries: list[tuple[int, str]] = []
    for child in list(body)[introduction:]:
        if child.tag != _qn(W, "p"):
            continue
        style = _paragraph_style(child)
        if style == "Heading1":
            entries.append((int(style[-1]), _text(child)))
    for child in list(body)[toc_heading + 1 : introduction]:
        body.remove(child)
    existing_heading = body[toc_heading]
    body.remove(existing_heading)
    body.insert(toc_heading, _paragraph("Table of Contents", "TOCHeading"))
    insertion = toc_heading + 1
    for level, title in entries:
        body.insert(insertion, _paragraph(title, f"TOC{level}"))
        insertion += 1


def _admin_contact_table(root: etree._Element) -> etree._Element | None:
    for paragraph in root.xpath(".//w:p", namespaces=NS):
        if _paragraph_style(paragraph) != "Heading2":
            continue
        if not _text(paragraph).startswith("Client Points of Contact"):
            continue
        current = paragraph.getparent()
        if current is None:
            continue
        siblings = list(current)
        try:
            start = siblings.index(paragraph)
        except ValueError:
            continue
        for sibling in siblings[start + 1 :]:
            if sibling.tag == _qn(W, "tbl"):
                return sibling
            if sibling.tag == _qn(W, "p") and _paragraph_style(sibling).startswith(
                "Heading"
            ):
                break
    return None


def _set_cell_text(cell: etree._Element, value: str) -> None:
    properties = cell.find("w:tcPr", namespaces=NS)
    for child in list(cell):
        if child is not properties:
            cell.remove(child)
    cell.append(_paragraph(value))


def _fill_admin_contacts(root: etree._Element, client: dict[str, Any]) -> None:
    table = _admin_contact_table(root)
    if table is None:
        raise SowDocxError("Template administrative contact table is missing")
    rows = table.findall("w:tr", namespaces=NS)
    values = [
        client["name"],
        client["role"],
        client["mailing_address"],
        client["email"],
        client["phone"],
    ]
    if len(rows) < len(values) + 1:
        raise SowDocxError("Template administrative contact table is incomplete")
    for row, value in zip(rows[1:], values):
        cells = row.findall("w:tc", namespaces=NS)
        if len(cells) < 3:
            raise SowDocxError("Template administrative contact row is incomplete")
        _set_cell_text(cells[1], value)
        _set_cell_text(cells[2], value)


def _normalize_admin_contacts(root: etree._Element) -> None:
    table = _admin_contact_table(root)
    if table is None:
        return
    rows = table.findall("w:tr", namespaces=NS)
    for row in rows[1:]:
        cells = row.findall("w:tc", namespaces=NS)
        for cell in cells[1:3]:
            _set_cell_text(cell, "__AIS_CONTACT_SLOT__")


def _normalize_fixed_region(
    document_bytes: bytes,
    boundary_heading: str,
    editable_tags: Iterable[str],
    fixed_literal_replacements: dict[str, str] | None = None,
) -> bytes:
    root = _parse_xml(document_bytes, "word/document.xml")
    body = root.find("w:body", namespaces=NS)
    if body is None:
        raise SowDocxError("Document body is missing")
    boundary = _find_heading_child(body, boundary_heading)
    wrapper = etree.Element("fixed-region")
    for child in list(body)[boundary:]:
        wrapper.append(deepcopy(child))
    _remove_instruction_paragraphs(wrapper)
    _remove_authoring_highlights(wrapper)
    _normalize_admin_contacts(wrapper)
    editable = set(editable_tags)
    for sdt in wrapper.xpath("//w:sdt", namespaces=NS):
        tag = sdt.find("./w:sdtPr/w:tag", namespaces=NS)
        if tag is None or tag.get(_qn(W, "val"), "") not in editable:
            continue
        properties = sdt.find("./w:sdtPr", namespaces=NS)
        if properties is not None:
            for editable_state in (
                properties.find("w:dataBinding", namespaces=NS),
                properties.find("w:showingPlcHdr", namespaces=NS),
            ):
                if editable_state is not None:
                    properties.remove(editable_state)
        for text_node in sdt.xpath("./w:sdtContent//w:t", namespaces=NS):
            text_node.text = "__AIS_EDITABLE_SLOT__"
            text_node.attrib.pop(_qn(XML, "space"), None)
    for old, new in (fixed_literal_replacements or {}).items():
        _replace_exact_text_nodes(
            wrapper,
            {
                old: "__AIS_FIXED_LITERAL_SLOT__",
                new: "__AIS_FIXED_LITERAL_SLOT__",
            },
        )
    return etree.tostring(wrapper, method="c14n", with_comments=False)


def fixed_region_digest(
    document_bytes: bytes,
    boundary_heading: str,
    editable_tags: Iterable[str],
    fixed_literal_replacements: dict[str, str] | None = None,
) -> str:
    return _sha256_bytes(
        _normalize_fixed_region(
            document_bytes,
            boundary_heading,
            editable_tags,
            fixed_literal_replacements,
        )
    )


def _protection_digest(settings_bytes: bytes) -> str | None:
    root = _parse_xml(settings_bytes, "word/settings.xml")
    protection = root.find("w:documentProtection", namespaces=NS)
    if protection is None:
        return None
    return _sha256_bytes(
        etree.tostring(protection, method="c14n", with_comments=False)
    )


def _enable_field_refresh(settings_bytes: bytes) -> bytes:
    root = _parse_xml(settings_bytes, "word/settings.xml")
    update = root.find("w:updateFields", namespaces=NS)
    if update is None:
        update = etree.SubElement(root, _qn(W, "updateFields"))
    update.set(_qn(W, "val"), "true")
    return _xml_bytes(root)


def _custom_properties(
    existing: bytes | None, properties: dict[str, str]
) -> bytes:
    if existing:
        root = _parse_xml(existing, "docProps/custom.xml")
    else:
        root = etree.Element(_qn(CP, "Properties"), nsmap={None: CP, "vt": VT})
    for prop in list(root.findall(_qn(CP, "property"))):
        if prop.get("name") in properties:
            root.remove(prop)
    pids = [int(prop.get("pid", "1")) for prop in root.findall(_qn(CP, "property"))]
    next_pid = max(pids, default=1) + 1
    for name, value in properties.items():
        prop = etree.SubElement(root, _qn(CP, "property"))
        prop.set("fmtid", "{D5CDD505-2E9C-101B-9397-08002B2CF9AE}")
        prop.set("pid", str(next_pid))
        prop.set("name", name)
        text = etree.SubElement(prop, _qn(VT, "lpwstr"))
        text.text = value
        next_pid += 1
    return _xml_bytes(root)


def _ensure_custom_relationship(rels_bytes: bytes) -> bytes:
    root = _parse_xml(rels_bytes, "_rels/.rels")
    relationships = root.findall(_qn(PKG_REL, "Relationship"))
    for relationship in relationships:
        if relationship.get("Type") == CUSTOM_REL_TYPE:
            relationship.set("Target", "docProps/custom.xml")
            return _xml_bytes(root)
    ids = {relationship.get("Id") for relationship in relationships}
    counter = 1
    while f"rId{counter}" in ids:
        counter += 1
    relationship = etree.SubElement(root, _qn(PKG_REL, "Relationship"))
    relationship.set("Id", f"rId{counter}")
    relationship.set("Type", CUSTOM_REL_TYPE)
    relationship.set("Target", "docProps/custom.xml")
    return _xml_bytes(root)


def _ensure_custom_content_type(content_types_bytes: bytes) -> bytes:
    root = _parse_xml(content_types_bytes, "[Content_Types].xml")
    for override in root.findall(_qn(CONTENT_TYPES, "Override")):
        if override.get("PartName") == "/docProps/custom.xml":
            override.set("ContentType", CUSTOM_CONTENT_TYPE)
            return _xml_bytes(root)
    override = etree.SubElement(root, _qn(CONTENT_TYPES, "Override"))
    override.set("PartName", "/docProps/custom.xml")
    override.set("ContentType", CUSTOM_CONTENT_TYPE)
    return _xml_bytes(root)


def _write_package(
    output_path: Path,
    source_infos: list[zipfile.ZipInfo],
    parts: dict[str, bytes],
) -> None:
    original_names = {info.filename for info in source_infos}
    with zipfile.ZipFile(output_path, "w") as archive:
        for info in source_infos:
            archive.writestr(info, parts[info.filename])
        for name in sorted(set(parts) - original_names):
            archive.writestr(name, parts[name], compress_type=zipfile.ZIP_DEFLATED)


def _relationship_targets(parts: dict[str, bytes]) -> list[str]:
    missing: list[str] = []
    for name, value in parts.items():
        if not name.endswith(".rels"):
            continue
        root = _parse_xml(value, name)
        if name == "_rels/.rels":
            base = ""
        else:
            rel_dir, rel_name = posixpath.split(name)
            source_dir = posixpath.dirname(rel_dir)
            source_name = rel_name[:-5]
            base = posixpath.dirname(posixpath.join(source_dir, source_name))
        for relationship in root.findall(_qn(PKG_REL, "Relationship")):
            if relationship.get("TargetMode") == "External":
                continue
            target = unquote(relationship.get("Target", "")).split("#", 1)[0]
            if not target:
                continue
            resolved = posixpath.normpath(
                target.lstrip("/") if target.startswith("/") else posixpath.join(base, target)
            )
            if resolved not in parts:
                missing.append(f"{name} -> {resolved}")
    return sorted(missing)


def _all_xml_well_formed(parts: dict[str, bytes]) -> list[str]:
    failures: list[str] = []
    for name, value in parts.items():
        if name.endswith(".xml") or name.endswith(".rels"):
            try:
                etree.fromstring(value)
            except etree.XMLSyntaxError as exc:
                failures.append(f"{name}: {exc}")
    return failures


def _source_ids(data: dict[str, Any]) -> list[str]:
    groups = [
        data["scope"]["in_scope"],
        data["scope"]["out_of_scope"],
        data["deliverables"],
        data["milestones"],
        data["responsibilities"]["ais"],
        data["responsibilities"]["client"],
        data["assumptions"],
    ]
    return [item["source_id"] for group in groups for item in group]


def read_custom_properties(path: Path | str) -> dict[str, str]:
    parts, _ = _read_package(Path(path))
    value = parts.get("docProps/custom.xml")
    if value is None:
        return {}
    root = _parse_xml(value, "docProps/custom.xml")
    result: dict[str, str] = {}
    for prop in root.findall(_qn(CP, "property")):
        children = list(prop)
        result[prop.get("name", "")] = children[0].text or "" if children else ""
    return result


def _check(name: str, passed: bool, detail: str) -> dict[str, Any]:
    return {"name": name, "passed": bool(passed), "detail": detail}


def _commercial_region_text(document: etree._Element, boundary: str) -> str:
    body = document.find("w:body", namespaces=NS)
    if body is None:
        return ""
    start = _find_heading_child(body, "Commercial Review")
    end = _find_heading_child(body, boundary)
    return " ".join(_text(child) for child in list(body)[start:end])


def _commercial_value_cells(
    document: etree._Element, boundary: str
) -> list[str]:
    body = document.find("w:body", namespaces=NS)
    if body is None:
        return []
    start = _find_heading_child(body, "Commercial Review")
    end = _find_heading_child(body, boundary)
    values: list[str] = []
    for child in list(body)[start:end]:
        if child.tag != _qn(W, "tbl"):
            continue
        rows = child.findall("w:tr", namespaces=NS)
        if not rows:
            continue
        header_cells = rows[0].findall("w:tc", namespaces=NS)
        value_columns = range(1, len(header_cells))
        for row in rows[1:]:
            cells = row.findall("w:tc", namespaces=NS)
            values.extend(
                _text(cells[index]) if index < len(cells) else ""
                for index in value_columns
            )
    return values


def _instruction_texts(document: etree._Element) -> list[str]:
    findings: list[str] = []
    for paragraph in document.xpath("//w:p", namespaces=NS):
        text = _text(paragraph)
        if _paragraph_style(paragraph) == INSTRUCTION_STYLE:
            findings.append(text or "SOWInstructions paragraph")
        elif re.search(
            r"(?i)turn on Review\s*>\s*Track Changes|insert (?:task|out of scope)|"
            r"Objective 1|Customeridname|Enter SOW|Enter MSA|pss_opportunityid|"
            r"Enter Client POC|Enter Email address|Enter Phone number|\$X{3,}|"
            r"\bX{2,}(?:/per week)?\b|50% of the average weekly cost",
            text,
        ):
            findings.append(text)
    return findings


def validate_generated_document(
    output_path: Path | str,
    data: dict[str, Any],
    manifest: dict[str, Any],
    profile: dict[str, Any],
    version: dict[str, Any],
    skill_root: Path | str,
) -> dict[str, Any]:
    output = Path(output_path)
    source = _asset_path(Path(skill_root), version["asset"])
    source_parts, _ = _read_package(source)
    output_parts, _ = _read_package(output)
    document = _parse_xml(output_parts["word/document.xml"], "word/document.xml")
    editable_tags = manifest["editable_sdt_tags"]
    checks: list[dict[str, Any]] = []

    language_issues = review_client_language(data)
    checks.append(
        _check(
            "client_language_policy",
            not language_issues,
            "No high-confidence prohibited client-language patterns detected."
            if not language_issues
            else "; ".join(
                f"{issue['code']} at {issue['path']}" for issue in language_issues[:5]
            ),
        )
    )

    xml_failures = _all_xml_well_formed(output_parts)
    checks.append(_check("package_xml_well_formed", not xml_failures, str(xml_failures)))
    missing_parts = sorted(set(manifest["required_package_parts"]) - set(output_parts))
    checks.append(_check("required_package_parts", not missing_parts, str(missing_parts)))
    missing_relationships = _relationship_targets(output_parts)
    checks.append(
        _check("package_relationships", not missing_relationships, str(missing_relationships))
    )

    changed_preserve_parts = sorted(
        name
        for name, value in source_parts.items()
        if not _is_allowed_changed_part(name) and output_parts.get(name) != value
    )
    checks.append(
        _check(
            "undeclared_package_parts_preserved",
            not changed_preserve_parts,
            str(changed_preserve_parts),
        )
    )

    source_fixed = fixed_region_digest(
        source_parts["word/document.xml"],
        version["fixed_boundary_heading"],
        editable_tags,
        manifest.get("fixed_literal_replacements"),
    )
    output_fixed = fixed_region_digest(
        output_parts["word/document.xml"],
        version["fixed_boundary_heading"],
        editable_tags,
        manifest.get("fixed_literal_replacements"),
    )
    checks.append(
        _check(
            "fixed_region_preserved",
            source_fixed == output_fixed,
            f"source={source_fixed}; output={output_fixed}",
        )
    )

    source_protection = _protection_digest(source_parts["word/settings.xml"])
    output_protection = _protection_digest(output_parts["word/settings.xml"])
    checks.append(
        _check(
            "document_protection_preserved",
            source_protection is not None and source_protection == output_protection,
            f"source={source_protection}; output={output_protection}",
        )
    )

    word_xml_parts = {
        name: _parse_xml(value, name)
        for name, value in output_parts.items()
        if re.fullmatch(r"word/(?:document|header\d+|footer\d+)\.xml", name)
    }
    instruction_findings = [
        finding
        for root in word_xml_parts.values()
        for finding in _instruction_texts(root)
    ]
    checks.append(
        _check("template_instructions_removed", not instruction_findings, str(instruction_findings[:5]))
    )

    commercial_text = _commercial_region_text(
        document, version["fixed_boundary_heading"]
    )
    commercial_value_cells = _commercial_value_cells(
        document, version["fixed_boundary_heading"]
    )
    numeric_commercial = bool(
        re.search(r"[$€£¥]\s*\d|\d\s*(?:%|/\s*(?:hour|hr))", commercial_text, re.I)
    )
    invalid_commercial_cells = [
        index
        for index, value in enumerate(commercial_value_cells, start=1)
        if value != COMMERCIAL_PLACEHOLDER
    ]
    placeholders_only = (
        bool(commercial_value_cells)
        and not invalid_commercial_cells
        and not numeric_commercial
    )
    checks.append(
        _check(
            "commercial_placeholders_only",
            placeholders_only,
            f"validated {len(commercial_value_cells)} commercial value cells"
            if placeholders_only
            else (
                f"commercial value cells requiring the controlled placeholder: "
                f"{invalid_commercial_cells}; numeric pattern detected: "
                f"{numeric_commercial}"
            ),
        )
    )

    expected_ids = _source_ids(data)
    bookmark_names = {
        node.get(_qn(W, "name"), "")
        for node in document.xpath("//w:bookmarkStart", namespaces=NS)
    }
    found_ids = [item for item in expected_ids if _bookmark_name(item) in bookmark_names]
    missing_ids = sorted(set(expected_ids) - set(found_ids))
    checks.append(
        _check("source_traceability", not missing_ids, f"missing={missing_ids}")
    )

    properties = read_custom_properties(output)
    expected_properties = {
        "AIS.SOW.Profile": profile["id"],
        "AIS.SOW.TemplateVersion": version["version"],
        "AIS.SOW.TemplateIdentity": version["template_identity"],
        "AIS.SOW.TemplateSHA256": version["sha256"],
    }
    metadata_matches = all(properties.get(key) == value for key, value in expected_properties.items())
    checks.append(
        _check("machine_readable_template_metadata", metadata_matches, str(expected_properties))
    )
    visible_text = " ".join(_text(root) for root in word_xml_parts.values())
    checks.append(
        _check(
            "visible_template_version",
            version["visible_version_label"] in visible_text,
            version["visible_version_label"],
        )
    )
    unresolved_controls: list[str] = []
    for part_name, root in word_xml_parts.items():
        for sdt in root.xpath("//w:sdt", namespaces=NS):
            tag = sdt.find("./w:sdtPr/w:tag", namespaces=NS)
            if tag is None or tag.get(_qn(W, "val"), "") not in editable_tags:
                continue
            if sdt.find("./w:sdtPr/w:dataBinding", namespaces=NS) is not None:
                unresolved_controls.append(f"{part_name}:dataBinding")
            if sdt.find("./w:sdtPr/w:showingPlcHdr", namespaces=NS) is not None:
                unresolved_controls.append(f"{part_name}:showingPlcHdr")
    checks.append(
        _check(
            "editable_controls_resolved",
            not unresolved_controls,
            str(unresolved_controls),
        )
    )
    highlights = document.xpath("//w:highlight", namespaces=NS)
    checks.append(
        _check(
            "authoring_highlights_removed",
            not highlights,
            f"remaining={len(highlights)}",
        )
    )
    body = document.find("w:body", namespaces=NS)
    toc_text = ""
    if body is not None:
        toc_heading_index = next(
            (
                index
                for index, child in enumerate(body)
                if child.tag == _qn(W, "p")
                and _paragraph_style(child) == "TOCHeading"
            ),
            None,
        )
        intro_index = _find_heading_child(body, "Introduction")
        if toc_heading_index is not None:
            toc_text = " ".join(
                _text(child)
                for child in list(body)[toc_heading_index + 1 : intro_index]
            )
    toc_current = (
        "Commercial Review" in toc_text
        and "Project Execution Phase Name" not in toc_text
        and "Price Proposal" not in toc_text
    )
    checks.append(_check("table_of_contents_current", toc_current, toc_text[:300]))
    settings = _parse_xml(output_parts["word/settings.xml"], "word/settings.xml")
    update = settings.find("w:updateFields", namespaces=NS)
    checks.append(
        _check(
            "field_refresh_requested",
            update is not None and update.get(_qn(W, "val")) in {"true", "1"},
            "Word fields are marked for refresh on open",
        )
    )

    structural_valid = all(check["passed"] for check in checks)
    evidence = {
        "schema_version": 1,
        "input_sha256": _sha256_bytes(
            json.dumps(data, sort_keys=True, separators=(",", ":")).encode("utf-8")
        ),
        "profile_id": profile["id"],
        "template_version": version["version"],
        "template_identity": version["template_identity"],
        "template_sha256": version["sha256"],
        "output_sha256": sha256_file(output),
        "traceability": {
            "expected": expected_ids,
            "found": found_ids,
            "missing": missing_ids,
        },
        "checks": checks,
        "structural_valid": structural_valid,
        "render": {
            "renderer": None,
            "page_count": None,
            "reviewed": False,
            "passed": False,
            "notes": "Rendered page review has not been recorded.",
        },
        "content_review": {
            "reviewer": None,
            "reviewed": False,
            "passed": False,
            "notes": "Human content review has not been recorded.",
        },
        "client_ready": False,
    }
    evidence["client_ready"] = compute_client_ready(evidence)
    return evidence


def compute_client_ready(evidence: dict[str, Any]) -> bool:
    render = evidence.get("render") or {}
    content_review = evidence.get("content_review") or {}
    reviewer = content_review.get("reviewer")
    return bool(
        evidence.get("structural_valid")
        and render.get("reviewed")
        and render.get("passed")
        and isinstance(render.get("page_count"), int)
        and render.get("page_count") > 0
        and content_review.get("reviewed")
        and content_review.get("passed")
        and isinstance(reviewer, str)
        and reviewer.strip()
    )


def _prepare_document_parts(
    source_parts: dict[str, bytes],
    data: dict[str, Any],
    manifest: dict[str, Any],
    profile: dict[str, Any],
    version: dict[str, Any],
) -> dict[str, bytes]:
    parts = dict(source_parts)
    document = _parse_xml(parts["word/document.xml"], "word/document.xml")
    body = document.find("w:body", namespaces=NS)
    if body is None:
        raise SowDocxError("Template document body is missing")

    client = _client_contact(data)
    sdt_values = {
        "Template Version": version["visible_version_label"],
        "Pipeline ID": data["document"]["opportunity_id"],
        "SOW Date": _long_date(data["document"]["effective_date"]),
        "Client Name": data["document"]["client_name"],
        "SOW Signatory": client["name"],
        "Client POC Title": client["role"],
        "Opportunity Name": data["document"]["project_name"],
        "MSA Date": _long_date(data["document"]["msa_date"]),
        "SOW Start Date": _long_date(data["document"]["effective_date"]),
        "SOW End Date": _long_date(data["document"]["expiration_date"]),
    }
    replaced = _replace_sdt_values(document, sdt_values)
    required_sdt = set(sdt_values) - {"SOW Start Date", "SOW End Date"}
    missing_sdt = sorted(required_sdt - replaced)
    if missing_sdt:
        raise SowDocxError(f"Template is missing required editable slots: {missing_sdt}")
    _replace_exact_text_nodes(
        document,
        {
            "Enter Email address": client["email"],
            "Enter Phone number": client["phone"],
        },
    )
    _replace_exact_text_nodes(
        document, manifest.get("fixed_literal_replacements", {})
    )
    _remove_instruction_paragraphs(document)
    _remove_authoring_highlights(document)
    _fill_admin_contacts(document, client)

    introduction = _find_heading_child(body, "Introduction")
    boundary = _find_heading_child(body, version["fixed_boundary_heading"])
    if boundary <= introduction + 1:
        raise SowDocxError("Template editable narrative boundary is invalid")
    intro_paragraph = None
    for index in range(introduction + 1, boundary):
        child = body[index]
        if child.tag == _qn(W, "p") and _text(child):
            if _paragraph_style(child) == "Heading2":
                break
            intro_paragraph = index
            break
    if intro_paragraph is None:
        raise SowDocxError("Template introductory agreement paragraph is missing")
    for child in list(body)[intro_paragraph + 1 : boundary]:
        body.remove(child)
    boundary = _find_heading_child(body, version["fixed_boundary_heading"])
    for offset, element in enumerate(_build_narrative(data, profile["id"])):
        body.insert(boundary + offset, element)

    _refresh_static_toc(body)

    parts["word/document.xml"] = _xml_bytes(document)
    for part_name in sorted(parts):
        if not re.fullmatch(r"word/(?:header\d+|footer\d+)\.xml", part_name):
            continue
        root = _parse_xml(parts[part_name], part_name)
        _replace_sdt_values(root, sdt_values)
        _remove_authoring_highlights(root)
        parts[part_name] = _xml_bytes(root)
    parts["word/settings.xml"] = _enable_field_refresh(parts["word/settings.xml"])
    properties = {
        "AIS.SOW.Profile": profile["id"],
        "AIS.SOW.TemplateVersion": version["version"],
        "AIS.SOW.TemplateIdentity": version["template_identity"],
        "AIS.SOW.TemplateSHA256": version["sha256"],
    }
    parts["docProps/custom.xml"] = _custom_properties(
        parts.get("docProps/custom.xml"), properties
    )
    parts["_rels/.rels"] = _ensure_custom_relationship(parts["_rels/.rels"])
    parts["[Content_Types].xml"] = _ensure_custom_content_type(
        parts["[Content_Types].xml"]
    )
    return parts


def generate_document(
    data: dict[str, Any],
    output_path: Path | str,
    manifest_path: Path | str,
    skill_root: Path | str,
) -> dict[str, Any]:
    root = Path(skill_root)
    manifest = load_manifest(manifest_path)
    validate_input(data, manifest)
    profile, version = resolve_template(
        manifest,
        data["classification"],
        data.get("template_version"),
        root,
    )
    source = _asset_path(root, version["asset"])
    source_parts, source_infos = _read_package(source)
    output_parts = _prepare_document_parts(
        source_parts, data, manifest, profile, version
    )

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        handle, temp_name = tempfile.mkstemp(
            prefix=f".{output.stem}-", suffix=".docx", dir=output.parent
        )
        os.close(handle)
        temporary = Path(temp_name)
        _write_package(temporary, source_infos, output_parts)
        evidence = validate_generated_document(
            temporary, data, manifest, profile, version, root
        )
        if not evidence["structural_valid"]:
            failed = [
                check["name"] for check in evidence["checks"] if not check["passed"]
            ]
            raise SowDocxError(
                f"Generated SOW failed structural validation: {', '.join(failed)}"
            )
        os.replace(temporary, output)
        temporary = None
        evidence["output_sha256"] = sha256_file(output)
        return evidence
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
