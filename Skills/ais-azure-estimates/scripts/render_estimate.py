# /// script
# dependencies = []
# requires-python = ">=3.10"
# ///

"""Render AIS Azure estimate output artifacts."""

from __future__ import annotations

import csv
import json
import zipfile
from pathlib import Path
from typing import Any
from xml.sax.saxutils import escape


CSV_COLUMNS = [
    "id",
    "name",
    "service_name",
    "service_family",
    "sku_name",
    "region",
    "quantity",
    "unit",
    "unit_price",
    "monthly_cost",
    "annual_cost",
    "pricing_source",
    "sizing_confidence",
    "pricing_confidence",
    "included_in_total",
    "notes",
]

WORKBOOK_COLUMNS = [
    "Service category",
    "Service type",
    "Custom name",
    "Region",
    "Description",
    "Estimated monthly cost",
    "Estimated annual cost",
    "Estimated upfront cost",
]


def render_outputs(estimate_output: dict[str, Any], output_dir: str | Path, overwrite: bool = True) -> dict[str, str]:
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    paths = {
        "estimate_section_md": output_path / "estimate-section.md",
        "estimate_review_md": output_path / "estimate-review.md",
        "line_items_csv": output_path / "estimate-line-items.csv",
        "estimate_workbook_xlsx": output_path / "estimate-workbook.xlsx",
        "estimate_audit_json": output_path / "estimate-audit.json",
    }

    if not overwrite:
        existing = [str(path) for path in paths.values() if path.exists()]
        if existing:
            raise FileExistsError("Output artifact(s) already exist: " + ", ".join(existing))

    estimate_output["artifacts"] = {
        "estimate_section_md": str(paths["estimate_section_md"]),
        "estimate_review_md": str(paths["estimate_review_md"]),
        "line_items_csv": str(paths["line_items_csv"]),
        "estimate_workbook_xlsx": str(paths["estimate_workbook_xlsx"]),
    }

    paths["estimate_section_md"].write_text(_proposal_markdown(estimate_output), encoding="utf-8")
    paths["estimate_review_md"].write_text(_review_markdown(estimate_output), encoding="utf-8")
    _write_csv(estimate_output, paths["line_items_csv"])
    _write_xlsx(estimate_output, paths["estimate_workbook_xlsx"])
    paths["estimate_audit_json"].write_text(json.dumps(estimate_output, indent=2), encoding="utf-8")
    return {key: str(value) for key, value in paths.items()}


def _proposal_markdown(estimate_output: dict[str, Any]) -> str:
    estimate = estimate_output.get("normalized_input", {}).get("estimate", {})
    defaults = estimate_output.get("normalized_input", {}).get("defaults", {})
    totals = estimate_output.get("totals", {})
    lines = [
        f"# Azure Consumption Estimate: {estimate.get('name', 'Untitled Estimate')}",
        "",
        f"Cloud/region: {defaults.get('cloud', 'N/A')} / {defaults.get('region', 'N/A')}",
        f"Estimated monthly total for resolved items: {totals.get('currency', 'USD')} {totals.get('monthly_total', 0):,.2f}",
        f"Estimated annual total for resolved items: {totals.get('currency', 'USD')} {totals.get('annual_total', 0):,.2f}",
        f"Unresolved items excluded from total: {totals.get('excluded_unresolved_count', 0)}",
        "",
        "This planning estimate uses public Azure retail pricing where available and requires Azure solution architect review before external use.",
        "",
        "## Top Cost Drivers",
    ]
    lines.extend(_top_service_summary_table(estimate_output))
    lines.extend([
        "",
        "## Estimate Assumptions",
    ])
    lines.extend(_assumption_lines(estimate_output))
    lines.extend([
        "",
        "## Cost by Impact Level",
    ])
    lines.extend(_impact_level_service_tables(estimate_output))
    lines.extend([
        "",
        "## Included Cost Items",
    ])
    included = _summarize_included_items(estimate_output.get("line_items", []))
    if included:
        currency = totals.get("currency", "USD")
        lines.extend(
            f"- {item['name']} ({item['count']} line item{'s' if item['count'] != 1 else ''}): "
            f"{currency} {item['monthly_cost']:,.2f}/month"
            for item in included
        )
    else:
        lines.append("- None")
    lines.extend([
        "",
        "## Caveats",
    ])
    caveats = estimate_output.get("caveats", [])
    if caveats:
        lines.extend(f"- {caveat['title']}: {caveat['message']}" for caveat in caveats)
    else:
        lines.append("- None")
    lines.extend([
        "",
        "## Unresolved Items",
    ])
    unresolved = _summarize_unresolved_items(estimate_output.get("line_items", []))
    if unresolved:
        lines.extend(
            f"- {item['name']} ({item['count']} line item{'s' if item['count'] != 1 else ''}): {item['notes']}"
            for item in unresolved
        )
    else:
        lines.append("- None")
    exclusions = estimate_output.get("normalized_input", {}).get("exclusions", [])
    if exclusions:
        lines.extend(["", "## Exclusions", *[f"- {item}" for item in exclusions]])
    return "\n".join(lines) + "\n"


