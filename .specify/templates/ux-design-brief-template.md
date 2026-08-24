# UX Design Brief: [FEATURE NAME]

**Feature ID**: [YYMM-NNN]
**Date**: [YYYY-MM-DD]
**Mode**: Greenfield (constitution-first) / Brownfield (existing Figma-first)
**Spec**: [path to spec.md]
**Design**: [path to design.md]
**Constitution**: [path to constitution.md]
**Figma File**: [figma URL]
**Target Frames**: [node IDs]

## Source Precedence

1. Constitution non-negotiables and quality gates
2. Feature design decisions in design.md
3. Feature stories and acceptance criteria in spec.md
4. Existing Figma implementation details

## Prompt Inputs Pack

Paste these inputs into external UX tools:

- Product context summary from spec.md
- UI/UX Scope and UX Decisions from design.md
- Constitution quality gates and thresholds
- Design tokens and style constraints
- i18n constraints and localization strategy
- Existing Figma frame URLs / node IDs

## Gate Traceability Matrix

| Gate ID | Constitution Threshold | Required Evidence in Figma | Current Status | Notes |
|---|---|---|---|---|
| QG-UX-001 | [threshold] | [frame(s), variants, notes] | Pass / Gap / Conflict | |
| QG-UX-002 | [threshold] | [focus states, keyboard flow] | Pass / Gap / Conflict | |
| QG-UX-003 | [threshold] | [contrast report, tokens] | Pass / Gap / Conflict | |
| QG-UX-004 | [threshold] | [loading/empty/error states] | Pass / Gap / Conflict | |

## Existing Figma Baseline (Brownfield)

Capture using MCP before any edits:

- Layout inventory (frames, hierarchy, constraints)
- State coverage inventory (default/hover/focus/disabled/loading/error)
- Accessibility inventory (keyboard annotations, focus visibility, semantic labels)
- Token usage inventory (colors, typography, spacing, radius, motion)
- i18n surface inventory (text nodes, ARIA strings, dynamic copy)

## Tool Execution Plan

| Tool | Purpose | Inputs | Expected Output |
|---|---|---|---|
| UX Pilot | Journey + interaction flow validation | Journeys, states, gates | Interaction flows, state map |
| Stitch | Responsive composition validation | Layout + breakpoints + gates | Responsive frame set |
| Claude Design | End-to-end synthesis + a11y checks | Full brief + precedence | Consolidated design proposal |

## Non-Negotiables

- Preserve i18n keys and localization constraints
- Preserve token-first styling
- Meet accessibility threshold from constitution
- Do not propose changes that violate constitution unless amendment is explicitly requested

## Handoff Acceptance Criteria

Before task generation, all must be true:

- Every QG-UX-* gate has evidence or approved amendment rationale
- No unresolved high-severity conflicts
- Reconciliation artifact status is Task-Ready
- Final frame/node references are implementation-ready

## Outputs

- Tool prompts used (attach or reference)
- Tool outputs (links or exports)
- Reconciliation artifact path
- Approved constitution deltas (if any)
- Implementation seed checklist for tasks.md
