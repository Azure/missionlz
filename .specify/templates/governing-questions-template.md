# Governing Questions Tracker

> Auto-generated from playbook: [PLAYBOOK NAME]
> Created: [DATE] | Last updated: [DATE]
>
> This tracker records the answer status for each governing question from the
> active playbook. AIS commands check this file at phase boundaries and surface
> unanswered questions as soft gates.
>
> **Status values**: `unanswered` | `answered` | `N/A`

## Pre-sales Phase

> These questions must be answered before the proposal can proceed.
> Unanswered Pre-sales questions are surfaced by `/ais.presales.propose`.

| ID | Domain | Question | Answer | Source | Date | Status |
|----|--------|----------|--------|--------|------|--------|
| GQ-001 | | [from playbook register] | | | | unanswered |

## Setup Phase

> These questions must be answered during project kickoff / planning.
> Unanswered Setup questions are surfaced by `/ais.setup.plan`.

| ID | Domain | Question | Answer | Source | Date | Status |
|----|--------|----------|--------|--------|------|--------|
| GQ-0XX | | [from playbook register] | | | | unanswered |

## Design Phase

> These questions must be answered before individual spec design.
> Unanswered Design questions relevant to a spec's domain are surfaced
> by `/ais.spec.design` as Phase 0 research tasks.

| ID | Domain | Question | Answer | Source | Date | Status |
|----|--------|----------|--------|--------|------|--------|
| GQ-0XX | | [from playbook register] | | | | unanswered |

---

## How This File Is Used

1. **Created by** `/ais.presales.synthesize` (if playbook active) or `/ais.setup.plan`
2. **Populated from** the active playbook's Governing Questions Register
3. **Auto-updated by** `/ais.maintain.clarify` when new context answers questions
4. **Checked by** each AIS command at its phase boundary (soft gate)
5. **Location**: `specs/.discovery/governing-questions.md`

### Soft Gate Behavior

When a command encounters unanswered questions for its phase:
1. List the unanswered questions with their domain and what they drive
2. Ask the user to: **answer**, **defer** (with justification), or **mark N/A**
3. Require explicit acknowledgment before proceeding
4. The command does NOT hard-block — it warns and requires acknowledgment