def _review_markdown(estimate_output: dict[str, Any]) -> str:
    lines = ["# Azure Estimate Review", "", "## Warnings"]
    warnings = estimate_output.get("warnings", [])
    if warnings:
        lines.extend(f"- {warning['code']}: {warning['message']}" for warning in warnings)
    else:
        lines.append("- None")
    lines.extend(["", "## Caveats"])
    caveats = estimate_output.get("caveats", [])
    if caveats:
        for caveat in caveats:
            lines.append(f"- {caveat['code']}: {caveat['message']}")
            for detail in caveat.get("details", []):
                lines.append(f"  - {detail}")
    else:
        lines.append("- None")
    lines.extend(["", "## Line Items"])
    for item in estimate_output.get("line_items", []):
        lines.append(
            f"- {item['id']} | {item['service_name']} | {item['pricing_source']} | "
            f"monthly={item.get('monthly_cost')} | included={item['included_in_total']}"
        )
    return "\n".join(lines) + "\n"


def _assumption_lines(estimate_output: dict[str, Any]) -> list[str]:
    normalized = estimate_output.get("normalized_input", {})
    defaults = normalized.get("defaults", {})
    assumptions = normalized.get("assumptions", [])
    lines = [
        f"- Provisioning basis: {defaults.get('provisioning_state', 'Median expected provisioned state over the estimate period')}.",
        f"- Estimate period: {defaults.get('period_months', 12)} months using {defaults.get('monthly_hours', 730)} hours per month.",
        f"- Data sizing: {defaults.get('data_sizing_policy', 'Conservative planning assumptions apply')}.",
    ]
    retention = defaults.get("retention_policy")
    if isinstance(retention, dict):
        lines.append(
            f"- Retention: {retention.get('duration_days', 'unspecified')} days; {retention.get('basis', 'planning assumption')}."
        )
    lines.extend(f"- {assumption['text']}" for assumption in assumptions if isinstance(assumption, dict) and assumption.get("text"))
    return lines


def _impact_level_service_tables(estimate_output: dict[str, Any]) -> list[str]:
    currency = estimate_output.get("totals", {}).get("currency", "USD")
    grouped: dict[str, list[dict[str, Any]]] = {}
    for item in estimate_output.get("line_items", []):
        if not item.get("included_in_total"):
            continue
        dimensions = item.get("source_dimensions", {})
        impact_level = str(dimensions.get("impact_level", "Unspecified"))
        grouped.setdefault(impact_level, []).append(item)

    if not grouped:
        return ["- None"]

    lines: list[str] = []
    environment_order = {"shared": 0, "dev": 1, "test": 2, "stage": 3, "prod": 4, "Unspecified": 99}
    for impact_level in sorted(grouped):
        monthly_total = round(sum(float(item.get("monthly_cost") or 0) for item in grouped[impact_level]), 2)
        annual_total = round(sum(float(item.get("annual_cost") or 0) for item in grouped[impact_level]), 2)
        lines.extend([
            f"### {impact_level}",
            "",
            "| Service | Environment | Assumptions | Monthly Cost | Annual Cost |",
            "|---------|-------------|-------------|--------------|-------------|",
            ])
        for item in sorted(grouped[impact_level], key=lambda row: (environment_order.get(str(row.get("source_dimensions", {}).get("environment", "Unspecified")), 50), str(row.get("name", "")))):
            environment = str(item.get("source_dimensions", {}).get("environment", "Unspecified"))
            lines.append(
                f"| {_escape_markdown_cell(str(item.get('name', 'Unnamed service')))} | "
                f"{environment} | "
                f"{_escape_markdown_cell(_service_assumption(item))} | "
                f"{currency} {float(item.get('monthly_cost') or 0):,.2f} | "
                f"{currency} {float(item.get('annual_cost') or 0):,.2f} |"
            )
        lines.append(f"| **Total {impact_level}** |  |  | **{currency} {monthly_total:,.2f}** | **{currency} {annual_total:,.2f}** |")
        lines.append("")
    return lines[:-1]


