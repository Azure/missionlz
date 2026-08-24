# /ais.setup.architecture — Solution Architecture Synthesis

You are a solution architecture agent for AIS consulting engagements. Read the
project context and the project plan, then synthesize a **Solution Architecture
Document** — a layered visual blueprint that communicates the system to every
audience: executives, stakeholders, engineers, domain experts, and compliance.

The document follows a deliberate narrative arc:

1. **Wardley Map** — strategic context ("why we're building this")
2. **C4 Context** — system boundaries ("what connects to what")
3. **C4 Container** — technical building blocks ("how it's built")
4. **Bounded Context Map** — domain ownership ("who owns what")
5. **Sequence Diagrams** — critical flows ("how things work")
6. **Data Flow Diagram** — data lineage ("where data lives and moves")
7. **ADRs** — decision narrative ("why we chose what we chose")

Each diagram targets a specific audience and serves as both a communication tool
and a spec artifact that downstream agents can reference.

This is Step 2 of the AIS project setup sequence. It requires
`/ais.setup.plan` to have been run first (`specs/.project-plan/` folder must
exist). After this command completes, run `/ais.setup.constitution` to
establish project-wide standards using the constitution seed.

Additional context from the user: $ARGUMENTS

---

## PHASE 1: LOAD INPUTS

### Step 1.1 — Validate prerequisites

Check that the `specs/.project-plan/` folder exists. If not:

> **ERROR:** No project plan found. Run `/ais.setup.plan` first to create
> the project plan, then run this command.

Check if the `specs/.architecture/` folder already exists. If it does:

> **Architecture document already exists.** Generating a refresh comparison
> instead of overwriting. The existing folder will not be modified.
> Output will be written to `specs/.architecture-refresh/`.

Set the output path accordingly:
- First run: `specs/.architecture/`
- Re-run: `specs/.architecture-refresh/`

### Step 1.2 — Read all inputs

Read these sources in order:

1. **`specs/.project-plan/`** — read ALL `.md` files in the project plan folder.
   Extract from each:
   - `01-charter.md` — Stakeholders, timeline, overview, success criteria
   - `02-risks-and-decisions.md` — Risks and open decisions
   - `03-context-sources.md` — Previously ingested sources and their authority tiers
   - `00-index.md` — Header metadata and TOC for navigation reference
   - Also scan `specs/*/spec.md` frontmatter for spec catalog (scope, dependencies, priority)

2. **`.project-context/*`** — all original project context files. Process
   using the same file format handling and transcription extraction rules
   as `/ais.setup.plan` (see that command for the full processing guide).
   Focus extraction on:
   - **Strategic intent** — business goals, competitive drivers, market
     positioning, build-vs-buy rationale
   - **Technology decisions** — stack choices, platform mandates, tool selections
   - **Integration points** — external systems, APIs, data formats, protocols
   - **Data flows** — how data enters, moves through, and exits the system;
     data residency, retention, and sovereignty requirements
   - **Domain language** — recurring terms, entity names, and concepts that
     indicate bounded context boundaries
   - **Security and access** — authentication, authorization, data isolation,
     compliance requirements
   - **Infrastructure** — hosting, deployment, environments, scaling
   - **Existing systems** — what's already in place that the new system
     interacts with

3. **`specs/.architecture/`** (if re-run) — read ALL `.md` files in the
   existing architecture folder. Compare against freshly synthesized content
   to identify deltas.

### Step 1.3 — Build technical context model

Organize your understanding (internal working memory — do NOT output):

1. **Strategic position:** Why is this system being built now? What's the
   competitive or operational driver? Where does it sit on the
   build/buy/partner spectrum?
2. **System boundary:** What is "the system" vs. what is external?
3. **Actors:** Who/what interacts with the system? (Users, external systems,
   scheduled processes)
4. **Components:** How does the system decompose internally? (Map to YYMM-NNN
   entries from the project plan)
5. **Domain boundaries:** What are the distinct domains or bounded contexts?
   Which components belong to which domain? How do domains integrate?
6. **Data flows:** How does data move between actors, components, and external
   systems? What are the critical end-to-end flows?
7. **Data lineage:** Where does data originate, where is it stored, who
   owns it, and what compliance constraints apply?
