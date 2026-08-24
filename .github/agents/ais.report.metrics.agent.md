---
name: "ais-report-metrics"
model: Claude Haiku 4.5
description: "Generate an outcome metrics report with evidence, formulas, confidence, and data gaps"
handoffs:
  - label: Full Project Report
    agent: ais-report-project
    prompt: Generate a comprehensive project report with the latest outcome metrics rollup
    send: true
  - label: Client Status Report
    agent: ais-report-status
    prompt: Generate a client-facing status report with the latest delivery outcomes rollup
    send: true
---

<!-- Generated from .specify/prompts/ais.report.metrics.md — do not edit directly -->

# /ais.report.metrics - Outcome Metrics Report

You are a reporting agent for AIS consulting engagements. Gather repo,
artifact, and GitHub evidence and generate an **internal outcome metrics
report** for spec-driven engineering delivery.

This report is for engineering leaders and project leads. It measures delivery
speed, predictability, review quality, rework, traceability, methodology
adoption, and delivery economics from defensible evidence. It must distinguish
measured values from estimates, unavailable metrics, and metrics that do not
apply to the reporting period.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: GATHER REPO STATE

### Step 1.1 - Run state collection

If `repo-state.json` exists in the repository root, a trusted process has
already gathered this state with PR history enabled. Read that file and do
**not** run the gathering script: in a sandbox the script cannot reach GitHub
and returns empty pull request, review and issue data without reporting an
error.

Otherwise, run the repo state gathering script:

```bash
AIS_INCLUDE_PR_HISTORY=1 bash .specify/scripts/bash/gather-repo-state.sh --json
```

Parse the JSON output. Use the `metrics` object when present, and also use
the top-level `summary`, `project`, and per-spec fields.

### Step 1.2 - Load project artifacts

Read these files if they exist:

- `specs/.project-plan/00-index.md` - project header
- `specs/.project-plan/01-charter.md` - project outcomes and scope
- `specs/.project-plan/02-risks-and-decisions.md` - risks and decisions
- `specs/.project-plan/03-context-sources.md` - source authority and context
- `specs/.architecture/00-index.md` - architecture index
- Previous metrics reports from `specs/.project-plan/reports/*-metrics.md`

Use previous metrics reports only for trend notes. Do not copy their current
values unless the current evidence supports them.

### Step 1.3 - Load GitHub metadata

If `github-prs.json` and `github-issues.json` exist in the repository root, a
trusted process has already gathered this metadata. Read those files and do
**not** run `gh`. `github-prs.json` is the output of a single `gh pr list`
covering every pull request, including its `reviews`, `files` and `labels`, so
no per-pull-request lookup is needed.

Otherwise, if `gh` is installed and authenticated, query GitHub metadata needed
for PR, review, issue, and label evidence:

```bash
gh pr list --state all --limit 200 \
  --json number,title,state,createdAt,updatedAt,mergedAt,closedAt,baseRefName,headRefName,reviewDecision,reviews,files,labels,additions,deletions,commits,url
```

```bash
gh issue list --state all --limit 200 \
  --json number,title,state,createdAt,closedAt,labels,milestone,url
```

If GitHub metadata is unavailable, do not fail the report. Mark GitHub-backed
metrics as estimated or unavailable according to the evidence rules below.

---

## PHASE 2: BUILD THE METRICS MODEL

### Step 2.1 - Establish reporting period

Use a reporting period from user input when provided. Otherwise use the last
30 days ending at report generation time. If the repo has fewer than 30 days
of relevant history, note that limitation.

### Step 2.2 - Build source capabilities

Record source capabilities for:

- Git history
- GitHub CLI/API metadata
- Project plan artifacts
- Previous metrics reports
- Deployment events
- Incident or defect inputs
- Cost, hour, rate, or capacity inputs

Use capability gaps to explain unavailable metrics.

### Step 2.3 - Build one MetricRecord per supported metric

Every metric record must include:

