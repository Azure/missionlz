# Estimation Patterns

## Planning Basis

Estimates represent a single-point planning view for the median expected
provisioning state over the estimate period. The default estimate period is 12
months and the default monthly-hours basis is 730 hours unless the input states
otherwise.

## Data Sizing

When exact data volume is unknown, use a conservative high-end planning
assumption and make the retained quantity visible in inputs and outputs. Do not
hide major storage, logging, backup, or egress assumptions inside narrative
notes only.

## Retention

Retention assumptions must state an explicit duration and basis. When NIST SP
800-53 alignment is relevant, record the alignment as context rather than
hard-coding one universal retention duration for all data types.

## Dimensions

Use dimensions for environment and impact-level expansion while preserving
traceability. Typical dimensions include:

- `environment`: `dev`, `test`, `stage`, `prod`
- `impact_level`: `IL4`, `IL5`, `IL6`

Expanded line items should retain the source dimension values that produced the
normalized output row.

## Workload Templates

Workload templates are convenience inputs only. They must expand into canonical
resource-level line items that satisfy the same validation rules as authored
line items.

The MVP supports an `app_service_workload` template for common App Service
proposal estimates. Generated line items may include App Service compute,
storage, database, Key Vault, monitoring, networking, and backup components
when the sample or user input provides enough sizing detail.

## Confidence

Track sizing confidence separately from pricing confidence. A service can have
high price confidence from a selected meter while still having low sizing
confidence because workload volume or retention assumptions are uncertain.

## Proposal Output Reviewability

Proposal Markdown should be concise enough for `proposal.md` insertion. Show
resolved-item totals, unresolved-item count, caveats, exclusions, and grouped
unresolved items. Keep row-level warnings and expanded line-item detail in
`estimate-review.md`, `estimate-line-items.csv`, `estimate-workbook.xlsx`, and
`estimate-audit.json`.