def _top_service_summary_table(estimate_output: dict[str, Any]) -> list[str]:
    currency = estimate_output.get("totals", {}).get("currency", "USD")
    grouped: dict[str, dict[str, Any]] = {}
    for item in estimate_output.get("line_items", []):
        if not item.get("included_in_total"):
            continue
        key = str(item.get("source_line_item_id") or item.get("id"))
        summary = grouped.setdefault(
            key,
            {
                "name": str(item.get("name", key)),
                "count": 0,
                "monthly_cost": 0.0,
                "annual_cost": 0.0,
            },
        )
        summary["count"] += 1
        summary["monthly_cost"] += float(item.get("monthly_cost") or 0)
        summary["annual_cost"] += float(item.get("annual_cost") or 0)

    if not grouped:
        return ["- None"]

    summaries = sorted(grouped.values(), key=lambda item: (-item["monthly_cost"], item["name"]))
    top_items = summaries[:4]
    other_items = summaries[4:]
    if other_items:
        top_items.append(
            {
                "name": "Other",
                "count": sum(item["count"] for item in other_items),
                "monthly_cost": sum(item["monthly_cost"] for item in other_items),
                "annual_cost": sum(item["annual_cost"] for item in other_items),
            }
        )

    lines = [
        "| Service | Environment | Assumptions | Monthly Cost | Annual Cost |",
        "|---------|-------------|-------------|--------------|-------------|",
    ]
    for item in top_items:
        assumption = (
            "All remaining included Azure consumption services."
            if item["name"] == "Other"
            else f"Rollup of {item['count']} included line items across all impact levels and environments."
        )
        lines.append(
            f"| {_escape_markdown_cell(item['name'])} | All ILs/environments | "
            f"{assumption} | {currency} {item['monthly_cost']:,.2f} | {currency} {item['annual_cost']:,.2f} |"
        )
    return lines


def _service_assumption(item: dict[str, Any]) -> str:
    sku_name = str(item.get("sku_name", "")).strip()
    quantity = item.get("quantity")
    unit = str(item.get("unit", "")).strip()
    notes = _proposal_note(str(item.get("notes", "")))
    sizing = f"{quantity:g} {unit}" if isinstance(quantity, (int, float)) and unit else ""
    parts = [part for part in (f"SKU: {sku_name}" if sku_name else "", sizing, notes) if part]
    return "; ".join(parts) or "Planning assumption pending customer sizing confirmation."


def _escape_markdown_cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def _summarize_unresolved_items(line_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}
    for item in line_items:
        if item.get("included_in_total"):
            continue
        key = str(item.get("source_line_item_id") or item.get("id"))
        summary = grouped.setdefault(
            key,
            {
                "name": str(item.get("name", key)),
                "count": 0,
                "notes": _proposal_note(str(item.get("notes", "Requires confirmation."))),
            },
        )
        summary["count"] += 1
    return list(grouped.values())


def _summarize_included_items(line_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}
    for item in line_items:
        if not item.get("included_in_total"):
            continue
        key = str(item.get("source_line_item_id") or item.get("id"))
        summary = grouped.setdefault(
            key,
            {
                "name": str(item.get("name", key)),
                "count": 0,
                "monthly_cost": 0.0,
            },
        )
        summary["count"] += 1
        summary["monthly_cost"] += float(item.get("monthly_cost") or 0)
    for summary in grouped.values():
        summary["monthly_cost"] = round(summary["monthly_cost"], 2)
    return list(grouped.values())


