## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `bash .specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR, IMPLEMENTATION_PLAN, and AVAILABLE_DOCS list. All paths must be absolute.

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | PASS   |
     | test.md   | 8     | 5         | 3          | FAIL   |
     | security.md | 6   | 6         | 0          | PASS   |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution order
   - **REQUIRED**: Read design.md for tech stack, architecture, file structure,
     and Verification Strategy
   - **REQUIRED**: Read spec.md for user stories, acceptance criteria, and
     QA/UAT Readiness
   - **REQUIRED**: Read `specs/constitution.md` for non-negotiable
     principles, technology standards, quality gates, and integration patterns.
     Extract all MUST rules — these are hard constraints during implementation.
   - **IF EXISTS**: Read `implementation-plan.md` and `PLANS.md`. Treat `implementation-plan.md` as a living execution artifact that must stay current during implementation.
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   - **IF INFRA**: If `Skills/` contains an infrastructure skill applicable to
     this spec (check `infra/` directory, constitution IaC language, or spec
     involves cloud resource provisioning), load the matching skill:
     - Azure → read `Skills/ais-infra-azure/SKILL.md` and follow its
       `workflow/README.md` "During `/ais.spec.implement`" section.
     The skill is authoritative — implement exactly what it requires.
   - Extract required automated checks, manual/UAT scenarios, test data,
     environment needs, observability evidence, QA judgment areas, deferred or
     retired test items, and deployment-readiness gates. These are completion
     obligations when they are required by the spec, tasks, design, plan, or
     constitution.

4. **Optional Worktree Isolation**:
   - Use an isolated git worktree only when the user explicitly requests it
     (for example, "use a worktree" or "isolated workspace") or when
     `implementation-plan.md` contains a Worktree Isolation Decision requiring
     isolation.
   - If worktree isolation is requested:
     1. Determine the active feature or sub-spec branch from the current branch
        or FEATURE_DIR name.
     2. Prefer `.worktrees/` at the repository root when it already exists;
        otherwise ask before creating a project-local worktree directory.
     3. Before using any project-local worktree directory, verify it is ignored
        with `git check-ignore`. If it is not ignored, STOP and ask whether to
        add the ignore rule before proceeding.
     4. Create or reuse a worktree for the feature/sub-spec branch. If that
        branch is already checked out in the current workspace, report that the
        current workspace is the implementation workspace instead of creating a
        duplicate checkout.
     5. Run the project setup and baseline validation commands from the
        worktree before making changes. If baseline validation fails, report the
        failures and ask whether to debug or proceed.
     6. Do not run framework command generation, release automation, or project
        reporting from a per-spec implementation worktree; those belong in the
        primary repository workspace.
   - Worktree isolation is scoped to the active feature or sub-spec only. Parent
     specs and sibling sub-specs keep their own execution context.

5. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in design.md -> create/verify .dockerignore
   - Check if .eslintrc* exists -> create/verify .eslintignore
   - Check if eslint.config.* exists -> ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists -> create/verify .prettierignore
   - Check if .npmrc or package.json exists -> create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist -> create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) -> create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from design.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

6. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

7. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding
   - **Living implementation plan**: If `implementation-plan.md` exists, keep it aligned with the real execution path before and during code changes

8. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation
   - **Constitution compliance**: Throughout all phases, enforce constitutional
     MUST rules. Use mandated technology standards (e.g., strict mode, typed
     abstractions). Follow integration patterns (e.g., shared abstraction
     layers). If implementation requires deviating from a constitutional
     standard, STOP and flag the deviation with justification before proceeding.
   - **Implementation plan maintenance**: When `implementation-plan.md` exists:
     - Update `Progress` at every meaningful stopping point
     - Record unexpected runtime behavior, test findings, or constraint changes in `Surprises & Discoveries`
     - Record design or sequencing changes in `Decision Log`
     - If the implementation diverges from the written milestone plan, update the plan before or alongside the code change
     - Keep the document restartable by a new contributor from repo state alone

9. Review gates after each phase or user story:
   - After each setup/foundation/story/polish phase, or after each independently
     delivered user story, run two review gates before moving on:
     1. **Spec compliance review**: Confirm completed work maps to the active
        `spec.md`, `design.md`, `tasks.md`, and constitution MUST rules. Verify
        no required behavior is missing and no unrequested scope was added.
     2. **Code quality review**: Check the changed files for correctness,
        maintainability, type safety, error handling, security/privacy impact,
        and consistency with existing codebase patterns.
     3. **QA/UAT review**: When applicable, confirm required automated evidence,
        manual/UAT scenario results, QA review status, deferred or retired test
        disposition, and deployment-readiness evidence are current.
   - Use reviewer agents when available for non-trivial implementation work.
     If reviewer agents are not available, perform the same checks inline and
     record the result in `implementation-plan.md` when present, otherwise in
     the implementation report.
   - Critical or important review findings must be fixed before the next phase
     or story begins. Minor follow-ups may be recorded as tasks only when they
     do not block the current spec's acceptance criteria.
   - Review gates apply independently to sub-specs; do not mark a parent or
     sibling sub-spec reviewed because the active sub-spec passed.

