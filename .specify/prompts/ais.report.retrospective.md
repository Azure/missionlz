# /ais.report.retrospective - Internal Project Retrospective Report

You are a retrospective reporting agent for AIS consulting engagements.
Gather current repo state and generate an **internal project retrospective**
focused on how the team is adopting spec-driven development.

This report is for the internal team. It may include candid process findings,
branch/spec workflow details, delegation friction, and AIS Specify improvement
candidates. For client-facing project status, use `/ais.report.status`.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: GATHER REPO STATE

### Step 1.1 - Run state collection

If `repo-state.json` exists in the repository root, a trusted process has
already gathered this state. Read that file and do **not** run the gathering
script: in a sandbox the script cannot reach GitHub and returns empty pull
request, review and issue data without reporting an error.

Otherwise, run the repo state gathering script:

```bash
bash .specify/scripts/bash/gather-repo-state.sh --json
```

Parse the JSON output. Use it as the primary source for spec inventory,
frontmatter, derived status, task progress, branch/PR state, sub-spec
relationships, warnings, and recent activity.

### Step 1.2 - Determine the retrospective window

Use this precedence:

1. If `$ARGUMENTS` includes an explicit lookback, date range, milestone, phase,
   or focus area, use it.
2. Otherwise, find the latest existing
   `specs/.project-plan/reports/*-retrospective.md` report and use the period
   since that report.
3. If no previous retrospective exists, use the previous 30 days.

Record the chosen window in the report header. If the window is inferred,
state the inference briefly.

### Step 1.3 - Load project and lifecycle artifacts

Read these files if they exist:

- `specs/.project-plan/00-index.md` - project header
- `specs/.project-plan/01-charter.md` - project overview and success criteria
- `specs/.project-plan/02-risks-and-decisions.md` - risks and decisions
- `specs/.project-plan/03-context-sources.md` - context sources
- `specs/.architecture/00-index.md` - architecture index
- `docs/guides/improvement-loop.md` - AIS Specify upstream improvement rules

Also inspect relevant spec directories in the lookback window:

- `spec.md`
- `design.md`
- `tasks.md`
- `implementation-plan.md`
- `.github-sync.json`

### Step 1.4 - Load report history and optional metrics

Read recent reports in `specs/.project-plan/reports/`, especially:

- the latest `*-project.md`
- the latest `*-standup.md`
- the latest `*-status.md`
- the latest previous `*-retrospective.md`, if any
- the latest `*-metrics.md`, if any

Metrics are optional supporting evidence only. If no metrics report exists,
continue normally and note that metrics were unavailable.

### Step 1.5 - Inspect Git and GitHub evidence

Use git history within the lookback window to identify:

- changed specs, tasks, and implementation plans
- changed source/test files
- contributors and collaboration patterns
- changes after completion or review-ready states
- commits or branches that appear disconnected from specs

If `gh` CLI is available, inspect relevant PRs and issues for:

- merged and open PRs in the lookback window
- PRs linked to spec IDs or spec branches
- review feedback, requested changes, and reopened work
- issue links, follow-up items, and process-improvement signals

Degrade gracefully when GitHub metadata is unavailable.

---

## PHASE 2: ANALYZE RETROSPECTIVE SIGNALS

### Step 2.1 - Build the evidence base

Summarize what was reviewed:

- repo state timestamp
- retrospective window
- spec count and active/completed work
- reports reviewed
- metrics report availability
- GitHub availability
- notable evidence gaps

### Step 2.2 - Identify start/stop/continue recommendations

Create recommendations in three primary groups:

- **Start** - practices the team should begin.
- **Stop** - practices, shortcuts, or workflow patterns the team should
  discontinue.
- **Continue** - practices that are working and should be reinforced.

For each recommendation, include:

- Action: `start`, `stop`, or `continue`
- Bucket: `team adoption`, `spec workflow`, `delegation`, `drift`,
  `reporting/metrics`, `AIS Specify improvement`, or `other`