def _proposal_note(notes: str) -> str:
    for marker in (" Data sizing policy:", " Retention policy:", " Manual override:", " Azure Retail Prices API", " Line item is marked"):
        notes = notes.split(marker, 1)[0]
    return notes.strip() or "Requires confirmation."


def _write_csv(estimate_output: dict[str, Any], path: Path) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(estimate_output.get("line_items", []))


def _write_xlsx(estimate_output: dict[str, Any], path: Path) -> None:
    sheets = _workbook_sheets(estimate_output)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as workbook:
        workbook.writestr("[Content_Types].xml", _content_types_xml(len(sheets)))
        workbook.writestr("_rels/.rels", _root_rels_xml())
        workbook.writestr("docProps/core.xml", _core_properties_xml())
        workbook.writestr("docProps/app.xml", _app_properties_xml([name for name, _rows in sheets]))
        workbook.writestr("xl/workbook.xml", _workbook_xml([name for name, _rows in sheets]))
        workbook.writestr("xl/_rels/workbook.xml.rels", _workbook_rels_xml(len(sheets)))
        workbook.writestr("xl/styles.xml", _styles_xml())
        for index, (_name, rows) in enumerate(sheets, start=1):
            workbook.writestr(f"xl/worksheets/sheet{index}.xml", _worksheet_xml(rows))


def _workbook_sheets(estimate_output: dict[str, Any]) -> list[tuple[str, list[list[Any]]]]:
    line_items = [item for item in estimate_output.get("line_items", []) if item.get("included_in_total")]
    impact_levels = sorted({str(item.get("source_dimensions", {}).get("impact_level", "Unspecified")) for item in line_items})
    sheets = [("Total Estimate", _total_estimate_rows(estimate_output, line_items))]
    for impact_level in impact_levels:
        impact_items = [
            item
            for item in line_items
            if str(item.get("source_dimensions", {}).get("impact_level", "Unspecified")) == impact_level
        ]
        sheets.append((_safe_sheet_name(impact_level), _impact_level_rows(estimate_output, impact_level, impact_items)))
    return sheets


def _total_estimate_rows(estimate_output: dict[str, Any], line_items: list[dict[str, Any]]) -> list[list[Any]]:
    estimate = estimate_output.get("normalized_input", {}).get("estimate", {})
    rows = _workbook_header_rows(str(estimate.get("name", "Total Estimate")))
    rows.extend(_workbook_category_rows(_workbook_service_summaries(line_items)))
    rows.extend(_workbook_total_rows(estimate_output.get("totals", {}).get("monthly_total", 0)))
    return rows


def _impact_level_rows(estimate_output: dict[str, Any], impact_level: str, line_items: list[dict[str, Any]]) -> list[list[Any]]:
    estimate = estimate_output.get("normalized_input", {}).get("estimate", {})
    rows = _workbook_header_rows(f"{estimate.get('name', 'Estimate')} - {impact_level}")
    rows.extend(_workbook_category_rows(_workbook_line_item_details(line_items, include_environment=True)))
    rows.extend(_workbook_total_rows(sum(float(item.get("monthly_cost") or 0) for item in line_items)))
    return rows


def _workbook_header_rows(estimate_name: str) -> list[list[Any]]:
    return [
        ["Microsoft Azure Estimate"],
        [estimate_name],
        WORKBOOK_COLUMNS,
    ]


def _workbook_total_rows(monthly_total: float) -> list[list[Any]]:
    annual_total = round(float(monthly_total) * 12, 2)
    return [
        ["", "", "", "Total", "", round(float(monthly_total), 2), annual_total, 0],
        ["Disclaimer"],
        ["This estimate is for planning purposes only and requires Azure solution architect review before external use."],
    ]


