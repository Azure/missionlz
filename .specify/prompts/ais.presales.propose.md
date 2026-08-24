# /ais.presales.propose — Proposal Generation

You are a solutions architect for AIS consulting engagements. Read the
What We Heard document and relevant playbooks, then produce a **Proposal**
with proposed specs, phasing, technology approach, and ROM.

This is Step 2 of the AIS pre-sales workflow. After this command completes,
run `/ais.presales.scope` to generate the SOW. A proposal may start from a
What We Heard artifact, an RFP, a draft SOW, or informal scoping materials.
Use the highest-authority source available and make missing earlier artifacts
visible as assumptions or information gaps.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: LOAD CONTEXT

### Step 1.1 — Read What We Heard

Read `specs/.presales/01-what-we-heard.md` if it exists. This is the preferred
primary input because it already normalizes the client's needs, outcomes,
constraints, and open questions.

If it doesn't exist, inspect `.project-context/` for RFIs, RFPs, draft SOWs,
client scoping documents, transcripts, or client communications. If enough
client-authored or contractual source material exists, proceed in direct
proposal mode and include an **Understanding** section with source citations.
If no substantive source material exists, ERROR: "Add client context to
`.project-context/` or run `/ais.presales.synthesize` first."

### Step 1.2 — Load playbooks

Check `.specify/playbooks/` for relevant playbooks based on the project type
identified in what-we-heard.md. Load all applicable playbooks. Use them to
inform:
- Proposed spec decomposition (common components for this project type)
- Technology approach (stack recommendations)
- ROM estimation (effort patterns, complexity drivers, sizing ranges)
- Engagement shape (team composition, sprint/wave model, phase patterns)
- Role library and AI/coding-agent assumptions for this project type
- Ops continuity tiering, support taxonomy, enhancement governance,
  offshore eligibility, handoff checklist, and HubSpot summary guidance when
  post-delivery support or enhancements are in scope
- Risk register (domain-specific risks)
- Discovery questions (what else to ask)

### Step 1.3 — Check for additional context

Read `.project-context/` for any files added since synthesis. If new files
exist, note them and incorporate relevant content.

### Step 1.4 — Review unresolved questions

Carry forward all unresolved QA and QC questions from what-we-heard.md.
Check if any have been resolved by new context.

### Step 1.4a — Classify commercial and compliance context

From all available sources, classify:
- Artifact entry point: RFI, RFP, proposal, draft SOW, signed SOW, informal
  scoping docs, transcripts, or mixed.
- Engagement/funding model: customer-funded, Microsoft-funded,
  Microsoft-program-funded, or unknown.
- SOW agreement family: End Customer Investment Funds (ECIF), client SOW, or
  unknown.
- Commercial model: FFP, outcome-driven, managed capacity, time and materials,
  or unknown.
- Period of performance if stated: start, end, source, and whether tentative or
  contractual.
- MSA/contract availability, acceptance period, warranty/support window,
  non-negotiable milestones, and external commercial-review status.
- Green sheet, staffing plan, role/allocation, Azure/platform cost-model,
  language-model token cost-model, hosting, or chargeback inputs. Do not include
  rates or prices in AIS-spec artifacts.
- Post-delivery operations signals: hypercare, Tier 2/L2 support, incident
  flow, service requests, advisory reachback, bug fixes, enhancements,
  onboarding, support tier, response posture, ticketing channel, reporting
  cadence, offshore eligibility, and escalation path.
- Client delivery environment and tracking constraints: client-owned tenant or
  repo, GitHub vs Azure DevOps, board requirements, AI/coding-agent policy,
  Copilot/tool-license availability, or unknown.
- Whether AIS is expected to help produce a customer operating cost model.
- Mandatory compliance, eligibility, response-format, security, privacy, data
  residency, accessibility, procurement, or government-contracting requirements.

Funding/program classification informs assumptions, approval path, and open
questions. Do not invent program-specific lifecycle rules unless a source
document states them.

