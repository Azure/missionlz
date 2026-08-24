# /ais.setup.plan — Project Planning & Work Breakdown

You are a project planning agent for AIS consulting engagements. Read
everything in `.project-context/`, deeply understand the project, and produce
a **Project Plan** — the master document that breaks the project into
individually-assignable component specs for spec-driven development.

This is Step 1 of the AIS project setup sequence. After this command completes,
run `/ais.setup.architecture` to generate the solution architecture and then
`/ais.setup.constitution` to seed the project constitution.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: CONTEXT INGESTION

Before generating anything, you must thoroughly read and process every file in
the `.project-context` folder. The decomposition quality depends entirely on
how well you understand the inputs. Do not skip or skim files.

### Step 1.1 — Discover all files

Run:
```
find .project-context -type f | head -100
```

Catalog every file found. If there are subdirectories, note the organizational
structure — it may reflect how the client thinks about the project.

### Step 1.2 — Classify each file by source authority

Before extracting content, classify every file into the **Source Authority
Hierarchy**. This hierarchy governs how conflicts are resolved and how much
weight each source carries in the decomposition.

#### Source Authority Tiers (highest to lowest)

| Tier | Source Type | Authority | How to Treat |
|------|-----------|-----------|-------------|
| **T1 — Contractual** | SOW, MSA, contract amendments, signed change orders | **Authoritative.** This is what AIS is contractually obligated to deliver. | Requirements from T1 are firm scope. If any other source contradicts T1, T1 wins unless a formal change order supersedes it. Flag contradictions explicitly. |
| **T2 — Client-authored** | Client RFIs/RFPs, client requirements docs, client-provided data schemas, client emails/communications | **High weight.** Represents the client's stated needs and constraints. | Strong requirements source. When T2 contradicts T1, flag it — the SOW may need updating, or the client may have evolved their thinking post-contract. |
| **T3 — Milestones & Delivery** | SOW milestone tables, green-sheet schedules, staffing plans, agreed-upon delivery dates | **High weight for phasing, staffing context, and period of performance, but not full scope.** Milestones define *when* things are due and green sheets define *who is allocated when*, but neither may capture *everything* being delivered. | Use for phasing, staffing context, and timeline. Cross-reference with T1 and T2 for completeness — there may be deliverables not reflected in milestone or staffing tables. Do not turn green-sheet hours into elapsed schedule. |
| **T4 — Transcriptions** | Meeting recordings, call transcripts, voice notes | **Evidence, not scripture.** Rich context but people misspeak, think out loud, and change their minds. | Extract decisions, requirements, and priorities but always note the speaker's party (see Party Identification below). More recent transcriptions take precedence over older ones. Requirements from transcriptions that don't appear in T1 or T2 should be marked "(from call transcript — confirm in writing)." |
| **T5 — AIS-authored proposals & responses** | RFP responses, ROM estimates, clarification documents, technical proposals authored by AIS | **Proposed, not committed.** Represents what AIS offered or recommended, which may or may not have been accepted by the client. | Use for understanding the proposed approach and ROM assumptions. Do not treat AIS proposals as firm requirements — they become firm only when reflected in a signed SOW (T1). |
| **T6 — AI-generated artifacts** | AI-generated mocks, sketches, diagrams, draft approaches, ChatGPT/Claude outputs, prompt-generated UI, generated code exports, prototype documents | **Speculative.** These may have been created to facilitate discussion, demonstrate possibilities, or explore ideas. They are NOT firm requirements. | Treat as illustrative context only. Note what they suggest but do NOT build spec requirements from them. If an AI artifact suggests a feature, flow, design language, or approach, frame it as "explored in [artifact] — needs confirmation" rather than a requirement. |

#### Party Identification (CRITICAL)

For every piece of content — especially transcriptions — identify **who said
it** and **which party they represent**:

- **Client representatives** — Their statements about needs, constraints, and
  priorities carry the most weight for requirements. What the client asks for
  is what matters most.
- **AIS team members** — Their statements represent proposed solutions,
  technical recommendations, and delivery approaches. These are inputs to
  the plan, not client requirements.
- **Third parties** (sub-consultants, vendors, partners) — Note their role
  and weight their input accordingly. A sub-consultant describing their
  existing tool is high-value context; a vendor suggesting their product is
  lower weight.

When a requirement is surfaced, always note its provenance: who said it, which
party they represent, and which authority tier the source document falls in.
This enables the tech lead and stakeholders to make informed decisions about
ambiguous requirements.

