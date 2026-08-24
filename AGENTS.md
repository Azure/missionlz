<!-- Generated from .specify/repo-instructions.md by generate-commands.sh — do not edit directly -->

# AIS Spec-Driven Development Framework

Unified workflow for decomposing raw requirements (RFPs, SOWs, transcripts) into structured, implementable specifications. Language/framework-agnostic.

## Workflow

Pre-sales is optional. Run project setup once, then cycle the spec lifecycle per feature:

```
PRE-SALES (optional, per engagement):
  /ais.presales.synthesize → specs/.presales/01-what-we-heard.md
  /ais.presales.propose    → specs/.presales/02-proposal.md
  /ais.presales.scope      → specs/.presales/03-sow.md

PROJECT SETUP (once):
  /ais.setup.plan          → specs/.project-plan/
  /ais.setup.architecture  → specs/.architecture/
  /ais.setup.constitution  → specs/constitution.md

SPEC LIFECYCLE (per feature):
  /ais.spec.brainstorm → Spec Seed Brief (optional pre-spec discovery)
  /ais.spec.specify   → specs/YYMM-NNN-name/spec.md with QA/UAT readiness (defining)
  /ais.spec.design    → design.md, data-model, contracts, Verification Strategy (planning)
  /ais.spec.tasks     → tasks.md, verification tasks, implementation-plan.md* (ready)
  /ais.spec.implement → execute tasks with review/QA/evidence gates (in-dev → complete)

REPORTING (anytime):
  /ais.report.standup  → specs/.project-plan/reports/YYYY-MM-DD-HHMM-standup.md
  /ais.report.status   → specs/.project-plan/reports/YYYY-MM-DD-HHMM-status.md
  /ais.report.project  → specs/.project-plan/reports/YYYY-MM-DD-HHMM-project.md
  /ais.report.retrospective → specs/.project-plan/reports/YYYY-MM-DD-HHMM-retrospective.md

MAINTAIN (anytime):
  /ais.maintain.clarify → ingest new context or resolve spec ambiguities
  /ais.maintain.debug   → diagnose failures before fixing
```

## Key Conventions

- **Spec IDs**: `YYMM-NNN` format (e.g., `2602-001` = Feb 2026, first spec). Sub-specs use `.N` suffix.
- **Brainstorming**: `/ais.spec.brainstorm` is optional and produces a Spec Seed Brief only. It must not create `specs/YYMM-NNN-*` artifacts or modify `/ais.spec.specify`.
- **Pre-sales specs**: Pre-sales proposes specs by name. At delivery kickoff, `/ais.setup.plan` assigns `YYMM-NNN` identifiers and creates directories.
- **Branches**: Spec work uses `YYMM-NNN-short-description` branches. Non-spec work uses `feature/`, `bugfix/`, `chore/`, `docs/` prefixes.
- **All PRs** squash-merge to main. No direct commits to main.
- **Framework releases**: Every PR must include exactly one release label: `release:patch`, `release:minor`, or `release:major`. Fill in the PR template's `## Release note`; `release:major` requires a `BREAKING CHANGE:` line.
- **Paths**: Always use absolute paths in commands and scripts.
- **Templates**: Live in `.specify/templates/`. Commands auto-fill them.
- **Playbooks**: Live in `.specify/playbooks/`. Domain-specific patterns for pre-sales and delivery.
- **Implementation Plans**: For larger or riskier specs, use `implementation-plan.md` guided by `PLANS.md`. Plans include validation evidence, review gates, worktree decisions, and recovery guidance.
- **QA/UAT Integration**: QA/UAT belongs inside the existing lifecycle. Specs capture readiness, designs define Verification Strategy, tasks generate required verification work, and implementation records automated/manual evidence, QA status, deferred tests, and deployment readiness. Do not create `/ais.qa.*` commands.
- **Constitution**: `specs/constitution.md` defines non-negotiable standards. All designs must comply or justify violations.
- **Status tracking**: Spec.md YAML frontmatter is canonical. Report commands derive live status from repo state.
- **Context discipline**: Treat each `/ais.*` command boundary as a file-backed handoff. When the tool supports it, clear the conversation or start a fresh assistant context before the next command; persist decisions, blockers, evidence, and handoffs in `specs/` artifacts because token reduction only happens after an actual context reset.