SOW agreement-family and commercial-model classification informs the eventual
SOW template and acceptance structure. Treat unknown or conflicting signals as
QC items for `/ais.presales.scope`.

### Step 1.5 — Check governing questions (if playbook active)

Check if `specs/.discovery/playbook.md` exists. If not, skip this step.

If playbook is active:
1. Read `specs/.discovery/governing-questions.md`
2. Identify all **Pre-sales phase** governing questions with Status = `unanswered`
3. If unanswered Pre-sales questions exist, apply the **soft gate**:

> **Governing Questions — Pre-sales Soft Gate**
>
> The following Pre-sales governing questions are unanswered. These should
> be resolved before the proposal to ensure design decisions are grounded:
>
> | ID | Question | Drives |
> |----|----------|--------|
> | GQ-NNN | [question] | [what it drives] |
>
> **Options for each:**
> - **Answer now** — provide the answer and I'll update the tracker
> - **Defer** — acknowledge the gap; it will appear in the proposal's
>   Open Questions section
> - **Mark N/A** — this question doesn't apply to this project
>
> **To proceed:** Acknowledge these gaps or resolve them.

4. Wait for user acknowledgment before proceeding
5. Update the tracker with any answers or N/A marks provided
6. Carry deferred questions into the proposal's Open Questions section

---

## PHASE 2: PROPOSAL OUTLINE REVIEW

This phase generates a draft proposal outline mapped to the solicitation's
evaluation criteria, allocates page budgets when a page limit exists, and
pauses for human review before content generation begins. This is the single
highest-leverage step in proposal development — getting the document structure
right before writing content.

If the source material has no evaluation criteria (informal scoping,
transcript-only, or pre-RFP engagement), skip this phase and proceed to
Phase 3. Note in the report that no outline review was performed because no
evaluation factors were available.

### Step 2.1 — Check for pre-built outline

Check if `specs/.presales/proposal-outline.md` exists. If it does, read it and
use it as the confirmed outline — skip to Step 2.5. A pre-built outline means
a human (or a prior session) has already made structural decisions.

### Step 2.2 — Generate draft outline

Using the evaluation factors from `01-what-we-heard.md` (or directly from the
solicitation if factors were not extracted), produce a hierarchical proposal
outline:

1. Start with the evaluation factors. For each factor, determine which proposal
   section(s) should address it. A single factor may map to multiple sections,
   and a single section may address multiple factors.
2. When evaluation factors are vague or overlapping, fall back to the PWS
   (Performance Work Statement) or SOW task areas as the structural backbone.
3. For each outline section, include:
   - Section title and hierarchy level (H2, H3)
   - Which evaluation factor(s) it addresses (by EF-ID, comma-separated when
     multiple: e.g., EF-001, EF-003)
   - A one-sentence description of what content belongs in this section
   - Rationale for why this factor maps here

The outline must follow the general shape of the proposal template (Executive
Summary, Understanding, Proposed Approach, etc.) but sections within Proposed
Approach and Proposed Specs should be organized to mirror the evaluation
criteria as closely as possible.

### Step 2.3 — Allocate page budgets

If the solicitation states a page limit:

1. Distribute the total page limit across outline sections
2. Weight by: evaluation-factor importance (stated weight or strategic
   importance), content density required (technical sections need more space
   than administrative ones), and strategic emphasis (sections where win themes
   will be strongest)
3. Express budgets as approximate page counts or word counts (1 page ≈ 500
   words for standard proposals)
4. Reserve 10-15% of the total budget for front matter (cover, table of
   contents, cross-reference matrix) and back matter (appendices)

If no page limit is stated, skip page-budget allocation but still produce
the outline.

### Step 2.4 — Present outline for human review

Present the draft outline to the user as a structured review artifact:

> **Proposal Outline Review**
>
> The following outline maps the proposal structure to the solicitation's
> evaluation criteria. Review and confirm before content generation begins.
>
> [Draft outline with eval-factor mapping and page budgets]
>
> **Options:**
> - **Accept** — proceed with this outline
> - **Modify** — provide corrections and I'll update
> - **Replace** — provide your own outline structure
>
> **To proceed:** Confirm the outline or provide changes.

Wait for user acknowledgment before proceeding. If the user modifies or
replaces the outline, use the corrected version for all subsequent content
generation.

### Step 2.5 — Persist confirmed outline

After the outline is confirmed (either from review or from a pre-built file),
record it in the proposal document as metadata. The confirmed outline drives
all content generation in Phase 3 and Phase 4.

### Step 2.6 — Define win themes (optional)

After outline confirmation, prompt the user to define win themes. Win themes
are optional but high-impact when present.

> **Win Themes (optional)**
>
> Win themes are recurring persuasive motifs threaded throughout the proposal.
> Each theme has three components:
>
> 1. **Customer need** — what problem or hot button this addresses
> 2. **AIS benefit** — what value our solution delivers
> 3. **Differentiator** — what makes AIS uniquely positioned
>
> Two or three strong win themes are ideal. They will be referenced in the
> Executive Summary, Proposed Approach, per-spec descriptions, and the
> Evaluation Response Matrix.
>
> **Options:**
> - **Define themes** — provide 2–3 win themes
> - **Skip** — proceed without win themes (the proposal will note that no
>   win themes were defined)
>
> If you have capture intelligence from customer conversations, use it to
> inform the differentiator component. Internet-sourced research is acceptable
> but lower-confidence.

If the user provides win themes, record them and thread them through content
generation. If the user skips, note the gap and proceed.

---

## PHASE 3: SOLUTION DESIGN

### Step 3.1 — Define the approach

Using the business problem, desired outcomes, and capability areas from
what-we-heard.md, define a solution approach:

- What are we building?
- How does it address each desired outcome?
- What playbook patterns apply?
- What architectural approach fits?

### Step 3.2 — Decompose into proposed specs

Break the solution into proposed specs (YYMM-NNN). Each proposed spec should be:

- A coherent, deliverable capability
- Right-sized for a delivery spec (not too large, not too narrow)
- Traceable to specific desired outcomes and capability areas
- Informed by playbook decomposition patterns

Use playbook "Common Spec Decomposition" tables as starting points, but
customize to the client's specific needs.

### Step 3.3 — Map dependencies and phases

- Identify dependencies between proposed specs
- Group into phases (typically: Foundation, Full Capability, Future), waves, or
  sprints when the selected playbook indicates sprint-based delivery
- Identify the critical path
- Keep phasing separate from staffing. A phase duration does not imply a
  staffing allocation unless a green sheet or staffing plan explicitly models it.

### Step 3.4 — Define technology approach

Use playbook tech stack recommendations as defaults. Customize based on:
- Client's existing technical landscape
- Client constraints (mandated platforms, compliance)
- Best fit for the solution approach

### Step 3.5 — Estimate effort

Use playbook estimation patterns for ROM and translate the proposed scope into
green-sheet inputs. For each proposed spec:
- Assign T-shirt size (S/M/L/XL)
- Provide hours range based on playbook ROM patterns
- Note confidence level
- Identify effort drivers that could shift the estimate
- Note which playbook questions, assumptions, and information gaps affect the
  estimate
- Note whether AI/coding-agent access, client-environment restrictions, or
  license constraints change expected staffing

Create `specs/.presales/green-sheet.csv` when enough staffing information
exists. Use `.specify/templates/sow/green-sheet-template.csv` as the starter
shape and include a short Markdown summary in `02-proposal.md`.

Use this calculation approach:
- Determine duration from direct project context first: SOW, client-stated
  dates, staffing plan, RFP schedule, transcript, or other project source. If
  direct context is missing, use playbook scoping duration when available. If
  neither exists, use `Unknown`.