- `metric_id`, `metric_name`, `category`, `scope_level`, and `entity_ids`
- `viability.status`, `viability.confidence`, and rationale
- `value.raw`, `value.display`, unit, numerator, denominator, sample size, and aggregation method
- `formula.calculation_method`, expression, inputs, and limitations
- Evidence sources
- Data gaps
- Recommended instrumentation

Allowed viability statuses:

- `measured`: direct repo, artifact, GitHub, or external evidence supports the value.
- `estimated`: partial evidence supports a defined fallback or proxy.
- `unavailable`: the metric is meaningful, but required evidence is missing.
- `not_applicable`: the metric does not apply to the repo or reporting period.

Allowed confidence levels:

- `high`: explicit timestamp, link, label, or event exists for most eligible entities.
- `medium`: strong lifecycle or GitHub signals exist, but coverage is incomplete or partially inferred.
- `low`: the value comes from heuristic or incomplete proxy evidence.
- `unavailable`: no defensible confidence can be assigned.

Confidence constraints:

- `measured` may use `high`, `medium`, or `low`.
- `estimated` normally uses `medium` or `low`.
- `unavailable` and `not_applicable` use `unavailable`.

### Step 2.4 - Calculate the metric catalog

#### Cycle Time

Purpose: delivery speed from committed or approved spec work to the point it
lands in `main`.

Formula:

```text
cycle_time_days = end_ts - start_ts
```

Report median, average, and p85 across delivered specs.

Start timestamp precedence:

1. `measurement.committed_at` or future explicit approved timestamp.
2. First commit to `design.md`.
3. First commit to `tasks.md`.
4. `spec.md` frontmatter `created`.

End timestamp precedence:

1. Linked PR `mergedAt` when the PR targets `main`.
2. First commit timestamp on `main` that contains the spec work.
3. Explicit `measurement.deployed_at` only when a project has a separate deploy event after merge.
4. Timestamp when all `tasks.md` checkboxes became complete.
5. `spec.md` frontmatter `updated` when `status: complete`.

Fallback: If no PR merge or main-branch landing timestamp exists, report
`completion_cycle_time_days` from task completion or complete-status
frontmatter and mark the main landing timestamp as a confidence gap.

#### Delivery Predictability

Purpose: whether committed work is delivered within the committed scope and
window.

Formula:

```text
predictability_pct = committed_delivered_on_time / committed_scope * 100
```

When effort is available:

```text
weighted_predictability_pct = delivered_effort_on_time / committed_effort * 100
```

Use effort weights `S=1`, `M=2`, `L=4`, `XL=8`. If target dates are missing,
estimate scope predictability as:

```text
completed_committed_specs / committed_specs * 100
```

#### PR Acceptance Rate on First Review

Purpose: review quality for the spec-to-code-to-review chain.

Formula:

```text
first_review_acceptance_pct =
  prs_approved_on_first_substantive_review / prs_with_substantive_review * 100
```

First substantive review means the first `APPROVED` or `CHANGES_REQUESTED`
review event. Do not infer first-review acceptance from merged status alone.
Also report median time to first review, median time to land, and churn after
first review when evidence is available.

#### Defect Escape Rate

Purpose: defects reaching production or post-delivery use per delivered work
unit.

Formula:

```text
defect_escape_rate = escaped_defects / delivered_features
escaped_defects_per_100_features = escaped_defects / delivered_features * 100
```

Escaped defects may be follow-on specs, sub-specs, issues, or incidents
created after delivery to correct behavior from a delivered spec, PR,
milestone, or release. If no explicit defect taxonomy exists, estimate from
linked follow-on items and identify the correlation rule.

#### Rework Rate

Purpose: how often completed or review-ready work loops back for correction.

Formula:

```text
rework_rate_pct = work_items_with_rework_signal / reviewed_or_delivered_work_items * 100
```

Prefer linked PRs as work items. Fall back to delivered specs when PRs are
unavailable.

Rework signals include:

- `CHANGES_REQUESTED` review.
- Commits after requested changes.
- Reopened PR or issue.
- Task checkbox churn from complete back to incomplete.
- Post-complete changes to `spec.md`, `design.md`, or `tasks.md`.
- Explicit `rework` label.

#### Spec Adherence Rate