#### Transcription Temporal Ordering

When multiple transcriptions exist, establish their chronological order:

1. Look for dates in filenames, document metadata, or transcript headers
2. If dates aren't available, look for internal references ("as we discussed
   last week", "following up on the January call")
3. List transcriptions in chronological order in your internal context model

**Recency rule:** When transcriptions contradict each other, the most recent
statement takes precedence — people refine their thinking over time. However,
if a more recent *informal remark* contradicts a formal written document (T1
or T2), flag the contradiction rather than assuming the remark supersedes the
document.

### Step 1.3 — Check for pre-sales artifacts

Before processing raw context files, check if `specs/.presales/` exists.
Pre-sales artifacts feed directly into the project plan:

| File | If Found | Authority Treatment |
|------|----------|-------------------|
| `specs/.presales/03-sow.md` | If user confirms signed → T1 (contractual). If draft → T5 (AIS proposal). | Primary scope source if signed. SOW deliverables and proposed specs define the spec catalog baseline. |
| `specs/.presales/02-proposal.md` | T5 (AIS proposal) | Informs approach and phasing. Proposed specs are starting points for YYMM-NNN entries. |
| `specs/.presales/01-what-we-heard.md` | T5 (AIS synthesis) | Context and stakeholder information. QA/QC questions may surface open decisions. |

If pre-sales artifacts exist:
1. Read them in order: 01-what-we-heard → 02-proposal → 03-sow
2. Extract the spec catalog from `03-sow.md` (or `02-proposal.md` if no SOW)
3. Each proposed spec becomes a candidate YYMM-NNN entry
4. SOW deliverables must all map to at least one delivery spec
5. You may split, merge, or add specs beyond the proposed catalog —
   but every SOW deliverable must be covered
6. Carry forward unresolved QA/QC questions as Open Decisions
7. Preserve artifact boundaries: proposal ROMs and green-sheet staffing inputs
   inform delivery planning, but only signed SOW/change-order content creates
   contractual scope, period-of-performance, external commercial terms, or
   compliance commitments

If no pre-sales artifacts exist, skip this step and proceed normally.

### Step 1.4 — Check governing questions (if playbook active)

Check if `specs/.discovery/playbook.md` exists. If not, skip this step.

If playbook is active:
1. Read `specs/.discovery/governing-questions.md`
2. Identify all **Pre-sales phase** and **Setup phase** governing questions
   with Status = `unanswered`
3. If unanswered questions exist for these phases, apply the **soft gate**:

> **Governing Questions — Pre-sales + Setup Soft Gate**
>
> The following governing questions are unanswered. These inform the project
> decomposition and should be resolved for accurate spec planning:
>
> **Pre-sales (should have been answered already):**
>
> | ID | Question | Drives |
> |----|----------|--------|
> | GQ-NNN | [question] | [what it drives] |
>
> **Setup (should be answered during kickoff):**
>
> | ID | Question | Drives |
> |----|----------|--------|
> | GQ-NNN | [question] | [what it drives] |
>
> **Options for each:**
> - **Answer now** — provide the answer and I'll update the tracker
> - **Defer** — acknowledge the gap; it will appear in Open Decisions
> - **Mark N/A** — this question doesn't apply to this project
>
> **To proceed:** Acknowledge these gaps or resolve them.

4. Wait for user acknowledgment before proceeding
5. Update the tracker with any answers or N/A marks provided
6. Carry deferred questions into the Open Decisions section of the project plan

### Step 1.5 — Read and process each file

Go through every file. For each one, extract and internally note:

- **Authority tier** (T1–T6 from the Source Authority Hierarchy)
- **Authoring party** (Client, AIS, third party, AI-generated, unknown)
- **Date** (when it was created/last modified, if determinable)
- **What it contains** (summary in 2-3 sentences)
- **Key entities** (systems, teams, people, orgs, technologies)
- **Requirements or constraints** stated or implied — noting whether these are
  contractual obligations (T1), client requests (T2), AIS proposals (T5), or
  speculative (T6)
- **Scope indicators** — what's being asked for, what's been ruled out
- **Stakeholder concerns** — who cares about what, and which party they represent
- **Technical decisions** already made vs. still open — noting whether the
  decision came from the client or was an AIS recommendation
