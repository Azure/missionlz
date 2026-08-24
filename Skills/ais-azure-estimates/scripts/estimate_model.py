# /// script
# dependencies = [
#   "jsonschema>=4.20.0",
# ]
# requires-python = ">=3.10"
# ///

"""Shared model and validation helpers for AIS Azure estimates."""

from __future__ import annotations

import json
from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import jsonschema

SKILL_DIR = Path(__file__).resolve().parent.parent
INPUT_SCHEMA_PATH = SKILL_DIR / "assets" / "estimate-input.schema.json"
OUTPUT_SCHEMA_PATH = SKILL_DIR / "assets" / "estimate-output.schema.json"

CONFIDENCE_VALUES = {"high", "medium", "low", "unresolved"}
PRICING_SOURCE_VALUES = {"azure_retail_prices_api", "manual_override", "unresolved"}
USAGE_BASIS_VALUES = {"hourly", "monthly", "storage", "transaction", "one_time"}
DEFAULT_ESTIMATE_VALUES: dict[str, Any] = {
    "currency": "USD",
    "period_months": 12,
    "monthly_hours": 730,
    "provisioning_state": "Median expected provisioned state over the estimate period",
    "data_sizing_policy": "Use conservative high-end estimates when precise usage is unknown",
}

NON_AZURE_COST_KEYWORDS = (
    "labor",
    "labour",
    "o&m",
    "operations and maintenance",
    "support labor",
    "implementation service",
    "professional service",
    "managed service",
    "retainer",
    "incident response",
    "proposal labor",
)


@dataclass(frozen=True)
class ValidationIssue:
    """Structured validation issue returned by validation helpers."""

    severity: str
    code: str
    message: str
    path: str = ""

    def format(self) -> str:
        location = f" at {self.path}" if self.path else ""
        return f"{self.severity.upper()} {self.code}{location}: {self.message}"


def load_json(path: str | Path) -> dict[str, Any]:
    json_path = Path(path)
    with json_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"Expected a JSON object in {json_path}")
    return data


def load_schema(path: str | Path = INPUT_SCHEMA_PATH) -> dict[str, Any]:
    return load_json(path)


def validate_against_schema(
    data: dict[str, Any],
    schema_path: str | Path = INPUT_SCHEMA_PATH,
) -> list[ValidationIssue]:
    schema = load_schema(schema_path)
    validator = jsonschema.Draft7Validator(schema)
    issues: list[ValidationIssue] = []
    for error in sorted(validator.iter_errors(data), key=lambda item: list(item.path)):
        path = _format_path(error.path)
        issues.append(
            ValidationIssue(
                severity="error",
                code="schema_error",
                message=error.message,
                path=path,
            )
        )
    return issues


