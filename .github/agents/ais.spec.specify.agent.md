---
name: "ais-spec-specify"
description: "Create or update a feature specification with QA/UAT readiness. Handles new specs, sub-specs, and re-specification with YYMM-NNN versioning."
handoffs:
  - label: Create Technical Design
    agent: ais-spec-design
    prompt: Create a design for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: ais-maintain-clarify
    prompt: Clarify specification requirements
    send: true
---

<!-- Generated from .specify/prompts/ais.spec.specify.md — do not edit directly -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/ais.spec.specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

### Step 1: Determine Mode (New / Sub-spec / Re-specify)

Detect which mode applies:

- **New spec** (default): No `--parent` flag and not running inside an existing spec directory.
- **Sub-spec**: User passes `--parent YYMM-NNN` (e.g., `--parent 2602-001`).
- **Re-specify**: Command is run while the working directory is inside an existing `specs/YYMM-NNN-*` directory, or user explicitly names an existing spec.

### Step 2: YYMM-NNN Versioning (New Spec)

For **new specs**:

1. Get the current date and derive the YYMM prefix (e.g., `2602` for February 2026).
2. Scan existing directories under `specs/` matching the pattern `specs/YYMM-*` for the current YYMM prefix.
3. Extract the highest NNN sequence number found. If none exist, start at 000.
4. Assign `YYMM-NNN` where NNN = highest + 1, zero-padded to 3 digits (e.g., `2602-001`, `2602-002`).

### Step 3: Generate Short Name

Generate a concise short name (2-4 words) for the branch:

- Analyze the feature description and extract the most meaningful keywords
- Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
- Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
- Keep it concise but descriptive enough to understand the feature at a glance
- Examples:
  - "I want to add user authentication" -> "user-auth"
  - "Implement OAuth2 integration for the API" -> "oauth2-api-integration"
  - "Create a dashboard for analytics" -> "analytics-dashboard"

### Step 4: Sub-spec Handling

When `--parent YYMM-NNN` is provided:

1. **Check parent status**: Read the parent's `tasks.md` (at `specs/YYMM-NNN-*/tasks.md`) and assess implementation state:
   - Count total tasks vs completed tasks (lines with `- [X]` or `- [x]`).
   - **NOT implemented** (0% complete): Ask the user "Parent spec hasn't been built yet. Update it instead?" and wait for confirmation.
     - If user confirms update: switch to **Re-specify mode** on the parent.
     - If user insists on sub-spec: proceed.
   - **Partially or fully implemented**: Proceed with sub-spec creation.

2. **Assign sub-spec ID**: `YYMM-NNN.N` where N is the next available sub-sequence.
   - Scan for existing directories matching `specs/YYMM-NNN.*-*` to find the highest sub-number.
   - Examples: `2602-001.1`, `2602-001.2`.

3. **Directory**: `specs/YYMM-NNN.N-short-name/`

4. **Sub-spec header**: Include `**Parent**: [parent-id]` in the spec metadata.

### Step 5: Re-specify Handling

When run on an existing spec directory:

1. **Check implementation status** by reading `tasks.md` in the spec directory:
   - Count completed vs total tasks.
2. **If unimplemented (0% tasks done)**: Update the existing spec in place. Do not create a new branch or directory.
   - If `design.md` or `tasks.md` exist, warn user: "Existing design and task artifacts will need regeneration after re-specification. Consider running `/ais.spec.design` and `/ais.spec.tasks` again."
3. **If partially or fully implemented**: Warn the user and suggest either:
   - Creating a new spec (`/ais.spec.specify <description>`)
   - Creating a sub-spec (`/ais.spec.specify --parent YYMM-NNN <description>`)

### Step 6: Branch and Directory Setup (New Spec / Sub-spec only)

1. **Fetch remote branches**:

   ```bash
   git fetch --all --prune
   ```

2. **Create branch and directory**:
   - Branch name: `YYMM-NNN-short-name` (or `YYMM-NNN.N-short-name` for sub-specs)
   - Directory: `specs/YYMM-NNN-short-name/` (or `specs/YYMM-NNN.N-short-name/`)

3. **Run setup script**: `bash .specify/scripts/bash/create-new-feature.sh --json "$ARGUMENTS"` with the calculated ID and short-name:
   - Pass `--number` with the NNN sequence number and `--short-name` with the generated name
   - Example: `bash .specify/scripts/bash/create-new-feature.sh --json --number 1 --short-name "user-auth" "Add user authentication"`

   **IMPORTANT**:
   - You must only ever run this script once per feature
   - The JSON is provided in the terminal as output - always refer to it to get actual paths
   - The JSON output will contain BRANCH and SPEC_FILE paths

