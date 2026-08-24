# Design: [FEATURE NAME]

**ID**: [YYMM-NNN] | **Date**: [DATE] | **Spec**: [link to spec.md]

## Summary

[Primary requirement + chosen technical approach — 2-3 sentences]

## Technical Context

| Aspect | Decision |
|--------|----------|
| Language | [e.g., Python 3.12 or NEEDS CLARIFICATION] |
| Framework | [e.g., FastAPI or NEEDS CLARIFICATION] |
| Storage | [e.g., PostgreSQL or N/A] |
| Platform | [e.g., Linux server, iOS 17+] |
| Testing | [e.g., pytest, vitest] |

**Performance**: [Targets or NEEDS CLARIFICATION]
**Constraints**: [Hard limits or NEEDS CLARIFICATION]

## UI/UX Scope (UI Features Only)

- **UI Surface**: [Yes/No]
- **Screens/Views in Scope**: [List]
- **Primary Journeys**: [List]
- **Accessibility Target**: [Project target]
- **Approved Visual Source**: [Figma frame/design system/prototype link or N/A]
- **Prototype Status**: [None / exploratory / approved visual reference / rejected]

> Remove this section for non-UI features.

## Constitution Compliance

| Principle | Status | Notes |
|-----------|--------|-------|
| [Principle name] | Pass / Justified | [Detail if justified] |

## Verification Strategy

- **Automated Checks**: [Unit, integration, contract, accessibility, security,
  performance, smoke, or N/A with rationale]
- **Manual / UAT Scope**: [Business-critical journeys, exploratory focus,
  acceptance owner, and explicit out-of-scope items]
- **Test Data**: [Seed data, fixtures, identities, tenant state, data reset
  needs, or N/A]
- **Environment Needs**: [Local, CI, staging, sandbox integrations, feature
  flags, credentials, or N/A]
- **Observability Evidence**: [Logs, metrics, traces, audit records, screenshots,
  exports, or other signals needed to prove behavior]
- **QA Judgment Areas**: [Risky behavior that needs human evaluation beyond
  deterministic checks, or N/A]
- **Deferred / Retired Tests**: [Tests not being run and why, or N/A]

## Research

[Key findings from Phase 0 research — decisions, rationale, alternatives rejected.
Full details in research.md if generated.]

## Existing System Findings

> Use this section when the spec touches an existing codebase, configuration,
> infrastructure, integration, or operational workflow. For greenfield work with
> no existing-system claims, state `N/A` with rationale.

| Claim | Evidence Location | Verification Method | Status |
|-------|-------------------|---------------------|--------|
| [Existing-system claim that affects implementation] | [path:line, source artifact, command output, or UNVERIFIED] | [How the claim was checked] | Verified / UNVERIFIED / N/A |

`UNVERIFIED` findings that touch in-scope implementation files or behavior must
be resolved, waived, or converted into blocking tasks before implementation.

## Data Model

[Entities, fields, relationships, state transitions.
Full details in data-model.md if generated.]

## API Contracts

[Endpoints, request/response shapes, auth requirements.
Full details in contracts/ if generated.]

## UX Decisions (UI Features Only)

- **Information Architecture**: [Navigation and screen grouping]
- **Interaction States**: [default, hover, focus, disabled, loading, error]
- **Responsive Strategy**: [Key breakpoints or adaptive behavior]
- **Motion & Feedback**: [Transition and reduced-motion behavior]
- **Design Tokens**: [Color, type, spacing, radius, elevation, motion]
- **Prototype Decisions**: [Generated UI choices accepted, rejected, or deferred]
- **Implementation Evidence**: [Screenshots, recordings, accessibility checks, visual parity notes]

Optional companion artifacts (when needed):

- `ux/design-system.md`
- `ux/journeys.md`
- `ux/accessibility.md`
- `ux/prototype-notes.md`

> Remove this section for non-UI features.

## Project Structure

```text
[Chosen directory layout for this feature's source code]
```

**Structure Decision**: [Why this layout was chosen]

## Implementation Planning

- **Implementation Plan Required**: [Yes/No]
- **Why**: [Reason this spec does or does not need a living implementation plan]
- **Primary Risks**: [Migration, cutover, rollback, parallel work, unknowns, or N/A]
- **Milestone Shape**: [Suggested execution slices for larger work, or N/A]

## Complexity Tracking

> Only populated if constitution violations must be justified.

| Violation | Why Needed | Simpler Alternative Rejected |
|-----------|------------|------------------------------|
