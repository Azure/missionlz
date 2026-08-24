# Implementation Plans

This document defines the AIS standard for `implementation-plan.md`, a living
spec artifact used when a feature is large enough or risky enough that
`design.md` and `tasks.md` are not sufficient on their own.

## When To Use An Implementation Plan

Use `specs/YYMM-NNN-name/implementation-plan.md` when one or more of these are
true:

- The spec effort is `L` or `XL`
- The work is a major refactor, migration, or platform change
- The implementation touches multiple systems, repos, or deployment surfaces
- The work will span multiple PRs, multiple contributors, or long-running agent sessions
- The design includes major unknowns, spike work, rollback risk, or staged cutovers
- The user explicitly asks for a deeper implementation plan

Do not create `implementation-plan.md` for every spec by default. Small,
straightforward specs should continue to use `spec.md`, `design.md`, and
`tasks.md` only.

## Role In The AIS Workflow

`implementation-plan.md` is not a replacement for existing artifacts:

- `spec.md` defines what and why
- `design.md` defines the technical approach
- `tasks.md` defines atomic implementation work
- `implementation-plan.md` explains how the work will actually be delivered,
  validated, and recovered if execution gets interrupted or the plan changes

When QA/UAT applies, the plan also ties the spec's readiness signals to
execution evidence: automated checks, manual/UAT scenarios, QA review status,
deferred or retired test items, and deployment readiness.

Treat it as the bridge between task generation and long-running implementation.

## Core Requirements

Every implementation plan must be:

- **Self-contained**: a new contributor should be able to resume the work from
  the plan and current repo state alone
- **Outcome-focused**: describe what useful behavior will exist and how to
  observe it
- **Living**: update it as progress is made, discoveries occur, and decisions
  are finalized
- **Concrete**: name exact files, modules, commands, and validation steps
- **Safe**: include retry, rollback, or staged-cutover guidance when the work
  is risky or stateful

## Required Sections

Every `implementation-plan.md` must contain these sections:

- `Purpose / Big Picture`
- `Progress`
- `Surprises & Discoveries`
- `Decision Log`
- `Outcomes & Retrospective`
- `Context and Orientation`
- `Milestones`
- `Concrete Steps`
- `Validation and Acceptance`
- `Evidence Ledger`
- `Review Plan`
- `Worktree Isolation Decision`
- `Debugging and Recovery`
- `Idempotence and Recovery`
- `Interfaces and Dependencies`

## Writing Guidance

- Write in plain language and define project-specific terms the first time
  they appear.
- Prefer prose for narrative sections. Use checkboxes only in `Progress`.
- Name repository-relative paths explicitly.
- Describe what to run, where to run it, and what success looks like.
- Include expected output or failure signals for validation commands whenever
  the signal is known in advance.
- Record the reason for major course changes, not just the final choice.
- Keep the plan current. If the implementation diverges from the written plan,
  update the plan before or alongside the code change.
- Do not leave execution-time placeholders. Placeholder text is acceptable only
  in the template before `/ais.spec.tasks` fills the plan.

## Progress Tracking

`Progress` is the live execution ledger. Each entry should:

- Use a checkbox
- Include a timestamp
- Distinguish finished work from remaining work when a milestone is partially complete

Example:

- [x] (2026-04-21 14:00Z) Added contract tests for the ingestion adapter.
- [ ] Wire the adapter into the runtime path and verify dual-path behavior.
- [ ] Partially complete the cutover rehearsal (completed: dry-run in staging;
  remaining: production rollback exercise).

## Discovery And Decisions

Use `Surprises & Discoveries` for facts you learned while implementing:

- unexpected runtime behavior
- performance constraints
- missing assumptions in the design
- edge cases only revealed by tests, logs, or real data

Use `Decision Log` for choices you made because of those findings. Each entry
should include the decision, the rationale, and the date/author.

## Validation Standard

Validation is mandatory. Every plan must explain:

- what commands to run
- the working directory for each command
- what output, exit status, or observable behavior indicates success
- what output, exit status, or observable behavior indicates failure
- what behavior to observe
- what tests or checks prove the change works
- what failures would indicate the work is incomplete
- which manual/UAT scenarios, QA review outcomes, deferred or retired test
  items, and deployment-readiness gates apply

When relevant, describe the exact before/after proof, such as a failing test
that now passes or a manual scenario that now works.

Do not claim a milestone or spec is complete until fresh validation evidence has
been recorded. Evidence belongs in the plan's `Evidence Ledger` when the plan
exists; for smaller specs without `implementation-plan.md`, `/ais.spec.implement`
must include the same evidence in its final report before marking the spec
complete.

Manual QA/UAT evidence is not required for every small spec. It is required
when the spec, acceptance criteria, Verification Strategy, constitution, risk
profile, or release gate says human judgment or business acceptance is needed.
Deferred or retired test items must name the reason, owner, and follow-up or
accepted risk.

## Idempotence And Recovery

If the work is safe to repeat, say so. If it is not, say how to recover:

- retry steps
- staged rollout order
- rollback path
- cleanup expectations

Prefer additive, testable changes over destructive or one-shot operations.

## Worktree Isolation

Use `Worktree Isolation Decision` to state whether implementation should run in
the current workspace or an isolated git worktree. Choose an isolated worktree
when the work is long-running, risky, likely to overlap other development, or
explicitly requested by the user. Keep framework maintenance work, command
generation, release automation, and reporting in the primary repository
workspace unless the plan explicitly justifies otherwise.

## Review Plan

Every implementation plan must say how phase or story review gates will run.
At minimum, reviews must check:

- spec compliance against `spec.md`, `design.md`, `tasks.md`, and constitution
  MUST rules
- code quality, including correctness, maintainability, type safety, error
  handling, security/privacy impact, and consistency with repository patterns
- QA/UAT readiness when applicable, including automated evidence, manual/UAT
  scenario results, QA status, deferred test disposition, and deployment gates

Critical and important findings block the next milestone. Minor findings may be
recorded as follow-up tasks when they do not block acceptance criteria.

## Debugging And Recovery

When validation fails, use root-cause debugging before changing more code:

- reproduce the failure with the smallest reliable command or scenario
- read full errors, logs, assertions, and exit status
- compare against recent changes and working patterns
- trace bad data or state to its source
- test one hypothesis at a time
- add or identify regression proof before fixing

If repeated fix attempts fail, stop and reassess the design or route through
`/ais.maintain.debug`.

## Lifecycle Expectations

- `/ais.spec.tasks` may create `implementation-plan.md` for larger or riskier work.
- `/ais.spec.implement` must keep the plan current when it exists.
- Important discoveries from the plan should be promoted later into playbooks,
  prompts, templates, constitutions, or checks when they become reusable.