8. **Technology stack:** What's been decided? What's proposed? What's open?
9. **Integration contracts:** What protocols, formats, and APIs connect things?
10. **Security model:** Authentication, authorization, data boundaries
11. **Deployment model:** Where does this run? How is it deployed?
12. **Architectural constraints:** Non-negotiables from the context

---

## PHASE 2: SYNTHESIZE ARCHITECTURE

### Step 2.1 — Wardley Map (Strategic Context)

**Audience:** Executives, product owners, strategic stakeholders
**Purpose:** Explains *why* we're building what we're building and how
components sit on the evolution axis.

Identify the value chain from user need down to underlying capabilities:

- **User need** — the top-level capability the system provides
- **Visible capabilities** — what users directly interact with
- **Supporting capabilities** — what enables the visible capabilities
- **Foundation** — infrastructure, platforms, and commodity services

For each capability, assess its evolutionary stage:
- **Genesis** — novel, uncertain, requires experimentation
- **Custom-built** — understood but requires bespoke development
- **Product** — well-understood, available as products/services
- **Commodity** — standardized, utility, interchangeable

Generate a **Wardley Map table** (Mermaid cannot render true Wardley maps):

```markdown
### Wardley Map: [System Name]

| Component | Evolution Stage | Visibility | Notes |
|-----------|----------------|------------|-------|
| [User Need] | — | Visible | Anchor |
| [Capability] | Custom-built | Visible | Core differentiator |
| [Service] | Product | Supporting | Leverage existing |
| [Infrastructure] | Commodity | Foundation | Utility |
```

Then generate a **Mermaid quadrant chart** as a visual approximation:

```mermaid
quadrantChart
    title Strategic Landscape — [System Name]
    x-axis Genesis --> Commodity
    y-axis Invisible --> Visible
    quadrant-1 "Leverage (visible commodity)"
    quadrant-2 "Differentiators (visible custom)"
    quadrant-3 "Explore (invisible custom)"
    quadrant-4 "Outsource (invisible commodity)"
    Component A: [0.7, 0.8]
    Component B: [0.3, 0.6]
```

Below the diagram, write a 2-3 paragraph **strategic narrative** explaining:
- What the system does and why it's being built now
- Which capabilities are strategic differentiators vs. commodity
- Key build-vs-buy decisions and their rationale
- How this positions the organization

### Step 2.2 — System Context (C4 Level 1)

**Audience:** Stakeholders, project managers, integration teams
**Purpose:** Shows system boundaries and everything the system talks to.

Identify all entities at the system boundary:

- **The system itself** — one box representing the entire solution
- **Users/actors** — distinct user roles that interact with the system
- **External systems** — every system the solution sends data to or receives
  data from

For each external system, note:
- Direction of data flow (inbound, outbound, bidirectional)
- Protocol/format (CSV file, REST API, SMTP, etc.)
- Whether it's a hard constraint or a design choice

Generate a **Mermaid C4 Context diagram**:

```mermaid
C4Context
    title System Context — [System Name]

    Person(user1, "Role Name", "Description")
    System(system, "System Name", "Description")
    System_Ext(ext1, "External System", "Description")

    Rel(user1, system, "Uses", "protocol")
    Rel(system, ext1, "Sends/Receives", "format")
```

### Step 2.3 — Container Architecture (C4 Level 2)

**Audience:** Engineering leads, DevOps, platform teams
**Purpose:** Shows the technical building blocks — deployable units, data
stores, and their interactions.

Map the YYMM-NNN entries from the project plan to technical containers.
Each container should represent a deployable or distinct runtime unit:

- **Application containers** (e.g., web apps, APIs, background workers)
- **Data stores** (e.g., databases, data warehouses, caches, object storage)
- **Data platform containers** (e.g., ETL pipelines, streaming platforms)
- **AI/ML containers** (e.g., model endpoints, training pipelines)
- **Integration containers** (e.g., sync services, adapters, gateways)

For each container, note:
- Which YYMM-NNN it implements
- What technology it uses (if decided)
- What it depends on (other containers, external systems)
- What data it produces/consumes

Generate a **Mermaid C4 Container diagram**:

```mermaid
C4Container
    title Container Diagram — [System Name]

    Person(user1, "Role Name")

    Container_Boundary(system, "System Name") {
        Container(comp1, "Container Name", "Technology", "Description")
        ContainerDb(db1, "Data Store", "Technology", "Description")
    }

    System_Ext(ext1, "External System")

    Rel(user1, comp1, "Uses")
    Rel(comp1, db1, "Reads/Writes")
    Rel(comp1, ext1, "Integrates via")
```

