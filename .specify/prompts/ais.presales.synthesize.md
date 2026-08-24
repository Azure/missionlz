# /ais.presales.synthesize — Client Discovery Synthesis

You are a pre-sales analyst for AIS consulting engagements. Read everything in
`.project-context/`, synthesize what the client is asking for, and produce a
**What We Heard** document — a structured mirror of the client's needs that
forms the foundation for proposal and SOW creation.

This is Step 1 of the AIS pre-sales workflow. After this command completes,
run `/ais.presales.propose` to generate a proposal with proposed specs.
If an engagement starts from an RFP, draft SOW, informal scoping packet, or
meeting transcript instead of an RFI, still use this command to normalize the
inputs into a common understanding before proposal or SOW work.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: CONTEXT INGESTION

Read and process every file in `.project-context/`. This follows the same
source authority hierarchy as `/ais.setup.plan` (T1-T6), but with a
pre-sales lens — focus on understanding the client's problem and needs
rather than decomposing into implementation specs.

### Step 1.1 — Discover all files

Run:
```
find .project-context -type f | head -100
```

Catalog every file found.

### Step 1.2 — Classify each file by source authority

Use the Source Authority Tiers (T1-T6):

| Tier | Source Type | Pre-Sales Treatment |
|------|-----------|-------------------|
| **T1 — Contractual** | SOW, MSA, contracts | Firm scope boundaries. Use to validate, not to discover. Extract warranty, acceptance, IP, quality, and other SOW-readiness terms when present. |
| **T2 — Client-authored** | RFIs, RFPs, requirements docs, emails | Primary discovery source. Client's own words carry highest weight. |
| **T3 — Milestones & Delivery** | Delivery schedules, green sheets, staffing plans, agreed dates | Timeline, staffing, and phasing context. |
| **T4 — Transcriptions** | Meeting recordings, call notes | Rich context for understanding intent. Extract priorities and concerns. |
| **T5 — AIS-authored** | Previous proposals, ROM estimates | Understand what's been offered before. Don't assume it was accepted. |
| **T6 — AI-generated** | Mocks, drafts, ChatGPT outputs | Illustrative only. Note what they suggest but don't build scope from them. |

### Step 1.2a — Identify artifact entry point

Identify the most mature pre-sales artifact represented by the source set:

| Entry Point | Treatment |
|-------------|-----------|
| RFI | Capture requested response format, eligibility/compliance items, and early discovery gaps. Do not invent a full solution. |
| RFP | Capture response requirements, proposed scope, evaluation criteria, compliance obligations, and pricing/staffing inputs. |
| Proposal / ROM | Treat as AIS-authored unless accepted by the client or reflected in a signed SOW. |
| Draft SOW | Treat as proposed contractual language. Validate against client sources and flag unresolved commitments. |
| Signed SOW / contract | Treat as T1 scope boundary and transition candidate for `/ais.setup.plan`. |
| Informal scoping docs / transcripts | Extract intent, assumptions, risks, and questions with clear source attribution. |

Earlier artifacts are helpful but not required. If an RFP arrives without an
RFI, or an SOW arrives without a formal proposal, proceed from the highest
authority source available and note the missing prior artifact as context, not
as a blocker.

### Step 1.3 — Read and extract

For each file, extract:
- Authority tier and authoring party (Client / AIS / third party)
- Business problem statements
- Desired outcomes and success criteria
- Capability requests (what they want the system to do)
- Users and stakeholders mentioned
- Engagement/funding model if stated: customer-funded, Microsoft-funded,
  Microsoft-program-funded, or unknown
- SOW agreement-family signals: End Customer Investment Funds (ECIF), direct
  client SOW, MSA-backed SOW, supplier agreement, or unknown
- Commercial-model signals: FFP, outcome-driven, managed capacity, time and
  materials, or unknown
- Constraints (timeline, period of performance, budget, technical,
  compliance, funding/program, organizational)
- Green sheet, staffing-plan, role/allocation, Azure/platform,
  language-model/token, or chargeback cost-model signals. Do not include rates
  or prices in generated artifacts.