def _workbook_category_rows(details: list[dict[str, Any]]) -> list[Any]:
    grouped: dict[str, dict[str, Any]] = {}
    for detail in details:
        category = str(detail.get("service_family") or "Azure service")
        group = grouped.setdefault(category, {"name": category, "monthly_cost": 0.0, "annual_cost": 0.0, "details": []})
        group["monthly_cost"] += float(detail.get("monthly_cost") or 0)
        group["annual_cost"] += float(detail.get("annual_cost") or 0)
        group["details"].append(detail)

    rows: list[Any] = []
    for group in sorted(grouped.values(), key=lambda item: (-item["monthly_cost"], item["name"])):
        details_in_group = sorted(group["details"], key=lambda item: (-float(item.get("monthly_cost") or 0), str(item.get("name", ""))))
        rows.append(
            {
                "collapsed": True,
                "values": [
                    group["name"],
                    "Category total",
                    "",
                    "",
                    f"Rollup of {len(details_in_group)} included service line item{'s' if len(details_in_group) != 1 else ''}.",
                    round(group["monthly_cost"], 2),
                    round(group["annual_cost"], 2),
                    0,
                ],
            }
        )
        for detail in details_in_group:
            rows.append({"hidden": True, "outline_level": 1, "values": _workbook_detail_row(detail)})
    return rows


def _workbook_detail_row(detail: dict[str, Any]) -> list[Any]:
    return [
        detail["service_family"],
        detail["service_name"],
        detail["name"],
        detail["region"],
        detail["description"],
        round(float(detail.get("monthly_cost") or 0), 2),
        round(float(detail.get("annual_cost") or 0), 2),
        0,
    ]


def _workbook_service_summaries(line_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, dict[str, Any]] = {}
    for item in line_items:
        key = str(item.get("source_line_item_id") or item.get("id"))
        summary = grouped.setdefault(
            key,
            {
                "name": str(item.get("name", key)),
                "service_name": str(item.get("service_name", "")),
                "service_family": _service_category(item),
                "count": 0,
                "monthly_cost": 0.0,
                "annual_cost": 0.0,
                "region": "All regions",
                "description": "",
            },
        )
        summary["count"] += 1
        summary["monthly_cost"] += float(item.get("monthly_cost") or 0)
        summary["annual_cost"] += float(item.get("annual_cost") or 0)
        summary["description"] = f"Rollup of {summary['count']} included line items across all impact levels and environments."
    return sorted(grouped.values(), key=lambda item: (-item["monthly_cost"], item["name"]))


def _workbook_line_item_details(line_items: list[dict[str, Any]], include_environment: bool = False) -> list[dict[str, Any]]:
    def display_name(item: dict[str, Any]) -> str:
        name = str(item.get("name", "Unnamed service"))
        if not include_environment:
            return name
        environment = str(item.get("source_dimensions", {}).get("environment", "Unspecified"))
        return f"{name} ({environment})"

    return [
        {
            "name": display_name(item),
            "service_name": str(item.get("service_name", "")),
            "service_family": _service_category(item),
            "monthly_cost": float(item.get("monthly_cost") or 0),
            "annual_cost": float(item.get("annual_cost") or 0),
            "region": str(item.get("region", "")),
            "description": _service_assumption(item),
        }
        for item in line_items
    ]


def _service_category(item: dict[str, Any]) -> str:
    return str(item.get("service_family") or item.get("service_name") or "Azure service")


def _safe_sheet_name(name: str) -> str:
    cleaned = "".join(" " if char in "[]:*?/\\" else char for char in name).strip() or "Sheet"
    return cleaned[:31]


def _content_types_xml(sheet_count: int) -> str:
    sheet_overrides = "".join(
        f'<Override PartName="/xl/worksheets/sheet{index}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        for index in range(1, sheet_count + 1)
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
        '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        f'{sheet_overrides}'
        '</Types>'
    )


def _root_rels_xml() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
        '</Relationships>'
    )


def _workbook_xml(sheet_names: list[str]) -> str:
    sheets = "".join(
        f'<sheet name="{escape(name)}" sheetId="{index}" r:id="rId{index}"/>'
        for index, name in enumerate(sheet_names, start=1)
    )
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        f'<sheets>{sheets}</sheets>'
        '</workbook>'
    )


def _workbook_rels_xml(sheet_count: int) -> str:
    relationships = "".join(
        f'<Relationship Id="rId{index}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{index}.xml"/>'
        for index in range(1, sheet_count + 1)
    )
    relationships += f'<Relationship Id="rId{sheet_count + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        f'{relationships}'
        '</Relationships>'
    )