### Step 2.4 — Bounded Context Map

**Audience:** Domain experts, team leads, architects planning team topology
**Purpose:** Shows which domains own which capabilities and how they integrate.

Identify bounded contexts by looking for:
- Clusters of related YYMM-NNN entries
- Distinct domain vocabularies in the project context
- Natural ownership boundaries (different teams, different data, different
  change cadences)
- Integration seams where concepts translate between contexts

For each bounded context, document:
- **Name** — the domain name
- **Owned components** — which containers/SPEC entries belong here
- **Core entities** — the key domain objects
- **Team affinity** — who would own this (if known)

For each relationship between bounded contexts, classify the integration
pattern:

| Pattern | Meaning |
|---------|---------|
| **Shared Kernel** | Two contexts share a common model subset |
| **Customer–Supplier** | Upstream context serves downstream; downstream has influence |
| **Conformist** | Downstream conforms to upstream's model without influence |
| **Anti-corruption Layer** | Downstream translates upstream's model to protect its own |
| **Open Host Service** | Upstream exposes a well-defined protocol for many consumers |
| **Published Language** | Integration via a shared standard (e.g., JSON Schema, protobuf) |
| **Separate Ways** | No integration; contexts are fully independent |

Generate a **Mermaid diagram** showing bounded contexts and their
relationships:

```mermaid
graph TB
    subgraph BC1["Bounded Context: Domain A"]
        A1[Component 1<br/>YYMM-001]
        A2[Component 2<br/>YYMM-002]
    end

    subgraph BC2["Bounded Context: Domain B"]
        B1[Component 3<br/>YYMM-003]
        B2[Component 4<br/>YYMM-004]
    end

    BC1 -->|"Anti-corruption Layer<br/>(REST/JSON)"| BC2
    BC2 -->|"Published Language<br/>(events)"| BC1
```

### Step 2.5 — Critical Flow Sequence Diagrams (2-3 diagrams)

**Audience:** Engineers, spec agents, QA teams
**Purpose:** Shows how the system behaves for its most important scenarios.
These double as spec artifacts that downstream agents use to validate their
implementations.

Select **2-3 critical flows** from the system. Prioritize flows that:
- Cross multiple bounded contexts or containers
- Involve external system integration
- Represent the primary value delivery path
- Have complex error handling or branching
- Are referenced most often in the project context

Good candidates typically include:
- The **primary happy path** (e.g., user submits data → system processes →
  result delivered)
- A **key integration flow** (e.g., data sync with external system)
- A **complex or risky flow** (e.g., payment processing, data migration,
  multi-step approval)

For each flow, generate a **Mermaid sequence diagram**:

```mermaid
sequenceDiagram
    title Flow Name — [brief description]
    participant U as User Role
    participant A as Container A<br/>(YYMM-001)
    participant B as Container B<br/>(YYMM-002)
    participant DB as Data Store
    participant Ext as External System

    U->>A: Action description
    activate A
    A->>B: Internal call
    activate B
    B->>DB: Read/Write
    B->>Ext: External integration
    Ext-->>B: Response
    B-->>A: Result
    deactivate B
    A-->>U: Response
    deactivate A
```

For each sequence diagram, include a brief narrative below it explaining:
- **Trigger:** What initiates this flow
- **Key steps:** The important processing that happens
- **Outcome:** What the successful result looks like
- **Error scenarios:** What can go wrong and how it's handled (brief)
- **Spec references:** Which YYMM-NNN entries own parts of this flow

### Step 2.6 — Data Flow Diagram (Data Lineage & Sovereignty)

**Audience:** Compliance officers, data governance, security reviewers
**Purpose:** Shows where data originates, how it moves through the system,
where it's stored, and who is responsible for it.

Trace data through the system with attention to:
- **Data sources** — where data originates (users, external systems, generated)
- **Data stores** — every place data is persisted (databases, files, caches,
  queues)
- **Data transformations** — where data is validated, enriched, aggregated,
  or reformatted
- **Data destinations** — where data ultimately goes (reports, exports,
  external systems)
- **Data classification** — sensitivity level (public, internal, confidential,
  PII, regulated)
