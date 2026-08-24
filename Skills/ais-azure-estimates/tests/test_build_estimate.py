from __future__ import annotations

from copy import deepcopy
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

from azure_prices import MeterMatch, build_filter, fetch_prices, resolve_meter  # noqa: E402
from build_estimate import build_estimate_output, expand_workload_templates, normalize_estimate  # noqa: E402
from estimate_model import load_json  # noqa: E402


SKILL_DIR = Path(__file__).resolve().parents[1]
VIRTUALITICS_SAMPLE = SKILL_DIR / "examples" / "virtualitics-alz.sample.json"


def test_dimension_expansion_preserves_source_dimensions() -> None:
    normalized = normalize_estimate(load_json(VIRTUALITICS_SAMPLE))
    aks_rows = [
        item
        for item in normalized["normalized_line_items"]
        if item["source_line_item_id"] == "aks-system-node-pool"
    ]

    assert len(aks_rows) == 3
    assert {tuple(sorted(row["source_dimensions"].items())) for row in aks_rows} == {
        (("environment", "shared"), ("impact_level", "IL4")),
        (("environment", "shared"), ("impact_level", "IL5")),
        (("environment", "shared"), ("impact_level", "IL6")),
    }

    storage_rows = [
        item
        for item in normalized["normalized_line_items"]
        if item["source_line_item_id"] == "storage-hot-data" and item["source_dimensions"]["impact_level"] == "IL4"
    ]
    assert {row["source_dimensions"]["environment"]: row["quantity"] for row in storage_rows} == {
        "dev": 512,
        "test": 1024,
        "prod": 2048,
    }


def test_app_service_workload_template_expands_to_resource_line_items() -> None:
    generated = expand_workload_templates(
        {
            "defaults": {"cloud": "AzureCloud", "region": "eastus"},
            "workload_templates": [
                {
                    "id": "web-workload",
                    "type": "app_service_workload",
                    "applies_to": {"environment": ["dev", "prod"]},
                    "parameters": {
                        "app_service_instances": 2,
                        "storage_gb": 512,
                        "database_vcores": 2,
                        "log_ingestion_gb_per_month": 100,
                        "key_vault_operations": 10000,
                        "network_egress_gb_per_month": 100,
                        "backup_protected_instances": 2,
                    },
                }
            ],
        }
    )

    assert {item["service_name"] for item in generated} == {
        "App Service",
        "Storage",
        "Azure SQL Database",
        "Log Analytics",
        "Key Vault",
        "Bandwidth",
        "Azure Backup",
    }
    assert all(item["source_template_id"] == "web-workload" for item in generated)
    assert all(item["pricing_source"] == "unresolved" for item in generated)


def test_normalized_input_includes_defaults_and_line_item_groups() -> None:
    normalized = normalize_estimate(load_json(VIRTUALITICS_SAMPLE))

    assert normalized["defaults"]["cloud"] == "AzureGovernment"
    assert normalized["defaults"]["region"] == "usgovvirginia"
    assert len(normalized["authored_line_items"]) == 14
    assert len(normalized["generated_line_items"]) == 0
    assert len(normalized["normalized_line_items"]) == 114


def test_retail_prices_filter_includes_core_meter_fields() -> None:
    sample = load_json(VIRTUALITICS_SAMPLE)
    line_item = sample["line_items"][0]
    filter_expression = build_filter(line_item, sample["defaults"])

    assert "armRegionName eq 'usgovvirginia'" in filter_expression
    assert "serviceName eq 'Virtual Machines'" in filter_expression
    assert "meterName eq 'D4s v5'" in filter_expression
    assert "priceType eq 'Consumption'" in filter_expression


def test_retail_prices_fetch_follows_pagination() -> None:
    pages = {
        "first": {"Items": [{"meterId": "one"}], "NextPageLink": "second"},
        "second": {"Items": [{"meterId": "two"}], "NextPageLink": None},
    }

    def opener(url: str, _timeout: int) -> dict:
        return pages["second"] if url == "second" else pages["first"]

    assert [item["meterId"] for item in fetch_prices("serviceName eq 'App Service'", opener=opener)] == ["one", "two"]


def test_meter_resolution_selects_single_reliable_match() -> None:
    sample = load_json(VIRTUALITICS_SAMPLE)
    line_item = sample["line_items"][0]
    match = resolve_meter(
        line_item,
        sample["defaults"],
        [
            {
                "currencyCode": "USD",
                "unitPrice": 0.25,
                "armRegionName": "usgovvirginia",
                "meterId": "meter-1",
                "meterName": "D4s v5",
                "serviceName": "Virtual Machines",
                "serviceFamily": "Compute",
                "skuName": "D4s v5 Linux VM planning placeholder",
                "armSkuName": "Standard_D4s_v5",
                "type": "Consumption",
            }
        ],
    )

    assert match.status == "selected"
    assert match.selected_meter is not None
    assert match.selected_meter["meterId"] == "meter-1"
    assert "query" in match.selected_meter


def test_meter_resolution_flags_ambiguous_matches() -> None:
    sample = load_json(VIRTUALITICS_SAMPLE)
    line_item = sample["line_items"][0]
    meter = {
        "unitPrice": 0.25,
        "armRegionName": "usgovvirginia",
        "meterName": "D4s v5",
        "serviceName": "Virtual Machines",
        "serviceFamily": "Compute",
        "skuName": "D4s v5 Linux VM planning placeholder",
        "armSkuName": "Standard_D4s_v5",
        "type": "Consumption",
    }

    match = resolve_meter(line_item, sample["defaults"], [dict(meter, meterId="one"), dict(meter, meterId="two")])

    assert match.status == "ambiguous"
    assert match.selected_meter is None


def test_build_estimate_applies_manual_overrides_and_cost_math() -> None:
    sample = load_json(VIRTUALITICS_SAMPLE)
    output = build_estimate_output(sample, VIRTUALITICS_SAMPLE, price_lookup=_fake_price_lookup)
    log_item = next(
        item
        for item in output["line_items"]
        if item["source_line_item_id"] == "log-analytics-ingestion"
        and item["source_dimensions"] == {"environment": "prod", "impact_level": "IL4"}
    )

    assert log_item["pricing_source"] == "manual_override"
    assert log_item["unit_price"] == 2.76
    assert log_item["monthly_cost"] == 690.0
    assert log_item["annual_cost"] == 8280.0
    assert log_item["included_in_total"] is True


def test_build_estimate_excludes_unresolved_items_from_totals() -> None:
    sample = deepcopy(load_json(VIRTUALITICS_SAMPLE))
    sample["line_items"][0]["pricing_source"] = "unresolved"
    output = build_estimate_output(sample, VIRTUALITICS_SAMPLE, price_lookup=_fake_price_lookup)
    unresolved = [item for item in output["line_items"] if not item["included_in_total"]]

    assert unresolved
    assert output["totals"]["excluded_unresolved_count"] == len(unresolved)
    assert any(warning["code"] in {"unresolved_pricing", "ambiguous_meter"} for warning in output["warnings"])


def _fake_price_lookup(item: dict, defaults: dict) -> MeterMatch:
    if item.get("source_template_id"):
        return MeterMatch(status="unresolved", warning="Generated template item requires manual meter selection.")
    if item.get("service_name") == "App Service":
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