### Step 7: Generate Specification

1. Load `.specify/templates/spec-template.md` to understand required sections.

1a. **Determine UI applicability** before drafting content:

- Mark the feature as **UI Surface = Yes** if it includes end-user interfaces
   such as web pages, mobile screens, dashboards, portals, forms, or
   interaction-heavy workflows.
- Mark as **UI Surface = No** for API-only, infrastructure-only, data pipeline,
   background processing, and internal automation features without meaningful
   end-user interaction.

When UI Surface = Yes:

- Keep the template's UX-related sections/subsections.
- Add at least 2 UX/accessibility functional requirements (`FR-UX-*`).
- Add at least 1 measurable UX outcome (`SC-UX-*`).
- Populate `Design/Prototype Inputs` with approved design sources, exploratory
   prototype links, or `N/A`.
- Treat AI-generated UI, generated code exports, and prompt-derived design
   language as exploratory unless a human owner has approved them.

When UI Surface = No:

- Remove UX-related template sections/subsections entirely.
- Do not fabricate UX requirements.

1b. **Capture lightweight QA/UAT readiness** before drafting requirements:

- Identify the expected acceptance owner or reviewer when the description,
  project context, or stakeholder roles make that clear. Use `TBD` only when
  the owner materially affects scope and cannot be inferred.
- Create a UAT scenario inventory by naming the business/client-facing
  scenarios that need explicit acceptance. Map each scenario to user stories or
  acceptance criteria when practical.
- Record test data assumptions such as seed data, user roles, tenants,
  integration sandboxes, migration samples, or "N/A" for simple specs.
- Note known areas that need manual or exploratory validation because they rely
  on judgment, usability, business workflow confidence, or release readiness.
- Add traceability notes that explain how requirements, acceptance criteria,
  and later evidence should connect. Keep this as a planning skeleton; do not
  write unit tests, integration tests, or full manual scripts in `spec.md`.

2. **Load constitution** (if `specs/constitution.md` exists): Read and
   extract principle names and their non-negotiable rules. These inform spec
   requirements — e.g., if the constitution mandates "Offline by Default", the
   spec's functional requirements and success criteria must account for offline
   operation. Do not embed implementation details, but ensure the spec's
   requirements are compatible with constitutional principles.

3. Follow this execution flow:

   1. Parse user description from Input
      If empty: ERROR "No feature description provided"
   2. Extract key concepts from description
      Identify: objective, actors, actions, data, constraints, and likely guiding tradeoffs
   3. For unclear aspects:
      - Make informed guesses based on context and industry standards
      - Only mark with [NEEDS CLARIFICATION: specific question] if:
        - The choice significantly impacts feature scope or user experience
        - Multiple reasonable interpretations exist with different implications
        - No reasonable default exists
      - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
      - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
   4. Create the `## Alignment Brief`
      Distill the feature into four tight parts: objective, primary users/actors,
      key scenarios, and guiding principles.
      Keep it concise enough to scan or read aloud at the start of planning or
      review conversations.
      Treat it as a summary of the spec, not a second scope definition.
   5. Fill User Scenarios and QA/UAT Readiness sections
      If no clear user flow: ERROR "Cannot determine user scenarios"
   6. Generate Functional Requirements
      Each requirement must be testable
      Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
   7. Define Success Criteria
      Create measurable, technology-agnostic outcomes
      Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
      Each criterion must be verifiable without implementation details
   8. Identify Key Entities (if data involved)
   9. Return: SUCCESS (spec ready for design)

3. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description while preserving section order and headings. Keep the `## Alignment Brief` short, high-signal, and fully consistent with the fuller sections that follow.

4. For sub-specs: add `**Parent**: [parent-id]` at the top of the spec after the title.

### Step 8: Specification Quality Validation

After writing the initial spec, validate it against quality criteria:

a. **Create Spec Quality Checklist**: Generate a checklist file at `FEATURE_DIR/checklists/requirements.md`:

   ```markdown
   # Specification Quality Checklist: [FEATURE NAME]

   **Purpose**: Validate specification completeness and quality before proceeding to design
   **Created**: [DATE]
   **Feature**: [Link to spec.md]

   ## Content Quality

   - [ ] No implementation details (languages, frameworks, APIs)
   - [ ] Focused on user value and business needs
   - [ ] Written for non-technical stakeholders
   - [ ] Alignment Brief is concise and consistent with the rest of the spec
   - [ ] QA/UAT Readiness is lightweight and does not contain implementation test scripts
   - [ ] All mandatory sections completed

   ## Requirement Completeness

   - [ ] No [NEEDS CLARIFICATION] markers remain
   - [ ] Requirements are testable and unambiguous
   - [ ] Success criteria are measurable
   - [ ] Success criteria are technology-agnostic (no implementation details)
   - [ ] All acceptance scenarios are defined
   - [ ] Acceptance owner/reviewer and UAT scenario inventory are identified or marked N/A/TBD with rationale
   - [ ] Test data assumptions and manual/exploratory focus areas are identified or marked N/A
   - [ ] Requirement-to-acceptance traceability is clear enough for design and tasks
   - [ ] Edge cases are identified
   - [ ] Scope is clearly bounded
   - [ ] Dependencies and assumptions identified

   ## Constitution Alignment

   - [ ] Spec requirements are compatible with all constitutional MUST principles
   - [ ] Success criteria reflect constitutional quality gates (where applicable)
   - [ ] No requirements contradict constitutional technology standards or integration patterns

   ## Feature Readiness

   - [ ] All functional requirements have clear acceptance criteria
   - [ ] User scenarios cover primary flows
   - [ ] Feature meets measurable outcomes defined in Success Criteria
   - [ ] No implementation details leak into specification

   ## Notes

   - Items marked incomplete require spec updates before `/ais.spec.design`
   ```

b. **Run Validation Check**: Review the spec against each checklist item:
   - For each item, determine if it passes or fails
   - Document specific issues found (quote relevant spec sections)

c. **Handle Validation Results**:

   - **If all items pass**: Mark checklist complete and proceed to reporting

   - **If items fail (excluding [NEEDS CLARIFICATION])**:
     1. List the failing items and specific issues
     2. Update the spec to address each issue
     3. Re-run validation until all items pass (max 3 iterations)
     4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

   - **If [NEEDS CLARIFICATION] markers remain**:
     1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
     2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
     3. For each clarification needed (max 3), present options to user in this format:

        ```markdown
        ## Question [N]: [Topic]

        **Context**: [Quote relevant spec section]

        **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]

        **Suggested Answers**:

        | Option | Answer | Implications |
        |--------|--------|--------------|
        | A      | [First suggested answer] | [What this means for the feature] |
        | B      | [Second suggested answer] | [What this means for the feature] |
        | C      | [Third suggested answer] | [What this means for the feature] |
        | Custom | Provide your own answer | [Explain how to provide custom input] |

        **Your choice**: _[Wait for user response]_
        ```

     4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
        - Use consistent spacing with pipes aligned
        - Each cell should have spaces around content: `| Content |` not `|Content|`
        - Header separator must have at least 3 dashes: `|--------|`
     5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
     6. Present all questions together before waiting for responses
     7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
     8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
     9. Re-run validation after all clarifications are resolved

d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

### Step 8b: Markdown Linting (Before Completion)

Before reporting completion, ensure all generated markdown passes linting:

```bash
bash .specify/scripts/bash/lint-markdown.sh --fix "$SPEC_FILE" "$FEATURE_DIR/checklists/"
```

If the command exits with non-zero status:
- Review the lint errors
- Fix the issues in the spec file(s)
- Re-run the linting command
- Do not report completion until all files pass

This ensures the spec is CI-ready and won't fail the `markdown-lint` GitHub Actions job.

### Step 9: Report Completion

Report completion with:
- Spec ID (YYMM-NNN or YYMM-NNN.N)
- Branch name
- Spec file path
- Checklist results
- Markdown lint status (✓ passed)
- Readiness for next phase (`/ais.spec.design`)

**NOTE:** The script creates and checks out the new branch and initializes the spec file before writing.

## General Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- Use the `## Alignment Brief` as the top-of-spec readout: objective, primary
  users/actors, key scenarios, and guiding principles. It should be brief enough
  to ground a meeting quickly without duplicating the full spec.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- `## Alignment Brief` is mandatory and should stay tighter than the sections that follow
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

#### UI-smart section behavior

- UX sections are optional and only included when UI Surface = Yes.
- For non-UI specs, exclude UX sections to keep specs focused and lean.

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: RESTful APIs unless specified otherwise

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)

## Owner Handling

Apply `.specify/policies/owner-resolution.md`. Use the `shaping` stage for a new
or setup-seeded spec, and `reassign` for an owned re-spec. For a sub-spec under
an owned parent, ask whether it inherits that owner or names a different
accountable owner. If the policy or helper is unavailable, report it and leave
`owner` unchanged.

## Status Sync (automatic)

After the spec is written, update the spec's YAML frontmatter:

1. Open the spec.md file that was just written.
2. Update the frontmatter `status` field to `"defining"`.
3. Update the frontmatter `updated` field to today's date (YYYY-MM-DD).
4. Do NOT edit any project plan files — live status is derived from
   frontmatter by `/ais.report.*` commands.
