<!--
  Sync Impact Report
  ==================
  Version change: (template) → 1.0.0
  Bump rationale: MAJOR — initial ratification of the Mission Landing Zone
    constitution, adapted from the EP Cube Graph constitution (v1.20.0) to
    the MissionLZ reality (Bicep IaC hub-and-spoke landing zone for Azure
    sovereign clouds; no web/iOS clients, no Terraform, no Docker ingestion,
    no unit-test framework).
  Adaptations from source:
    - Principle IV retitled "Validation-Driven Infrastructure": keeps the goal
      of 100% automated test coverage but replaces the source's day-one
      100% mandate with a ratcheting "no regression on coverage %" policy,
      layered on top of Bicep build + lint + what-if + single-subscription
      deploy-test gates. Coverage is grown over time, never reduced.
    - "Performance Standards" → "Deployment Standards" (idempotency, what-if,
      deploy time).
    - "Platform Constraints" rewritten around Bicep, ARM/JSON generated
      artifacts, sovereign-cloud parameterization, and MLZ deployment methods
      (Portal, Template Spec, Command Line).
    - "Security" refocused on SCCA / SACA / zero trust (which MLZ implements),
      Key Vault secrets, no hardcoded secrets or env URLs.
    - "DevOps" refocused on Bicep IaC, generated-artifact sync (mlz.json /
      mlz.uiDefinition), super-linter + validate-build-bicep gates, zero
      warnings, and GitHub Issue Discipline.
  Templates requiring updates:
    - .specify/templates/plan-template.md        ✅ no changes needed
    - .specify/templates/spec-template.md        ✅ no changes needed
    - .specify/templates/tasks-template.md       ✅ no changes needed
    - .specify/templates/checklist-template.md   ✅ no changes needed
    - .specify/templates/constitution-template.md ✅ source template (unchanged)
  Follow-up TODOs: none
-->

# Mission Landing Zone Constitution

## Core Principles

### I. Simplicity

- Every solution MUST prefer the most straightforward approach that satisfies the
  requirement. MissionLZ is a highly opinionated, narrowly scoped template — its
  value comes from being simple, minimal, and easy to configure.
- New parameters, modules, layers, or indirection MUST be justified by a concrete,
  present-day need — not a hypothetical future one.
- When two designs solve the same problem, the one with fewer moving parts MUST be
  chosen unless measurable evidence demonstrates the simpler option is
  insufficient.

**Rationale**: MissionLZ exists to deliver a simple, secure, scalable hub-and-spoke
baseline. Unnecessary complexity undermines its core value proposition and raises the
maintenance and review burden for a small maintainer team.

### II. YAGNI (You Aren't Gonna Need It)

- Parameters, configuration options, add-ons, and extension points MUST NOT be built
  until they are explicitly required by a current specification or user story.
- Speculative generalization (e.g., unused conditionals, provider abstractions,
  "just in case" toggles) is prohibited unless a specification demands it.
- Code, parameters, or modules that exist without a covering requirement MUST be
  removed or justified in a plan document.

**Rationale**: Premature features create dead template code, widen the deployment
surface, and obscure the intent of a codebase whose defining feature is a narrow scope.

### III. Single Responsibility Principle

- Every Bicep module, script, and function MUST have one reason to change. If a unit
  does two things, split it.
- Modules SHOULD compose smaller modules rather than growing into one large template
  full of conditionals. Shared concerns MUST be extracted into a reusable module, not
  duplicated across templates.
- When a module is hard to reason about or deploy in isolation, that is a design
  signal — extract the independent concern into a module that CAN be deployed and
  validated on its own.

**Rationale**: SRP keeps modules small, composable, and independently deployable.
Violations surface as sprawling templates, brittle parameter surfaces, and changes
that break unrelated resources.

### IV. Validation-Driven Infrastructure (NON-NEGOTIABLE)

- **Build Clean**: `az bicep build` on `src/mlz.bicep` MUST succeed with zero errors
  before any change is merged. The compiled ARM artifact MUST be regenerated and
  committed in the same change (see Generated Artifact Sync).
- **Lint Clean**: All Bicep linter rules configured in `src/bicepconfig.json` and all
  super-linter checks (Bash, GitHub Actions, Markdown, YAML) MUST pass. Linter
  `error`-level rules MUST NOT be downgraded to bypass a failure.
- **What-If Before Apply**: Non-trivial infrastructure changes MUST be validated with
  a deployment what-if (or an actual test deployment) before merge. Reviewers MUST be
  able to see the intended resource delta.
- **Single-Subscription Test**: Per MLZ's design goals, changes SHOULD be validated by
  deploying into a single test subscription before being promoted for production use.
- **Automated Tests**: New functionality (Bicep modules, PowerShell artifacts, and
  scripts) MUST be accompanied by automated tests wherever a test harness exists for
  that technology (e.g., Pester for PowerShell, and PSRule for Azure / ARM-TTK /
  `az bicep test` for templates). Adding a test harness where none exists yet is
  encouraged and counts toward the coverage ratchet below.
