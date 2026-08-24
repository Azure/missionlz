# /ais.report.standup — Internal Daily Standup Report

You are a reporting agent for AIS consulting engagements. Gather current
repo state and generate an **internal daily standup report** showing active
work, blockers, stale specs, and warnings.

This report is for the internal team — it includes git details, usernames,
and implementation-level status. For client-facing reports, use
`/ais.report.status`.

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

Parse the JSON output. This contains per-spec data including:
- Spec IDs, titles, directories, branches
- Frontmatter fields (status, owner, priority, effort)
- Derived pipeline status
- Artifact inventory
- Task completion (done/total)
- Activity (last commit, contributors, staleness)
- PR status
- Sub-spec relationships
- Warnings

### Step 1.2 — Load additional context

If `specs/.project-plan/02-risks-and-decisions.md` exists, read it to
include pending decisions and active risks in the report.

---

## PHASE 2: ANALYZE STATE

### Step 2.1 — Classify specs by status

Group specs into:
- **Active** — In Development, Ready, or Planning with recent activity
- **Blocked** — Status is blocked or has unresolved blocking dependencies
- **Stale** — No commits in 14+ days and not Complete
- **Complete** — All tasks done

### Step 2.2 — Detect status changes

If a previous standup exists (check for last report in output), compare
current state to detect changes. If no previous report exists, skip this
section.

### Step 2.3 — Aggregate sub-spec rollups

For parent specs with sub-specs:
- Progress = parent tasks + all sub-spec tasks combined
- Blocked if any sub-spec blocked
- Stale if parent or any sub-spec stale

### Step 2.4 — Identify warnings

Flag:
- **Unapproved implementations**: Specs with source code commits but spec.md
  not merged to main
- **Unassigned specs**: Active specs with no owner in frontmatter
- **Stale specs**: No activity in 14+ days (not complete)
- **Dependency bottlenecks**: Specs blocking multiple other specs

---

## PHASE 3: GENERATE REPORT

### Step 3.1 — Load template

Read `.specify/templates/standup-template.md` for the section structure.

### Step 3.2 — Write the report

Generate the standup report. Output to the user AND persist to a file.

**File persistence:**
1. Create `specs/.project-plan/reports/` directory if it doesn't exist.
2. Write the report to `specs/.project-plan/reports/YYYY-MM-DD-HHMM-standup.md`
   where YYYY-MM-DD is today's date and HHMM is the current time (24-hour format).
3. Lint the report file before outputting to user:
   ```bash
   bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.project-plan/reports/YYYY-MM-DD-HHMM-standup.md"
   ```
   If linting fails (exit code 1), log the errors but proceed with output (linting failures in reports are non-blocking).
4. Output the full report to the user as well.

Fill each section:
- **Active Work** — All specs not in Complete/Blocked/Stale status
- **Status Changes** — Only include if changes detected
- **Blocked** — Specs with blocked status, include reason and duration
- **Stale** — Specs with no activity in 14+ days
- **Warnings** — All detected anomalies
- **Summary** — Aggregate counts and overall progress

---

## BEHAVIORAL RULES

- **Report facts, not opinions.** The standup shows state, not recommendations.
- **Include all active specs.** Don't filter unless the user asks for a subset.
- **Sub-spec rollup is mandatory.** Parent spec progress always includes sub-specs.
- **Stale threshold is 14 days.** Configurable via user input.
- **Degrade gracefully.** If `gh` CLI is unavailable, skip PR status. If git
  history is limited, note the limitation.
- **This is internal.** Git usernames, branch names, and implementation details
  are appropriate. For client reports, use `/ais.report.status`.