## Directory Structure

```
.github/workflows/     # GitHub Actions CI/CD pipelines
.project-context/      # Raw inputs (gitignored, never committed)
.specify/              # Templates, scripts, playbooks
  VERSION              # Framework version copied into project repos
  playbooks/           # Domain-specific engagement playbooks
  scripts/bash/        # Automation scripts (return JSON)
  templates/           # Markdown templates for all artifact types
CHANGELOG.md           # Framework release notes
VERSION                # Release automation version for this framework repo
docs/
  getting-started/     # Demos: hello-world, pre-sales-demo
  reference/           # Commands, workflow, multi-tool docs
  guides/              # Pre-sales, delivery, roles, process mapping, playbooks
infra/                 # Infrastructure as Code
specs/
  constitution.md      # Non-negotiable project standards
  .presales/           # Pre-sales artifacts (01-what-we-heard, 02-proposal, 03-sow)
  .architecture/       # Wardley map, C4, ADRs, tech stack, data flow
  .project-plan/       # Charter, risks, context sources
    reports/           # Persisted reports (dated, sortable)
  YYMM-NNN-name/       # Per-spec: spec.md, design.md, implementation-plan.md, tasks.md, etc.
src/                   # Application code
tests/                 # Tests mirroring src/ structure
Skills/                # Agent Skills (https://agentskills.io)
  README.md            # Skills overview and catalog
  {skill-name}/        # Per-skill: SKILL.md, scripts/, references/, assets/
```

## Rules

- Never modify `.project-context/` directly — it's raw input, read-only.
- Always invoke workflow steps via slash commands (`/ais.spec.specify`, etc.), not manually.
- When moving from one `/ais.*` command to another, start a fresh assistant context by clearing the conversation or opening a new session when the tool supports it. Continuing a command in the same context is acceptable only while that command is still running and its state is being written into the relevant artifact files.
- Commands must load current artifact files as their source of workflow state. Prior chat history is supporting context only; command correctness and resumability must not depend on it, and token savings must not be assumed unless a real context reset occurred.
- Use `/ais.spec.brainstorm` only when early ideas need optional discovery or scope shaping before `/ais.spec.specify`; it is not required for normal specification.
- For larger or riskier work, maintain `implementation-plan.md` as a living document from task generation through implementation.
- Tasks in `tasks.md` must follow checklist format: `- [ ] [ID] [P?] [Story?] Description`
- Status is tracked in spec.md YAML frontmatter. Report commands derive live state from the repo.
- Bash scripts return JSON; commands parse the output for paths and metadata.
- Run consistency checks (built into `/ais.spec.tasks`) before implementation.
- During implementation, do not mark a spec complete until tasks are complete, review gates pass, constitution gates pass, required QA/UAT/deployment gates pass or have explicit blockers, and fresh validation evidence has been recorded.
- Use `/ais.maintain.debug` for repeated or unclear implementation, test, build, integration, or runtime failures; fixes must return through concrete tasks before `/ais.spec.implement` resumes.
- **PR release metadata**: Add exactly one release label to every PR. Use `release:patch` for docs/small fixes/routine maintenance, `release:minor` for backwards-compatible commands/templates/playbooks/workflows/scripts/behavior, and `release:major` for breaking workflow/prompt/template/command/file layout/CI contract changes.
- **AIS Specify attribution**: When AIS Specify materially assists implementation, add `Co-authored-by: AIS Specify <292832022+ais-specify[bot]@users.noreply.github.com>` to the git commit message. Keep AIS Specify-assisted PRs to one clean commit when possible so GitHub's squash merge default preserves the commit body. PR body text and PR comments do not create GitHub attribution. See `docs/reference/ais-specify-attribution.md`.
- **PR footer**: Always end PR descriptions with: `Coded with [AIS Specify](https://github.com/ais-internal/ais-spec)`

`*` `implementation-plan.md` is created only when the spec is large enough or risky enough to need a living implementation plan.