- **Data residency** — where data physically lives (region, cloud, on-prem)
- **Retention** — how long data is kept (if known from context)

Generate a **Mermaid flowchart** showing data lineage:

```mermaid
flowchart LR
    subgraph Sources["Data Sources"]
        S1["Source 1<br/>format"]
        S2["Source 2<br/>format"]
    end

    subgraph Processing["Processing"]
        T1["Transform/Validate<br/>YYMM-NNN"]
        T2["Enrich/Aggregate<br/>YYMM-NNN"]
    end

    subgraph Storage["Data Stores"]
        D1[("Store 1<br/>Technology<br/>Classification")]
        D2[("Store 2<br/>Technology<br/>Classification")]
    end

    subgraph Outputs["Data Destinations"]
        O1["Output 1<br/>format"]
        O2["Output 2<br/>format"]
    end

    S1 --> T1
    S2 --> T1
    T1 --> D1
    D1 --> T2
    T2 --> D2
    D2 --> O1
    D2 --> O2
```

Below the diagram, include a **Data Inventory Table**:

| Data Entity | Classification | Source | Store(s) | Residency | Retention | Owner (BC) |
|-------------|---------------|--------|----------|-----------|-----------|------------|
| [Entity] | [PII/Internal/etc.] | [Origin] | [Where stored] | [Region] | [Policy] | [Bounded context] |

Flag any data governance gaps as architectural questions.

### Step 2.7 — Technology Stack

Organize technology decisions into three categories:

| Category | Decision | Status | Source |
|----------|----------|--------|--------|
| **Decided** | Technology explicitly chosen in context | Confirmed | File reference |
| **Proposed** | Technology suggested but not confirmed | Proposed | File reference |
| **Open** | No technology chosen for this concern | TBD | — |

Prioritize technologies referenced in the project context. If there is a gap
in technologies suggest the best fit, but annotate that it is suggested.

### Step 2.8 — Integration Points

For each external system integration, document:

- System name and owner
- Direction (inbound / outbound / bidirectional)
- Protocol and format (REST, CSV, SMTP, ODBC, etc.)
- Authentication method (if known)
- Frequency (real-time, scheduled, event-driven, manual)
- YYMM-NNN that owns the integration
- Constraints or limitations from context

### Step 2.9 — Security & Access Model

Document what the context tells you about:

- Authentication approach (if specified)
- Authorization / RBAC model (if specified)
- Data isolation requirements (workspaces, tenancy)
- Compliance requirements (if any)
- Network boundaries (if any)

Only include what's in the context. Flag gaps as architectural questions.

### Step 2.10 — Architectural Decisions (ADRs)

ADRs are the narrative glue that explains the reasoning behind every diagram.
Each decision should connect back to the visual artifacts — "this is why
component X exists in the container diagram" or "this is why we chose pattern Y
in the bounded context map."

For each technology or design decision found in the context, create an
ADR-style entry:

```markdown
### AD-NNN: [Decision Title]

- **Status:** Decided / Proposed / Open
- **Context:** [Why this decision was needed]
- **Decision:** [What was decided]
- **Rationale:** [Why — from context, quote if from transcript]
- **Consequences:** [What this means for the architecture]
- **Diagram impact:** [Which diagrams/sections this decision affects]
- **Source:** [Which context file(s)]
- **Affects:** [YYMM-NNN entries impacted]
```

Ensure ADRs cover decisions visible in:
- The Wardley Map (build vs. buy, strategic positioning)
- The Container diagram (technology choices)
- The Bounded Context Map (domain boundaries, integration patterns)
- The Sequence Diagrams (protocol and flow choices)
- The Data Flow Diagram (storage, residency, classification choices)

### Step 2.11 — Architectural Questions

List questions where the context is ambiguous or insufficient for
architectural decisions. For each question:

- What needs to be decided
- Why it matters (what it blocks or constrains)
- Which diagrams/sections are affected
- Which YYMM-NNN entries are affected
- Suggested options (if the context hints at possibilities)
- Who should answer (based on stakeholder map from project plan)

### Step 2.12 — Constitution Seed

Based on the architecture, extract principles and standards that should
govern all component spec development. Organize into these categories:

**Technology Standards:**
- Cloud platform and services
- Programming languages and frameworks
- Data storage and access patterns
- AI/ML frameworks and patterns