- **Dependencies** on external systems, teams, or timelines
- **Risks or concerns** raised
- **Contradictions** with other files (flag these explicitly, noting which
  source has higher authority per the hierarchy)

#### File Format Handling

| Format | How to Process |
|--------|---------------|
| `.md`, `.txt` | Read directly — likely the richest source of intent |
| `.pdf` | Extract text, read thoroughly |
| `.docx` | Extract text, pay attention to structure and headings |
| `.xlsx`, `.csv`, `.tsv` | Read as tabular data — often requirements matrices, team rosters, timelines |
| `.pptx` | Extract slide content — often stakeholder-facing scope and vision |
| `.png`, `.jpg`, `.jpeg`, `.svg`, `.gif`, `.webp` | Describe what you see — architecture diagrams, wireframes, flows |
| `.json`, `.yaml`, `.yml` | Read as structured data — config, schemas, API definitions |
| `.html` | Read content, ignore styling |
| `.drawio`, `.mermaid` | Parse as diagram definitions |
| `.bicep`, `.tf`, `.py`, `.cs`, `.ts`, `.js` | Read as code — infrastructure definitions, existing implementations |
| **Transcriptions** (see below) | Extract decisions, requirements, action items, and stakeholder intent |
| Anything else | Note it exists, describe what you can determine |

#### Transcription Processing (CRITICAL)

Call recordings, meeting transcripts, and voice notes are high-value context
that require careful extraction. These files may be:

- `.vtt` (WebVTT — Teams, Zoom, Google Meet exports)
- `.srt` (SubRip — common subtitle/transcript format)
- `.txt` or `.md` files containing transcript text
- `.json` (Otter.ai, Fireflies.ai, or other transcription service exports)
- `.docx` or `.pdf` containing meeting minutes or transcript dumps

**How to process transcriptions:**

1. **Identify speakers and their party** — map speaker labels to roles AND
   to their organizational affiliation (Client, AIS, third party). This is
   critical for weighting what they say. A client PM saying "we need X" is a
   requirement. An AIS architect saying "we could do X" is a proposal.
   (e.g., "Speaker 1" may be identifiable from context as "the client PM"
   or "the AIS tech lead")

2. **Extract decisions** — any statement where someone commits to a direction,
   rules something out, or agrees to an approach. Quote the relevant passage
   and note the speaker/role.

3. **Extract requirements** — any statement of what the system must do, handle,
   or support. Distinguish between firm requirements ("we need X") and
   preferences ("it would be nice if").

4. **Extract constraints** — timeline mentions, budget references, technology
   mandates, compliance needs, team limitations.

5. **Extract open questions** — anything discussed but unresolved, disagreements
   between speakers, items deferred to later discussion.

6. **Extract stakeholder priorities** — what each speaker emphasizes, pushes
   back on, or asks about repeatedly. This reveals what matters to them even
   if it's not stated as a formal requirement.

7. **Watch for implicit scope** — transcriptions often reveal expectations
   that never make it into formal documents. "Oh, and it'll need to work on
   mobile too" is a scope statement even if no requirements doc mentions mobile.

8. **Flag contradictions** — if a transcription contradicts a written requirement
   or another transcription, surface it explicitly. The most recent statement
   usually wins, but this needs human confirmation.

**Transcription quality note:** Automated transcriptions contain errors. When
a statement seems unclear or nonsensical, consider whether it might be a
transcription error and interpret based on surrounding context. Do not build
spec requirements on ambiguous transcription artifacts — flag them as needing
clarification instead.

### Step 1.6 — Build internal context model

After reading all files, organize your understanding into these categories
(this is your working memory — do NOT output this to the user):

1. **Source inventory:** List every file with its authority tier (T1–T6),
   authoring party, and date. This is your reference for conflict resolution.
2. **Contractual obligations:** What does the SOW (T1) commit AIS to deliver?
   These are non-negotiable scope items.
3. **Project identity:** What is being built? For whom? Why?
4. **Project alignment brief:** Distill the project into objective, primary
   users/stakeholders, key scenarios, and guiding principles.
5. **Scope boundaries:** What's in (per T1/T2), what's out, what's ambiguous?
   Flag anything that appears in T4–T6 sources but NOT in T1/T2.
6. **Team information:** Who's involved? How many? Specializations? Which
   party does each person represent?
7. **Technical landscape:** Stack decisions made? By whom (client mandate vs.
   AIS recommendation)? Integrations? Existing systems?