def _worksheet_xml(rows: list[list[Any]]) -> str:
    max_row = len(rows)
    max_col = max((_row_length(row) for row in rows), default=len(WORKBOOK_COLUMNS))
    sheet_rows = "".join(_row_xml(index, row) for index, row in enumerate(rows, start=1))
    merge_cells = "<mergeCells count=\"2\"><mergeCell ref=\"A1:C1\"/><mergeCell ref=\"A2:C2\"/></mergeCells>"
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetPr><outlinePr summaryBelow="0"/></sheetPr>'
        f'<dimension ref="A1:{_column_letter(max_col)}{max_row}"/>'
        '<sheetViews><sheetView workbookViewId="0"/></sheetViews>'
        '<sheetFormatPr defaultRowHeight="15"/>'
        '<cols><col min="1" max="4" width="24" customWidth="1"/><col min="5" max="5" width="50" customWidth="1"/><col min="6" max="8" width="30" customWidth="1"/></cols>'
        f'<sheetData>{sheet_rows}</sheetData>{merge_cells}'
        '</worksheet>'
    )


def _row_xml(row_index: int, row: Any) -> str:
    values = _row_values(row)
    attrs = [f'r="{row_index}"']
    if _row_hidden(row):
        attrs.append('hidden="1"')
    outline_level = _row_outline_level(row)
    if outline_level:
        attrs.append(f'outlineLevel="{outline_level}"')
    if _row_collapsed(row):
        attrs.append('collapsed="1"')
    cells = "".join(_cell_xml(row_index, column_index, value) for column_index, value in enumerate(values, start=1))
    return f'<row {" ".join(attrs)}>{cells}</row>'


def _row_values(row: Any) -> list[Any]:
    return row.get("values", []) if isinstance(row, dict) else row


def _row_length(row: Any) -> int:
    return len(_row_values(row))


def _row_outline_level(row: Any) -> int:
    return int(row.get("outline_level", 0)) if isinstance(row, dict) else 0


def _row_hidden(row: Any) -> bool:
    return bool(row.get("hidden", False)) if isinstance(row, dict) else False


def _row_collapsed(row: Any) -> bool:
    return bool(row.get("collapsed", False)) if isinstance(row, dict) else False


def _cell_xml(row_index: int, column_index: int, value: Any) -> str:
    reference = f"{_column_letter(column_index)}{row_index}"
    style = _cell_style(row_index, column_index)
    style_attr = f' s="{style}"' if style else ""
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f'<c r="{reference}"{style_attr}><v>{value}</v></c>'
    text = escape(str(value))
    return f'<c r="{reference}" t="inlineStr"{style_attr}><is><t>{text}</t></is></c>'


def _cell_style(row_index: int, column_index: int) -> int:
    if row_index == 1:
        return 1
    if row_index == 2:
        return 2
    if row_index == 3:
        return 3
    if column_index in (6, 7, 8):
        return 4
    return 0


def _column_letter(index: int) -> str:
    letters = ""
    while index:
        index, remainder = divmod(index - 1, 26)
        letters = chr(65 + remainder) + letters
    return letters


def _styles_xml() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<numFmts count="1"><numFmt numFmtId="164" formatCode="[$$]#,##0.00"/></numFmts>'
        '<fonts count="4"><font><name val="Segoe UI"/><sz val="11"/></font><font><b/><name val="Segoe UI Light"/><sz val="14"/></font><font><i/><name val="Segoe UI Light"/><sz val="12"/></font><font><b/><name val="Segoe UI"/><sz val="11"/></font></fonts>'
        '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFDDEBF7"/><bgColor indexed="64"/></patternFill></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="5"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFill="1"/><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>'
    )


def _core_properties_xml() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:creator>AIS Azure Estimates</dc:creator><cp:lastModifiedBy>AIS Azure Estimates</cp:lastModifiedBy>'
        '</cp:coreProperties>'
    )


def _app_properties_xml(sheet_names: list[str]) -> str:
    titles = "".join(f'<vt:lpstr>{escape(name)}</vt:lpstr>' for name in sheet_names)
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
        'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
        '<Application>AIS Azure Estimates</Application>'
        f'<TitlesOfParts><vt:vector size="{len(sheet_names)}" baseType="lpstr">{titles}</vt:vector></TitlesOfParts>'
        '</Properties>'
    )
