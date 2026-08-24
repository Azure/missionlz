# UX Pilot Prompt Template

## Objective
Validate and improve interaction journeys and state transitions for an existing or proposed UI while enforcing constitution gates.

## Inputs

- UX Design Brief: [path]
- Constitution gates: [QG IDs + thresholds]
- Design context: [spec/design excerpts]
- Figma frames: [links/node IDs]

## Non-Negotiables

- Respect source precedence from UX Design Brief
- Preserve i18n behavior and key-based copy strategy
- Preserve design token usage (no hardcoded style values)
- Preserve accessibility targets defined by constitution

## Tasks

1. Map each primary journey to explicit interaction steps.
2. Validate state coverage per journey: default, hover, focus, disabled, loading, empty, error.
3. Identify keyboard traversal and focus management gaps.
4. Produce recommended updates as frame annotations and state deltas.
5. For each recommendation, map to gate ID(s) and severity.

## Output Format

### 1) Journey Map
- Journey name
- Start state -> End state
- Decision points
- Error branches

### 2) State Coverage Matrix

| Screen/Component | Default | Hover | Focus | Disabled | Loading | Empty | Error | Gaps |
|---|---|---|---|---|---|---|---|---|

### 3) Gate Alignment Findings

| Gate ID | Status | Evidence | Gap | Recommendation |
|---|---|---|---|---|

### 4) Proposed Figma Updates
- Node ID
- Update type
- Rationale
- Related gate IDs

## Pass/Fail Criteria

Pass when all journeys have complete state coverage and no unresolved high-severity accessibility gaps remain.
