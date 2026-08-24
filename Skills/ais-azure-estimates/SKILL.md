---
name: ais-azure-estimates
description: >-
  Develop proposal-grade Azure cloud consumption estimates from structured JSON
  inputs. Use when proposal teams need traceable Azure Retail Prices API meter
  evidence, validated manual overrides, unresolved pricing caveats, and
  Markdown/CSV/XLSX/JSON estimate artifacts for Azure solution architect review.
license: Proprietary
compatibility: Requires Python 3.10+ and uv (https://docs.astral.sh/uv/)
metadata:
  author: ais-internal
  version: "0.1"
---

# AIS Azure Estimates

Use this skill to create proposal-grade Azure consumption estimates with clear
assumptions, pricing sources, confidence ratings, unresolved items, and review
evidence. The skill is intended for Azure solution architects preparing planning
estimates for proposal review. It does not approve pricing for external use.

## When to Use

- User asks for an Azure cloud consumption estimate for a proposal
- User needs Azure Pricing Calculator-style line items with traceable evidence
- User needs to separate Azure Retail Prices API results from manual overrides
- User needs Markdown, CSV, Excel, and JSON artifacts for proposal or commercial review
- User needs Azure Government caveats, unresolved items, or assumptions surfaced

## Do Not Use For

- Non-Azure labor, O&M, support, implementation services, or retainer pricing
- Customer agreement pricing or authenticated Azure Billing API estimates
- Azure Pricing Calculator UI scraping or saved-calculator imports
- MCP server behavior
- DOCX generation

## Principles

- Prefer defensible estimates over false precision.
- Treat input JSON as the rerun source of truth.
- Treat output JSON as audit evidence for a specific estimate run.
- Query Azure Retail Prices API live when meter metadata is sufficient.
- Do not cache API responses in the MVP.
- Flag ambiguous or unavailable meters instead of silently choosing a price.
- Allow manual overrides only for valid Azure consumption items with source,
  rationale, sizing confidence, and pricing confidence.
- Exclude unresolved items from priced totals and show them clearly.
- Require Azure solution architect review before external use.

## Available Scripts

- `scripts/check_environment.py` - checks Python, dependency, network,
  schema-validation, and output writeability prerequisites.
- `scripts/validate_estimate.py` - validates estimate input JSON against schema
  and business rules.
- `scripts/build_estimate.py` - normalizes inputs, resolves pricing where
  practical, calculates totals, and invokes renderers.
- `scripts/render_estimate.py` - renders proposal Markdown, internal review
  Markdown, CSV, Excel workbook, and audit JSON artifacts.
- `scripts/azure_prices.py` - contains Azure Retail Prices API lookup and meter
  matching helpers.
- `scripts/estimate_model.py` - contains shared model, validation, and
  normalization helpers.

## Input Contract

Author an estimate input JSON that conforms to:

```text
assets/estimate-input.schema.json
```

The input captures estimate metadata, defaults, dimensions, assumptions,
optional workload templates, resource-level line items, manual overrides, and
exclusions. See `examples/` for sample inputs after implementation.

## Output Contract

Successful builds create these artifacts in the selected output directory:

- `estimate-section.md` - proposal-ready Markdown for `proposal.md`
- `estimate-review.md` - internal review details, warnings, and traceability
- `estimate-line-items.csv` - flat normalized line-item export
- `estimate-workbook.xlsx` - Azure Pricing Calculator-style workbook with a
  `Total Estimate` sheet followed by one sheet per impact level; rows are
  grouped by service category with collapsed-by-default Excel outline controls,
  sorted by descending monthly cost, and include monthly, annual, and upfront
  totals
- `estimate-audit.json` - JSON audit evidence for the estimate run

The audit JSON conforms to:

```text
assets/estimate-output.schema.json
```

## Workflow

### 1. Run Pre-Flight

```bash
uv run Skills/ais-azure-estimates/scripts/check_environment.py
```

Confirm Python, `uv`, declared dependencies, Retail Prices API connectivity,
schema validation, and output writeability are available.

### 2. Validate Input

```bash
uv run Skills/ais-azure-estimates/scripts/validate_estimate.py \
  --input Skills/ais-azure-estimates/examples/generic-app-service.sample.json
```

Validation must block schema errors, missing confidence, invalid manual
overrides, and non-Azure costs.

### 3. Build Estimate Artifacts

```bash
uv run Skills/ais-azure-estimates/scripts/build_estimate.py \
  --input Skills/ais-azure-estimates/examples/virtualitics-alz.sample.json \
  --output-dir specs/.presales/proposal-redline/azure-estimate \
  --overwrite
```

The build must show source type, sizing confidence, pricing confidence, totals,
warnings, unresolved items, and selected meter metadata where available.
Use `--overwrite` when rerunning against an existing stable output directory;
omit it only when writing to a new or empty directory.

### 4. Review Before External Use

An Azure solution architect reviews generated artifacts for service
reasonableness, Azure Government caveats, unresolved meters, manual override
quality, conservative data sizing, retention assumptions, and proposal-safe
wording before any estimate language is used externally.

## Reference Materials

- [Azure Pricing Sources](references/AZURE-PRICING-SOURCES.md)
- [Estimation Patterns](references/ESTIMATION-PATTERNS.md)
- [Government Cloud Caveats](references/GOV-CLOUD-CAVEATS.md)
