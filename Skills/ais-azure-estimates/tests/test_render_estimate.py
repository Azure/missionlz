from __future__ import annotations

import csv
import json
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

import jsonschema
import pytest

SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

from azure_prices import MeterMatch  # noqa: E402
from build_estimate import build_estimate_output  # noqa: E402
from estimate_model import load_json  # noqa: E402
from render_estimate import render_outputs  # noqa: E402

SKILL_DIR = Path(__file__).resolve().parents[1]
VIRTUALITICS_SAMPLE = SKILL_DIR / "examples" / "virtualitics-alz.sample.json"


def test_render_outputs_writes_markdown_csv_and_audit_json(tmp_path: Path) -> None:
    estimate_output = build_estimate_output(load_json(VIRTUALITICS_SAMPLE), VIRTUALITICS_SAMPLE, price_lookup=_fake_price_lookup)
    paths = render_outputs(estimate_output, tmp_path)

    assert Path(paths["estimate_section_md"]).exists()
    assert Path(paths["estimate_review_md"]).exists()
    assert Path(paths["line_items_csv"]).exists()
    assert Path(paths["estimate_workbook_xlsx"]).exists()
    assert Path(paths["estimate_audit_json"]).exists()
    assert "Azure Consumption Estimate" in Path(paths["estimate_section_md"]).read_text(encoding="utf-8")
    assert "Warnings" in Path(paths["estimate_review_md"]).read_text(encoding="utf-8")

    with Path(paths["line_items_csv"]).open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    assert rows
    assert "monthly_cost" in rows[0]

    audit = json.loads(Path(paths["estimate_audit_json"]).read_text(encoding="utf-8"))
    assert audit["schema_version"] == "1.0"
    assert audit["artifacts"]["line_items_csv"].endswith("estimate-line-items.csv")
    assert audit["artifacts"]["estimate_workbook_xlsx"].endswith("estimate-workbook.xlsx")
    schema = json.loads((SKILL_DIR / "assets" / "estimate-output.schema.json").read_text(encoding="utf-8"))
    jsonschema.validate(audit, schema)


def test_render_outputs_writes_pricing_calculator_style_workbook(tmp_path: Path) -> None:
    estimate_output = build_estimate_output(load_json(VIRTUALITICS_SAMPLE), VIRTUALITICS_SAMPLE, price_lookup=_fake_price_lookup)
    paths = render_outputs(estimate_output, tmp_path)

    workbook_path = Path(paths["estimate_workbook_xlsx"])
    sheet_names = _workbook_sheet_names(workbook_path)
    assert sheet_names == ["Total Estimate", "IL4", "IL5", "IL6"]

    total_rows = _worksheet_rows(workbook_path, 1)
    assert total_rows[0][0] == "Microsoft Azure Estimate"
    assert total_rows[2][:8] == [
        "Service category",
        "Service type",
        "Custom name",
        "Region",
        "Description",
        "Estimated monthly cost",
        "Estimated annual cost",
        "Estimated upfront cost",
    ]
    assert any(len(row) > 6 and row[3] == "Total" and row[5] == "40088.85" and row[6] == "481066.2" for row in total_rows)
    assert total_rows[3][1] == "Category total"
    assert float(total_rows[3][5]) >= float(total_rows[4][5])

    il4_rows = _worksheet_rows(workbook_path, 2)
    assert il4_rows[1][0].endswith(" - IL4")
    assert any(len(row) > 2 and row[2] == "AKS user workload node pool (shared)" for row in il4_rows)
    assert any(len(row) > 2 and row[2] == "PostgreSQL Flexible Server (prod)" for row in il4_rows)
    assert any(len(row) > 6 and row[3] == "Total" and row[6] == "160355.4" for row in il4_rows)

    worksheet_children = _worksheet_child_names(workbook_path, 1)
    assert worksheet_children[:6] == ["sheetPr", "dimension", "sheetViews", "sheetFormatPr", "cols", "sheetData"]
    assert _worksheet_outline_levels(workbook_path, 1)
    assert _worksheet_hidden_outline_rows(workbook_path, 1)
    assert _worksheet_collapsed_rows(workbook_path, 1)


def test_render_outputs_requires_overwrite_for_existing_artifacts(tmp_path: Path) -> None:
    estimate_output = build_estimate_output(load_json(VIRTUALITICS_SAMPLE), VIRTUALITICS_SAMPLE, price_lookup=_fake_price_lookup)
    render_outputs(estimate_output, tmp_path)

    with pytest.raises(FileExistsError):
        render_outputs(estimate_output, tmp_path, overwrite=False)


def test_render_outputs_surfaces_government_and_manual_caveats(tmp_path: Path) -> None:
    estimate_output = build_estimate_output(load_json(VIRTUALITICS_SAMPLE), VIRTUALITICS_SAMPLE, price_lookup=_fake_price_lookup)
    paths = render_outputs(estimate_output, tmp_path)

    proposal = Path(paths["estimate_section_md"]).read_text(encoding="utf-8")
    review = Path(paths["estimate_review_md"]).read_text(encoding="utf-8")
    audit = json.loads(Path(paths["estimate_audit_json"]).read_text(encoding="utf-8"))

    assert "AzureGovernment / usgovvirginia" in proposal
    assert "NIST SP 800-53" in proposal
    assert "conservative high-end data volume" in proposal
    assert "Azure Government Secret" in proposal
    assert "Manual override" in proposal
    assert "Planning placeholder based on public Azure Monitor ingestion assumptions" in review
    assert any(caveat["code"] == "azure_government" for caveat in audit["caveats"])


