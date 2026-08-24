# Constitution: [PROJECT NAME]

**Version**: 1.0.0 | **Ratified**: [DATE] | **Amended**: [DATE]

## Principles

### I. [Principle Name]

[What it requires, why it matters, what is non-negotiable.]

### II. [Principle Name]

[What it requires, why it matters, what is non-negotiable.]

### III. [Principle Name]

[What it requires, why it matters, what is non-negotiable.]

## Technology Standards

| ID | Standard | Decision | Status | Source |
|----|----------|----------|--------|--------|
| TS-001 | [Category] | [Choice] | Decided / Proposed / Open | [Source] |

## Quality Gates

| ID | Gate | Threshold | Enforcement |
|----|------|-----------|-------------|
| QG-001 | Requirement Testability | P1/P2 requirements have objective acceptance criteria or a documented exception | `/ais.spec.specify` checklist and design review |
| QG-002 | UAT Readiness | Business-critical workflows identify acceptance owner, UAT scope, and test data assumptions before implementation | `/ais.spec.design` Verification Strategy |
| QG-003 | Evidence Traceability | Required checks and manual/UAT evidence map back to requirements or user stories | `/ais.spec.tasks` consistency check and PR review |
| QG-004 | QA Review Status | Required QA/manual review is passed, blocked with owner, or explicitly not applicable before completion | `/ais.spec.implement` evidence ledger |
| QG-005 | Deployment Readiness | Release-blocking smoke, rollback, observability, and approval gates are satisfied or deferred with owner | Implementation plan and release review |

## Integration Patterns

| ID | Pattern | Description | Applies To |
|----|---------|-------------|------------|
| IP-001 | [Pattern name] | [How components communicate] | [Which specs] |

## Governance

- Amendments require documentation, versioned bump, and approval
- MAJOR: principle removed/redefined; MINOR: principle added/expanded; PATCH: wording/typos
- All specs validate against this constitution during design phase
- Constitution supersedes individual spec decisions on conflicts
