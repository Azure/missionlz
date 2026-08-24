---
name: "ais-spec-design"
description: "Create the technical design -- research, data model, contracts, Verification Strategy, architecture decisions, and implementation planning guidance."
handoffs:
  - label: Create Tasks
    agent: ais-spec-tasks
    prompt: Break the design into tasks
    send: true
---

<!-- Generated from .specify/prompts/ais.spec.design.md — do not edit directly -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `bash .specify/scripts/bash/setup-design.sh --json` from repo root and parse JSON for FEATURE_SPEC, DESIGN, FEATURE_DIR, BRANCH.

2. **Load context**: Read FEATURE_SPEC and `specs/constitution.md`. Load the design template at `.specify/templates/design-template.md` (DESIGN already copied by script). Also read `specs/.architecture/06-tech-stack.md`, `specs/.architecture/07-decisions.md`, and `PLANS.md` for project-wide technology context, architectural decisions, and the standard for `implementation-plan.md`.

2a. **Determine UI applicability from spec.md**:

- Treat as **UI feature** when spec includes end-user interfaces (web/mobile/
   dashboard/form/portal flows).
- Treat as **non-UI feature** when spec is API-only, infra-only, data pipeline,
   or background automation.

When UI feature:

- Populate `UI/UX Scope` and `UX Decisions` sections in `design.md`.
- Generate optional UX artifacts under `FEATURE_DIR/ux/` only when they add
   decision clarity: `design-system.md`, `journeys.md`, `accessibility.md`,
   `prototype-notes.md`.
- Record approved visual sources, Figma/prototype links, approval status,
   design-system constraints, and generated prototype decisions that were
   accepted, rejected, or deferred.
- Treat prompt-generated UI and design-tool code exports as exploratory inputs
   unless an approving role has promoted them into `design.md` decisions.

When non-UI feature:

- Remove UI/UX sections from `design.md` and skip `ux/` artifacts.

2b. **Translate QA/UAT readiness into a Verification Strategy**:

- Read the `QA/UAT Readiness` section in `spec.md`, including UAT scenario
  inventory, acceptance owner/reviewer, test data assumptions, manual or
  exploratory focus areas, and traceability notes.
- Populate `Verification Strategy` in `design.md` with the checks and evidence
  needed to prove the spec, without turning the design into a detailed test
  script.
- Cover automated checks where they are useful and practical: unit,
  integration, contract, accessibility, security, performance, smoke, or
  regression checks.
- Cover manual/UAT scope for business-critical journeys, judgment-heavy
  workflows, exploratory testing, and release readiness.
- Identify environment, test data, and observability needs early enough for
  `/ais.spec.tasks` to generate the right setup and evidence tasks.
- State `N/A` with rationale when a category does not apply. Do not invent QA
  work for trivial or low-risk specs.

2c. **Load applicable infrastructure skills**:

- If `Skills/` directory contains infrastructure skills relevant to this spec
  (check `infra/` directory exists, constitution references an IaC language, or
  spec involves cloud resource provisioning), load the matching skill:
  - Azure → read `Skills/ais-infra-azure/SKILL.md`, load relevant `standards/`
    files per its "Loading Instructions", and follow its
    `workflow/README.md` "During `/ais.spec.design`" section.
- The skill defines the default standards for all infrastructure decisions in
  this design. The project constitution takes precedence where they conflict.
  Where a project requirement or constraint means a skill rule cannot be met,
  document an exception in design.md per the skill's exception format — do not
  silently deviate.

3. **Execute design workflow**: Follow the structure in the design template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Fill Verification Strategy:
     - Automated checks: unit, integration, contract, accessibility, security,
       performance, smoke, or regression expectations
     - Manual/UAT scope: scenarios, acceptance owner/reviewer, exploratory
       focus, and explicit out-of-scope items
     - Test data, environment, and observability evidence needed to prove
       behavior
     - QA judgment areas and any deferred or retired tests with rationale
   - Fill Implementation Planning section:
     - Set **Implementation Plan Required** to `Yes` when the spec is large or execution-risky enough that `tasks.md` alone is not sufficient
     - Default to `Yes` when effort is `L` or `XL`, when migrations/cutovers/rollback risk exist, when the work spans multiple systems or contributors, or when the user explicitly asks for a deeper implementation plan
     - Otherwise set it to `No` and explain why a regular task list is sufficient
     - Suggest milestone shape and primary execution risks when the answer is `Yes`
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION and cite
     evidence for existing-system claims)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Evaluate constitution gates after Phase 1 design is complete. If MUST principles are violated without justification, ERROR and halt.