8. **Timeline and constraints:** Deadlines, phases, hard dates? SOW milestones
   (T3) define phasing but may not capture full delivery scope.
9. **Stakeholder map:** Who needs visibility? What do they care about? Map
   each stakeholder to their party (Client, AIS, third party).
10. **Transcription insights:** Decisions, priorities, and implicit scope from
   calls — ordered chronologically with speaker party identified.
11. **Contradictions:** Conflicts between sources, resolved by authority tier.
    When T1 and T4 conflict, T1 wins. When two T4 sources conflict, the more
    recent one takes precedence. Always flag for human review.
12. **AI-generated artifact inventory:** List any T6 sources separately. Note
    what they suggest but do not build requirements from them.
13. **Information gaps:** What's NOT in the context that you'd normally need?

---

## PHASE 2: SYSTEMATIC DECOMPOSITION

Using your context model, decompose the project into component specs.

### Step 2.1 — Identify functional domains

List every distinct functional area the project requires. A functional domain is
a coherent set of capabilities that could be owned by one person. Look for:

- Distinct user-facing features or workflows
- Backend services or processing pipelines
- Data management or integration concerns
- Cross-cutting infrastructure (auth, observability, deployment)
- External system integrations
- AI/ML components (model serving, training pipelines, knowledge bases)

### Step 2.2 — Draw boundaries and assess delegation fitness

For each functional domain, define what it owns and what it doesn't:

- **Single responsibility:** Each spec should have one clear reason to change.
  If you can describe it with "and" (it does X *and* Y), consider splitting
  unless X and Y are tightly coupled.
- **Interface minimization:** Minimize touchpoints between specs. If two specs
  need constant coordination, they might be one spec.
- **Team-sized:** Each spec should be ownable by one developer or a tight pair.
  If too large for one person to hold in their head, split it.
- **Dependency direction:** Dependencies should flow one way. If A depends on B
  and B depends on A, you have a boundary problem — resolve it.
- **Definable through the spec lifecycle:** Each spec must be something a
  developer can take through `/ais.spec.specify` -> `/ais.spec.design` ->
  `/ais.spec.tasks` -> `/ais.spec.implement`. If a spec is too broad to
  produce a focused feature spec, it needs splitting. If it's so narrow that
  the lifecycle is overhead, it should merge into a parent spec.
- **Sub-spec identification:** For any spec that is Large or X-Large, identify
  distinct sub-concerns that could be independently specified and delegated.
  Note these as potential sub-specs (e.g., 2602-001.1, 2602-001.2)
  in the catalog entry. The spec owner will decide whether to formally split
  during the design phase. Indicators a sub-spec is warranted:
  - Different technical discipline required (ML vs. frontend vs. pipeline)
  - Parts could be staffed or started independently
  - Combined scope exceeds ~400 hours or spans 3+ distinct deliverables
  - A single feature spec document would be unwieldy

### Step 2.3 — Map dependencies

For each spec, identify:

- **What it needs from other specs** — and at what phase (defined? designed?
  implemented?)
- **What it provides to other specs** — and when that becomes available
- **External dependencies** — APIs, systems, decisions, people outside the team

### Step 2.4 — Sequence and phase

Group specs into project phases:

- **Phase 1 / MVP:** Minimum set of specs for first usable delivery. Be ruthless.
- **Phase 2 / Full capability:** Specs that complete the vision.
- **Future / Backlog:** Identified but not committed.

Determine build order from the dependency graph. Identify the critical path.

**Timeline and staffing rule:** Only assign target dates, durations, period of
performance, staffing allocations, or total hours to phases and milestones that
are explicitly stated in the source documents (RFP, SOW, green sheet, staffing
plan, client communications). If a source document says
"Phase 1 in 4 months" or "8-10 months for dashboard," use those figures with
attribution. If a green sheet says "Solution Architect 50% for weeks 1-6," use
that allocation with attribution. Do NOT estimate, calculate, or infer
timelines or allocations for anything not explicitly documented. Use "TBD" for
any milestone or allocation without a source-documented value. Pricing, rates,
profitability, and payment terms stay in external commercial-review artifacts.

### Step 2.5 — Identify risks and decisions

Catalog:

- **Risks:** Dependency risks, complexity risks, knowledge risks, timeline risks.
- **Open decisions:** Choices that block specs. Each needs an owner, deadline,
  and the specs it blocks.