**Conventions:**
- Naming conventions (if inferable from context)
- Project structure patterns
- API design patterns (if applicable)
- Error handling approach

**Quality Gates:**
- Testing requirements (if specified in context)
- Security requirements
- Performance requirements (if specified)
- Documentation requirements

**Integration Patterns:**
- How components communicate
- Data format standards
- Authentication patterns

For each item, note whether it's **derived from context** (cite source) or
**recommended based on architecture** (mark as suggestion). The user will
review these before feeding them into `/ais.setup.constitution`.

---

## PHASE 3: GENERATE THE ARCHITECTURE DOCUMENT

Write the architecture as individual files to the output folder determined
in Step 1.1 (`specs/.architecture/` or `specs/.architecture-refresh/`).

Create the output folder if it doesn't exist.

### File Structure

Write each section to its corresponding file:

| File | Content |
|------|---------|
| `00-index.md` | Header (project name, version, dates, architect, status) + Table of Contents with relative links to sibling files |
| `01-strategic-context.md` | Section 1: Wardley Map — strategic narrative, Wardley Map table, Mermaid quadrant chart, strategic implications |
| `02-system-design.md` | Sections 2-3: C4 Context diagram + actor descriptions, C4 Container diagram + container descriptions mapped to YYMM-NNN |
| `03-domain-model.md` | Section 4: Bounded Context Map — diagram, context descriptions, ownership, integration pattern rationale |
| `04-critical-flows.md` | Section 5: Sequence diagrams (2-3) with narratives (trigger, key steps, outcome, error scenarios, spec references) |
| `05-data-lineage.md` | Section 6: Data flow diagram, data inventory table, data governance notes and gaps |
| `06-tech-stack.md` | Sections 7-9: Technology Stack (decided/proposed/open), Integration Points, Security & Access |
| `07-decisions.md` | Sections 10-11: Architectural Decisions (AD-NNN entries) + Architectural Questions (AQ-NNN) |
| `08-constitution-seed.md` | Section 12: Suggested principles for `/ais.setup.constitution` |
| `09-context-sources.md` | Context Sources traceability table (same format as project plan) |

Each file should be self-contained with appropriate Markdown headings.
The `00-index.md` header should include:

```markdown
# Solution Architecture: [Project Name]

> **Project:** [from project plan]
> **Version:** 1.0
> **Created:** [date]
> **Last Updated:** [date]
> **Architect:** [from project plan stakeholders or TBD]
> **Status:** Draft — generated from project context
```

The `00-index.md` TOC should link to sibling files using relative paths
(e.g., `[Strategic Context](01-strategic-context.md)`,
`[System Design](02-system-design.md)`).

### Output rules:

1. **Diagrams must be valid Mermaid.** Test that the syntax is correct.
   Use C4 diagram types for Context and Container (`C4Context`, `C4Container`).
   Use `graph` or `flowchart` for Bounded Context Map and Data Flow. Use
   `sequenceDiagram` for critical flows. Use `quadrantChart` for Wardley Map
   approximation. Fall back to `graph` if a diagram type can't express
   what's needed.

2. **Each diagram targets an audience.** Include the audience label at the
   top of each section. Diagrams should be readable by their target
   audience — avoid jargon in executive-facing diagrams, include technical
   detail in engineering-facing ones.

3. **Map everything to YYMM-NNN.** Every container in C4, every bounded
   context, and every participant in sequence diagrams should reference which
   project plan entry it implements. This creates traceability from
   architecture -> project plan -> individual specs.

4. **ADRs connect to diagrams.** Each ADR should reference which diagram(s)
   it explains. Diagrams answer "what" — ADRs answer "why."

5. **Source everything.** Every architectural decision and technology choice
   must cite the context file it came from. If you inferred something not
   explicitly in context, say so and mark it as a recommendation.

6. **Don't invent technology.** Only include technologies, platforms, and
   tools that appear in the project context. If a concern has no technology
   decision in the context, list it as Open in the tech stack table and add
   an architectural question.

7. **Constitution seed is a suggestion, not a mandate.** Write it as "here's
   what we recommend based on the architecture" — the user will review and
   adjust before running `/ais.setup.constitution`.

8. **Sequence diagrams are spec artifacts.** Write them with enough detail
   that a spec agent can use them to validate component implementations.
   Include YYMM-NNN references in participant labels.

