# /// script
# dependencies = [
#   "jsonschema>=4.20.0",
# ]
# requires-python = ">=3.10"
# ///

"""Build AIS Azure estimate outputs from structured inputs."""

from __future__ import annotations

import argparse
import itertools
import json
import sys
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from azure_prices import MeterMatch, lookup_meter
from estimate_model import apply_defaults, build_caveats, load_json, split_issues, validate_estimate
from render_estimate import render_outputs

TOOL_VERSION = "0.1"


def normalize_estimate(data: dict[str, Any]) -> dict[str, Any]:
    estimate = apply_defaults(data)
    authored_line_items = estimate.get("line_items", [])
    generated_line_items = expand_workload_templates(estimate)
    combined_line_items = [*authored_line_items, *generated_line_items]

    return {
        "schema_version": estimate.get("schema_version"),
        "estimate": estimate.get("estimate", {}),
        "defaults": estimate.get("defaults", {}),
        "dimensions": estimate.get("dimensions", []),
        "assumptions": estimate.get("assumptions", []),
        "exclusions": estimate.get("exclusions", []),
        "authored_line_items": authored_line_items,
        "generated_line_items": generated_line_items,
        "normalized_line_items": expand_line_items(combined_line_items, estimate.get("dimensions", [])),
    }


def expand_workload_templates(estimate: dict[str, Any]) -> list[dict[str, Any]]:
    generated: list[dict[str, Any]] = []
    defaults = estimate.get("defaults", {})
    for template in estimate.get("workload_templates", []) or []:
        if template.get("type") != "app_service_workload":
            continue
        template_id = template.get("id", "app-service-workload")
        parameters = template.get("parameters", {})
        applies_to = template.get("applies_to", {})
        generated.extend(
            [
                _generated_line_item(
                    template_id,
                    "app-service-compute",
                    "App Service compute",
                    "App Service",
                    "Compute",
                    parameters.get("app_service_instances", 1),
                    "instance-hour",
                    "hourly",
                    applies_to,
                    defaults,
                ),
                _generated_line_item(
                    template_id,
                    "storage",
                    "Application data storage",
                    "Storage",
                    "Storage",
                    parameters.get("storage_gb", 0),
                    "GB-month",
                    "storage",
                    applies_to,
                    defaults,
                ),
                _generated_line_item(
                    template_id,
                    "managed-database",
                    "Managed database compute",
                    "Azure SQL Database",
                    "Databases",
                    parameters.get("database_vcores", 0),
                    "vCore-hour",
                    "hourly",
                    applies_to,
                    defaults,
                ),
                _generated_line_item(
                    template_id,
                    "log-ingestion",
                    "Log Analytics ingestion",
                    "Log Analytics",
                    "Management and Governance",
                    parameters.get("log_ingestion_gb_per_month", 0),
                    "GB",
                    "monthly",
                    applies_to,
                    defaults,
                ),
                _generated_line_item(
                    template_id,
                    "key-vault-operations",
                    "Key Vault operations",
                    "Key Vault",
                    "Security",
                    parameters.get("key_vault_operations", 10000),
                    "operations",
                    "transaction",
                    applies_to,
                    defaults,
                ),
                _generated_line_item(
                    template_id,
                    "network-egress",
                    "Network egress",
                    "Bandwidth",
                    "Networking",
                    parameters.get("network_egress_gb_per_month", 0),
                    "GB",
                    "monthly",
                    applies_to,
                    defaults,
                ),
                _generated_line_item(
                    template_id,
                    "backup",
                    "Backup protected instances",
                    "Azure Backup",
                    "Storage",
                    parameters.get("backup_protected_instances", 0),
                    "instance-month",
                    "monthly",
                    applies_to,
                    defaults,
                ),
            ]
        )
    return generated