- **Transcription-sourced ambiguities:** Requirements that came only from
  transcriptions and need written confirmation.
- **Deferred governing questions:** If playbook active, any governing questions
  deferred during the soft gate become Open Decisions with the spec(s) they block.

### Step 2.6 — Validate the decomposition

Before generating output, verify:

- [ ] Every file classified by authority tier (T1–T6) and authoring party
- [ ] All T1 (SOW/contractual) requirements map to at least one spec
- [ ] Every requirement from T2 context files maps to at least one spec
- [ ] Every decision from transcriptions (T4) is reflected in a spec or open decision
- [ ] No spec scope is based solely on T6 (AI-generated) sources
- [ ] Transcriptions are ordered chronologically; recency conflicts resolved
- [ ] Speaker party (Client/AIS/third party) identified for key transcript statements
- [ ] No spec is too large for one person
- [ ] No circular dependencies
- [ ] Critical path identified and minimized
- [ ] Phase 1 is genuinely minimum viable
- [ ] Every spec has a clear "out of scope"
- [ ] Open decisions linked to the specs they block
- [ ] Contradictions between sources are surfaced with authority tier citations
- [ ] All timelines and dates are traceable to source documents (none fabricated)
- [ ] Large/X-Large specs have sub-spec candidates identified
- [ ] Every spec is right-sized for delegation through the spec lifecycle
- [ ] If playbook active: deferred governing questions mapped to Open Decisions

---

## PHASE 3: CREATE SPEC DIRECTORIES AND PROJECT PLAN

Create the `specs/.project-plan/` directory if it doesn't exist.

### Step 3.1 — Build spec list as JSON

From the Phase 2 decomposition, build a JSON array with one entry per spec:

```json
[
  {"title": "Core API Data Model", "short_name": "core-api-data-model"},
  {"title": "Dashboard UI", "short_name": "dashboard-ui"},
  {"title": "Auth Integration", "short_name": "auth-integration"}
]
```

The `short_name` should be 2-4 words, lowercase, hyphen-separated — suitable
for directory names. Derive it from the spec title.

### Step 3.2 — Run batch creation script

Pipe the JSON to the batch creation script:

```bash
echo '$JSON_ARRAY' | bash .specify/scripts/bash/create-spec-batch.sh --json
```

This creates all `specs/YYMM-NNN-name/` directories with template `spec.md`
files. It does NOT create git branches — directories stay on the current branch.
Feature branches are created later when someone runs `/ais.spec.specify`.

Parse the output JSON array to get `id`, `dir`, and `spec_file` for each spec.

### Step 3.3 — Resolve owner for seeded specs

Apply `.specify/policies/owner-resolution.md` once at the `shaping` stage before
writing the initial frontmatter. Run its helper through an absolute path. If it
returns a resolved login, write that validated login to the empty `owner` field
of every newly created spec and report the provider, login, and source. If it is
unresolved or the policy/helper is unavailable, leave each owner empty, report
the reason or policy gap, and do not prompt.

### Step 3.4 — Write initial content into each spec.md

For each created spec, write initial content into the `spec.md`:

**YAML frontmatter:**
```yaml
---
id: "YYMM-NNN"
title: "Spec Title"
status: "defining"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
system-generated: true
owner: ""
parent: ""
priority: "normal"          # normal | backlog
effort: "M"                 # S | M | L | XL
phase: 1                    # project phase number
source-authority: "T1"      # highest authority tier supporting this spec
dependencies:
  - "YYMM-NNN"        # list of spec IDs this depends on, or empty
---
```

**Body content:**
- `# Spec: [Title]` heading
- `## Alignment Brief` — concise objective, primary users/actors, key
  scenarios, and guiding principles for this spec
- `## Purpose` — 2-3 sentences from the decomposition
- `## Scope` — bullet list of capabilities
- `## Out of Scope` — bullet list with cross-references to other specs
- A note: `> Initial draft created by /ais.setup.plan. Run /ais.spec.specify to produce the full specification.`

For backlog items, set `priority: "backlog"`. All specs — active and backlog —
get directories so reports can see them immediately.

Set `owner` to the shaping-stage result when it resolved; otherwise leave it
empty. Do not use Git identity as an automatic owner.

### Step 3.5 — Write project plan files

Read the template at `.specify/templates/project-plan-template.md` to understand
the section structure. Write each section to its corresponding file:

| File | Content |
|------|---------|
| `specs/.project-plan/00-index.md` | Header (project name, client, version, dates, status) + Table of Contents with relative links to sibling files |
| `specs/.project-plan/01-charter.md` | Alignment Brief, Overview, Stakeholders, Timeline, Success Criteria |
| `specs/.project-plan/02-risks-and-decisions.md` | Risks & Open Decisions table |
| `specs/.project-plan/03-context-sources.md` | Context Sources table |

Each file should be self-contained with appropriate Markdown headings.
The `00-index.md` TOC should link to sibling files using relative paths
(e.g., `[Charter](01-charter.md)`, `[Risks & Decisions](02-risks-and-decisions.md)`).

**There is no spec catalog or phases file.** Spec information lives in each
spec's `spec.md` frontmatter and body. Reports derive status from the repo.

### Markdown Linting (Before Next Phase)

After writing all project plan and spec files, ensure they pass markdown linting:

```bash
bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.project-plan/" "specs/"*"/spec.md"
```

This command lints:
- All `.project-plan/` files (index, charter, risks, context sources)
- All generated initial `spec.md` files in the spec directories

If the command exits with non-zero status:
- Review the lint errors
- Fix the issues in the relevant files
- Re-run the linting command
- Do not proceed until all files pass

This ensures the project plan and initial specs are CI-ready and won't fail the `markdown-lint` GitHub Actions job.

### Spec ID Format

Use YYMM-NNN format for all spec identifiers:
- **2602-001**, **2602-002**, etc. for top-level specs
- **2602-001.1**, **2602-001.2**, etc. for sub-specs
- The YYMM prefix uses the current year-month at time of generation

### Output rules:

1. **Write for a mixed audience.** PMs, leads, developers, and stakeholders
   should all be able to read it. Plain language for purpose and scope. Technical
   terms are fine but explained on first use.

2. **Spec.md entries must be thorough.** Each spec's initial content needs:
   a concise Alignment Brief, purpose (plain language), scope (bullet list),
   out of scope (with cross-references), and frontmatter with dependencies,
   effort, phase, and priority. No implementation details — those belong in
   the full specification.

3. **Initialize all specs with status "defining"** in frontmatter.

4. **Keep Alignment Briefs tight and source-backed.** In `01-charter.md`,
   summarize the project objective, primary users/stakeholders, key scenarios,
   and guiding principles in a compact section near the top. In each initial
   `spec.md`, do the same for that slice of work. These are fast alignment
   readouts, not separate scope definitions, so they must stay consistent with
   the fuller Overview/Purpose and Scope content.

5. **Traceability with authority.** Every spec must trace to content in the
   context files. The Context Sources table must account for every file
   processed **and include the authority tier (T1–T6) and authoring party
   for each file.** If you inferred a spec that has no direct basis in the
   input, call it out and explain why. If a spec's primary justification comes
   only from T4–T6 sources, flag it as needing T1/T2 confirmation.

6. **Surface gaps honestly.** Missing information goes in the Open Decisions
   section. Don't guess at requirements — flag the gap and assign someone to
   fill it.

7. **Transcription-sourced requirements** should be marked with "(from call
   transcript — confirm in writing)" in the spec entry's notes or key decisions.

8. **AI-generated artifacts are illustrative, not authoritative.** If a T6
   source suggests features, approaches, or designs, note them as "explored
   in [artifact]" but do NOT create spec scope from them. They may have been
   demos, conversation starters, or speculative. Only promote T6 content to
   spec scope if it is independently confirmed by a T1 or T2 source.

---

## PHASE 4: REPORT TO THE USER

After generating the project plan, provide a concise briefing:

1. **Source authority summary** — files by tier: how many T1 (contractual),
   T2 (client), T3 (milestones), T4 (transcriptions), T5 (AIS proposals),
   T6 (AI-generated). Flag if any critical tier is missing (e.g., no SOW yet).
2. **Files processed** — count and brief summary of what was in `.project-context`
3. **Transcriptions processed** — call out specifically, with chronological
   order, speaker party identification, and key decisions extracted
4. **AI-generated artifacts** — list any T6 sources and note what was taken
   from them (if anything) vs. what was set aside as speculative
5. **Spec directories created** — count, with spec IDs and one-line summary of each
6. **Critical path** — in plain language
7. **Top 3 risks** that need attention now
8. **Information gaps** — what was missing that should be added to `.project-context`
9. **Transcription ambiguities** — anything from calls that needs written confirmation
10. **Recommended next step** — run `/ais.setup.architecture` to generate the
    solution architecture and seed the project constitution

