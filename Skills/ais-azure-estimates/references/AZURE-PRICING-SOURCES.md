# Azure Pricing Sources

## Source Types

| Source Type | Use | Total Treatment | Evidence Required |
|-------------|-----|-----------------|-------------------|
| `azure_retail_prices_api` | Public Azure retail meter resolved through the Azure Retail Prices API | Included when a reliable meter is selected | Query, selected meter metadata, unit price, currency, region, and confidence |
| `manual_override` | Valid Azure consumption item that cannot be reliably resolved through the API | Included when source, rationale, unit price, and confidence are present | Source note, rationale, unit of measure, sizing confidence, and pricing confidence |
| `unresolved` | Item cannot be priced reliably | Excluded from priced totals | Warning, follow-up owner or confirmation need, and reviewer caveat |

## Azure Retail Prices API

The MVP uses the unauthenticated Azure Retail Prices API as the live public
pricing source:

```text
https://prices.azure.com/api/retail/prices
```

Useful filter fields include `armRegionName`, `meterId`, `meterName`,
`productName`, `skuName`, `serviceName`, `serviceFamily`, `priceType`, and
`armSkuName`.

Selected meter metadata should be preserved in `estimate-audit.json` so a
reviewer can trace a calculated price back to the meter used for that run.

## No Cache Policy

The MVP does not maintain a reusable checked-in price catalog or API response
cache. Each run queries live pricing when pricing metadata is sufficient and
stores only the selected meter evidence in the output audit JSON.

## Manual Override Policy

Manual overrides are allowed only for Azure consumption items. They must include
source notes, rationale, unit price, unit of measure, sizing confidence, and
pricing confidence. Manual overrides missing any required evidence must fail
validation before final artifacts are accepted.

Resolved totals include only line items with a selected Retail Prices API meter
or a valid manual override. Unresolved items are excluded from totals and must
remain visible in proposal, review, CSV, and audit outputs.

## Excluded Pricing Sources

The MVP does not support customer agreement pricing, authenticated Azure Billing
APIs, saved Azure Pricing Calculator estimates, marketplace quote imports, or
non-Azure services. If those values are needed, list them as exclusions or
confirmation-needed items outside the Azure consumption total.