def expand_line_items(line_items: list[dict[str, Any]], global_dimensions: list[dict[str, Any]] | None = None) -> list[dict[str, Any]]:
    expanded: list[dict[str, Any]] = []
    for item in line_items:
        dimension_sets = _dimension_combinations(_effective_dimensions(item.get("dimensions", {}), global_dimensions or []))
        for index, dimensions in enumerate(dimension_sets, start=1):
            row = deepcopy(item)
            source_id = str(item.get("id"))
            row["source_line_item_id"] = source_id
            row["source_dimensions"] = dimensions
            row["id"] = source_id if len(dimension_sets) == 1 else f"{source_id}-{index}"
            _apply_dimension_overrides(row, dimensions)
            row.pop("dimensions", None)
            row.pop("dimension_overrides", None)
            expanded.append(row)
    return expanded


def _effective_dimensions(item_dimensions: dict[str, Any], global_dimensions: list[dict[str, Any]]) -> dict[str, Any]:
    dimensions = deepcopy(item_dimensions)
    for dimension in global_dimensions:
        name = dimension.get("name")
        values = dimension.get("values")
        if name and values and name not in dimensions:
            dimensions[name] = values
    return dimensions


def _apply_dimension_overrides(row: dict[str, Any], dimensions: dict[str, str]) -> None:
    for override in row.get("dimension_overrides", []) or []:
        match = override.get("match", {})
        if not all(str(dimensions.get(name)) == str(value) for name, value in match.items()):
            continue
        for field in (
            "quantity",
            "unit_price",
            "sku_name",
            "arm_sku_name",
            "meter_name",
            "sizing_confidence",
            "pricing_confidence",
        ):
            if field in override:
                row[field] = override[field]
        if override.get("notes"):
            row["notes"] = _append_note(str(row.get("notes", "")), str(override["notes"]))


