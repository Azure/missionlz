# Stitch Prompt Template

## Objective
Validate and propose responsive layout/system composition updates aligned to constitution quality gates and existing design tokens.

## Inputs

- UX Design Brief: [path]
- Breakpoint strategy from design.md
- Existing Figma frame set
- Constitution gates and thresholds

## Non-Negotiables

- Preserve token-driven styling and spacing scales
- Preserve i18n surfaces and text expansion safety
- Preserve accessibility constraints (touch targets, focus visibility, reading order)
- Do not violate constitution thresholds without explicit amendment path

## Tasks

1. Evaluate each target screen at required breakpoints.
2. Validate container/grid behavior, constraints, and resizing logic.
3. Identify overflow, truncation, and reading-order risks.
4. Propose frame updates for responsive parity.
5. Tag each change with gate IDs and confidence.

## Output Format

### 1) Responsive Coverage Matrix

| Screen | Desktop | Tablet | Mobile | Gap Summary |
|---|---|---|---|---|

### 2) Layout Risk Log

| Risk | Breakpoint | Severity | Gate ID | Fix Proposal |
|---|---|---|---|---|

### 3) Token Compliance Findings

| Node ID | Current Value | Expected Token | Status | Recommendation |
|---|---|---|---|---|

### 4) Proposed Figma Updates
- Node ID
- Constraint/layout changes
- Token updates
- Gate mapping

## Pass/Fail Criteria

Pass when required breakpoints meet responsive and accessibility thresholds with no unresolved high-severity layout failures.