10. Systematic debugging for failures or unexpected behavior:
   - If a test, build, lint, smoke check, integration call, or runtime behavior
     fails unexpectedly, STOP changing implementation code for that issue until
     root cause investigation is complete.
   - Follow this sequence before proposing or applying a fix:
     1. Read the full error output, stack trace, failing assertion, and command
        exit status.
     2. Reproduce the failure with the smallest reliable command or scenario.
     3. Check recent changes and compare against the nearest working pattern in
        the same codebase.
     4. Trace the bad value, state, request, or control flow backward to the
        source. In multi-component flows, inspect each boundary before choosing
        a fix.
     5. State one root-cause hypothesis and the evidence that would prove or
        disprove it.
     6. Write or identify a regression test/check that fails for the observed
        issue before applying the fix whenever the project has a suitable test
        surface.
     7. Apply one minimal fix for the root cause, then rerun the focused
        reproduction and required broader validation.
   - Do not stack speculative fixes. If three fix attempts fail, STOP and route
     to `/ais.maintain.debug` with the commands, outputs, changed files, and
     hypotheses already tested.
   - If debugging identifies work outside the current task list, add or propose
     a concrete recovery task in `tasks.md` before handing back to this command.

11. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT**: For completed tasks, mark the task off as [X] in the tasks file.
   - **IMPORTANT**: If `implementation-plan.md` exists, keep `Progress` synchronized with what actually happened, not what was originally expected to happen.

12. Completion validation:
   - Verify all required tasks are completed.
   - Confirm every phase/story review gate has passed or has an explicit
     non-blocking follow-up task.
   - Identify the exact commands and manual scenarios that prove completion for
     this spec. Run the full commands fresh, from the correct working
     directory, and read the output before making any completion claim.
   - Record an evidence ledger with command/scenario, working directory, result,
     and the key output or observation. If `implementation-plan.md` exists,
     place this in `Validation and Acceptance` or `Outcomes & Retrospective`;
     otherwise include it in the final implementation report.
   - Verify required automated checks have fresh evidence, required manual/UAT
     scenarios have a result or explicit blocker, QA review status is current,
     deferred or retired test items have rationale and owner, and deployment
     readiness gates have evidence or documented blockers.
   - Check that implemented features match the original specification.
   - For UI specs, verify the implementation against the approved visual
     source recorded in `design.md`, not against unapproved prompt-generated
     output. Capture screenshot or recording evidence and document intentional
     deviations from Figma/prototype/design-system references.
   - Validate that tests pass and coverage meets requirements.
   - Confirm the implementation follows the technical design.
   - **Constitution gate check**: Verify the implementation satisfies
     constitutional quality gates (e.g., accessibility, offline operation,
     performance thresholds). List each applicable gate and its pass/fail
     status. If any MUST gate fails, flag it as a blocking issue.
   - If `implementation-plan.md` exists, write an `Outcomes & Retrospective`
     entry summarizing what was achieved, what changed during implementation,
     and any follow-on work or framework lessons worth promoting.
    - Report final status only after the evidence ledger, review gates, task
      completion, and constitution gate all pass. If any proving command cannot
      be run, say the work is not fully verified and do not mark the spec
      complete.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/ais.spec.tasks` first to regenerate the task list. If `implementation-plan.md` is absent, continue with tasks only.

## Sub-spec Handling

Sub-specs (`YYMM-NNN.N`) are independent specs that inherit no parent state. They go through the full implementation lifecycle independently — tasks, artifacts, and any `implementation-plan.md` are scoped entirely to the sub-spec's own directory.

## Owner Handling

Before executing tasks, apply `.specify/policies/owner-resolution.md`: use the
`build` stage when `owner` is empty and the `reassign` stage when it is set. If
the policy or helper is unavailable, report it and leave `owner` unchanged. At
`reassign`, preserve the existing owner unless the user explicitly confirms a
replacement; do not present replacement as the default.

## Status Sync (automatic)

During and after implementation, update the spec's YAML frontmatter:

1. Open the spec.md file in FEATURE_DIR.
2. When the first task is marked [X]: update frontmatter `status` to `"in-dev"`.
3. When all tasks are [X] and all review gates, evidence-before-completion
   checks, and constitution gates pass: update frontmatter `status` to
   `"complete"`.
4. After each status change, update the frontmatter `updated` field to today's date (YYYY-MM-DD).
5. Do NOT edit any project plan files — live status is derived from
   frontmatter by `/ais.report.*` commands.