4. **Stop and report**: Command ends after Phase 1 design. Report branch, DESIGN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

0. **Check governing questions (if playbook active)**:

   Check if `specs/.discovery/playbook.md` exists. If not, skip this step.

   If playbook is active:
   1. Read `specs/.discovery/governing-questions.md`
   2. Identify **Design-phase** governing questions relevant to this spec's
      domain (match by domain tag or by the design decision the question drives)
   3. For each relevant unanswered Design-phase question:
      - Add it as a research task: "Resolve GQ-NNN: [question]"
      - The research output should provide enough context to answer the question
        or confirm it needs escalation to the user
   4. After Phase 0 research completes, update the tracker with any resolved
      questions

   This ensures spec-level design is informed by playbook-level discovery.

1. **Extract unknowns from Technical Context**:
   - For each NEEDS CLARIFICATION -> research task
   - For each dependency -> best practices task
   - For each integration -> patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Apply Codebase Evidence standard for brownfield work**:

   When research describes existing code, configuration, infrastructure,
   workflow behavior, deployment shape, or repository conventions:

   - Cite concrete evidence with `path:line` whenever the source is in the
     repository.
   - Use a URL, command output reference, or named source artifact only when the
     evidence is outside the repository.
   - Mark the claim `UNVERIFIED` when no evidence was found or the evidence is
     ambiguous.
   - Do not turn an `UNVERIFIED` claim into a design decision. Escalate it as a
     clarification, research follow-up, or implementation blocker.

4. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Evidence: [path:line, source artifact, command reference, or UNVERIFIED]
   - Alternatives considered: [what else evaluated]

5. **Populate Existing System Findings in `design.md`**:

   - Include every existing-system claim that materially affects implementation.
   - For each finding, record the claim, evidence location, verification method,
     and status (`Verified`, `UNVERIFIED`, or `N/A`).
   - If any `UNVERIFIED` finding touches in-scope implementation files or
     behavior, call it out as a design risk for `/ais.spec.tasks`.

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** -> `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action -> endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Agent context update**:
   - Run `bash .specify/scripts/bash/update-agent-context.sh`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current design
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

### Verification Strategy Guidance

The `Verification Strategy` section is the handoff from specification to
execution planning:

- Use automated checks for repeatable and deterministic behavior.
- Use manual QA/UAT for judgment, exploratory confidence, business workflow
  acceptance, and release-readiness evaluation.
- Tie each required check or scenario to requirements, user stories, or
  acceptance criteria where practical.
- Capture test data and environment needs early; missing data or unavailable
  environments are design risks, not implementation surprises.
- Name the observability evidence reviewers should expect, such as logs,
  metrics, traces, audit entries, screenshots, exports, or generated reports.
- Do not create a separate QA command surface or companion artifact unless the
  spec's size and risk clearly justify one.

## Markdown Linting (Before Status Sync)

After Phase 1 design is complete, ensure all generated markdown files pass linting:

```bash
bash .specify/scripts/bash/lint-markdown.sh --fix "$FEATURE_DIR/"
```

This command lints all markdown files in the feature directory, including:
- research.md
- data-model.md
- quickstart.md
- Any other generated documentation files

If the command exits with non-zero status:
- Review the lint errors
- Fix the issues in the relevant files
- Re-run the linting command
- Do not proceed to status sync until all files pass

This ensures the design artifacts are CI-ready and won't fail the `markdown-lint` GitHub Actions job.

## Key Rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
- All design artifacts go in FEATURE_DIR alongside the spec
- The output file is `design.md`

## Sub-spec Handling

Sub-specs (`YYMM-NNN.N`) are independent specs that inherit no parent state. They go through the full design lifecycle independently — design artifacts are scoped entirely to the sub-spec's own `spec.md`.

## Owner Handling

Apply `.specify/policies/owner-resolution.md` at the `build` stage. If the
policy or helper is unavailable, report it and leave `owner` unchanged.

## Status Sync (automatic)

After the design is complete, update the spec's YAML frontmatter:

1. Open the spec.md file in FEATURE_DIR.
2. Update the frontmatter `status` field to `"planning"`.
3. Update the frontmatter `updated` field to today's date (YYYY-MM-DD).
4. Do NOT edit any project plan files — live status is derived from
   frontmatter by `/ais.report.*` commands.