def validate_business_rules(data: dict[str, Any]) -> list[ValidationIssue]:
    issues: list[ValidationIssue] = []
    line_items = data.get("line_items", [])
    if not isinstance(line_items, list):
        return issues

    line_item_ids = {
        item.get("id")
        for item in line_items
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    overrides = {
        item.get("line_item_id"): item
        for item in data.get("manual_overrides", []) or []
        if isinstance(item, dict)
    }

    for index, item in enumerate(line_items):
        if not isinstance(item, dict):
            continue
        item_id = item.get("id", f"index-{index}")
        path = f"line_items[{index}]"
        pricing_source = item.get("pricing_source")

        if _looks_like_non_azure_cost(item):
            issues.append(
                ValidationIssue(
                    severity="error",
                    code="non_azure_cost",
                    path=path,
                    message=(
                        f"Line item '{item_id}' appears to describe labor, O&M, support, "
                        "or another non-Azure consumption cost."
                    ),
                )
            )

        if pricing_source in {"azure_retail_prices_api", "manual_override"}:
            for field_name in ("sizing_confidence", "pricing_confidence"):
                if item.get(field_name) in {None, "", "unresolved"}:
                    issues.append(
                        ValidationIssue(
                            severity="error",
                            code="missing_confidence",
                            path=f"{path}.{field_name}",
                            message=(
                                f"Priced line item '{item_id}' requires a resolved "
                                f"{field_name.replace('_', ' ')} value."
                            ),
                        )
                    )

        if pricing_source == "manual_override" and item_id not in overrides:
            issues.append(
                ValidationIssue(
                    severity="error",
                    code="missing_manual_override",
                    path=path,
                    message=f"Line item '{item_id}' requires a matching manual override.",
                )
            )

        if pricing_source == "unresolved":
            issues.append(
                ValidationIssue(
                    severity="warning",
                    code="unresolved_pricing",
                    path=path,
                    message=f"Line item '{item_id}' is unresolved and must be excluded from totals.",
                )
            )

    for index, override in enumerate(data.get("manual_overrides", []) or []):
        if not isinstance(override, dict):
            continue
        override_id = override.get("line_item_id")
        path = f"manual_overrides[{index}]"
        if override_id not in line_item_ids:
            issues.append(
                ValidationIssue(
                    severity="error",
                    code="orphan_manual_override",
                    path=path,
                    message=f"Manual override references unknown line item '{override_id}'.",
                )
            )
        for field_name in ("source_note", "rationale", "sizing_confidence", "pricing_confidence"):
            if override.get(field_name) in {None, ""}:
                issues.append(
                    ValidationIssue(
                        severity="error",
                        code="invalid_manual_override",
                        path=f"{path}.{field_name}",
                        message=f"Manual override for '{override_id}' requires {field_name}.",
                    )
                )

    return issues


def validate_estimate(data: dict[str, Any]) -> list[ValidationIssue]:
    return validate_against_schema(data) + validate_business_rules(data)


def apply_defaults(data: dict[str, Any]) -> dict[str, Any]:
    normalized = deepcopy(data)
    defaults = normalized.setdefault("defaults", {})
    for key, value in DEFAULT_ESTIMATE_VALUES.items():
        defaults.setdefault(key, value)
    return normalized


def build_caveats(
    defaults: dict[str, Any],
    line_items: list[dict[str, Any]],
    manual_overrides: list[dict[str, Any]],
    assumptions: list[dict[str, Any]],
    exclusions: list[str],
) -> list[dict[str, Any]]:
    caveats: list[dict[str, Any]] = []
    corpus = _caveat_corpus(defaults, line_items, assumptions, exclusions)
    cloud = str(defaults.get("cloud", ""))
    region = str(defaults.get("region", ""))

    if cloud == "AzureGovernment" or region.startswith("usgov"):
        _add_caveat(
            caveats,
            "azure_government",
            "Azure Government pricing context",
            f"Azure Government estimate uses {cloud or 'AzureGovernment'} / {region or 'unspecified region'}; public retail meter availability may differ from commercial Azure and requires Azure solution architect review.",
        )
        _add_caveat(
            caveats,
            "availability",
            "Government meter availability",
            "Azure Government service availability and Retail Prices API meter coverage must be confirmed for unresolved or manually overridden items.",
        )

    retention_policy = defaults.get("retention_policy")
    if isinstance(retention_policy, dict):
        nist_text = " NIST SP 800-53-aligned retention planning assumption." if retention_policy.get("nist_800_53_aligned") else ""
        _add_caveat(
            caveats,
            "retention_policy",
            "Retention assumption",
            f"Retention assumes {retention_policy.get('duration_days', 'unspecified')} days based on {retention_policy.get('basis', 'provided planning assumptions')}.{nist_text}",
        )

    data_sizing_policy = defaults.get("data_sizing_policy")
    if data_sizing_policy:
        _add_caveat(
            caveats,
            "data_sizing_policy",
            "Conservative data sizing",
            f"Data sizing uses conservative high-end data volume assumptions until workload telemetry is available: {data_sizing_policy}.",
        )

    if manual_overrides:
        details = [
            f"{override.get('line_item_id')}: {override.get('source_note', 'source note required')}"
            for override in manual_overrides
        ]
        _add_caveat(
            caveats,
            "manual_override",
            "Manual override pricing",
            "Manual override pricing is used for Azure consumption items and requires source-note and rationale review before external use.",
            details,
        )

    keyword_caveats = [
        ("azure_government_secret", "Azure Government Secret", "Azure Government Secret availability and pricing require separate confirmation.", "secret"),
        ("gpu_specialized_sku", "GPU and specialized SKU", "GPU, high-memory, specialty networking, and constrained-region SKUs may have availability or quota limits.", "gpu"),
        ("marketplace", "Marketplace items", "Marketplace and third-party items require a valid Azure consumption meter or documented manual override before inclusion.", "marketplace"),
        ("reserved_instance", "Reserved instances", "Reserved-instance assumptions are out of scope for the MVP and are excluded from totals unless explicitly approved later.", "reserved"),
        ("savings_plan", "Savings plans", "Savings-plan assumptions are out of scope for the MVP and are excluded from totals unless explicitly approved later.", "savings plan"),
        ("customer_discount", "Customer agreement pricing", "Customer agreement pricing and customer-specific discounts are out of scope; public retail estimates are not customer agreement pricing.", "customer agreement"),
    ]
    for code, title, message, keyword in keyword_caveats:
        if keyword in corpus:
            _add_caveat(caveats, code, title, message)

    return caveats


def split_issues(issues: list[ValidationIssue]) -> tuple[list[ValidationIssue], list[ValidationIssue]]:
    errors = [issue for issue in issues if issue.severity == "error"]
    warnings = [issue for issue in issues if issue.severity == "warning"]
    return errors, warnings


def _add_caveat(
    caveats: list[dict[str, Any]],
    code: str,
    title: str,
    message: str,
    details: list[str] | None = None,
) -> None:
    if any(caveat["code"] == code for caveat in caveats):
        return
    caveat: dict[str, Any] = {"code": code, "title": title, "message": message}
    if details:
        caveat["details"] = details
    caveats.append(caveat)


def _caveat_corpus(
    defaults: dict[str, Any],
    line_items: list[dict[str, Any]],
    assumptions: list[dict[str, Any]],
    exclusions: list[str],
) -> str:
    parts: list[str] = [json.dumps(defaults)]
    parts.extend(json.dumps(item) for item in line_items)
    parts.extend(json.dumps(item) for item in assumptions)
    parts.extend(str(item) for item in exclusions)
    return " ".join(parts).lower()


def _format_path(path_parts: Any) -> str:
    parts = list(path_parts)
    if not parts:
        return "$"
    output = "$"
    for part in parts:
        if isinstance(part, int):
            output += f"[{part}]"
        else:
            output += f".{part}"
    return output


def _looks_like_non_azure_cost(item: dict[str, Any]) -> bool:
    text = " ".join(
        str(item.get(field_name, ""))
        for field_name in ("id", "name", "service_name", "service_family", "sku_name", "notes")
    ).lower()
    return any(keyword in text for keyword in NON_AZURE_COST_KEYWORDS)