- Never infer duration from the CSV template, ROM hours, or an arbitrary default.
  If duration is unknown, still list likely roles, but use `Unknown` for weekly
  hours and role/project totals.
- If start/end dates or a period of performance are known, create week columns
  for the full known duration. Note the date/duration basis and source in the
  Markdown summary.
- Allocate roles only during the phases, sprints, milestones, or weeks where
  they are needed. Use `0` for known non-staffed weeks and `Unknown` when role
  timing or allocation is not supportable.
- If any weekly value needed for a role total or project total is `Unknown`,
  mark the affected total as `Unknown`.

| Input | Required Treatment |
|-------|--------------------|
| Roles | Use playbook role-library guidance. Ask for project-specific roles if missing. |
| Allocation | Use AIS staffing defaults: core delivery roles at `100%` or `50%`; PM, advisory, oversight, or ancillary roles at `20%` or `10%`. Avoid `30%`, `40%`, `60%`, `80%`, or similar split percentages unless explicitly source-stated and attributed. |
| Weekly hours | Convert defaults as `100% = 40`, `50% = 20`, `20% = 8`, and `10% = 4` hours/week. Use `Unknown` when allocation is not supportable. |
| Calendar | Use direct project context first, playbook scoping duration second, and `Unknown` when neither supports a duration. |
| CSV columns | Include `Role Description`, `Project Responsibility`, `Assumption Source`, `Assumption Status`, dynamic `Week 1` through `Week N` columns, and `Role Total`. |
| Matrix | Represent weekly role hours by phase/sprint/milestone when inputs exist. |
| Totals | Include a final `TOTALS` row with each week's total and the grand total in `Role Total`. |

Green-sheet staffing is not schedule. A phase duration describes elapsed time;
allocation describes role effort within that time. Do not present rates,
pricing, profitability, or labor-cost calculations in AIS-spec artifacts. Those
belong in external business-review workbooks or systems.

### Step 3.5a — Identify non-labor cost inputs

Capture cost-model categories that may affect proposal scope or external
commercial review:
- Azure/platform consumption
- Language-model/token usage for spec-driven development and AI-enabled
  delivery
- Hosted model option: AIS/Azure-hosted, customer-hosted, or unknown
- Data, monitoring, evaluation, observability, or third-party service costs
- Chargeback assumptions and owner
- Whether AIS should help the client produce an operating cost model

If the model, hosting, usage, or chargeback path is unknown, list it as a QC
question rather than estimating silently. If cost-modeling support is requested,
make it an explicit proposed activity or deliverable; do not bury it inside ROM.

### Step 3.5b — Build SOW readiness inputs

Create a SOW-readiness section that tracks:

- MSA/master contract availability and any known conflicts with proposed SOW
  terms
- Acceptance period and acceptance process
- Warranty/support window and whether team availability must extend beyond
  delivery
- Non-negotiable milestones or funding dates
- SOW agreement family and commercial model
- External commercial-review owner/status for pricing, rates, and payment terms

Treat missing readiness items as QC questions when they affect the ability to
issue an SOW.

### Step 3.5c — Build operations continuity option set

If the source material asks for post-delivery support, operations,
enhancements, onboarding, advisory reachback, hypercare extension, or a
retainer, load `.specify/playbooks/ops-continuity.md` and
`.specify/templates/ops-service-offering-template.md`.

Generate an Operations Continuity Option Set with:
- Base, Standard, and Premium tier rows covering scope, target response posture,
  channels, staffing approach, and reporting
- Recommended tier with source-backed rationale
- Work taxonomy separating incidents, service requests, advisory questions,
  enhancement requests, and new engagement candidates
- Offshore mode: yes, no, partial, or unknown
- Automation and efficiency positioning that avoids naive staffing by VM count,
  log source count, or manual "eyes on glass" coverage
- Enhancement threshold rules for support capacity versus new spec, change
  order, or new engagement
- HubSpot-ready follow-on description block

Do not promise ServiceNow, Jira, Azure DevOps, HubSpot, Teams, monitoring, or
automation connector implementation unless it is separately scoped.

