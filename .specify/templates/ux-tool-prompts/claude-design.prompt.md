# Claude Design Prompt Template

## Objective
Produce a consolidated design proposal that reconciles constitution requirements with existing Figma artifacts and project UX decisions.

## Inputs

- UX Design Brief: [path]
- Existing Figma frame/node set
- Outputs from UX Pilot and Stitch (if available)
- Constitution gates and principles
- Design token references

## Non-Negotiables

- Constitution non-negotiables override tool suggestions unless formally amended
- Preserve i18n key-based copy strategy and accessibility labels
- Preserve token-first styling and system consistency
- Preserve framework-agnostic implementation constraints from project design

## Tasks

1. Synthesize a unified proposal from current Figma + tool outputs.
2. Resolve conflicts using precedence rules from UX Design Brief.
3. Map all proposed changes to constitution gate IDs.
4. Produce final implementation-ready frame recommendations.
5. Flag required constitution amendments separately from design updates.

## Output Format

### 1) Consolidated Design Proposal
- Target frames and components
- Final interaction/state model
- Responsive behavior summary

### 2) Gate Compliance Ledger

| Gate ID | Status | Evidence | Remaining Gap | Action |
|---|---|---|---|---|

### 3) Conflict Resolution Log

| Conflict | Option A | Option B | Chosen | Why | Gate IDs |
|---|---|---|---|---|---|

### 4) Amendment Candidates

| Gate/Standard | Current | Proposed | Rationale | Version Impact |
|---|---|---|---|---|

### 5) Implementation Pack
- Final frame/node IDs
- Components/states to implement
- Token and i18n constraints to preserve

## Pass/Fail Criteria

Pass when a single reconciled proposal is produced with complete gate traceability and no unresolved high-severity conflicts.