- SOW-readiness signals: MSA availability, warranty/support window, acceptance
  period, IP/quality terms, non-negotiable milestones, and external commercial
  review status
- Post-delivery operations signals: Tier 2/L2 support, hypercare, incident
  flow, service requests, advisory reachback, enhancements, onboarding,
  ticketing channel, reporting cadence, offshore eligibility, and support
  timezone/coverage expectations
- Delivery environment and tracking signals: client repo/tenant expectations,
  GitHub vs Azure DevOps constraints, board expectations, AI/coding-agent
  policy, and Copilot or tool-license availability
- Whether AIS is expected to help produce a customer operating cost model
- Mandatory compliance, eligibility, response-format, security, privacy, data
  residency, accessibility, procurement, or government-contracting requirements
- Questions already asked or answered
- Contradictions between sources

### Step 1.4 — Load playbooks

Check `.specify/playbooks/` for relevant playbooks. If the user specified a
playbook or the project type is identifiable, load the relevant playbook(s)
for discovery question guidance.

### Step 1.5 — Playbook detection and governing questions activation

Check if `specs/.discovery/playbook.md` exists.

**If playbook already active:**
1. Read `specs/.discovery/playbook.md` to get the active playbook path
2. Load the playbook's Governing Questions Register
3. If `specs/.discovery/governing-questions.md` exists, read it
4. If it doesn't exist, create it from the playbook's register using the
   template at `.specify/templates/governing-questions-template.md`

**If no playbook active but project type is identifiable:**
1. Based on the context files processed, identify the most likely project type
2. Check `.specify/playbooks/` for a matching playbook
3. Suggest the playbook to the user:
   > **Playbook detected:** Based on the project context, this appears to be
   > a [PROJECT TYPE] engagement. The **[PLAYBOOK NAME]** playbook is available
   > at `[PATH]`.
   >
   > Would you like to activate it? This enables structured governing questions
   > that ensure critical discovery items are addressed at each phase.
   >
   > To activate: I'll create `specs/.discovery/playbook.md` and initialize
   > the governing questions tracker.
4. If the user accepts, create `specs/.discovery/playbook.md` using the template
   at `.specify/templates/playbook-selection-template.md` and create the
   governing questions tracker
5. If the user declines, proceed without playbook — generate ad-hoc discovery
   questions from context (existing QA/QC behavior)

**If no playbook and no identifiable project type:**
Skip — proceed with existing QA/QC question generation behavior.

---

## PHASE 2: SYNTHESIS

Organize your understanding into client-facing language.

### Step 2.1 — Identify the business problem

Synthesize across all sources to articulate what the client is trying to solve.
Use the client's language where possible. Distinguish between:
- Problems the client explicitly stated
- Problems implied by their requests
- Problems AIS identified (note as AIS observation)

### Step 2.2 — Map desired outcomes

List every outcome the client wants, with priority and source attribution.
Outcomes should be measurable where possible.

### Step 2.3 — Group capabilities

Organize what the client is asking for into logical capability areas. These
become the structure for the "What You're Asking For" section.

### Step 2.4 — Identify constraints and commercial context

Catalog all constraints by category: timeline, period of performance, budget,
funding/program model, SOW agreement family, commercial model, technical,
compliance, organizational, staffing, contract-readiness, operations/support,
delivery environment, and cost-model needs. Quote specific constraints with
source attribution.

Classify the engagement funding model as one of:
- **Customer-funded** — pricing, staffing, SOW, and acceptance terms are direct
  client-facing commitments.
- **Microsoft-funded** — funding approval, eligible activities, and program
  constraints may affect artifact shape and assumptions.
- **Microsoft-program-funded** — program lifecycle and required evidence may
  affect response and delivery obligations.
- **Unknown** — carry as a QC question before pricing or SOW commitment.

Do not infer detailed ECIF or program-specific rules unless a source document
states them. Capture the classification and list what program details are
needed.

Classify SOW agreement-family and commercial-model signals when present:

- **ECIF** — Microsoft ECIF language, Microsoft as payer, CAS/REQ or
  supplier-agreement identifiers, proof-of-execution requirements, or a
  milestone table with service description, amount, hours, and due dates.
- **Client SOW** — direct client contracting, MSA-backed scope, customer-funded
  delivery, or standard AIS client SOW structure.
- **FFP** — fixed deliverables, fixed phases/milestones, firm fixed price, or
  FFP language.
- **Outcome-driven** — measurable business outcomes, value realization, adoption
  gates, or result-based scope/pricing signals.
- **Managed capacity** — role capacity, standing team, throughput expectations,
  managed service, or operating cadence.
- **Time and materials** — roles, hours, burn governance, T&M, rate-card
  reference, or extension by approved hours.

If the agreement family or commercial model is unclear, mark it unknown and add
a QC question because it affects SOW template selection and acceptance shape.

### Step 2.4a — Identify SOW readiness and delivery environment signals

Capture whether the source set provides:

- MSA or master contract terms that affect SOW language
- Acceptance period, acceptance process, warranty/support window, and quality
  terms
- Non-negotiable milestones, funding dates, or period-of-performance
  constraints
- Post-delivery support expectations: incident handling, service requests,
  advisory reachback, enhancements, onboarding, support tier, response posture,
  ticketing channel, reporting cadence, offshore mode, and escalation path
- Client delivery environment expectations: client-owned tenant/repo, GitHub,
  Azure DevOps, other board system, or unknown
- AI/coding-agent policy and whether the client will provide required licenses,
  tool access, and tokens
- Whether AIS should help the client model operating costs such as Azure,
  hosting, language-model/token usage, third-party services, or support

Treat missing or conflicting SOW readiness items as QC questions because they
affect commitments. Treat delivery-environment and AI-tooling gaps as staffing
or setup risks unless they block the proposal.

### Step 2.4b — Identify compliance obligations

For RFIs, RFPs, government procurements, regulated industries, or SOWs, extract
mandatory compliance requirements separately from general risks. Track:
- Requirement or clause summary
- Source and authority tier
- Whether AIS can answer with the available context
- Evidence, artifact, or owner needed
- Whether it affects eligibility, scope, timeline, staffing, cost, or
  acceptance

### Step 2.4c — Extract evaluation factors

When the source material includes an RFP, RFI, solicitation, or government
procurement document with evaluation criteria or evaluation factors, extract
them as a separate structured section. This step is critical for downstream
proposal outline generation — evaluators score proposals against these factors,
so they must be captured precisely.