def build_estimate_output(
    data: dict[str, Any],
    input_path: str | Path,
    command: str = "",
    price_lookup: Any | None = None,
) -> dict[str, Any]:
    normalized = normalize_estimate(data)
    defaults = normalized.get("defaults", {})
    line_items: list[dict[str, Any]] = []
    warnings: list[dict[str, str]] = []
    overrides = {
        override["line_item_id"]: override
        for override in data.get("manual_overrides", []) or []
        if isinstance(override, dict) and "line_item_id" in override
    }

    for item in normalized["normalized_line_items"]:
        priced_item, item_warnings = _price_line_item(item, defaults, overrides, price_lookup)
        line_items.append(priced_item)
        warnings.extend(item_warnings)

    monthly_total = round(sum(item.get("monthly_cost") or 0 for item in line_items if item["included_in_total"]), 2)
    annual_total = round(sum(item.get("annual_cost") or 0 for item in line_items if item["included_in_total"]), 2)
    return {
        "schema_version": "1.0",
        "run": {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "input_path": str(input_path),
            "tool_version": TOOL_VERSION,
            "command": command,
        },
        "normalized_input": normalized,
        "totals": {
            "currency": defaults.get("currency", "USD"),
            "monthly_total": monthly_total,
            "annual_total": annual_total,
            "excluded_unresolved_count": sum(1 for item in line_items if not item["included_in_total"]),
        },
        "line_items": line_items,
        "warnings": warnings,
        "caveats": build_caveats(defaults, line_items, data.get("manual_overrides", []) or [], normalized.get("assumptions", []), normalized.get("exclusions", [])),
        "artifacts": {
            "estimate_section_md": "",
            "estimate_review_md": "",
            "line_items_csv": "",
            "estimate_workbook_xlsx": "",
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Path to estimate input JSON")
    parser.add_argument("--output-dir", help="Directory for estimate output artifacts")
    parser.add_argument("--overwrite", action="store_true", help="Explicitly allow replacing generated artifacts")
    parser.add_argument("--print-normalized", action="store_true", help="Print normalized input JSON")
    parser.add_argument("--skip-api", action="store_true", help="Do not call Azure Retail Prices API; mark API-priced items unresolved")
    args = parser.parse_args()

    input_path = Path(args.input)
    data = load_json(input_path)
    errors, warnings = split_issues(validate_estimate(data))
    for warning in warnings:
        print(warning.format(), file=sys.stderr)
    if errors:
        for error in errors:
            print(error.format(), file=sys.stderr)
        return 1

    if args.output_dir:
        price_lookup = None if not args.skip_api else _skip_api_lookup
        estimate_output = build_estimate_output(data, input_path, " ".join(sys.argv), price_lookup=price_lookup)
        paths = render_outputs(estimate_output, args.output_dir, overwrite=args.overwrite)
        print(
            "Generated estimate artifacts: "
            f"{paths['estimate_section_md']}, {paths['estimate_review_md']}, "
            f"{paths['line_items_csv']}, {paths['estimate_workbook_xlsx']}, "
            f"{paths['estimate_audit_json']}"
        )
        print(
            f"Monthly total {estimate_output['totals']['currency']} {estimate_output['totals']['monthly_total']:.2f}; "
            f"excluded unresolved {estimate_output['totals']['excluded_unresolved_count']} item(s)."
        )
        return 0

    normalized = normalize_estimate(data)
    if args.print_normalized:
        print(json.dumps(normalized, indent=2))
    else:
        print(
            "Normalized "
            f"{len(normalized['authored_line_items'])} authored, "
            f"{len(normalized['generated_line_items'])} generated, and "
            f"{len(normalized['normalized_line_items'])} expanded line item(s)."
        )
    return 0


def _price_line_item(
    item: dict[str, Any],
    defaults: dict[str, Any],
    overrides: dict[str, dict[str, Any]],
    price_lookup: Any | None,
) -> tuple[dict[str, Any], list[dict[str, str]]]:
    pricing_source = item.get("pricing_source")
    line_item_id = item.get("source_line_item_id") or item.get("id")
    warnings: list[dict[str, str]] = []
    output = _base_output_line_item(item, defaults)

    if pricing_source == "manual_override":
        override = overrides.get(str(line_item_id))
        if not override:
            return _exclude(output, "manual_override_missing", "Manual override was not found."), [
                _warning("manual_override_missing", output["id"], "Manual override was not found.")
            ]
        unit_price = float(item.get("unit_price", override["unit_price"]))
        output.update(
            {
                "unit_price": unit_price,
                "monthly_cost": _monthly_cost(item, unit_price, defaults),
                "pricing_source": "manual_override",
                "sizing_confidence": override.get("sizing_confidence", output["sizing_confidence"]),
                "pricing_confidence": override.get("pricing_confidence", output["pricing_confidence"]),
                "notes": _append_note(output.get("notes", ""), f"Manual override: {override.get('source_note', '')}"),
                "included_in_total": True,
            }
        )
        output["annual_cost"] = _annual_cost(item, output["monthly_cost"], defaults)
        return output, warnings

    if pricing_source == "azure_retail_prices_api":
        match = price_lookup(item, defaults) if price_lookup else lookup_meter(item, defaults)
        if match.status == "selected" and match.selected_meter:
            unit_price = float(match.selected_meter.get("unitPrice") or match.selected_meter.get("retailPrice") or 0)
            output.update(
                {
                    "unit_price": unit_price,
                    "monthly_cost": _monthly_cost(item, unit_price, defaults),
                    "annual_cost": None,
                    "pricing_source": "azure_retail_prices_api",
                    "selected_meter": match.selected_meter,
                    "included_in_total": True,
                }
            )
            output["annual_cost"] = _annual_cost(item, output["monthly_cost"], defaults)
            return output, warnings
        warning_code = "ambiguous_meter" if match.status == "ambiguous" else "unresolved_pricing"
        warning_message = match.warning or "Retail Prices API pricing could not be resolved."
        return _exclude(output, warning_code, warning_message), [_warning(warning_code, output["id"], warning_message)]

    return _exclude(output, "unresolved_pricing", "Line item is marked unresolved."), [
        _warning("unresolved_pricing", output["id"], "Line item is marked unresolved and excluded from totals.")
    ]


def _base_output_line_item(item: dict[str, Any], defaults: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": str(item.get("id")),
        "source_line_item_id": str(item.get("source_line_item_id", item.get("id"))),
        "source_dimensions": item.get("source_dimensions", {}),
        "name": str(item.get("name", item.get("id", "Unnamed line item"))),
        "service_name": str(item.get("service_name", "")),
        "service_family": str(item.get("service_family", "")),
        "sku_name": str(item.get("sku_name", "")),
        "region": str(item.get("region") or defaults.get("region", "")),
        "quantity": float(item.get("quantity", 0)),
        "unit": str(item.get("unit", "")),
        "unit_price": None,
        "monthly_cost": None,
        "annual_cost": None,
        "pricing_source": str(item.get("pricing_source", "unresolved")),
        "sizing_confidence": str(item.get("sizing_confidence", "unresolved")),
        "pricing_confidence": str(item.get("pricing_confidence", "unresolved")),
        "included_in_total": False,
        "selected_meter": None,
        "notes": _line_item_notes(item, defaults),
    }


def _line_item_notes(item: dict[str, Any], defaults: dict[str, Any]) -> str:
    notes = str(item.get("notes", ""))
    data_sizing_policy = defaults.get("data_sizing_policy")
    if data_sizing_policy:
        notes = _append_note(notes, f"Data sizing policy: {data_sizing_policy}.")
    retention_policy = defaults.get("retention_policy")
    if isinstance(retention_policy, dict):
        retention_note = f"Retention policy: {retention_policy.get('duration_days', 'unspecified')} days; {retention_policy.get('basis', 'planning assumption')}"
        if retention_policy.get("nist_800_53_aligned"):
            retention_note += "; NIST SP 800-53-aligned retention assumption"
        notes = _append_note(notes, retention_note + ".")
    return notes


def _monthly_cost(item: dict[str, Any], unit_price: float, defaults: dict[str, Any]) -> float:
    quantity = float(item.get("quantity", 0))
    usage_basis = item.get("usage_basis")
    if usage_basis == "hourly":
        return round(quantity * unit_price * float(defaults.get("monthly_hours", 730)), 2)
    return round(quantity * unit_price, 2)


def _annual_cost(item: dict[str, Any], monthly_cost: float | None, defaults: dict[str, Any]) -> float | None:
    if monthly_cost is None:
        return None
    if item.get("usage_basis") == "one_time":
        return round(monthly_cost, 2)
    return round(monthly_cost * int(defaults.get("period_months", 12)), 2)


def _exclude(output: dict[str, Any], code: str, message: str) -> dict[str, Any]:
    output["included_in_total"] = False
    output["unit_price"] = None
    output["monthly_cost"] = None
    output["annual_cost"] = None
    output["notes"] = _append_note(output.get("notes", ""), message)
    if code == "ambiguous_meter":
        output["pricing_source"] = "unresolved"
    return output


def _warning(code: str, line_item_id: str, message: str) -> dict[str, str]:
    return {"code": code, "line_item_id": line_item_id, "message": message}


def _append_note(existing: str, addition: str) -> str:
    if not existing:
        return addition
    if not addition:
        return existing
    return f"{existing} {addition}"


def _skip_api_lookup(_item: dict[str, Any], _defaults: dict[str, Any]) -> MeterMatch:
    return MeterMatch(status="unresolved", warning="Azure Retail Prices API lookup skipped by --skip-api.")


def _generated_line_item(
    template_id: str,
    suffix: str,
    name: str,
    service_name: str,
    service_family: str,
    quantity: int | float,
    unit: str,
    usage_basis: str,
    dimensions: dict[str, Any],
    defaults: dict[str, Any],
) -> dict[str, Any]:
    return {
        "id": f"{template_id}-{suffix}",
        "source_template_id": template_id,
        "name": name,
        "service_name": service_name,
        "service_family": service_family,
        "region": defaults.get("region"),
        "quantity": quantity,
        "unit": unit,
        "usage_basis": usage_basis,
        "dimensions": dimensions,
        "pricing_source": "unresolved",
        "sizing_confidence": "low",
        "pricing_confidence": "unresolved",
        "notes": "Generated from app_service_workload template; select meter or manual override before pricing.",
    }


def _dimension_combinations(dimensions: dict[str, Any]) -> list[dict[str, str]]:
    if not dimensions:
        return [{}]
    names = sorted(dimensions)
    values: list[list[str]] = []
    for name in names:
        raw_value = dimensions[name]
        if isinstance(raw_value, list):
            values.append([str(value) for value in raw_value])
        else:
            values.append([str(raw_value)])
    return [dict(zip(names, combination, strict=True)) for combination in itertools.product(*values)]


if __name__ == "__main__":
    raise SystemExit(main())