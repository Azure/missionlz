from __future__ import annotations

import copy
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

from estimate_model import load_json, split_issues, validate_estimate  # noqa: E402


SKILL_DIR = Path(__file__).resolve().parents[1]
GENERIC_SAMPLE = SKILL_DIR / "examples" / "generic-app-service.sample.json"
VIRTUALITICS_SAMPLE = SKILL_DIR / "examples" / "virtualitics-alz.sample.json"


def test_generic_sample_is_valid() -> None:
    errors, warnings = split_issues(validate_estimate(load_json(GENERIC_SAMPLE)))

    assert errors == []
    assert warnings == []


def test_virtualitics_sample_is_valid_without_unresolved_pricing_warnings() -> None:
    errors, warnings = split_issues(validate_estimate(load_json(VIRTUALITICS_SAMPLE)))

    assert errors == []
    assert warnings == []


def test_missing_pricing_confidence_fails_schema_validation() -> None:
    data = copy.deepcopy(load_json(GENERIC_SAMPLE))
    del data["line_items"][0]["pricing_confidence"]

    errors, _warnings = split_issues(validate_estimate(data))

    assert any(error.code == "schema_error" for error in errors)


def test_manual_override_requires_source_note() -> None:
    data = copy.deepcopy(load_json(VIRTUALITICS_SAMPLE))
    data["manual_overrides"][0]["source_note"] = ""

    errors, _warnings = split_issues(validate_estimate(data))

    assert any(error.code in {"schema_error", "invalid_manual_override"} for error in errors)


def test_manual_override_requires_rationale() -> None:
    data = copy.deepcopy(load_json(VIRTUALITICS_SAMPLE))
    data["manual_overrides"][0]["rationale"] = ""

    errors, _warnings = split_issues(validate_estimate(data))

    assert any(error.code in {"schema_error", "invalid_manual_override"} for error in errors)


def test_non_azure_cost_is_rejected() -> None:
    data = copy.deepcopy(load_json(GENERIC_SAMPLE))
    data["line_items"].append(
        {
            "id": "implementation-support",
            "name": "Implementation support labor",
            "service_name": "Professional Services",
            "quantity": 1,
            "unit": "month",
            "usage_basis": "monthly",
            "pricing_source": "manual_override",
            "sizing_confidence": "medium",
            "pricing_confidence": "medium",
            "notes": "Non-Azure labor must not enter the consumption estimate.",
        }
    )
    data["manual_overrides"] = [
        {
            "line_item_id": "implementation-support",
            "unit_price": 1000,
            "currency": "USD",
            "unit_of_measure": "month",
            "source_note": "Example",
            "rationale": "Example",
            "sizing_confidence": "medium",
            "pricing_confidence": "medium",
        }
    ]

    errors, _warnings = split_issues(validate_estimate(data))
    assert any(error.code == "non_azure_cost" for error in errors)