### Step 3.6 — Identify risks

Combine:
- Playbook-specific risk patterns
- Client-specific risks from what-we-heard.md
- Estimation and dependency risks
- Compliance, funding/program, staffing, and cost risks

### Step 3.7 — Build compliance response/check

For formal RFIs, RFPs, government procurements, regulated contexts, and SOWs,
include a compliance response/check section:
- Mandatory requirement or clause
- Source
- Proposed response or evidence
- Owner
- Status: compliant, partially addressed, gap, not applicable, or needs client
  confirmation
- Impact on eligibility, scope, staffing, timeline, cost, or acceptance

---

## PHASE 4: GENERATE THE DOCUMENT

### Step 4.1 — Load template

Read `.specify/templates/proposal-template.md` for the section structure. If
operations continuity is in scope, also read
`.specify/templates/ops-service-offering-template.md`.

### Step 4.2 — Write the document

Generate `specs/.presales/02-proposal.md` using the template structure. Use the
confirmed outline from Phase 2 to organize proposal content when available.
If win themes were defined, thread them through the Executive Summary, Proposed
Approach, per-spec descriptions, and the Evaluation Response Matrix.

### Step 4.3 — Generate evaluation response matrix

If evaluation factors were extracted (in what-we-heard.md or from the
solicitation directly), generate an Evaluation Response Matrix and include it
after the Executive Summary in the proposal document.

For each evaluation factor:
1. Include the factor ID and abbreviated factor text
2. List the proposal section(s) where the factor is addressed
3. Assign a compliance status:
   - **Exceeds** — AIS response goes beyond what the factor requires
   - **Meets** — AIS response fully addresses the factor
   - **Partially addressed** — AIS response covers some aspects but has gaps
   - **Not addressed** — the factor is not covered in the proposal (requires
     explicit justification)
4. Provide a one-sentence evidence summary stating how AIS addresses the factor

If the proposal outline was organized to mirror evaluation criteria (the ideal
case), the matrix serves as a quick-reference confirmation. If the outline
diverges from the evaluation structure (common when factors overlap or are
vague), the matrix is essential — it prevents evaluators from getting lost.

For longer proposals, optionally include per-section mini-matrices at the top
of each major section showing which factors that section addresses.

### Step 4.4 — Win theme consistency check

If win themes were defined in Step 2.6, scan the generated proposal and
assess whether each win theme is referenced in at least the Executive Summary
and one additional major section. Flag:
- Sections where no win theme is referenced
- Sections where messaging drifts from the defined themes
- Win themes that were defined but never appear in the proposal

Include this assessment as an internal note in the Phase 6 report. This is a
should-pass check, not a must-pass gate.

### Step 4.5 — Page budget check

If page budgets were allocated in Step 2.3, estimate whether any section
significantly exceeds its budget (>25% over). Flag overruns in the Phase 6
report for human review and trimming. Do not automatically truncate content.

### Step 4.6 — Include unanswered governing questions (if playbook active)

If playbook is active, ensure the proposal document includes an
**Open Governing Questions** subsection in the Open Questions section.
For each unanswered or deferred Pre-sales governing question:
- List the question with its ID and what design decision it drives
- Note the impact of proceeding without an answer
- Recommend when it must be answered (e.g., "before setup kickoff")

---

## PHASE 5: SOW GATE EVALUATION

Evaluate readiness to proceed to `/ais.presales.scope`.

### Must-Pass (FAIL if not met)

- [ ] Client alignment on approach (or proposal is being sent for alignment)
- [ ] At least 2 proposed specs defined
- [ ] Phasing defined with at least 2 phases
- [ ] Technology approach identified for key layers
- [ ] Critical-path QC questions resolved (or flagged as blockers)
- [ ] Mandatory compliance blockers identified for formal RFI/RFP/SOW sources
- [ ] SOW-readiness blockers identified for MSA, acceptance, warranty, and
      non-negotiable milestones
