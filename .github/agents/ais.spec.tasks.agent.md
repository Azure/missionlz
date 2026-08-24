---
name: "ais-spec-tasks"
description: "Generate dependency-ordered task list, required verification work, optional implementation plan, and cross-artifact consistency validation."
handoffs:
  - label: Implement Project
    agent: ais-spec-implement
    prompt: Start the implementation in phases
    send: true
---

<!-- Generated from .specify/prompts/ais.spec.tasks.md — do not edit directly -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `bash .specify/scripts/bash/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: design.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios), implementation-plan.md
   - Note: Not all projects have all documents. Generate tasks based on what's available.
   - Read `PLANS.md` from repo root to understand the required shape of `implementation-plan.md` when one is needed.
   - Extract QA/UAT readiness from `spec.md` and Verification Strategy from
     `design.md`. These determine when verification tasks are required.
   - **IF INFRA**: If `Skills/` contains an infrastructure skill applicable to
     this spec (check `infra/` directory, constitution IaC language, or spec
     involves cloud resource provisioning), load the matching skill:
     - Azure → read `Skills/ais-infra-azure/SKILL.md` and follow its
       `workflow/README.md` "During `/ais.spec.tasks`" section.
     The skill is authoritative — generate exactly the tasks it requires.

3. **Execute task generation workflow**:
   - Load design.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)
   - Load `QA/UAT Readiness` from spec.md and `Verification Strategy` from
     design.md
   - Load `Existing System Findings` from design.md and identify unresolved
     `UNVERIFIED` findings that affect implementation scope
   - Load the `Implementation Planning` section from design.md and determine whether the spec requires `implementation-plan.md`
   - If data-model.md exists: Extract entities and map to user stories
   - If contracts/ exists: Map endpoints to user stories
   - If research.md exists: Extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate verification tasks when required by the spec, acceptance
     criteria, Verification Strategy, risk profile, or constitution gates
   - Generate blocking research or verification tasks before story work for each
     in-scope `UNVERIFIED` existing-system finding. If the finding cannot be
     resolved by a task, report it as a blocker instead of generating dependent
     implementation tasks.
   - Detect if the spec is UI-facing (web/mobile/dashboard/forms/portal interaction)
   - Include UI/UX verification tasks only when UI-facing; skip for non-UI specs
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

4. **Pre-flight check**:
   - If `tasks.md` already exists in FEATURE_DIR, check for completed tasks (`[x]` or `[X]`).
   - If `implementation-plan.md` already exists, check whether it has any completed progress entries (`- [x]` / `- [X]`) or non-placeholder decision/discovery content.
   - If either artifact contains execution progress, warn the user that regenerating will overwrite live implementation state.
   - Offer options: **(A)** Overwrite — replace `tasks.md` and `implementation-plan.md` as needed, **(B)** Create as `tasks-v2.md` and `implementation-plan-v2.md`, **(C)** Abort.
   - Wait for user response before proceeding.

5. **Generate tasks.md**: Use `.specify/templates/tasks-template.md` as structure, fill with:
   - Correct feature name from design.md
   - Verification Scope summarizing required automated checks, manual/UAT
     scenarios, expected evidence, and deferred or retired test items
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, required
     verification tasks, implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)
   - Set the `Implementation Plan` link in the header to `implementation-plan.md` when one is created, otherwise `N/A`

6. **Generate implementation-plan.md when required**:
   - Create `implementation-plan.md` when the design says **Implementation Plan Required: Yes**
   - Also create it when the user explicitly asks for a deeper implementation plan, even if the design did not mark it yet
   - Use `.specify/templates/implementation-plan-template.md` as the structure and follow `PLANS.md`
   - Make the plan self-contained and specific to this spec:
     - Explain the user-visible outcome in `Purpose / Big Picture`
     - Describe the current repository context in `Context and Orientation`
     - Break the work into independently verifiable milestones
     - Translate risky or long-running work into staged execution steps
     - Include concrete commands, validation expectations, and rollback/retry guidance when relevant
     - Include expected success and failure signals for validation commands whenever they are knowable
     - Add an Evidence Ledger table ready to capture fresh command/scenario
       proof, manual/UAT scenario results, QA review status, and deployment
       readiness during `/ais.spec.implement`
     - Add a Review Plan describing spec compliance, code quality, QA/UAT, and
       deployment-readiness review gates after each phase or user story
     - Add a Worktree Isolation Decision stating whether implementation should use the current workspace or an isolated worktree
     - Add Debugging and Recovery guidance for validation failures, including when to route through `/ais.maintain.debug`
     - Seed `Progress` with unchecked steps aligned to the generated tasks, but keep milestones prose-first rather than duplicating the full task list
     - Initialize `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` with placeholders ready for live updates
   - If an implementation plan is not required, do not create a placeholder file. Report that the spec will use `tasks.md` only.

7. **Consistency Check** (absorbed from analyze): After generating tasks.md, automatically run a validation pass:

   a. **Build semantic models**:
      - **Requirements inventory**: Each functional + non-functional requirement with a stable key (derive slug from imperative phrase; e.g., "User can upload file" -> `user-can-upload-file`)
      - **Task coverage mapping**: Map each task to one or more requirements or stories (by keyword / explicit reference patterns)
      - **Constitution rule set**: Load `specs/constitution.md` and extract principle names and MUST/SHOULD normative statements
      - **Cross-spec context**: Read `specs/*/spec.md` frontmatter for inter-spec dependencies and `specs/.architecture/06-tech-stack.md` for technology decisions

   b. **Run detection passes** (focus on high-signal findings, limit to 30 findings total):

      - **Duplication**: Near-duplicate requirements; mark lower-quality phrasing for consolidation
      - **Ambiguity**: Vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria; unresolved placeholders (TODO, TKTK, ???, `<placeholder>`)
      - **Underspecification**: Requirements with verbs but missing object or measurable outcome; user stories missing acceptance criteria alignment; tasks referencing files or components not defined in spec/plan; `UNVERIFIED` existing-system findings that affect in-scope implementation
      - **Constitution alignment**: Requirements or plan elements conflicting with a MUST principle; missing mandated sections or quality gates
      - **Coverage gaps**: Requirements with zero associated tasks; tasks with no mapped requirement/story; non-functional requirements not reflected in tasks
      - **Inconsistency**: Terminology drift (same concept named differently); data entities in plan but absent in spec (or vice versa); task ordering contradictions; conflicting requirements

   c. **Assign severity**:
      - **CRITICAL**: Violates constitution MUST, missing core artifact, requirement with zero coverage blocking baseline functionality, or in-scope `UNVERIFIED` existing-system finding with no verification task or waiver
      - **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion
      - **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case
      - **LOW**: Style/wording improvements, minor redundancy

   d. **Append Consistency Check section** to the task report output (NOT to the tasks.md file itself):

      ```markdown
      ## Consistency Check

      | ID | Category | Severity | Location(s) | Summary | Recommendation |
      |----|----------|----------|-------------|---------|----------------|

      **Coverage**: X/Y requirements mapped (Z%)
      **Issues**: N critical, N high, N medium, N low
      ```

   e. **Act on results**:
      - If CRITICAL issues found: Warn user and recommend resolving before proceeding to `/ais.spec.implement`. List specific remediation steps.
      - If only LOW/MEDIUM: Note them and proceed. User may address at their discretion.

8. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)
   - Consistency check results summary
   - Whether `implementation-plan.md` was created and, if so, its path and milestone count

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context. When `implementation-plan.md` is created, it should provide the narrative execution guidance for larger, riskier work without duplicating every task line.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Verification is CONDITIONAL, not blind**: Do not generate tests for every
requirement by default. Generate automated, manual, UAT, data, observability, or
deployment-readiness tasks when required by the feature specification,
acceptance criteria, Verification Strategy, risk profile, constitution gates, or
an explicit user request such as TDD.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **Description**: Clear action with exact file path

**Examples**:

- CORRECT: `- [ ] T001 Create project structure per implementation plan`
- CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- WRONG: `- [ ] Create User model` (missing ID and Story label)
- WRONG: `T001 [US1] Create model` (missing checkbox)
- WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - Required automated or manual/UAT verification specific to that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each contract/endpoint -> to the user story it serves
   - If contracts are acceptance-critical, externally consumed, risky, or
     mandated by constitution: generate contract test tasks [P] before
     implementation in that story's phase

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships -> service layer tasks in appropriate story phase
   - If test data or migration samples are needed for QA/UAT or automated
     checks: generate setup tasks for fixtures, seed data, reset scripts, or
     documented data assumptions

4. **From Setup/Infrastructure**:
   - Shared infrastructure -> Setup phase (Phase 1)
   - Foundational/blocking tasks -> Foundational phase (Phase 2)
   - Story-specific setup -> within that story's phase

5. **UI/UX Verification (UI specs only)**:
   - Add a task to confirm the approved visual source, design system, or
     prototype authority before implementation work relies on it
   - Add tasks for keyboard navigation/focus visibility in primary journeys
   - Add tasks for loading/empty/error states on critical interactions
   - Add tasks for responsive/adaptive behavior at agreed breakpoints
   - Add tasks for reduced-motion behavior where motion exists
   - Add tasks for screenshot or recording evidence against the approved
     Figma/prototype/design-system source
   - Add tasks to document intentional deviations from prompt-generated or
     Figma-derived output
   - Place these tasks within relevant user story phases or in final polish

For non-UI specs, do not add UI/UX verification tasks.

6. **QA/UAT and Evidence Tasks (when required)**:
   - Add automated test tasks for deterministic behavior that should be
     repeatable in CI or local validation.
   - Add manual/UAT scenario tasks for business-critical workflows, acceptance
     owner review, exploratory judgment, or release readiness.
   - Add observability evidence tasks when logs, metrics, traces, audit
     records, screenshots, or reports are required to prove behavior.
   - Add deployment-readiness tasks for smoke checks, rollback rehearsal,
     environment validation, approval gates, or deferred test disposition.
   - Every required verification task should reference a user story,
     requirement, acceptance criterion, constitution gate, or design risk when
     practical.

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) -> Models -> Services -> Endpoints -> Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns

## Implementation Plan Rules

- `implementation-plan.md` is a spec-level artifact for larger or riskier work, not a replacement for `tasks.md`.
- Prefer creating it when the work includes migration risk, staged rollout, parallel contributors, multiple systems, or significant unknowns.
- The plan must be restartable from repo state alone.
- The plan must name exact files, commands, validation steps, and recovery paths when applicable.
- Keep milestone sections prose-first. Only `Progress` uses checklist-style tracking.
- The plan must identify automated evidence, manual/UAT evidence, QA status,
  deferred or retired test items, and deployment readiness when those apply.

## Sub-spec Handling

Sub-specs (`YYMM-NNN.N`) are independent specs that inherit no parent state. They go through the full task generation lifecycle independently — tasks and any generated `implementation-plan.md` are scoped entirely to the sub-spec's own `spec.md` and `design.md`.

## Markdown Linting (Before Status Sync)

After tasks are generated, ensure all markdown files in the feature directory pass linting:

```bash
bash .specify/scripts/bash/lint-markdown.sh --fix "$FEATURE_DIR/"
```

This command lints all markdown files in the feature directory, including:
- tasks.md
- implementation-plan.md (if generated)
- Any other spec-related documentation

If the command exits with non-zero status:
- Review the lint errors
- Fix the issues in the relevant files
- Re-run the linting command
- Do not proceed to status sync until all files pass

This ensures the task artifacts are CI-ready and won't fail the `markdown-lint` GitHub Actions job.

## Owner Handling

Apply `.specify/policies/owner-resolution.md` at the `build` stage. If the
policy or helper is unavailable, report it and leave `owner` unchanged.

## Status Sync (automatic)

After tasks are generated, update the spec's YAML frontmatter:

1. Open the spec.md file in FEATURE_DIR.
2. Update the frontmatter `status` field to `"ready"`.
3. Update the frontmatter `updated` field to today's date (YYYY-MM-DD).
4. Do NOT edit any project plan files — live status is derived from
   frontmatter by `/ais.report.*` commands.
