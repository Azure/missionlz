# Feature Specification: Validate Weekly MLZ Deployments in AllInOne with Automatic Cleanup

**Feature Branch**: `1309-single-subscription-validation`

**Feature Issue**: [#1309](https://github.com/Azure/missionlz/issues/1309) — Validate weekly MLZ deployments in AllInOne with automatic cleanup (canonical source of truth)

**Created**: 2026-10-22

**Status**: Approved (canonical specification in [#1309](https://github.com/Azure/missionlz/issues/1309))

**Input**: Canonical issue body of [#1309](https://github.com/Azure/missionlz/issues/1309): Deploy core MLZ Bicep from the current `main` branch into the dedicated AllInOne test subscription every week using the supported deployment path, mapping the hub and every enabled spoke to the same verified subscription ID in Azure Government (`AzureUSGovernment`, region `usgovarizona`), running post-deployment validation hooks, and automatically cleaning up run-owned resource groups and subscription-level security resources while preserving pre-existing/bootstrap resources and original failure statuses.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Shared Deployment and Cleanup Lifecycle (Priority: P1)

As a maintainer, I need a repeatable weekly deployment lifecycle with reliable cleanup and visible outcomes so failed validation does not leave test resources running or hide its original failure.

**Why this priority**: Without a deterministic lifecycle that tracks run ownership before provisioning and guarantees cleanup across success, partial failure, and cleanup errors, automated deployments either leak costly resources in the test subscription or mask deployment failures behind successful teardown steps.

**Independent Test**: Exercise the lifecycle against controlled successful, partially failing, and cleanup-failing runs to verify that pre-existing resources are snapshotted and preserved, run-owned resource groups and subscription security artifacts are cleaned up, Defender plans affected by the run return to `Free`, and deployment, testing, and cleanup outcomes remain distinct in the final exit status and report.

**Acceptance Scenarios**:

1. **Given** a target subscription containing pre-existing resource groups, policy assignments, security contacts, and Defender pricing states, **When** a validation run starts, **Then** the lifecycle records a pre-deployment ownership baseline before provisioning any resources so only run-created resources are eligible for deletion or reset.
2. **Given** a completed core MLZ deployment with `deployDefender` enabled, **When** cleanup executes, **Then** the lifecycle deletes only run-created resource groups, deletes only run-created subscription policy assignments and security contacts, resets only Defender plans changed by the run back to `Free`, and leaves pre-existing and bootstrap resources untouched.
3. **Given** a deployment that fails partway through after creating a subset of resource groups or subscription-level settings, **When** the deployment step terminates, **Then** cleanup still runs for all resources created by that run and the overall run still exits as failed with the original deployment failure preserved.
4. **Given** a run where deployment succeeds or fails and a cleanup operation subsequently fails, **When** the run completes, **Then** the cleanup failure is reported visibly and causes the overall validation run to fail.
5. **Given** the post-deployment test hook for [#1310](https://github.com/Azure/missionlz/issues/1310), **When** comprehensive functional tests are not yet provided or a requested test script is missing, **Then** the report records the test phase accurately (such as skipped when not configured, or failed when an explicitly requested test path is missing) and never reports missing tests as passed.

---

### User Story 2 - AllInOne Configuration and Live Validation (Priority: P2)

As a maintainer, I need live evidence for the single-subscription topology so I know the shared lifecycle deploys the hub and all enabled spokes into AllInOne and cleans up afterward.

**Why this priority**: Mocked or static verification cannot prove that the core template provisions and tears down cleanly in a live Azure Government subscription; maintainers need verified live execution evidence in the dedicated AllInOne test subscription (`AzureUSGovernment`, `usgovarizona`).

**Independent Test**: Run the validation lifecycle against the dedicated AllInOne test subscription in `AzureUSGovernment` (`usgovarizona`) for both a full deployment followed by cleanup and a controlled partial-failure deployment followed by cleanup, confirming all run-owned resources and subscription security settings are cleaned up while pre-existing resources remain intact.

**Acceptance Scenarios**:

1. **Given** authenticated access to the dedicated AllInOne test subscription in `AzureUSGovernment` (`usgovarizona`), **When** the AllInOne validation scenario runs on schedule or via manual trigger, **Then** the hub and every enabled spoke (`identity`, `operations`, `sharedServices`) deploy into that single verified subscription ID using the supported deployment path.
2. **Given** a live successful deployment in AllInOne, **When** automatic cleanup completes, **Then** all run-created resource groups and run-created subscription policy assignments/security contacts are removed, affected Defender plans are reset to `Free`, and pre-existing subscription resources remain intact.
3. **Given** a live deployment in AllInOne that fails after creating partial resources, **When** automatic cleanup completes, **Then** the partial run-created resources are removed, pre-existing resources remain intact, and the overall run status remains failed.

---

### Edge Cases

- **Partial deployment failure**: Deployment fails after creating resource groups or subscription policy assignments/Defender pricing changes, before template outputs exist; cleanup must discover run-created resources from the run prefix and pre-deployment baseline snapshot rather than relying on deployment outputs.
- **Pre-existing resources and Defender tiers**: If a subscription already has a resource group, policy assignment, security contact, or a Defender plan set to `Standard` before the run, cleanup must preserve that pre-existing state and must not delete or downgrade it.
- **Defender pricing API constraint**: Subscription-scope Defender pricing does not support the `DELETE` API (which is resource-scope only); cleanup must reset run-modified Defender plans to `Free` rather than attempting deletion.
- **Missing or unavailable functional test suite**: When the comprehensive test suite from [#1310](https://github.com/Azure/missionlz/issues/1310) is not yet present, the lifecycle must not report functional tests as passed.
- **Regional quota constraints**: `usgovvirginia` is excluded due to requester-reported quota restrictions; AllInOne validation targets `usgovarizona` in `AzureUSGovernment`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The validation workflow MUST deploy the core MLZ template from the current `main` branch on a weekly schedule and MUST also support independent manual triggering.
- **FR-002**: In the AllInOne scenario, the deployment MUST map the hub and every enabled spoke (`hubSubscriptionId`, `identitySubscriptionId`, `operationsSubscriptionId`, and `sharedServicesSubscriptionId` with `deployIdentity = true`) to the same verified AllInOne subscription ID in Azure Government (`AzureUSGovernment`), region `usgovarizona`.
- **FR-003**: The deployment MUST perform a real provisioning operation via the supported command-line deployment path rather than only compiling, linting, or running `what-if`.
- **FR-004**: `deployDefender` MUST remain enabled (`true`) during validation runs; Defender deployment MUST NOT be disabled to simplify cleanup.
- **FR-005**: Before starting provisioning, the lifecycle MUST capture a baseline snapshot of existing resource groups, subscription policy assignments, security contacts, and subscription Defender pricing tiers so ownership is established prior to deployment rather than inferred solely from naming patterns afterward.
- **FR-006**: Cleanup MUST execute after every validation run—whether deployment and testing succeed, fail, or partially complete—and MUST delete run-created resource groups, delete run-created subscription policy assignments and security contacts, and reset Defender plans changed by the run back to `Free`.
- **FR-007**: Cleanup MUST preserve all pre-existing resource groups, policy assignments, security contacts, Defender plans already at `Standard`, and authentication/bootstrap resources.
- **FR-008**: The lifecycle report and exit status MUST keep deployment, test, and cleanup outcomes distinct: a failed deployment or test MUST still fail the run even when cleanup succeeds, and a failed cleanup MUST fail the run visibly even when deployment succeeded.
- **FR-009**: The lifecycle MUST provide a post-provisioning, pre-cleanup test integration hook for [#1310](https://github.com/Azure/missionlz/issues/1310) and MUST NOT report missing or unexecuted functional tests as passed.
- **FR-010**: The deployment, configuration, cleanup, reporting, and test lifecycle MUST be structured for reuse by the backlog multi-subscription validation feature ([#1316](https://github.com/Azure/missionlz/issues/1316)) without implementing multi-subscription workflows on this branch.
- **FR-011**: Published run summaries, logs, documentation, and committed files MUST NOT expose credentials, secrets, or customer network addressing.
- **FR-012**: Operations documentation MUST cover reproducible local and CI commands, required configuration and permissions, weekly scheduling, cleanup boundaries, failure investigation, and the shared [#1310](https://github.com/Azure/missionlz/issues/1310) test integration point.

### Key Entities

- **Validation Run Configuration**: The target cloud (`AzureUSGovernment`), region (`usgovarizona`), verified subscription ID(s), unique run identifier/prefix, template path, and optional post-deployment test hook path.
- **Pre-Deployment Ownership Baseline**: The recorded pre-run inventory of subscription resource groups, policy assignments, security contacts, and Defender plan pricing states used to distinguish run-created changes from pre-existing state.
- **Validation Run Report**: The structured outcome record capturing run metadata and separate statuses and error details for the deployment, post-deployment test, and cleanup phases.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Weekly scheduled and manually triggered validation runs provision the complete core MLZ hub-and-spoke topology (`identity`, `operations`, `sharedServices`, and `deployDefender` enabled) into the single AllInOne test subscription in `AzureUSGovernment` (`usgovarizona`).
- **SC-002**: Following both successful and intentionally failed/partial validation runs, all run-created resource groups, run-created subscription policy assignments, and run-created security contacts are removed, and all Defender plans modified by the run are returned to `Free`.
- **SC-003**: Across all validation runs, all pre-existing subscription resources, policy assignments, security contacts, Defender plans, and authentication/bootstrap resources remain intact after cleanup.
- **SC-004**: Every run with a deployment failure, test failure, or cleanup failure exits with a non-zero failure status and surfaces the specific failing phase(s) in the run report without masking earlier failures.
- **SC-005**: Automated unit/lifecycle tests developed via Red-Green-Refactor TDD validate successful deployment, partial deployment failure, cleanup failure, original-failure preservation, and pre-existing resource protection while maintaining or increasing the repository's enforced test coverage baseline.

## Assumptions

- The canonical requirements, User Stories, tasks (`T001`–`T010`), and acceptance criteria live in the body of [#1309](https://github.com/Azure/missionlz/issues/1309); if this file ever differs from the issue body, [#1309](https://github.com/Azure/missionlz/issues/1309) is authoritative.
- Quota-sufficiency verification in `usgovarizona` is deferred during local implementation of the lifecycle and tests, but remains required prior to live provisioning (`T008`/`T009`).
- Comprehensive Bicep and deployed-resource functional assertions belong to [#1310](https://github.com/Azure/missionlz/issues/1310), and multi-subscription deployment validation belongs to [#1316](https://github.com/Azure/missionlz/issues/1316).