For each evaluation factor found:
1. Assign a sequential ID: EF-001, EF-002, etc.
2. Extract the factor text exactly as stated in the solicitation
3. Record the weight or priority if the solicitation states one (e.g., "most
   important," "equally weighted," a point value). Use "unstated" if no weight
   is given.
4. Record the source section, page, or clause reference
5. Classify the factor as one of:
   - **Specific** — clear, measurable, and unambiguous
   - **Vague** — subjective, open-ended, or hard to map to concrete proposal
     content
   - **Overlapping** — covers ground shared with one or more other factors
6. If a factor overlaps with or conflicts with another, note the relationship

If the solicitation has no identifiable evaluation criteria (informal scoping,
transcript-only, or pre-RFP engagement), skip this step and note that no
evaluation factors were found.

If evaluation criteria exist but are poorly structured (vague, overlapping,
contradictory), extract them as-is and note the structural issues. Do not
attempt to fix or reorganize the solicitation's evaluation structure — the
proposal step will handle mapping.

### Step 2.5 — Sort questions

Split open questions into two categories:

**QA (AIS-answerable)**: Questions where we have enough context to make a
reasonable assumption. For each, state our assumption and confidence level.
These reduce client burden — we propose an answer for them to confirm.

**QC (Client-required)**: Questions that genuinely need client input. We
don't have enough information to assume. For each, explain why it matters
and what it blocks.

### Step 2.6 — Auto-populate governing questions (if playbook active)

If a playbook is active and the governing questions tracker exists:

1. Scan all extracted context (business problems, outcomes, constraints,
   questions answered) for answers to governing questions
2. For each governing question where the context provides a clear answer:
   - Update the tracker row: fill Answer, Source (file + authority tier), Date
   - Change Status from `unanswered` to `answered`
3. For questions where context provides a partial or uncertain answer:
   - Add the partial answer with a note: "(partial — confirm with client)"
   - Keep Status as `unanswered`
4. Report the auto-population results in Phase 5

If no playbook is active, skip this step.

---

## PHASE 3: GENERATE THE DOCUMENT

### Step 3.1 — Load template

Read `.specify/templates/what-we-heard-template.md` for the section structure.

### Step 3.2 — Create output directory

Create `specs/.presales/` if it doesn't exist.

### Step 3.3 — Write the document

Generate `specs/.presales/01-what-we-heard.md` using the template structure.
Fill every section with concrete content from the context files.

---

## PHASE 4: PROPOSAL GATE EVALUATION

Evaluate readiness to proceed to `/ais.presales.propose`.

### Must-Pass (FAIL if not met)

- [ ] Business problem is clearly understood and articulated
- [ ] At least 1 desired outcome identified
- [ ] At least 1 capability area described
- [ ] Client contact identified
- [ ] No blocking high-impact QC items (questions where lack of answer would make proposal meaningless)

### Should-Pass (WARN if not met)

- [ ] Timeline constraints known (or explicitly noted as unknown)
- [ ] Budget range known (or explicitly noted as unknown)
- [ ] Engagement/funding model known (or explicitly noted as unknown)
- [ ] SOW agreement-family and commercial-model signals known or explicitly
      noted as unknown
- [ ] Mandatory compliance requirements identified (or explicitly noted as none provided)
- [ ] Key stakeholders identified
- [ ] Evaluation factors extracted and classified (when solicitation contains
      evaluation criteria or factors)
- [ ] If playbook active: Pre-sales governing questions >50% answered (or deferred with justification)

### Gate Result

Report the gate result:
- **PASS** — All must-pass items met. Ready for `/ais.presales.propose`.
- **WARN** — Must-pass items met, but some should-pass items missing. Can proceed with noted gaps.
- **FAIL** — One or more must-pass items not met. List what's needed before proceeding.

---

## PHASE 5: REPORT

Provide a summary to the user:

1. **Sources processed** — count by authority tier
2. **Business problem** — one-sentence summary
3. **Outcomes identified** — count
4. **Capability areas** — list
5. **Open questions** — QA count (we can answer) vs. QC count (need client)
6. **Constraints and funding** — timeline, period of performance, budget,
   engagement/funding model, SOW family/model signals, staffing/cost-model
   signals, SOW readiness, operations/support signals, and
   delivery-environment signals known vs. unknown
7. **Compliance** — mandatory requirements found, gaps, and response blockers
8. **Evaluation factors** — count extracted, count by classification (specific /
   vague / overlapping), and any structural issues noted
9. **Governing questions** (if playbook active) — answered count / total for Pre-sales phase; list unanswered with what they block
10. **Gate result** — PASS / WARN / FAIL with details
11. **Recommended next step** — `/ais.presales.propose` or resolve gaps first

---

## BEHAVIORAL RULES

- **Mirror, don't propose.** This document reflects what the client said, not
  what AIS recommends. Save recommendations for the proposal.
- **Use the client's language.** Where possible, use their terminology and
  phrasing. They should read this and think "yes, they understood us."
- **Separate fact from inference.** When you infer something not explicitly
  stated, mark it clearly.
- **Be honest about gaps.** Missing information is valuable — it shows the
  client what we still need.
- **QA questions reduce burden.** The more questions we can answer ourselves
  (with assumptions the client can confirm), the less work for the client.
- **Carry questions forward.** Unresolved questions from this stage flow into
  the proposal and SOW. They don't get lost.
- **Never fabricate client statements.** If something wasn't said or written,
  don't attribute it to the client.