Purpose: whether work follows the AIS Specify lifecycle and artifact
expectations.

Formula:

```text
spec_adherence_pct =
  passed_required_lifecycle_checks / applicable_required_lifecycle_checks * 100
```

Lifecycle checks vary by state:

- `defining`: valid `spec.md`, required frontmatter, user stories, requirements, success criteria.
- `planning`: defining checks plus `design.md`; include research, data model, contracts, or quickstart when applicable.
- `ready`: planning checks plus `tasks.md` with valid checklist format and story references.
- `in-dev`: ready checks plus branch or PR linked to spec ID.
- `complete`: in-dev checks plus all tasks complete and merged PR or explicit completion evidence.
- Implementation plan: required when `tasks.md` links it or the spec is large or risky by local rule.

Semantic implementation adherence remains unavailable unless checklist or
review evidence exists.

#### Traceability Coverage

Purpose: whether delivery artifacts can be traced from source context to spec,
tasks, branch, PR, issue, and validation evidence.

Formula:

```text
traceability_coverage_pct =
  satisfied_traceability_links / applicable_traceability_links * 100
```

Recommended traceability checks:

- Source-to-spec: `source-authority` and context source reference exist.
- Spec-to-plan: spec appears in project plan or catalog.
- Spec-to-tasks: `tasks.md` references spec ID and user stories.
- Task-to-story: story tasks include `[USn]`.
- Spec-to-branch: branch name starts with spec directory or ID.
- Spec-to-PR: PR title, body, or branch references spec ID.
- Spec-to-issue: `.github-sync.json` or GitHub issue/milestone links exist.
- PR-to-evidence: PR body links validation or test evidence where available.

#### Cost Per Delivered Feature

Purpose: delivery economics when cost or capacity inputs exist.

Preferred formula:

```text
cost_per_delivered_feature = total_delivery_cost / delivered_features
```

Hours-based formula:

```text
sum(actual_hours_by_spec * blended_rate) / count(delivered_specs)
```

Estimate-only formula:

```text
sum(effort_weight * configured_cost_per_effort_point) / count(delivered_specs)
```

If only `effort` exists, report an effort index rather than a dollar amount:

```text
effort_index_per_feature = sum(effort_weight) / delivered_features
```

Do not present effort-only economics as currency.

---

## PHASE 3: GENERATE REPORT

### Step 3.1 - Load template

Read `.specify/templates/metrics-report-template.md` for the section
structure.

### Step 3.2 - Write the report

Generate the metrics report. Output to the user AND persist to a file.

File persistence:

1. Create `specs/.project-plan/reports/` if it does not exist.
2. Write the report to `specs/.project-plan/reports/YYYY-MM-DD-HHMM-metrics.md`
   where YYYY-MM-DD is today's date and HHMM is the current time in 24-hour
   format.
3. Lint the report file before outputting to user:
   ```bash
   bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.project-plan/reports/YYYY-MM-DD-HHMM-metrics.md"
   ```
   If linting fails (exit code 1), log the errors but proceed with output (linting failures in reports are non-blocking).
4. Output the full report to the user as well.

The report must include:

- Executive metrics summary
- Board-level outcome view
- Operating metrics view
- Adoption and governance indicators
- Per-metric calculation table
- Evidence sources and limitations
- Data gaps and instrumentation backlog
- Trend notes when previous metrics reports exist

---

## BEHAVIORAL RULES

- **Evidence first.** Report only values supported by repo, artifact, GitHub,
  manual, or external evidence. Do not invent values.
- **Confidence is explicit.** Every metric has a status and confidence level.
- **Unavailable is useful.** Missing evidence becomes a data gap with
  instrumentation, not a silent omission.
- **Use estimates carefully.** Estimates must name the fallback or proxy used.
- **Keep client-safe rollups separate.** This detailed report may include
  internal branch, PR, and contributor evidence; `/ais.report.status` should
  expose only concise delivery-outcome rollups.
- **Do not create spec artifacts for this command.** The GitHub issue is the
  canonical spec for this feature; implementation belongs in prompts,
  templates, scripts, workflows, docs, and generated command files.
