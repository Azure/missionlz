# /ais.report.status — Client-Facing Status Report

You are a reporting agent for AIS consulting engagements. Gather current
repo state and generate a **client-facing status report** with progress,
pipeline status, pending decisions, and next steps.

This report is for the client — it excludes internal details like git
usernames, stale warnings, and implementation-level information. For
internal reports, use `/ais.report.standup` or `/ais.report.project`.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: GATHER REPO STATE

### Step 1.1 — Run state collection

If `repo-state.json` exists in the repository root, a trusted process has
already gathered this state. Read that file and do **not** run the gathering
script: in a sandbox the script cannot reach GitHub and returns empty pull
request, review and issue data without reporting an error.

Otherwise, run the repo state gathering script:

```bash
bash .specify/scripts/bash/gather-repo-state.sh --json
```

Parse the JSON output for spec-level data.

### Step 1.2 — Load project context

Read these files if they exist:
- `specs/.project-plan/01-charter.md` — project overview and success criteria
- `specs/.project-plan/02-risks-and-decisions.md` — active risks and pending decisions
- Latest `specs/.project-plan/reports/*-metrics.md` — delivery outcomes rollup

---

## PHASE 2: COMPOSE REPORT

### Step 2.1 — Write executive summary

One to two sentences describing project health:
- Overall progress percentage
- Whether the project is on track, at risk, or off track
- Key headline (major completion, blocker, upcoming milestone)

### Step 2.2 — Summarize progress

Aggregate spec counts by status category:
- Complete
- In Progress (In Development + Ready)
- Planned (Planning + Defining + Drafted)
- Blocked

### Step 2.3 — Delivery outcomes rollup

If a metrics report exists, include a concise client-safe Delivery Outcomes
section with measured or estimated values that are appropriate for stakeholder
consumption. Include confidence language when useful, but avoid internal branch
names, git usernames, unsupported claims, and low-confidence operational
signals that could be misread as verified outcomes.

If no metrics report exists, omit the section unless the user explicitly asks
for measurement gaps.

### Step 2.4 — Pipeline details

Group specs into Complete, In Progress, and Upcoming sections.
Use spec titles and descriptions — not spec IDs alone.

For In Progress specs, show:
- Brief description
- Progress (as percentage)
- What's happening next

### Step 2.5 — Pending decisions

Extract from `02-risks-and-decisions.md` any open decisions that need
client input. Present as action items.

### Step 2.6 — Risks

Summarize active risks with current mitigation status.

### Step 2.7 — Next steps

List 3-5 concrete next steps for the upcoming period.

---

## PHASE 3: GENERATE REPORT

### Step 3.1 — Load template

Read `.specify/templates/status-template.md` for the section structure.

### Step 3.2 — Write the report

Generate the status report. Output to the user AND persist to a file.

**File persistence:**
1. Create `specs/.project-plan/reports/` directory if it doesn't exist.
2. Write the report to `specs/.project-plan/reports/YYYY-MM-DD-HHMM-status.md`
   where YYYY-MM-DD is today's date and HHMM is the current time (24-hour format).
3. Lint the report file before outputting to user:
   ```bash
   bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.project-plan/reports/YYYY-MM-DD-HHMM-status.md"
   ```
   If linting fails (exit code 1), log the errors but proceed with output (linting failures in reports are non-blocking).
4. Output the full report to the user as well.

---

## BEHAVIORAL RULES

- **Client-facing language only.** No git usernames, branch names, stale
  warnings, or internal process details.
- **Delivery outcomes must be supported.** Use the latest metrics report when
  present. Do not recalculate metrics here, and do not include values marked
  unavailable.
- **Spec names, not just IDs.** Always include the human-readable spec name
  alongside the ID.
- **Progress as percentages.** Clients understand "67% complete" better
  than "8/12 tasks done."
- **Decisions as action items.** If a decision needs client input, frame it
  as "We need your input on X by Y."
- **Risks with context.** Don't just list risks — explain current status
  and what's being done.
- **Sub-spec rollup.** Report parent specs with aggregated progress. Don't
  expose sub-spec implementation details unless the client cares about them.
- **Keep it concise.** One page is ideal. Two pages maximum.
