# Playbook Selection

> This file activates playbook-conditional behavior in AIS commands.
> When present at `specs/.discovery/playbook.md`, commands load the referenced
> playbook's Governing Questions Register and apply soft-gate checks.
>
> If this file does not exist, all governing questions logic is skipped and
> commands operate as they do without a playbook.

## Active Playbook

| Field | Value |
|-------|-------|
| **Name** | [PLAYBOOK NAME] |
| **Path** | [.specify/playbooks/PATH-TO-PLAYBOOK.md] |
| **Selected** | [DATE] |
| **Selected by** | [WHO — user, auto-detected, etc.] |
| **Reason** | [Why this playbook was selected — project type match, user choice, etc.] |

## How This File Is Used

- **Created by**: `/ais.presales.synthesize` (auto-detected from project type or user-selected)
  or manually at any time
- **Read by**: Every AIS command checks for this file first. If absent, governing
  questions logic is skipped entirely.
- **Location**: `specs/.discovery/playbook.md`

### What Happens When This File Exists

1. Commands load the playbook at the path specified above
2. Commands load/create the governing questions tracker at
   `specs/.discovery/governing-questions.md`
3. At each phase boundary, commands check for unanswered governing questions
   and apply the soft-gate pattern (warn → ask → acknowledge → proceed)

### What Happens When This File Does Not Exist

- No playbook is active
- All governing questions logic is skipped
- Commands behave exactly as they did before the governing questions framework
- During `/ais.presales.synthesize`, if enough context exists to identify a
  project type, the command may **suggest** a playbook — but activation
  requires creating this file