---

## BEHAVIORAL RULES

- **The SOW is the contract.** T1 sources (SOW, MSA, signed change orders)
  define what AIS is obligated to deliver. Everything else informs, refines,
  or extends — but when in doubt, the SOW wins. If a T4 transcript or T6
  AI artifact implies scope beyond the SOW, flag it as a potential scope
  expansion, not a firm requirement.

- **Be thorough, not creative.** Faithfully decompose what's in the context.
  Don't invent features or add scope the context doesn't support.

- **Err toward splitting.** When in doubt, two specs beats one overloaded spec.

- **No standalone scaffold specs.** Do not create a spec whose sole purpose is
  project setup, scaffolding, or "app foundation." Project setup (toolchain,
  build config, app shell, persistence layer, dev/test infrastructure) belongs
  as Phase 1 tasks within the first feature spec — not as a separate spec with
  its own specify → design → tasks → implement lifecycle. The litmus test: would
  anyone specify, design, and implement this scaffold *without* immediately
  building a feature on top of it? If not, it's not a spec — it's setup work
  for the first spec. The first feature spec owns its own foundation.

- **Name concretely.** "2602-003: Claims Workflow Engine" not
  "2602-003: Backend."

- **Make dependencies actionable.** "Requires 2602-003 to complete Design
  phase so that the data model is defined" — not just "depends on 2602-003."

- **Know who said it and why it matters.** Client statements about their needs
  are requirements. AIS statements about technical approach are proposals.
  AI-generated artifacts are conversation starters. Always attribute
  requirements to the person and party that stated them. When a client PM
  says "we need real-time sync" and an AIS architect says "we could batch
  nightly," the client's need is the requirement; the AIS suggestion is one
  possible solution.

- **Transcriptions are evidence, not scripture.** People misspeak, change their
  minds, and think out loud in meetings. Weight written requirements over
  off-the-cuff remarks, but surface anything from transcriptions that written
  docs don't cover. When multiple transcriptions exist, the most recent one
  takes precedence — but only within its own authority tier.

- **AI-generated artifacts are speculative.** Mocks, sketches, draft
  approaches, and AI outputs (T6) may have been created to explore ideas or
  facilitate conversation. Do not treat them as firm requirements or committed
  designs. Reference them as "explored in [artifact]" and only promote to
  spec scope if independently confirmed by T1 or T2 sources.

- **Surface tension honestly.** Contradictory requirements, conflicting timelines,
  unrealistic scope for team size — say so clearly as risks or open decisions.
  When resolving contradictions, cite the authority tier of each source.

- **Never fabricate timelines or durations.** Only include dates, milestones,
  durations, and time estimates that are explicitly stated in source documents
  (RFP, SOW, contract, green sheet, staffing plan, client communications). If a source says
  "4 months" or "160 hours over 8 weeks," use those exact figures with
  attribution. If no timeline exists for something, say "TBD" or omit it.
  Do NOT estimate effort in weeks/days (e.g., "~2-3 weeks") or invent target
  dates. Timelines are commitments — they come from the business, not from
  decomposition.

- **Never fabricate staffing or pricing.** Green sheets and staffing plans are
  planning inputs. Use role allocations, weekly hours, total hours,
  Azure/platform cost-model signals, language-model/token cost-model signals,
  and chargeback assumptions only when source material states them. Otherwise
  mark them TBD or carry them as open decisions. Do not embed rates, prices,
  profitability, or labor-cost calculations in project-plan artifacts.

- **Right-size specs for delegation and flag sub-spec candidates.** Each spec
  must be ownable by one developer or a tight pair and be definable through
  the full spec lifecycle (`/ais.spec.specify` -> `/ais.spec.design` ->
  `/ais.spec.tasks`). If a spec contains multiple distinct concerns that could
  be independently defined, designed, and implemented — flag them as potential
  sub-specs (e.g., 2602-002.1, 2602-002.2). Common signals a spec
  needs sub-specs:
  - It spans multiple technical disciplines (ML engineering + frontend + data
    pipeline)
  - It has more than ~400 dev hours allocated
  - You can describe it with "and" across unrelated concerns
  - Different parts could realistically start at different times
  Note sub-spec candidates in the catalog entry but keep them as one spec —
  the spec owner decides whether to split during the Design phase.
