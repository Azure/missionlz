# Implementation Plan: [FEATURE NAME]

This implementation plan is a living document. Keep `Progress`,
`Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective`
current as work proceeds.

## Purpose / Big Picture

[Explain what useful behavior this change enables, why it matters, and how a
reviewer can tell the implementation is working.]

## Progress

- [ ] (YYYY-MM-DD HH:MMZ) [First planned execution step]
- [ ] [Next step]

## Surprises & Discoveries

- Observation: [Unexpected behavior, constraint, or insight]
  Evidence: [Short proof — test output, logs, measurement, or file reference]

## Decision Log

- Decision: [What changed in the implementation approach]
  Rationale: [Why this was the right move]
  Date/Author: [YYYY-MM-DD — name]

## Outcomes & Retrospective

[Summarize what was achieved, what remains open, and what should be promoted
into framework guidance after the work is complete.]

## Context and Orientation

[Describe the current state relevant to this work. Name the important files,
modules, services, data flows, or deployment surfaces using repository-relative
paths. Define any non-obvious terms used below.]

## Milestones

### Milestone 1: [Name]

[Describe the scope, what will exist at the end of the milestone, how to
exercise it, and what proof indicates it is complete.]

### Milestone 2: [Name]

[Describe the next independently verifiable increment.]

## Concrete Steps

1. [Exact change to make, including file paths and implementation scope]
2. [Next change, command, or validation checkpoint]
3. [Safe rollout or cutover step if needed]

## Validation and Acceptance

- **Commands**: [Exact commands to run and the working directory]
- **Expected success signals**: [Exit status, output, screenshots, logs, metrics, or behavior that prove success]
- **Expected failure signals**: [Errors, output, behavior, or missing evidence that would mean the work is incomplete]
- **Behavior to observe**: [What success looks like]
- **Tests/checks**: [Specific tests, lint, build, smoke tests, or manual scenarios]
- **Manual/UAT scenarios**: [Scenario name, acceptance owner, result evidence,
  or N/A]
- **QA status**: [Not started / In review / Passed / Blocked / Not applicable]
- **Deferred or retired test items**: [Item, reason, owner, follow-up, or N/A]
- **Deployment readiness**: [Required gates, rollback/smoke proof, approval
  status, or N/A]

## Evidence Ledger

| Command or scenario | Working directory | Result | Evidence | Owner / Reviewer |
|---------------------|-------------------|--------|----------|------------------|
| [Command/scenario] | [Path] | [Pass/Fail/Blocked] | [Key output, observation, artifact, or link] | [Role/name] |

## Review Plan

- **Spec compliance review**: [How completed work will be checked against spec.md, design.md, tasks.md, and constitution MUST rules]
- **Code quality review**: [How correctness, maintainability, type safety, error handling, security/privacy, and repo pattern consistency will be checked]
- **QA/UAT review**: [How manual judgment, UAT acceptance, deferred tests, and
  deployment readiness will be reviewed when applicable]
- **Blocking criteria**: [Which review findings prevent the next milestone or completion]

## Worktree Isolation Decision

[State whether implementation should run in the current workspace or an isolated
git worktree. If isolated, name the intended worktree location and baseline
validation command. If not isolated, explain why the current workspace is safe.]

## Debugging and Recovery

[Describe the focused reproduction command or scenario to use if validation
fails, how to capture evidence, when to add a recovery task, and when to route
through /ais.maintain.debug.]

## Idempotence and Recovery

[Explain whether the steps are safe to repeat. For risky steps, describe the
retry path, rollback path, or cleanup required.]

## Interfaces and Dependencies

- **Libraries / services**: [What this work depends on]
- **Interfaces / contracts**: [Key types, endpoints, schemas, or modules that must exist]
- **Handoffs**: [Where future contributors should continue if work stops mid-stream]