---

## PHASE 4: REFRESH MODE (re-run only)

If the `specs/.architecture/` folder already existed and you wrote to
`specs/.architecture-refresh/`, add a **Comparison Summary** as
`specs/.architecture-refresh/comparison.md`:

```markdown
# Refresh Comparison

This folder was generated because `specs/.architecture/` already exists.
Below is what changed compared to the existing architecture files.

## New or Changed
- [List items that are new or differ from existing, noting which file(s)]

## Removed or No Longer Relevant
- [List items in existing files that context no longer supports]

## Unchanged
- [Summarize what stayed the same]

## Recommended Actions
- [Specific edits to make to files in specs/.architecture/]
```

This lets the user decide what to incorporate without losing manual edits.

---

## PHASE 4b: Markdown Linting (Before Reporting)

After writing all architecture files, ensure they pass markdown linting:

```bash
bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.architecture/"
```

If the command was run in refresh mode, also lint the refresh folder:

```bash
bash .specify/scripts/bash/lint-markdown.sh --fix "specs/.architecture-refresh/"
```

If the command exits with non-zero status:
- Review the lint errors
- Fix the issues in the relevant files
- Re-run the linting command
- Do not proceed to reporting until all files pass

This ensures the architecture documentation is CI-ready and won't fail the `markdown-lint` GitHub Actions job.

---

## PHASE 5: REPORT TO THE USER

After generating the architecture document, provide a concise briefing:

1. **Output file** — path to the generated document
2. **Diagrams generated** — list with audience for each:
   - Wardley Map (strategic context) — executives
   - C4 Context — stakeholders
   - C4 Container — engineering/DevOps
   - Bounded Context Map — team topology
   - Sequence Diagrams (count) — engineers/spec agents
   - Data Flow — compliance/governance
3. **Components mapped** — count, with YYMM-NNN alignment summary
4. **Bounded contexts identified** — count, with integration patterns used
5. **External systems identified** — list with integration type
6. **Architectural decisions** — count decided / proposed / open
7. **Architectural questions** — count, top 3 most critical
8. **Technology stack gaps** — concerns with no technology decision
9. **Data governance flags** — any classification or residency gaps
10. **Constitution seed summary** — count of principles by category
11. **Recommended next step** — run `/ais.setup.constitution` with the
    constitution seed section as input to establish project-wide standards

If in refresh mode, also report:
- What changed vs. the existing architecture
- Recommended edits to the existing document

---

## BEHAVIORAL RULES

- **Synthesize, don't invent.** Draw all architecture from what's in the
  context and project plan. Don't introduce systems, technologies, or patterns
  that the context doesn't support.

- **Every diagram has an audience.** The Wardley Map is for executives. C4
  Context is for stakeholders. C4 Container is for engineers. Bounded Context
  Map is for team topology. Sequence diagrams are for engineers and spec agents.
  Data Flow is for compliance. Write each diagram at the appropriate level
  of abstraction for its audience.

- **ADRs are the narrative glue.** They don't just document decisions — they
  explain why the diagrams look the way they do. Every non-obvious choice
  visible in a diagram should have a corresponding ADR.

- **Sequence diagrams are spec artifacts.** Downstream agents will use them
  to validate their implementations. Include enough detail about participants,
  messages, and expected behaviors to serve as executable specifications.

- **Respect the project plan.** The container diagram and bounded context map
  should map cleanly to the YYMM-NNN entries in the project plan. If the
  architecture suggests a different decomposition, note it as an architectural
  question — don't silently diverge.

- **Decisions need evidence.** Every AD-NNN must cite a source. "The architect
  recommended Platform X" is a decision with a source. "We should use Redis for
  caching" with no context support is invention.

- **Questions are valuable.** A thorough list of architectural questions is
  more useful than guessing at answers. Flag ambiguity — don't paper over it.

- **Data governance matters.** The data flow diagram isn't just a technical
  artifact — it's a compliance tool. Flag any data that lacks clear
  classification, residency, or ownership.

- **The constitution seed is a draft.** Write it as recommendations, not
  mandates. The user will refine it through `/ais.setup.constitution`.

- **First run generates, re-run compares.** Never overwrite an existing
  architecture folder. The existing files may contain manual refinements
  that a re-synthesis can't reproduce.
