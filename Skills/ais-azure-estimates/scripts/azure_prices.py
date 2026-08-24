# /// script
# dependencies = []
# requires-python = ">=3.10"
# ///

"""Azure Retail Prices API lookup helpers for AIS Azure estimates."""

from __future__ import annotations

import json
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any, Callable

PRICES_ENDPOINT = "https://prices.azure.com/api/retail/prices"
SELECTED_METER_FIELDS = (
    "currencyCode",
    "retailPrice",
    "unitPrice",
    "armRegionName",
    "location",
    "effectiveStartDate",
    "meterId",
    "meterName",
    "productName",
    "skuName",
    "serviceName",
    "serviceFamily",
    "unitOfMeasure",
    "type",
    "armSkuName",
)


@dataclass(frozen=True)
class MeterMatch:
    status: str
    selected_meter: dict[str, Any] | None = None
    warning: str | None = None
    candidates: int = 0


def build_filter(line_item: dict[str, Any], defaults: dict[str, Any]) -> str:
    clauses = ["priceType eq 'Consumption'"]
    region = line_item.get("region") or defaults.get("region")
    if region:
        clauses.append(f"armRegionName eq '{_escape_filter_value(str(region))}'")
    for field_name in ("serviceName", "serviceFamily", "skuName", "armSkuName", "meterName"):
        item_key = _retail_field_to_line_item_key(field_name)
        value = line_item.get(item_key)
        if value:
            clauses.append(f"{field_name} eq '{_escape_filter_value(str(value))}'")
    return " and ".join(clauses)


def build_query_url(filter_expression: str, currency: str = "USD") -> str:
    params = {
        "$filter": filter_expression,
        "currencyCode": currency,
    }
    return f"{PRICES_ENDPOINT}?{urllib.parse.urlencode(params)}"


def fetch_prices(
    filter_expression: str,
    currency: str = "USD",
    timeout: int = 30,
    opener: Callable[[str, int], dict[str, Any]] | None = None,
) -> list[dict[str, Any]]:
    url = build_query_url(filter_expression, currency)
    items: list[dict[str, Any]] = []
    while url:
        payload = opener(url, timeout) if opener else _open_json(url, timeout)
        values = payload.get("Items", [])
        if isinstance(values, list):
            items.extend(item for item in values if isinstance(item, dict))
        next_link = payload.get("NextPageLink")
        url = next_link if isinstance(next_link, str) and next_link else ""
    return items


def resolve_meter(
    line_item: dict[str, Any],
    defaults: dict[str, Any],
    meters: list[dict[str, Any]],
) -> MeterMatch:
    if not meters:
        return MeterMatch(status="unresolved", warning="No Retail Prices API meters matched the query.")

    ranked = sorted(
        ((_score_meter(line_item, defaults, meter), meter) for meter in meters),
        key=lambda item: item[0],
        reverse=True,
    )
    best_score = ranked[0][0]
    best_meters = [meter for score, meter in ranked if score == best_score]
    if best_score < 3:
        return MeterMatch(
            status="unresolved",
            warning="Retail Prices API returned meters, but none matched enough line-item metadata.",
            candidates=len(meters),
        )
    if len(best_meters) > 1:
        return MeterMatch(
            status="ambiguous",
            warning=f"Retail Prices API returned {len(best_meters)} equally plausible meters.",
            candidates=len(best_meters),
        )
    return MeterMatch(
        status="selected",
        selected_meter=select_meter_metadata(best_meters[0], build_filter(line_item, defaults)),
        candidates=len(meters),
    )


def lookup_meter(
    line_item: dict[str, Any],
    defaults: dict[str, Any],
    timeout: int = 30,
) -> MeterMatch:
    filter_expression = build_filter(line_item, defaults)
    meters = fetch_prices(filter_expression, str(defaults.get("currency", "USD")), timeout=timeout)
    return resolve_meter(line_item, defaults, meters)


def select_meter_metadata(meter: dict[str, Any], query: str) -> dict[str, Any]:
    selected = {field: meter[field] for field in SELECTED_METER_FIELDS if field in meter}
    selected["query"] = query
    return selected


def _open_json(url: str, timeout: int) -> dict[str, Any]:
    with urllib.request.urlopen(url, timeout=timeout) as response:  # noqa: S310 - public Microsoft pricing endpoint.
        payload = json.loads(response.read().decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("Azure Retail Prices API returned a non-object payload")
    return payload


def _score_meter(line_item: dict[str, Any], defaults: dict[str, Any], meter: dict[str, Any]) -> int:
    score = 0
    expected_region = (line_item.get("region") or defaults.get("region") or "").lower()
    if expected_region and str(meter.get("armRegionName", "")).lower() == expected_region:
        score += 2
    for line_key, meter_key in (
        ("service_name", "serviceName"),
        ("service_family", "serviceFamily"),
        ("sku_name", "skuName"),
        ("arm_sku_name", "armSkuName"),
        ("meter_name", "meterName"),
    ):
        expected = str(line_item.get(line_key, "")).lower()
        actual = str(meter.get(meter_key, "")).lower()
        if expected and actual == expected:
            score += 2
        elif expected and expected in actual:
            score += 1
    if str(meter.get("type", "")).lower() == "consumption":
        score += 1
    return score


def _retail_field_to_line_item_key(field_name: str) -> str:
    return {
        "serviceName": "service_name",
        "serviceFamily": "service_family",
        "skuName": "sku_name",
        "armSkuName": "arm_sku_name",
        "meterName": "meter_name",
    }[field_name]


def _escape_filter_value(value: str) -> str:
    return value.replace("'", "''")