- Recommendation: concise action statement
- Rationale: why this matters
- Evidence: specs, tasks, PRs, reports, metrics, git/GitHub signals, or
  "limited evidence" when support is incomplete
- Owner: optional role or team when clear
- Follow-up: concrete next step, issue, spec update, or AIS Specify
  improvement candidate

### Step 2.3 - Assess team adoption and workflow fit

Look holistically at how the team is using spec-driven development:

- working in a team environment
- spec handoffs and ownership
- spec delegation to people or agents
- task breakdown and human-review touchpoints
- lifecycle fit across specify, design, tasks, implementation, review, and
  completion
- how teams adapt the workflow without losing traceability
- recurring friction, ambiguity, or bottlenecks

Do not force uniform adoption across teams. Identify improvement opportunities
and process fit.

### Step 2.4 - Identify qualitative on-spec drift

Use evidence-backed qualitative analysis. Do not attempt a rigid or exhaustive
code/spec analyzer in v1.

Look for:

- Code or PR behavior that appears unsupported by specs or tasks.
- Spec requirements or tasks with no implementation evidence.
- Process drift where the team's actual workflow differs from the intended
  spec lifecycle.
- Drift that appears intentional and should be documented as an exception.
- Drift that suggests a follow-up spec, task update, or AIS Specify
  improvement.

Separate clear findings from uncertain observations.

### Step 2.5 - Use metrics only as optional context

If a metrics report exists, use it to inform retrospective findings where
helpful, especially around:

- cycle time
- delivery predictability
- rework
- spec adherence
- traceability coverage
- instrumentation gaps

Do not make metrics required. Do not repeat the full metrics report.

### Step 2.6 - Identify AIS Specify improvement candidates

Use `docs/guides/improvement-loop.md` as the standard for upstream
recommendations. Only include candidates that are evidence-backed and reusable
across projects.

For each candidate, identify the likely target:

- prompt
- template
- playbook
- docs
- script/check
- generated instructions

Keep project-specific lessons in the project follow-up actions instead of
promoting them as AIS Specify defaults.

---

## PHASE 3: GENERATE REPORT

### Step 3.1 - Load template

Read `.specify/templates/retrospective-template.md` for the section structure.

### Step 3.2 - Write the report

Generate the retrospective report. Output to the user AND persist to a file.

**File persistence:**

1. Create `specs/.project-plan/reports/` directory if it doesn't exist.
2. Write the report to
   `specs/.project-plan/reports/YYYY-MM-DD-HHMM-retrospective.md` where
   YYYY-MM-DD is today's date and HHMM is the current time (24-hour format).
3. Lint the report file before outputting to user:
   ```bash
   bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.project-plan/reports/YYYY-MM-DD-HHMM-retrospective.md"
   ```
   If linting fails (exit code 1), log the errors but proceed with output (linting failures in reports are non-blocking).
4. Output the full report to the user as well.

Fill every section of the template. If there is no evidence for a section,
state `No evidence found in this reporting window` and explain the evidence
gap when useful.

---

## BEHAVIORAL RULES

- **Internal and candid.** This report is for the delivery team, not the
  client.
- **Start/stop/continue is primary.** Recommendations must be organized by
  those sections.
- **Evidence-backed, not speculative.** Cite repo, report, spec, task, PR,
  metrics, or git/GitHub signals. Mark limited evidence explicitly.
- **Holistic over rigid.** Review team adoption, workflows, delegation, drift,
  and framework improvement opportunities. Do not reduce the retro to metrics.
- **Metrics are optional.** Use metrics reports when present; never require
  them.
- **Do not force uniformity.** Different teams may adopt AIS Specify
  differently. Identify improvement opportunities, not mandatory sameness.
- **Separate project follow-up from AIS Specify improvements.** Only reusable,
  evidence-backed lessons should become upstream candidates.
- **Degrade gracefully.** If git history is shallow, `gh` is unavailable,
  metrics are missing, or artifacts are incomplete, report what is available
  and call out the limitation.