def test_proposal_output_summarizes_unresolved_items_for_reviewability(tmp_path: Path) -> None:
    estimate_output = build_estimate_output(load_json(VIRTUALITICS_SAMPLE), VIRTUALITICS_SAMPLE, price_lookup=_unresolved_price_lookup)
    paths = render_outputs(estimate_output, tmp_path)

    proposal = Path(paths["estimate_section_md"]).read_text(encoding="utf-8")

    assert "Unresolved items excluded from total: 0" in proposal
    assert "## Estimate Assumptions" in proposal
    assert "one Kubernetes cluster per impact level" in proposal
    assert "## Cost by Impact Level" in proposal
    assert proposal.index("## Top Cost Drivers") < proposal.index("## Estimate Assumptions") < proposal.index("## Cost by Impact Level")
    assert "### IL4" in proposal
    assert "| Service | Environment | Assumptions | Monthly Cost | Annual Cost |" in proposal
    assert "| AKS system node pool | shared | SKU: D4s v5 Linux VM planning placeholder; 3 node-hour; One production-grade AKS system node pool per impact level" in proposal
    assert "| Hot storage for application data | dev | SKU: Hot LRS dev planning tier; 512 GB-month; Conservative high-end data estimate until customer sizing is confirmed. Dev storage is reduced" in proposal
    assert "| Hot storage for application data | prod | SKU: Hot LRS production planning tier; 2048 GB-month; Conservative high-end data estimate until customer sizing is confirmed. Prod storage uses" in proposal
    assert "| **Total IL4** |" in proposal
    assert "App Service" not in proposal
    assert "Managed database compute" not in proposal
    assert "Managed MySQL compute" not in proposal
    assert "Azure SQL Database" not in proposal
    assert "PostgreSQL Flexible Server" in proposal
    assert "MySQL Flexible Server" in proposal
    assert "## Top Cost Drivers" in proposal
    assert "| AKS user workload node pool | All ILs/environments | Rollup of 3 included line items across all impact levels and environments. | USD 9,198.00 | USD 110,376.00 |" in proposal
    assert "| MySQL Flexible Server | All ILs/environments | Rollup of 9 included line items across all impact levels and environments. | USD 7,665.00 | USD 91,980.00 |" in proposal
    assert "| Log Analytics ingestion | All ILs/environments | Rollup of 9 included line items across all impact levels and environments. | USD 3,933.00 | USD 47,196.00 |" in proposal
    assert "| Other | All ILs/environments | All remaining included Azure consumption services. | USD 11,627.85 | USD 139,534.20 |" in proposal
    assert "AKS system node pool (3 line items): USD 2,299.50/month" in proposal
    assert "AKS user workload node pool (3 line items): USD 9,198.00/month" in proposal


def _fake_price_lookup(item: dict, defaults: dict) -> MeterMatch:
    if item.get("service_name") == "App Service" and not item.get("source_template_id"):
        return MeterMatch(
            status="selected",
            selected_meter={
                "currencyCode": defaults.get("currency", "USD"),
                "unitPrice": 0.10,
                "retailPrice": 0.10,
                "armRegionName": defaults.get("region"),
                "meterId": "app-service-meter",
                "meterName": item.get("meter_name"),
                "serviceName": item.get("service_name"),
                "serviceFamily": item.get("service_family"),
                "query": "test-query",
            },
        )
    return MeterMatch(status="unresolved", warning="No test meter configured.")


def _unresolved_price_lookup(item: dict, defaults: dict) -> MeterMatch:
    return MeterMatch(status="unresolved", warning="Azure Retail Prices API lookup skipped by test.")


def _workbook_sheet_names(path: Path) -> list[str]:
    namespace = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read("xl/workbook.xml"))
    return [sheet.attrib["name"] for sheet in root.findall("main:sheets/main:sheet", namespace)]


def _worksheet_rows(path: Path, sheet_index: int) -> list[list[str]]:
    namespace = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read(f"xl/worksheets/sheet{sheet_index}.xml"))
    rows: list[list[str]] = []
    for row in root.findall("main:sheetData/main:row", namespace):
        values_by_column: dict[int, str] = {}
        for cell in row.findall("main:c", namespace):
            column_index = _cell_column_index(cell.attrib["r"])
            inline = cell.find("main:is/main:t", namespace)
            value = cell.find("main:v", namespace)
            values_by_column[column_index] = inline.text if inline is not None else value.text if value is not None else ""
        max_column = max(values_by_column, default=0)
        rows.append([values_by_column.get(index, "") for index in range(1, max_column + 1)])
    return rows


def _worksheet_child_names(path: Path, sheet_index: int) -> list[str]:
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read(f"xl/worksheets/sheet{sheet_index}.xml"))
    return [child.tag.rsplit("}", 1)[-1] for child in root]


def _worksheet_outline_levels(path: Path, sheet_index: int) -> list[str]:
    namespace = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read(f"xl/worksheets/sheet{sheet_index}.xml"))
    return [row.attrib["outlineLevel"] for row in root.findall("main:sheetData/main:row", namespace) if "outlineLevel" in row.attrib]


def _worksheet_hidden_outline_rows(path: Path, sheet_index: int) -> list[str]:
    namespace = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read(f"xl/worksheets/sheet{sheet_index}.xml"))
    return [row.attrib["r"] for row in root.findall("main:sheetData/main:row", namespace) if row.attrib.get("outlineLevel") == "1" and row.attrib.get("hidden") == "1"]


def _worksheet_collapsed_rows(path: Path, sheet_index: int) -> list[str]:
    namespace = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read(f"xl/worksheets/sheet{sheet_index}.xml"))
    return [row.attrib["r"] for row in root.findall("main:sheetData/main:row", namespace) if row.attrib.get("collapsed") == "1"]


def _cell_column_index(reference: str) -> int:
    column = 0
    for char in reference:
        if not char.isalpha():
            break
        column = column * 26 + ord(char.upper()) - 64
    return column