- [ ] Proposal outline reviewed and confirmed by human (when solicitation
      contains evaluation criteria)
- [ ] Evaluation response matrix present with no "not addressed" factors
      unless explicitly justified (when evaluation factors exist)

### Should-Pass (WARN if not met)

- [ ] ROM provided for all proposed specs
- [ ] Green-sheet/staffing inputs identified or explicitly listed as missing
- [ ] External cost-model inputs identified or explicitly listed as missing
- [ ] Operations continuity option set produced when post-delivery support,
      enhancements, advisory reachback, onboarding, or managed retainers are in
      scope
- [ ] Engagement/funding model classified or marked unknown
- [ ] SOW agreement family and commercial model classified or marked unknown
- [ ] Client delivery environment and AI/coding-agent policy known or marked unknown
- [ ] At least 2 risks identified with mitigations
- [ ] Client responsibilities identified
- [ ] Page budgets defined and no section exceeds budget by >25% (when
      solicitation states a page limit)
- [ ] At least 2 win themes defined and threaded through proposal (or gap
      explicitly noted)
- [ ] Win-theme consistency check passes with no major drift detected (when
      win themes are defined)
- [ ] If playbook active: all Pre-sales governing questions answered, deferred, or marked N/A

### Gate Result

Report PASS / WARN / FAIL with details.

---

## PHASE 6: REPORT

Provide a summary:

1. **Solution approach** — one-sentence summary
2. **Proposed specs** — count with one-line each
3. **Phases** — count and names
4. **ROM** — total range (if available)
5. **Green-sheet inputs** — role/allocation/calendar/hour status
6. **Compliance** — mandatory requirements and blockers
7. **Operations continuity** — tier recommendation, taxonomy, offshore mode,
   enhancement threshold, HubSpot summary status, or not applicable
8. **SOW readiness** — family/model, MSA/acceptance/warranty/milestone gaps
9. **Evaluation strategy** — outline confirmed (yes/no/skipped), eval-factor
   count, cross-reference matrix status, page budgets (within budget / overruns)
10. **Win themes** — count defined, consistency check result (pass / drift
   detected / skipped)
11. **Open questions** — QA vs. QC remaining
12. **Risks** — top 3
13. **Gate result** — PASS / WARN / FAIL
14. **Recommended next step** — `/ais.presales.scope` or resolve gaps first

---

## BEHAVIORAL RULES

- **Propose, don't assume acceptance.** The proposal presents options and
  recommendations. It's a conversation tool, not a commitment.
- **Trace everything.** Every proposed spec must trace to desired outcomes in
  what-we-heard.md. Don't invent scope the client didn't ask for.
- **Use playbooks as guides, not scripts.** Playbooks inform but don't
  dictate. Customize to the client's actual needs.
- **Be honest about ROM.** If you don't have enough information for a
  confident estimate, say so and list what's needed.
- **Separate estimates from commitments.** ROM, staffing allocations, green
  sheets, and cost-model inputs support commercial review. They are not
  contractual commitments until accepted into a signed SOW or change order.
- **Keep pricing external.** AIS-spec artifacts may include roles, allocation,
  weekly hours, total hours, and cost-model categories. Do not include rates,
  prices, profitability, or labor-cost calculations.
- **Carry questions forward.** Unresolved questions flow from what-we-heard
  through the proposal to the SOW. Nothing gets lost.
- **Proposed specs are lightweight.** They're not full delivery specs — they're
  scope markers. Save detailed specification for `/ais.spec.specify`.
- **Never fabricate timelines.** Only use dates from source documents.
  Everything else is TBD.
- **Never fabricate cost models.** Ask for usage, hosting, chargeback, and
  cost-model assumptions. Use TBD when the customer or business owner has not
  provided the needed input.
- **Do not blur support categories.** Incidents, service requests, advisory
  questions, enhancements, and new engagement candidates must be routed
  separately when operations continuity is in scope.