- **Coverage Ratchet (NON-NEGOTIABLE)**: The project's goal is 100% automated test
  coverage. 100% is NOT required from day one. Instead:
  - Coverage MUST be measured and reported in CI.
  - Each change MUST NOT decrease the measured coverage percentage — a strict
    "no regression on coverage %" policy. A change that lowers coverage MUST NOT be
    merged until tests restore or exceed the prior percentage.
  - The enforced coverage floor MUST only ever ratchet upward as coverage improves;
    it MUST NOT be lowered. Lowering the floor requires a constitution amendment.
  - Coverage MUST trend toward 100% over time; new work SHOULD add more tests than
    the minimum needed to avoid regression.
- **Bug-Fix Regression (NON-NEGOTIABLE)**: Every bug fix MUST begin by reproducing the
  defect (e.g., a failing build, a failing deployment, or a documented what-if
  showing the wrong result), then demonstrating the fix resolves it. Fixes MUST NOT be
  merged without evidence the original failure no longer occurs.
- **5-Minute Debug Limit (NON-NEGOTIABLE)**: When debugging an issue (failed
  deployment, broken build, unexplained resource behaviour), stop after 5 minutes of
  unsuccessful investigation and brief the requester with: (a) what was checked,
  (b) what is known vs. unknown, and (c) the candidate hypotheses. No "one more
  search", no "let me just check", no follow-up rabbit holes. Brief and wait for
  guidance.

**Rationale**: MissionLZ's correctness is established by clean compilation, strict
linting, what-if review, real deployment into Azure, and a growing automated test
suite. Full coverage cannot be achieved on day one for an existing IaC codebase, so a
ratcheting "no regression on coverage %" policy grows the safety net steadily toward
100% while keeping the non-negotiable build, lint, and what-if gates that prevent
silently broken templates from reaching downstream consumers who deploy into secure
government environments.

## Deployment Standards

- **Idempotency**: Redeploying the same templates with the same parameters against an
  existing environment MUST NOT cause unintended changes or resource churn.
- **What-If Accuracy**: A what-if against an unchanged environment MUST report no
  changes. Drift between declared templates and deployed state MUST be treated as a
  defect.
- **Deployment Reproducibility**: Given the same commit and parameters, a deployment
  to a fresh subscription MUST produce an equivalent environment.
- **Single-Subscription Baseline**: The template MUST remain deployable end-to-end
  into a single Azure subscription for experimentation and testing, per MLZ design
  goals, while also supporting multi-subscription production topologies.

## Platform Constraints

- **Infrastructure Language**: All infrastructure MUST be authored in Bicep under
  `src/`. The compiled ARM/JSON (`src/mlz.json`) is a generated artifact, not a source
  of truth, and MUST be produced from the Bicep via `az bicep build`.
- **Target Clouds**: Templates MUST remain deployable across Azure Commercial, Azure
  Government, Azure Government Secret, and Azure Government Top Secret. Cloud-specific
  values (endpoints, resource IDs, DNS suffixes) MUST be parameterized or resolved at
  deploy time — hardcoded environment URLs are prohibited.
- **Architecture**: The solution MUST implement a SCCA-compliant hub-and-spoke
  topology. Changes MUST preserve the hub-and-spoke separation and the security
  boundaries it enforces.
- **Deployment Methods**: The template MUST remain deployable via the supported
  methods — Azure Portal (UI definition), Template Spec, and Azure command-line
  tools. Changes to parameters MUST keep `src/mlz.uiDefinition.json` consistent with
  the Bicep parameter surface.
- **Add-Ons**: Optional capabilities MUST be delivered as self-contained add-ons under
  `src/add-ons/` rather than expanding the core template. The core template MUST stay
  minimal.

**Rationale**: Standardising on Bicep and a fixed set of deployment methods keeps the
template auditable and portable across sovereign clouds, which is the whole point of
MissionLZ.

## Security

- **Zero Trust**: MissionLZ implements Microsoft's zero-trust and SACA guidance.
  Changes MUST NOT weaken zero-trust posture. Network location MUST NOT be treated as
  proof of trust; identity-based verification is required at every boundary.
- **SCCA / SACA Compliance (NON-NEGOTIABLE)**: The architecture MUST remain compliant
  with the Secure Cloud Computing Architecture (SCCA) and Microsoft's SACA controls.
  Any change that could affect a compliance control MUST document the impact in the
  plan.
- **Least Privilege**: Every identity, role assignment, and network rule MUST grant
  only the minimum access required. Over-scoped roles and permissive network rules are
  prohibited.
- **Secrets Management**: Keys, passwords, and credentials MUST NOT be stored in
  source, parameter files committed to the repo, or the generated ARM template.
  Secrets MUST be sourced from Azure Key Vault or generated at deploy time. Bicep
  `secure`-decorated parameters MUST NOT have insecure defaults.
