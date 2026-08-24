# UX Figma Reconciliation: [FEATURE NAME]

**Feature ID**: [YYMM-NNN]
**Date**: [YYYY-MM-DD]
**Status**: Draft Reconciliation / In Review / Approved / Task-Ready
**Spec**: [path]
**Design**: [path]
**Constitution**: [path]
**Figma File**: [url]

## Purpose

Reconcile constitution requirements with existing Figma designs and tool outputs into one implementation-ready decision source.

## Precedence Rules

1. Constitution non-negotiables and quality gates
2. Feature design decisions (design.md)
3. Feature acceptance requirements (spec.md)
4. Tool-generated recommendations

## MCP Back-and-Forth Checkpoints

- Checkpoint 1: Baseline Figma read (pre-amendment)
- Checkpoint 2: Validation read (post-proposal)
- Checkpoint 3: Lock read (pre-task generation)

For each checkpoint, capture:

- Frame/node IDs reviewed
- Snapshot timestamp
- Summary of detected state
- Delta vs prior checkpoint

## Constitution Delta Matrix

| Gate ID | Current Constitution Threshold | Current Figma Evidence | Gap Type | Proposed Constitution Change | Proposed Figma Change | Owner | Status |
|---|---|---|---|---|---|---|---|
| QG-UX-001 | [threshold] | [evidence] | None / Gap / Conflict | [if any] | [if any] | [role] | Open / Approved / Rejected |

## Divergence Table

| Topic | Source A | Source B | Conflict Severity | Resolution | Rationale |
|---|---|---|---|---|---|

## Amendment Safety Checks

Complete for every proposed constitution change:

- Rationale documented
- Impact scope documented
- Version bump intent documented (MAJOR / MINOR / PATCH)
- Accessibility thresholds not silently weakened
- i18n constraints not silently weakened

## Decision Log

| ID | Decision | Chosen Option | Rejected Alternatives | Why | Gate IDs | Owner |
|---|---|---|---|---|---|---|

## Final Reconciled Handoff

- Approved target frame/node IDs
- Required component/state updates
- Required token updates
- i18n constraints for implementation
- Accessibility constraints for implementation

## Task Seeding Checklist

Before `/ais.spec.tasks`, all must be true:

- Reconciliation status is Task-Ready
- Every QG-UX-* gate has evidence or approved amendment rationale
- No unresolved high-severity conflicts
- Final Figma references are implementation-ready

## Sign-Off

- Product: [name/date]
- Design: [name/date]
- Engineering: [name/date]
- QA/Accessibility (optional): [name/date]