- **Encryption**: Data in transit and at rest MUST use encryption consistent with the
  target government cloud's requirements. Plain-text/unencrypted endpoints MUST NOT be
  introduced.
- **Diagnostics & Auditing**: Resources that support diagnostic settings MUST route
  logs to the central Log Analytics workspace so the environment remains auditable.
  Removing or bypassing diagnostic logging is prohibited without a documented
  justification.

**Rationale**: MissionLZ is built for US Government mission customers deploying into
secure and classified clouds. Security controls are the product; weakening them
defeats the reason the landing zone exists.

## DevOps

- **Infrastructure as Code**: All infrastructure and configuration MUST be defined in
  version-controlled Bicep. Manual creation or modification of Azure resources via the
  portal or ad-hoc CLI is prohibited as a substitute for template changes.
- **Generated Artifact Sync (NON-NEGOTIABLE)**: The compiled `src/mlz.json` MUST be
  regenerated from `src/mlz.bicep` and committed in the same change as any Bicep edit.
  The `validate-build-bicep` workflow enforces this — a change that leaves `mlz.json`
  out of sync with the Bicep MUST NOT be merged. The `src/mlz.uiDefinition.json` MUST
  likewise stay consistent with the parameter surface.
- **CI Gates**: The `super-linter` and `validate-build-bicep` workflows MUST pass
  before merge. These gates MUST NOT be bypassed, made informational, or reduced to a
  warning. Raising or removing a gate requires a constitution amendment.
- **CI Zero Warnings**: Errors and warnings reported by CI MUST be analyzed and
  resolved. Persistent warnings that cannot be fixed MUST be suppressed with an inline
  justification comment explaining why.
- **Reproducible Deployments**: Every deployment MUST be reproducible from the
  repository alone. Manual steps (e.g., one-time secret seeding, DNS delegation) MUST
  be documented in the relevant deployment guide with exact commands.
- **GitHub Issue Discipline (NON-NEGOTIABLE)**:
  - **Issues-First Ordering**: The parent Feature issue and its User Story sub-issues
    MUST be created at the very start of the SpecKit workflow — as the first action of
    `/speckit.specify`, BEFORE spec.md, plan.md, or tasks.md are authored or
    committed. spec.md MUST record the parent Feature issue number.
  - **Traceability**: Every User Story issue MUST be a sub-issue of its parent Feature
    issue. Clean Feature → User Story traceability MUST be maintained via GitHub's
    sub-issue relationships. Issues MUST NOT exist without proper parent linkage.
  - **Synchronization**: Every Feature and User Story defined in speckit documents
    MUST have a corresponding GitHub issue. GitHub issues are the source of truth;
    speckit documents reflect that truth. When an issue is added, updated, or
    completed, the corresponding speckit document MUST be updated accordingly.
  - **Task Tracking**: Tasks in tasks.md do not require individual GitHub issues.
    Tasks MUST be reflected as checklist items in their parent User Story issue body,
    and completion tracked in both tasks.md and the issue checklist.

**Rationale**: Infrastructure as code with enforced build/lint gates ensures
auditability, reproducibility, and no configuration drift. Keeping the generated ARM
template in sync guarantees consumers who deploy `mlz.json` get exactly what the Bicep
declares.

## Development Workflow

- **Branching**: Each feature or fix MUST be developed on a dedicated branch. Direct
  commits to `main` are prohibited.
- **Commits**: Commits MUST be atomic and describe the "what" and "why". One logical
  change per commit.
- **Code Review**: All changes MUST be reviewed against this constitution's principles
  before merge.
- **CI Gate**: The `super-linter` and `validate-build-bicep` workflows MUST pass
  before any branch is merged. No failing checks are permitted on `main`.
- **Documentation**: User-facing behaviour changes (new parameters, changed defaults,
  new add-ons) MUST be reflected in the relevant docs under `docs/` or add-on READMEs
  before merge.
- **Local Build Parity (NON-NEGOTIABLE)**: Contributors MUST be able to reproduce the
  CI build locally. Running `az bicep build --file src/mlz.bicep --outfile
  src/mlz.json` locally MUST catch build errors before push — no one should have to
  wait for CI to discover a compilation failure.

## Governance

- This constitution supersedes all other development practices. When a conflict
  arises, the constitution is authoritative.
- **Amendments**: Any change to this constitution MUST be documented with a version
  bump, rationale, and updated date. Amendments follow semantic versioning:
  - MAJOR: Principle removal or backward-incompatible redefinition.
  - MINOR: New principle or section added, or material expansion.
  - PATCH: Clarifications, wording fixes, non-semantic refinements.
- **Compliance Review**: Every plan and implementation MUST include a Constitution
  Check gate verifying alignment with these principles.
- **Complexity Justification**: Any deviation from Simplicity or YAGNI MUST be
  documented in the plan's Complexity Tracking table with a rejected simpler
  alternative.

**Version**: 1.0.0 | **Ratified**: 2026-07-06 | **Last Amended**: 2026-07-06
