# Playbook: DDF — Microsoft Fabric

> **Version**: 2.1 | **Last Updated**: 2026-05-21
> **Framework**: AIS Data Delivery Framework (DDF)
> **Platform**: Microsoft Fabric

## Overview

**What this project type involves**: Implementing a modern analytics platform on
Microsoft Fabric using the AIS Data Delivery Framework (DDF). DDF prescribes a
5-phase methodology — Strategic Assessment, Ingestion, Storage, Modeling, Analytics
— layered on Fabric's OneLake architecture with Medallion zones (Bronze → Silver →
Gold), dbt-based transformation, and Power BI semantic models. Projects typically
involve migrating from legacy BI/data warehouse platforms or building greenfield
analytics on Fabric.

**Typical client profile**: Organizations committed to the Microsoft ecosystem
(Azure, M365, Power BI) looking to consolidate data silos into a governed analytics
platform. Often have existing Power BI usage but lack a unified data engineering
layer. May be migrating from Azure Synapse, SSIS/ADF pipelines, or on-premises
SQL Server/SSAS.

**What success looks like**: Data flows reliably from source to OneLake via
Medallion zones, transforms are version-controlled in dbt and tested, Power BI
semantic models serve self-service analytics with governance (endorsement labels,
RLS), and the platform operates within Fabric capacity limits with clear cost
attribution per domain.

---

## Governing Questions Register

> These questions must be answered before their tagged phase begins.
> When using AIS spec commands with an active playbook, unanswered questions
> for the current phase will be surfaced as soft-gate blockers.
>
> **Soft gate pattern**: surface unanswered questions → ask the user to
> answer, defer (with justification), or mark N/A → require explicit
> acknowledgment → proceed.

### Pre-sales Phase

| ID | Domain | Question | Drives |
|----|--------|----------|--------|
| GQ-001 | Business | What decisions are you trying to make with data that you can't make today? | Data product scope, domain boundaries, Gold model shape |
| GQ-002 | Business | Who are the data consumers? (analysts, executives, data scientists, applications) | Semantic model investment level, consumption interface choices |
| GQ-003 | Business | What's your current reporting cadence? (real-time, daily, weekly, ad-hoc) | Ingestion latency requirements, Direct Lake vs. Import mode |
| GQ-004 | Business | What are the regulatory/compliance requirements for your data? (GDPR, HIPAA, SOX) | Gold (Sensitive) scope, masking policies, data isolation |
| GQ-005 | Business | What's the org structure? (Functional, product-based, matrix?) | Number and shape of Fabric Domains |
| GQ-006 | Business | Which business units need independent cost attribution? | Dedicated capacity per domain vs. shared |
| GQ-007 | Business | Are there data isolation requirements between teams? (Compliance, competitive, contractual) | Domain separation, Gold (Sensitive) scope |
| GQ-008 | Business | How many distinct data consumption teams exist? | Workspace count, semantic model count |
| GQ-009 | Business | Who are the data stewards per domain? | Domain governance model, endorsement label ownership |
| GQ-010 | Technical | What are your current data sources? (databases, SaaS APIs, files, streaming) | Source inventory, ingestion pattern selection |
| GQ-011 | Technical | Is there an existing CAF hub-and-spoke topology, or greenfield? | IaC scope (new spoke vs. integrate into existing) |
| GQ-012 | Technical | Zero-trust networking or identity-boundary (Conditional Access) model? | Network security design (private endpoints vs. Conditional Access) |
| GQ-013 | Technical | Is ExpressRoute / VPN in place for on-premises connectivity? | VNet data gateway feasibility; Mirroring for on-prem sources |
| GQ-014 | Technical | Can data traverse public internet to OneLake, or must it be private? | BYOSA, private endpoints, managed VNet requirements |
| GQ-015 | Technical | Is multi-region DR required for the data platform? | Capacity architecture, replication strategy |
| GQ-016 | Technical | Do you have an existing GitHub org and CI/CD? | CI/CD setup effort; trunk-based feasibility |
| GQ-017 | Data | What does "a single source of truth" mean to you? Which entities matter most? | Silver entity model scope, Gold curated mart shape |
| GQ-018 | Data | Are there data governance policies in place? Data stewards? A data catalog? | Endorsement label process; RBAC complexity; domain stewardship |
| GQ-019 | Data | What's the latency requirement? (real-time, near-real-time, batch daily) | Ingestion priority (Mirroring vs. Shortcut vs. pipeline), Direct Lake feasibility |
| GQ-020 | Data | Is the team open to dbt? What's their SQL/analytics engineering maturity? | dbt adoption scope, training requirements, alternative tooling |
| GQ-021 | Operations | Who will operate the platform day-to-day? Do you have data engineers? | Ingestion strategy (Notebooks feasible only if yes); dbt training scope |
| GQ-022 | Analytics | Do consumers use Power BI, SQL, Python, or a mix? | Semantic model investment level, notebook infrastructure |
| GQ-023 | Analytics | Who will create and maintain semantic models? (BI team? dbt devs? Self-service?) | Co-gen strategy, governance complexity |
| GQ-024 | Analytics | How often do report requirements change? | Semantic versioning importance |
| GQ-025 | Analytics | Are there advanced analytics / ML use cases beyond BI? | Notebook infrastructure, feature store scope |
| GQ-026 | Assumptions | Do compliance requirements mandate environment-isolated raw data? | Whether single shared Bronze works or environments need separate raw zones |

### Setup Phase

| ID | Domain | Question | Drives |
|----|--------|----------|--------|
| GQ-027 | Network | How many on-premises data sources need gateway connectivity? | VNet gateway sizing and count |
| GQ-028 | Network | Are private endpoints standard for Azure services in this tenant? | Implementation effort for Fabric private link |
| GQ-029 | Data | How clean is your source data? Do you have known quality issues? | dbt test coverage scope; data profiling sprint sizing |
| GQ-030 | Technical | What's the total data volume and growth rate? | Capacity sizing, partitioning strategy |
| GQ-031 | Technical | Do you have existing ETL/ELT pipelines? What tools? (SSIS, ADF, Informatica) | Migration scope, parallel-run requirements |
| GQ-032 | Technical | What's your current branching strategy? Are approval gates acceptable for promotion? | Trunk-based feasibility, deployment pipeline design |
| GQ-033 | Technical | Are there sources where re-ingestion is impractical (cost, time, API limits)? | Incremental-only ingestion design, full-refresh feasibility |
| GQ-034 | Technical | Are there network or governance constraints that block Direct Lake? | Semantic model mode (Direct Lake vs. Import) |
| GQ-035 | Operations | What monitoring/alerting exists for data pipelines today? | Observability scope |
| GQ-036 | Data | What PII / regulated fields exist? What masking policies apply? | Sensitive publish (P6) scope |
| GQ-037 | Analytics | Is row-level security (RLS) required? For which datasets? | Semantic model complexity, Gold (Sensitive) scope |

### Design Phase

| ID | Domain | Question | Drives |
|----|--------|----------|--------|
| GQ-038 | Transformation | Which entities have frequent attribute changes requiring history? | SCD Type 2 (P2) scope |
| GQ-039 | Transformation | Do analysts query historical versions, or only current state? | P2 necessity vs. just keeping latest |
| GQ-040 | Transformation | What's the analytical grain consumers need? (Entity? Aggregated? Time-series?) | Gold model shape (P4 curated marts) |
| GQ-041 | Transformation | What pre-aggregations do consumers request today? | MV aggregates (P5) candidates |
| GQ-042 | Operations | What's your testing strategy for data quality? | dbt test patterns, quality gate thresholds |

---

## Core Principles

> **Driven by**: GQ-001 (business decisions), GQ-017 (source of truth),
> GQ-020 (dbt maturity)

1. **OneLake-first** — All data lands in OneLake. No external storage silos.
2. **Medallion zones** — Bronze (raw), Silver (conformed), Gold (consumption-ready),
   Gold Sensitive (masked/restricted).
3. **dbt for transformation** — All Silver → Gold transforms are dbt models.
   Version-controlled, tested, documented.
4. **Domain-organized** — Workspaces map to business domains. Capacities align
   to cost centers.
5. **Governed by default** — Endorsement labels (Certified/Promoted), RLS,
   sensitivity labels from day one.

---

## Network Security & Infrastructure

> **Driven by**: GQ-011 (CAF topology), GQ-012 (zero-trust model),
> GQ-013 (ExpressRoute/VPN), GQ-014 (data transit policy),
> GQ-027 (gateway sizing), GQ-028 (private endpoints)

### Hub-and-Spoke Network

When the client has existing CAF infrastructure (GQ-011), Fabric integrates as a
spoke. Key decisions:

- **Private endpoints** (GQ-012 = zero-trust): Fabric private link for workspace
  access, storage private endpoints for BYOSA, VNet data gateways for on-prem
  sources.
- **Conditional Access** (GQ-012 = identity-boundary): Entra ID Conditional Access
  policies, no private endpoints required. Simpler but less network isolation.
- **On-premises connectivity** (GQ-013): ExpressRoute or VPN required for VNet
  data gateways. Without it, on-prem sources need alternative ingestion
  (file-based, CDC to cloud staging).

### BYOSA (Bring Your Own Storage Account)

> **Driven by**: GQ-014 (data transit), GQ-026 (environment isolation)

When data cannot traverse public internet (GQ-014), use BYOSA with private
endpoints to keep data in the client's network boundary. Consider BYOSA also
when environment isolation is required (GQ-026).

---

## DDF Phase 0: Discovery & Assessment

> **Driven by**: GQ-001–GQ-026 (all Pre-sales governing questions)
>
> Renamed from "Phase 1: Strategic Assessment" — this is pre-project discovery,
> not an implementation phase.

### Source Inventory

> **Driven by**: GQ-010 (data sources), GQ-019 (latency), GQ-033 (re-ingestion)

Catalog all data sources with:
- System name, owner, technology
- Data volume and growth rate
- Latency requirement (real-time, near-real-time, batch)
- Ingestion eligibility: Mirroring-eligible? Shortcut-eligible? API available?
- Re-ingestion feasibility (GQ-033): Can we full-refresh, or incremental only?

### Domain Mapping

> **Driven by**: GQ-005 (org structure), GQ-006 (cost attribution),
> GQ-007 (data isolation), GQ-008 (consumption teams), GQ-009 (stewards)

Map business domains to Fabric organizational units:

| Question Answer | Design Impact |
|----------------|---------------|
| Functional org (GQ-005) | Domains = departments (Finance, Sales, HR) |
| Product-based org | Domains = product lines |
| Independent cost attribution needed (GQ-006) | Dedicated capacity per domain |
| Data isolation required (GQ-007) | Separate workspaces with RBAC, Gold Sensitive zone |
| Multiple consumption teams (GQ-008) | Multiple Gold workspaces per domain |
| Named stewards (GQ-009) | Steward = endorsement label owner per domain |

### Capacity Planning

> **Driven by**: GQ-006 (cost attribution), GQ-015 (multi-region DR),
> GQ-030 (data volume)

- Shared capacity: Suitable when cost attribution per domain is not required
- Dedicated capacity per domain: Required when GQ-006 = yes
- Multi-region: Required when GQ-015 = yes; plan paired capacities

### Analytics Maturity Assessment

> **Driven by**: GQ-022 (consumption tools), GQ-023 (semantic model ownership),
> GQ-024 (change frequency), GQ-025 (ML use cases)

| Assessment Area | Low Maturity | High Maturity |
|----------------|--------------|---------------|
| Consumption (GQ-022) | Power BI only | Power BI + SQL + Python notebooks |
| Semantic ownership (GQ-023) | BI team maintains all | Self-service with governance |
| Change frequency (GQ-024) | Quarterly | Weekly — semantic versioning critical |
| Advanced analytics (GQ-025) | None planned | Notebooks, feature store needed |

---

## DDF Phase 2: Ingestion

> **Driven by**: GQ-010 (sources), GQ-013 (on-prem connectivity),
> GQ-014 (network egress), GQ-019 (latency), GQ-033 (re-ingestion)

### Ingestion Priority (Decision Tree)

> **Driven by**: GQ-010 (source inventory), GQ-019 (latency requirements),
> GQ-013 (ExpressRoute/VPN), GQ-014 (network egress policy)

```
Source eligible for Mirroring?
├── Yes + latency ≤ near-real-time → Use Mirroring (CDC to Bronze)
├── Yes + batch acceptable → Consider Mirroring or Shortcut
└── No
    ├── Source in Azure? → Shortcut (zero-copy reference)
    ├── Source on-premises?
    │   ├── ExpressRoute/VPN in place (GQ-013)? → VNet data gateway
    │   └── No connectivity → File-based ingestion or cloud-stage first
    └── Source is SaaS API → Data pipeline (Copy activity) or Notebook
```

### Ingestion Patterns

| Pattern | When to Use | Governing Questions |
|---------|------------|-------------------|
| **Mirroring** | CDC from supported sources (SQL Server, Cosmos DB, Snowflake) | GQ-010, GQ-019 |
| **Shortcuts** | Azure data already in ADLS/S3; zero-copy reference | GQ-010, GQ-014 |
| **Data Pipelines** | Batch loads from APIs, files, unsupported sources | GQ-010, GQ-033 |
| **Notebooks** | Complex ingestion logic requiring Python/Spark | GQ-010, GQ-021 (engineers available?) |
| **VNet Data Gateway** | On-premises sources via ExpressRoute/VPN | GQ-013, GQ-027 |
| **Dataflow Gen2** | Low-code transforms for citizen integrators | GQ-021 (no engineers) |

### Data Landing (Bronze Zone)

All ingested data lands in Bronze as-is. No transformations in Bronze.

- Default to central/source-owned Bronze unless GQ-026 requires
  environment-isolated raw data.
- Domain workspaces consume approved central or legacy source data through
  OneLake shortcuts or read-only references; do not copy raw/source data into a
  domain just to make a model build.
- SQL-first domain projects that need same-workspace cross-database visibility
  create a schema-enabled domain source bridge Lakehouse with table shortcuts
  under the declared schema path, then point dbt source variables at that
  Lakehouse database.
- Parquet/Delta format
- Retention: keep raw data for reprocessing capability (unless GQ-033 = incremental only)

Fixtures are allowed only for explicitly named local/offline tests. They are not
valid Fabric deployment infrastructure and must not impersonate shared source
items.

### Schema Evolution & API Contract Drift

> **Learned from**: ai-reporting PRs #54, #40 — Bronze writes failed when upstream
> APIs added new fields without notice, causing Delta schema mismatch errors.

Source APIs **will** change their schemas without warning. Bronze ingestion must
handle this gracefully:

**Pre-flight schema check pattern:**

1. Before each write, compare incoming DataFrame columns against the existing
   Delta table schema
2. `ALTER TABLE ADD COLUMN` for any new fields (append-only schema evolution)
3. Write the data with the now-compatible schema
4. Never drop columns from Bronze — append-only schema evolution preserves history

**Rules:**

- Never assume API contracts are stable. Even well-documented APIs add fields.
- Schema normalization happens at write time, not read time.
- Log schema changes for audit trail (new fields detected per run).
- If a source removes a field, the Bronze column persists with NULLs — do not
  drop it. Silver models handle missing fields explicitly.

**Anti-pattern:** Using `saveAsTable(mode="overwrite")` with a fixed schema.
This silently drops new fields or fails on schema mismatch. Always use
append mode with pre-flight schema alignment.

### Fabric Runtime Environment

> **Learned from**: ai-reporting PRs #44, #40, #55 — Lakehouse path resolution
> failed with `/None/` in ABFSS paths; CI broke from missing optional dependencies.

Fabric's PySpark runtime APIs vary across versions and session types:

**Lakehouse ID resolution (multi-tier fallback):**

```python
# Tier 1: Default lakehouse API
lakehouse_id = notebookutils.lakehouse.getDefault().id

# Tier 2: Runtime context (key name varies by Fabric version)
if not lakehouse_id:
    ctx = notebookutils.runtime.context
    for key in ["currentLakehouseId", "lakehouseId", "defaultLakehouseId"]:
        lakehouse_id = ctx.get(key)
        if lakehouse_id:
            break

# Tier 3: Fail with actionable error
if not lakehouse_id:
    raise RuntimeError(
        "No lakehouse attached to this notebook. "
        "Attach a lakehouse in the Fabric UI before running."
    )
```

**Environment-specific dependencies:**

- CI environments and Fabric runtime differ from local dev. Make optional
  dependencies detectable and graceful:
  ```python
  try:
      from dotenv import load_dotenv
      load_dotenv()
  except ImportError:
      pass  # CI/Fabric — .env not needed
  ```
- Never add local-only dependencies (e.g., `python-dotenv`) as hard requirements.
- Fail fast with clear errors, not cryptic path errors (e.g., `/None/Tables/...`).

**Credential retrieval:**

- All API credentials from Azure Key Vault via `mssparkutils.credentials.getSecret()`
- Never hardcode credentials or use environment variables for secrets in notebooks
- CI/CD uses service principals with GitHub OIDC federation

---

## Identity Resolution

> **Learned from**: ai-reporting PRs #58, #49, #48, #39, specs 2603-006, 2603-010
>
> Identity resolution was the **#1 source of bugs** in the first DDF implementation.
> Five separate PRs fixed identity-related data quality issues. This section
> codifies the patterns that prevent these bugs.

### The Golden Rule

**All user activity MUST inner-join to a canonical identity dimension (`dim_user`)
as the first transformation step.** No exceptions for any platform or source.

Violations of this rule caused:
- Orphaned fact rows that broke referential integrity tests
- Guest accounts and service accounts leaking into activity metrics
- Inflated distinct user counts (815 showing when true count was 137)

### Resolution Priority Chain

When correlating identities across platforms, apply these strategies in order:

| Priority | Strategy | When to Use |
|----------|----------|-------------|
| 1 | **SAML assertion** | GitHub → corporate UPN (via SAML SSO identity provider) |
| 2 | **Email normalization** | Fallback for unresolved SAML (match on normalized email) |
| 3 | **Direct email match** | Platforms that use corporate email natively (Cursor, M365) |
| 4 | **Entra directory lookup** | Canonical identity source; all platforms resolve here |
| 5 | **Unresolved bucket** | Audit separately; do not include in aggregate metrics |

### Mandatory Patterns

**Case-insensitive comparisons everywhere:**

- All identity searches, joins, and filters MUST use case-insensitive comparison
  (e.g., `LOWER()` on both sides of join)
- This applies to: email, UPN, display name, department, job title
- Violation silently drops matches — no error, just wrong numbers

**Cross-org enterprise APIs:**

- Org-scoped API endpoints miss users licensed through other enterprise orgs
- Always use enterprise-level APIs for completeness, then supplement with
  org-scoped endpoints for detail
- Back-fill license status with activity data: if a user has activity in the
  last 28 days, they are effectively licensed regardless of what the seats
  endpoint reports

**Multi-signal licensing:**

- Never rely on a single API endpoint to determine license status
- Combine: seat assignment API + recent activity + directory membership
- Cross-validate: if seat count says 93 but activity shows 110 users,
  investigate cross-org scenarios

**Directory-resolvable users only:**

- Only count activity for users resolvable in corporate directory (Entra ID)
- Reject unresolvable identities immediately at the Silver layer
- Maintain an audit table of unresolved identities for investigation
- Acceptable unresolved rate: < 5% (typically external collaborators)

**Dimensional history preservation:**

- Keep ALL historical rows in `dim_user` — never filter the dimension itself
- Add `is_active_in_directory` flag for current vs. departed users
- Filter staleness at the consumption/aggregation layer, not at the dimension
- Violation breaks referential integrity on historical fact rows

### Platform-Specific Identity Notes

| Platform | Identity Field | Challenge | Resolution |
|----------|---------------|-----------|------------|
| GitHub Copilot | GitHub login (personal) | Not corporate identity | SAML SSO mapping → UPN |
| M365 Copilot | UPN | Native Entra identity | Direct match |
| Cursor | Email / display name | May not match corporate email | Email normalization + roster |
| Claude | Organization email | Entra-aligned | Direct match |

### Quality Gates for Identity

| Gate | Criteria | Severity |
|------|----------|----------|
| Zero unmatched licensed users | `dim_user` has no licensed users without directory match | MUST |
| Referential integrity | All `fact_*` user_key values exist in `dim_user` | MUST |
| Unresolved rate < 5% | Unresolved identities are external/expected | SHOULD |
| No orphaned activity | Activity without dim_user join = immediate test failure | MUST |

---

## DDF Phase 3: Storage — Domain Organization

> **Driven by**: GQ-005 (org structure), GQ-006 (cost attribution),
> GQ-007 (data isolation), GQ-018 (governance maturity)

### Workspace Layout

```
Fabric Tenant
├── Domain: [Business Domain 1]
│   ├── Workspace: [Domain]            (domain Warehouse, gold/silver outputs)
│   ├── Lakehouse: [Domain] source bridge(s) (shortcuts to approved sources)
│   └── Optional workspace: [Domain]-gold-sensitive (masked/restricted)
├── Workspace: Central/source Bronze    (source-faithful raw/legacy inputs)
└── Domain: [Business Domain 2]
    └── ...
```

### Zone Responsibilities

| Zone | Purpose | Transformation | Access |
|------|---------|---------------|--------|
| **Bronze** | Raw data landing | None (as-is from source) | Data engineers only |
| **Silver** | Conformed, cleaned, typed | dbt models (P1: staging, P3: conformed) | Data engineers + analysts (read) |
| **Gold** | Consumption-ready models | dbt models (P4: curated marts, P5: aggregates) | Analysts, BI tools, semantic models |
| **Gold Sensitive** | Masked/restricted data | dbt models (P6: sensitive publish) | Authorized users only (GQ-004, GQ-036) |

Domain source bridge Lakehouses are not a new transformation zone. They are
workspace-local references to approved source-owned data so that Warehouse/dbt
queries can resolve sources and outputs in one Fabric workspace without copying
or faking raw data.

### Endorsement Labels

> **Driven by**: GQ-009 (data stewards), GQ-018 (governance maturity)

| Label | Meaning | Who Can Apply |
|-------|---------|--------------|
| **Certified** | Production-quality, validated, governed | Data stewards (GQ-009) |
| **Promoted** | Recommended for use, in validation | Domain leads |
| (none) | Exploratory, development | Anyone |

---

## DDF Phase 4: Modeling (dbt Transformation Patterns)

> **Driven by**: GQ-020 (dbt maturity), GQ-029 (data quality),
> GQ-038–GQ-041 (transformation design questions)

### Pattern Reference

| ID | Pattern | Description | Governing Questions |
|----|---------|------------|-------------------|
| P1 | Staging | Bronze → Silver: type casting, renaming, basic cleaning | GQ-029 (data quality) |
| P2 | SCD Type 2 | Track historical changes to entity attributes | GQ-038 (frequent changes?), GQ-039 (query history?) |
| P3 | Conformed Dimensions | Silver entities with business keys, consistent naming | GQ-017 (source of truth) |
| P4 | Curated Marts | Gold models shaped for specific analytical use cases | GQ-040 (analytical grain), GQ-001 (business decisions) |
| P5 | MV Aggregates | Pre-computed aggregates for performance | GQ-041 (pre-aggregation needs) |
| P6 | Sensitive Publish | Gold Sensitive with masking/filtering for regulated data | GQ-004 (compliance), GQ-036 (PII fields), GQ-037 (RLS) |

### Pattern Selection Decision

> **Driven by**: GQ-038 (SCD needs), GQ-039 (historical queries),
> GQ-040 (analytical grain), GQ-041 (pre-aggregations)

- **P1 + P3**: Always required (minimum viable transform layer)
- **P2**: Only if GQ-038 = yes AND GQ-039 = yes (entities change AND consumers query history)
- **P4**: Always required (Gold consumption models)
- **P5**: Only if GQ-041 identifies specific pre-aggregation needs
- **P6**: Only if GQ-004 or GQ-036 identify regulated/PII data

### dbt Project Structure

Use docs-facing Medallion zone folders even when implementation model names use
local conventions such as `stg_`, `int_`, `fct_`, `dim_`, or `mart_`. Generated
dbt docs should help business and platform reviewers scan by data-zone
responsibility, not by internal transformation step names.

```
dbt/
├── models/
│   ├── bronze/           # Source docs and raw/bridge helper views
│   ├── silver/           # P1/P3: semantic bases and conformed entities/facts
│   ├── gold/             # P4/P5: governed reads, curated marts, aggregates
│   └── gold_sensitive/   # P6: masked/filtered models
├── tests/               # data quality tests (GQ-029, GQ-042)
├── macros/
└── dbt_project.yml
```

When a source inventory or profiling artifact exists, source YAML must document
every physical column for each declared source table, including non-empty column
descriptions and raw metadata such as source type, nullability, and ordinal. If
definitions are inferred before stewardship review, mark that confidence in
metadata and keep a local validation script/check that fails when declared
source columns or dbt model columns lack descriptions.

For cross-workspace Fabric sources, dbt source `database` variables point to the
domain source bridge Lakehouse, not the central source workspace and not the
domain output Warehouse. The deployment workflow provisions the source bridge
shortcuts before running dbt and validates table reachability before any model
build.

### Data Quality Testing

> **Driven by**: GQ-029 (source quality), GQ-042 (test strategy)
>
> **Learned from**: ai-reporting PRs #49, #48, #47, #19 — insufficient referential
> integrity testing allowed cascading data quality bugs across 4 consecutive PRs.

| Test Type | Where | Purpose |
|-----------|-------|---------|
| Schema tests | All models | Not-null, unique, accepted_values, relationships |
| Source freshness | Bronze | Detect stale ingestion (warn: 36h, error: 48h) |
| Row count validation | Bronze → Silver | Source-to-target reconciliation |
| Business rules | Gold | Domain-specific assertions |
| Anomaly detection | Gold | Statistical outlier detection |
| **Referential integrity** | **All fact tables** | **Every fact foreign key must exist in its dimension — no exceptions** |
| **Regression tests** | **Per bugfix** | **Every data quality bugfix must add a targeted dbt test** |
| **License role alignment** | **dim_user** | **Platform-specific role logic validated (e.g., free-* roles excluded from billable)** |

**Regression testing rule:** When fixing a data quality issue, the PR MUST include
a new dbt test that prevents re-occurrence. Examples from ai-reporting:
- `assert_fact_referential_integrity` — all fact user_keys exist in dim_user
- `assert_no_unknown_users` — no "Unknown User" records in activity
- `assert_cursor_billable_role_alignment` — free-tier roles excluded from billing

**Dimensional history pattern:** When scoping dimensions to "current state" (e.g.,
removing departed users), ALWAYS verify no orphaned fact rows result. The safe
pattern:
1. Keep all historical rows in the dimension
2. Add an `is_active` flag column
3. Filter at the consumption/aggregation layer
4. Run referential integrity tests after every scope change

**Multi-signal validation:** For license counts, cross-validate between:
- Seat assignment API counts
- Active user counts from activity data
- Directory membership counts
If these diverge by > 5%, investigate before publishing numbers.

### Cross-Platform Metric Standardization

> **Learned from**: ai-reporting constitution Principle VI, AD-008 — misleading
> comparisons when platform-specific metrics appeared in aggregate views.

When building models that aggregate across multiple data sources or platforms:

**Rule:** Only include metrics in aggregate views that exist across ALL platforms.
Platform-specific metrics belong in platform detail views only.

| Metric Type | Aggregate View | Platform Detail View |
|-------------|---------------|---------------------|
| Active users | ✅ (all platforms report this) | ✅ |
| Active days | ✅ | ✅ |
| Licensed users | ✅ | ✅ |
| Suggestions / acceptances | ❌ (GitHub-specific) | ✅ GitHub only |
| Token usage | ❌ (varies by platform) | ✅ per platform |
| Feature-level usage | ❌ (features differ) | ✅ per platform |

**Data-driven detection:** Use window functions to identify which platforms
support which metrics at runtime, rather than hardcoding platform lists. This
handles new platforms added in the future without code changes.

**Adoption rate definition:**
- Formula: Active Users / Licensed Users
- Maturity tiers: Not Yet Active (0 days), Exploring (1-4 days/month),
  Adopting (5-14 days/month), Champion (15+ days/month)
- Based on active days per month, not binary usage

---

## DDF Phase 5: Analytics

> **Driven by**: GQ-022 (consumption tools), GQ-023 (semantic ownership),
> GQ-024 (change frequency), GQ-025 (ML use cases),
> GQ-034 (Direct Lake feasibility), GQ-037 (RLS)

### Semantic Model Strategy

> **Driven by**: GQ-022 (who consumes), GQ-023 (who maintains),
> GQ-034 (Direct Lake)

| Mode | When to Use | Governing Questions |
|------|------------|-------------------|
| **Direct Lake** | Default for Fabric. Best performance, no data copy. | GQ-034 = no blockers |
| **Import** | When Direct Lake blocked by network/governance (GQ-034) or data shaping needed | GQ-034 = blockers exist |
| **DirectQuery** | Real-time requirements, infrequent queries | GQ-003 (real-time cadence) |

### Row-Level Security

> **Driven by**: GQ-037 (RLS required?), GQ-007 (data isolation)

When GQ-037 = yes:
- Define RLS roles per dataset in the semantic model
- Map roles to Entra ID security groups
- Test with "View as Role" before deployment
- Consider Gold Sensitive zone (P6) for field-level masking alongside RLS

### Self-Service Governance

> **Driven by**: GQ-023 (semantic ownership), GQ-009 (stewards),
> GQ-018 (governance maturity)

| Maturity Level | Model |
|---------------|-------|
| Low (GQ-023 = BI team only) | Centralized: BI team owns all semantic models, Certified labels |
| Medium (GQ-023 = shared) | Federated: domain teams own Gold models, central team governs |
| High (GQ-023 = self-service) | Self-service with guardrails: Promoted labels for team models, Certified for governed |

### Custom Reporting Application (Power BI Alternative)

> **Learned from**: ai-reporting specs 2603-009, 2603-010, 2603-017, PRs #52, #51,
> #50, #57, #46, #45, #43, #53 — a React/Express app replaced Power BI when
> custom UX, embedding constraints, or licensing made Power BI impractical.

When Power BI is not the right fit (AD-005 scenarios: custom UX needs, embedding
licensing costs, cross-platform data visualization), build a custom reporting
application with these battle-tested patterns:

**Architecture:**
- TypeScript + React frontend, Express API server
- Server holds all credentials; browser never sees secrets
- Gold schema (Warehouse) accessed via server-side ODBC/SQL
- Mock mode for local development (no live Fabric dependency needed)

**Authentication (every resource must be authenticated):**
- All data fetches go through the OAuth middleware layer
- Never use bare `<a href>` navigation for data resources — it bypasses OAuth
- Use `apiGet()` / `apiDownload()` helpers that attach bearer tokens
- Read filenames from `Content-Disposition` headers, not hardcoded

**Pagination and sorting:**
- Server-side `ORDER BY` is MANDATORY for paginated tables
- Client-side sort on paginated data produces misleading results (sorts
  only the current page, not the full dataset)
- Default page size: 50+ rows (not 10)
- Type-aware sorting: detect numeric, percentage, currency columns and sort
  by value, not string representation

**Data absence handling (N/A ≠ 0):**
- When a platform doesn't provide a metric, show "N/A" — never show 0
- Use data-driven detection (window functions) to identify which platforms
  support which metrics — don't hardcode platform lists
- Exclude N/A platforms from charts (don't plot them as zero)
- Always add explanatory text: "Only includes platforms that capture [metric]
  at the user level"

**Snapshot vs. time-series metrics:**
- Separate visually: date-filtered metrics first, then snapshot metrics
- Label snapshot cards: "Current snapshot — not affected by date filter"
- Card order should match user mental model (active → licensed → cost)

**CSV export:**
- Every data table must support CSV export
- Export returns the FULL dataset matching active filters (bypass pagination)
- Use RFC 4180 CSV formatting with proper escaping
- Human-readable column headers (not internal field names)
- Server-side generation with `Content-Disposition` header

**Filter consistency:**
- Same filter set (date range, platform, department) available on all pages
- Department filter scopes all visuals except reference tables (e.g., license
  tier definitions)
- When a platform lacks a dimension (e.g., Claude has no per-user licensing),
  hide that platform from user-level tables — don't show misleading data

**Chart readability:**
- Sort aggregate bar charts by value descending (not alphabetically)
- Rotate X-axis labels when > 5 categories
- Move legends above charts (not right-side, which compresses chart width)
- Increase chart height for departments with many entries
- Add helper text explaining caveats (e.g., "M365 data has ~72h latency")

### Performance & Response Caching

> **Learned from**: ai-reporting spec 2603-017, PR #41 — page loads took 15 seconds
> due to per-request connection pool creation and token acquisition. After caching,
> repeat loads dropped to < 2 seconds.

For any reporting application querying a data warehouse:

**Three-layer caching architecture:**

| Layer | What | TTL | Eviction |
|-------|------|-----|----------|
| Connection pool | Persistent ODBC pool with proactive token rotation | Rotate at 50 min (tokens expire 60-75 min) | Pool recycling |
| Response cache | In-memory LRU cache for query results | Meta: 60 min, Reports: 10 min | LRU with 200-entry cap |
| HTTP cache | Browser-side caching via headers | `Cache-Control`, `Vary` by auth | Standard HTTP |

**Request coalescing:** When multiple users request the same uncached report
simultaneously, only one warehouse query fires. Other requests await the result.
This prevents duplicate queries during cache miss storms.

**Proactive token rotation:** Don't wait for token expiry errors. Rotate the
connection pool's access token at 80% of TTL (e.g., 50 min for 60-min tokens).
Reactive rotation causes request failures during the refresh window.

---

## Authentication & Authorization

> **Learned from**: ai-reporting PRs #20, #24, #27, specs 2603-012 — three rounds
> of auth hardening were needed to get Entra SSO, OBO delegation, and multi-service
> auth controls right.

### Entra SSO + On-Behalf-Of (OBO) Pattern

For reporting applications that need to query Fabric Warehouse with the user's
delegated identity (not a shared service principal):

```
Browser → MSAL.js (Entra sign-in + ssoSilent)
       → Bearer token to Express API
       → Express validates token + checks group membership
       → OBO exchange: user token → Fabric-scoped token
       → Query Fabric Warehouse with user's delegated identity
```

**Key decisions:**
- Browser gets a token for the API scope (not Fabric directly)
- Server exchanges that token via OBO for a Fabric-scoped token
- User's identity flows end-to-end — audit trail preserved
- Group-based access control (Entra security group for authorized viewers)

### Auth Defaults & Fallback Chain

**Rule: Opt-in auth, never opt-out.**
- Don't default authentication to the CI/CD service principal — it breaks local dev
- Use explicit environment variables to enable auth per service
  (e.g., `AZURE_WEB_AUTH_REPORTING_APP=true`, `AZURE_WEB_AUTH_DOCS=true`)
- Each service gets independent auth controls — don't couple them

**Delegated → Service Principal fallback:**
- Primary: OBO delegated access (user's identity)
- Fallback: Service principal with `DefaultAzureCredential` when OBO unavailable
  (e.g., CI pipelines, background jobs)
- Document which path is active and why

### Auth Configuration

**Transient config generation:**
- Workspace IDs, connection strings, and parameter files should be generated
  during deploy — never checked into source control
- CI and local flows use the same config generation logic (e.g., `parameter.yml`
  generator that reads workspace IDs at deploy time)

**Public auth config endpoint:**
- Provide a non-authenticated `/api/auth/config` endpoint that returns:
  tenant ID, SPA client ID, API scope
- No secrets in this response — just enough for MSAL.js bootstrap

**Permission diagnostics:**
- When identity lacks permissions, fail fast with actionable messages
- Include: what permission is missing, which identity needs it, how to grant it
- Common failure: Fabric connection access not granted to the app's service principal

---

## Deployment & CI/CD Operations

> **Learned from**: ai-reporting PRs #27, #24, #55, specs 2603-007, 2603-013 —
> deployment failures from config misalignment between CI and local, unsafe defaults,
> and missing safety gates.

### Fabric Deployment (fabric-cicd)

**Safety gates:**
- `--recreate` (destructive) blocked without `--only` flag — prevents accidental
  Lakehouse data loss
- `--only` scopes deployment: notebooks, pipeline, lakehouse, warehouse
- Dangerous operations require explicit `--force` flag
- Item-level deployment (deploy notebooks without touching Lakehouse)
- Source-sharing manifests declare every central/legacy source shortcut, and
  CI validates source, target, environment, sensitivity, owner, and approval
  intent.
- Full apply creates/resolves schema-enabled domain source bridge Lakehouses,
  creates schema-scoped OneLake shortcuts such as `Tables/dbo` with
  `CreateOrOverwrite`, and runs a source health gate before dbt builds.
- If Fabric returns `FeatureNotAvailable` for automated Lakehouse creation,
  pre-create the bridge as a documented bootstrap exception, bind its item ID,
  and keep shortcut provisioning and source health validation in automation.

**Workspace layout:**
- Two shared workspaces: dev and prod (e.g., `project-v2-dev`, `project-v2-prod`)
- Optional: personal developer workspaces for isolation during development
- Promotion: dev → prod via CI pipeline (never manual)

### GitHub Actions as Fabric Control Plane

> **Learned from**: AIS Data SPEC-2604-001.2 — Fabric deployment became safer and
> more autonomous when GitHub Actions validated source-controlled policy before
> any write, then applied only through environment-gated workflow dispatch.

Use one Fabric deployment workflow with two explicit modes:

| Mode | Trigger | Behavior |
|------|---------|----------|
| PR validation | `pull_request` path filters for Fabric, dbt, scripts, and deployment specs | Parse YAML, validate spec frontmatter, validate security/deployment manifests, generate a temporary dbt profile, run `dbt deps`, and run `dbt parse`; no Fabric write permission required |
| Apply | Manual `workflow_dispatch` with target environment, `dry_run`, and dbt selector inputs | Bind to the GitHub environment, authenticate the deployment identity, provision/resolve Fabric targets, deploy supported workspace items, run source health checks, and build the selected dbt graph |

Apply defaults to `dry_run: true`. Set `dry_run: false` only after the target
GitHub environment, Fabric tenant settings, capacity binding, source sharing,
and dbt output bindings are configured.

### Deployment Autonomy Rules

- Treat GitHub Actions as the control plane. Humans approve qa/prod through
  GitHub environments; they do not apply routine Fabric UI changes.
- Keep external setup in source-controlled non-secret registries:
  deployment bootstrap, deployment policy, environment bindings, source-sharing
  manifests, and manual exception records.
- Validate those registries in CI. Missing environment fields, unsafe manual
  change policy, unknown source-sharing targets, or incomplete exception records
  should fail before apply.
- Prefer GitHub OIDC for the deployment identity. Allow a service-principal
  secret fallback only as a temporary bootstrap path and make the accepted auth
  modes explicit in repo configuration.
- Do not commit `profiles.yml`, tokens, tenant credentials, or generated
  connection files. Generate temporary dbt profiles in the runner with strict
  file permissions.
- Use Fabric CLI or Fabric REST for workspace, Warehouse, Lakehouse, shortcut,
  and role-assignment gaps that `fabric-cicd` does not own. Run `fabric-cicd`
  after the target workspace exists.
- Make apply scripts idempotent: resolve existing item IDs first, validate UUID
  inputs, create only when missing, and emit IDs back to GitHub Actions outputs.
- Expect Fabric eventual consistency. Poll for created workspace/Warehouse/
  Lakehouse IDs, retry source bridge health checks, and fail with diagnostics
  that tell the operator which binding or permission is missing.
- Write job summaries for target environment, source ref, actor, workspace ID,
  Warehouse ID, source bridge status, dbt selector, and result so an agent or
  maintainer can continue without reconstructing the run from logs.
- Record every break-glass or unsupported-API manual action with environment,
  Fabric item, approver, timestamp, reason, and follow-up automation task.

### GitHub Actions Workflow Suite

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | PR push | Markdown lint, dbt parse, docs validation |
| `fabric-deploy.yml` | PR validation / manual dispatch | Fabric policy validation, environment-gated apply, Fabric CLI provisioning, source bridge checks, fabric-cicd item deployment, dbt build |
| `dbt.yml` | Manual / called | `dbt seed → run → test` + docs generation |
| `daily-elt.yml` | Cron (daily) | Fabric pipeline → dbt run → dbt docs refresh |
| `deploy-web-infra.yml` | Manual | Bicep infrastructure for web apps |
| `deploy-reporting-app.yml` | Push to main | React/Express app deployment |

### Daily ELT Orchestration Pattern

```
Fabric Data Pipeline (extraction notebooks — parallel)
  → Web Activity triggers GitHub Actions dbt workflow
    → dbt seed → dbt run → dbt test
      → dbt docs generate + deploy
```

- Extraction notebooks run in parallel within Fabric Data Pipeline
- dbt is triggered externally (GitHub Actions) for version control and test gating
- dbt test failures block downstream publication
- Target: < 20 min total pipeline duration

### Multi-Path CI Validation

Every PR should validate the required deployment paths:
1. **Bicep build** — infrastructure templates compile
2. **Config generation** — parameter files generate without errors
3. **dbt parse** — all models, tests, and sources are valid
4. **Fabric policy validation** — deployment/security/source-sharing manifests
   prove the workflow owns routine changes and manual exceptions are temporary

### Environment Alignment

- dev/qa/prod environments mirror each other structurally
- Vary only what must differ: workspace ID, auth settings, Key Vault URI
- Use `parameter.yml` templates with environment-specific substitution
- Test on actual target environment (e.g., Windows App Service), not just local
- Separate source bindings from output bindings. Source variables identify the
  approved source bridge; dbt output settings identify the domain Warehouse.

---

## Observability & Alerting

> **Learned from**: ai-reporting spec 2604-003 — alerting was absent for the first
> month of operation, meaning pipeline failures went unnoticed until users reported
> stale data.

### Phased Alerting Rollout

Don't try to alert on everything at once. Roll out in phases:

| Phase | Priority | Alerts |
|-------|----------|--------|
| P1 | Critical | Daily ELT pipeline failure, Fabric capacity paused, App down (5xx) |
| P2 | High | dbt test failures, Bronze source staleness, Secret expiry, OBO auth failures |
| P3 | Medium | Fabric capacity overload (CU > 80%), App response time > 5s, Pipeline duration anomaly (> 2x baseline) |
| P4 | Low | dbt docs site availability, Disabled workflows, Stale dbt docs |

### Key Thresholds

| Metric | Threshold | Channel |
|--------|-----------|---------|
| 5xx error rate | > 5 in 5 minutes | Teams + Email |
| Response time | > 5s for 10 minutes | Teams |
| Pipeline duration | > 2x historical baseline | Email |
| Source freshness | warn: 36h, error: 48h | Teams |
| Secret expiry | < 30 days remaining | Email |
| Fabric CU utilization | > 80% sustained | Teams |

### Notification Channels

- **Microsoft Teams** — real-time alerts for pipeline and app failures
- **Email** — digest alerts for capacity, cost, and non-urgent issues
- Alerts should include: what failed, when, impact, and link to logs/runbook

---

## Common Spec Decomposition

| Area | Spec Scope | Effort Range | Frequency |
|------|-----------|--------------|-----------|
| Fabric Capacity & Workspace Setup | Capacity provisioning, domain structure, workspace layout, RBAC | S-M | Always |
| Network & Security Foundation | Private endpoints, VNet gateways, Conditional Access, BYOSA | M-L | Often |
| Ingestion Pipeline per Source Group | Mirroring / Shortcuts / Pipelines per source cluster | M | Always (per group) |
| Bronze Zone & Data Landing | Lakehouse setup, ingestion landing, raw retention policy | S-M | Always |
| **Identity Resolution** | **Cross-platform identity correlation, SAML mapping, directory integration** | **M** | **Always** |
| Silver Transformation Layer | dbt staging + conformed models (P1, P3) | M-L | Always |
| SCD Type 2 Implementation | dbt SCD models for entities with history (P2) | S-M | Sometimes |
| Gold Curated Marts | dbt consumption models per domain (P4) | M-L | Always |
| Gold Sensitive / Masking | P6 models, RLS, sensitivity labels | S-M | Sometimes |
| Semantic Models & Power BI | Direct Lake semantic models, endorsement, RLS | M | Always |
| **Custom Reporting Application** | **React/Express app with auth, caching, export** | **M-L** | **Sometimes** |
| dbt CI/CD Pipeline | GitHub Actions, trunk-based promotion, test gates | S-M | Always |
| Data Quality Framework | dbt tests, freshness monitoring, alerting | S-M | Always |
| **Alerting & Telemetry** | **Pipeline alerts, app monitoring, capacity thresholds, Teams notifications** | **S-M** | **Always** |
| **Auth & SSO Hardening** | **Entra SSO, OBO flow, per-service auth controls, permission diagnostics** | **S-M** | **Often** |
| **Response Caching & Performance** | **Connection pooling, response cache, HTTP cache, request coalescing** | **S** | **Often** |
| Capacity Monitoring & Cost Management | CU monitoring, autoscale config, cost attribution dashboards | S | Often |

---

## Estimation Patterns

### Effort Drivers

- **Number of data sources** — each source has unique schema, API patterns, and quality issues
- **Number of domains** — each domain multiplies workspace, capacity, and governance setup
- **Data volume and latency** — near-real-time (Mirroring) adds complexity over batch
- **Network complexity** — private endpoints, VNet gateways add 1.3-1.5x to infrastructure specs
- **dbt adoption** — if team is new to dbt (GQ-020), add training and ramp-up time
- **Compliance requirements** — GDPR, HIPAA add Gold Sensitive zone and audit work
- **Analytics maturity** — low maturity (GQ-022) requires more semantic model and training effort
- **Identity resolution complexity** — cross-org, multi-platform, SAML mapping add 1.2-1.4x
- **Custom reporting app** — React/Express alternative to Power BI adds M-L spec effort
- **Auth hardening** — Entra SSO + OBO + per-service controls typically requires 2-3 iteration sprints

### ROM Ranges by Complexity

| Complexity | Typical Range | Key Indicators |
|-----------|--------------|----------------|
| Simple | 300-600 hours | 2-5 sources, single domain, batch daily, basic Power BI, identity-boundary network |
| Moderate | 600-1200 hours | 5-15 sources, 2-3 domains, mix of Mirroring/pipelines, dbt CI/CD, RLS, private endpoints |
| Complex | 1200-2500 hours | 15+ sources, 4+ domains, near-real-time, Gold Sensitive, multi-region DR, advanced analytics |
| **Complex + Custom App** | **1500-3000 hours** | **Above + custom reporting app, Entra SSO/OBO, multi-platform identity resolution, alerting** |

### Common Multipliers

- **Private endpoint networking** — 1.3-1.5x for infrastructure specs
- **Legacy migration (parallel run)** — 1.3-1.5x for running old and new in parallel
- **dbt team ramp-up** — 1.2-1.4x if team is new to dbt
- **Data quality remediation** — 1.2-1.5x if source data has known issues (GQ-029)
- **Compliance/audit (GDPR, HIPAA)** — 1.2-1.4x for Gold Sensitive and audit trail
- **Cross-platform identity resolution** — 1.2-1.4x for SAML mapping, cross-org APIs
- **Auth hardening iterations** — 1.2-1.3x for SSO + OBO + fallback chain
- **Reporting app quality remediation** — 1.1-1.3x for data absence handling, metric semantics, UX polish

---

## Risk Patterns

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | Source data quality worse than expected | High | High | Data profiling sprint early (GQ-029). Build dbt test gates. Document issues as findings. |
| 2 | Fabric capacity costs exceed expectations | Medium | High | Capacity planning based on GQ-030. CU monitoring from day one. Autoscale with caps. |
| 3 | Direct Lake mode blocked by constraints | Medium | Medium | Validate GQ-034 early. Have Import mode fallback plan. |
| 4 | dbt adoption slower than planned | Medium | Medium | Assess GQ-020 honestly. Pair programming, training sprints. Start with P1 staging models. |
| 5 | Network/private endpoint complexity delays | Medium | High | Clarify GQ-011–GQ-014 in pre-sales. Involve client network team early. |
| 6 | Scope creep via "one more source" or "one more dashboard" | High | Medium | Define source list in SOW. New sources are change requests. |
| 7 | Governance overhead without stewardship | Medium | High | Identify stewards per domain (GQ-009). Define endorsement process in kickoff. |
| 8 | Trunk-based development rejected by client | Low | Medium | Validate GQ-032 in setup. Have feature-branch fallback with promotion gates. |
| 9 | **API schema drift breaks Bronze writes** | **High** | **High** | **Pre-flight schema checks on every write. ALTER TABLE for new columns. Never assume API contracts are stable.** |
| 10 | **Cross-org licensing gaps from single-org APIs** | **Medium** | **High** | **Use enterprise-level APIs. Back-fill with activity data. Cross-validate seat counts vs. active user counts.** |
| 11 | **Fabric runtime API version inconsistency** | **Medium** | **Medium** | **Multi-tier fallback for lakehouse IDs. Test on multiple Fabric versions. Fail fast with actionable errors.** |
| 12 | **Reporting app performance degradation** | **High** | **Medium** | **Implement 3-layer caching (connection pool, response cache, HTTP headers) from day one. Proactive token rotation.** |
| 13 | **Identity resolution cascading failures** | **High** | **High** | **Enforce dim_user inner-join rule on all activity. Add referential integrity tests. Case-insensitive joins mandatory.** |
| 14 | **Auth hardening requires multiple iterations** | **Medium** | **Medium** | **Plan 2-3 sprints for auth. Start with basic SSO, iterate to OBO + per-service controls. Test on actual App Service, not just local.** |

---

## Tech Stack Recommendations

| Layer | Default | Alternatives | Notes |
|-------|---------|-------------|-------|
| Platform | Microsoft Fabric | — | Non-negotiable for this playbook |
| Storage | OneLake (Delta Lake) | BYOSA (ADLS Gen2) | BYOSA when GQ-014 requires private network |
| Ingestion | Mirroring + Data Pipelines | Notebooks, Dataflow Gen2 | Mirroring for supported CDC sources; Pipelines for batch/API |
| Transformation | dbt (dbt-fabric adapter) | Notebooks (PySpark) | dbt is DDF standard; Notebooks for complex/ML transforms |
| Orchestration | Fabric Data Pipelines | — | Native Fabric orchestration; triggers GitHub Actions for dbt |
| BI | Power BI (Direct Lake) | **Custom React/Express app** | Direct Lake default; **custom app when embedding costs, cross-platform UX, or custom auth needed** |
| Data Quality | dbt tests + Fabric monitoring | Great Expectations | dbt tests for model-level; Fabric monitoring for pipeline-level |
| CI/CD | GitHub Actions | Azure DevOps Pipelines | GitHub Actions preferred; ADO if client mandate (GQ-016) |
| Version Control | GitHub | Azure DevOps Repos | GitHub preferred; ADO if client mandate (GQ-016) |
| IaC | Fabric REST API + Bicep | Terraform (azurerm) | Bicep for Azure infra; Fabric API for workspace/capacity |
| **Deployment** | **fabric-cicd (Python)** | **Manual Fabric UI** | **fabric-cicd for repeatable deployments with safety gates** |
| **Auth** | **Entra SSO + OBO** | **Easy Auth, Service Principal** | **OBO for delegated Fabric access; SP fallback for CI/background** |
| **Caching** | **In-memory LRU + HTTP headers** | **Redis** | **In-memory sufficient for single-instance apps; Redis for multi-instance** |
| **Alerting** | **GitHub Actions + Teams webhook** | **Azure Monitor, PagerDuty** | **Start with Actions-based; move to Azure Monitor at scale** |

---

## Quality Gates

| Gate | Category | Criteria | Severity |
|------|----------|----------|----------|
| Data Freshness | Reliability | All critical pipelines complete within SLA | MUST |
| dbt Test Pass | Quality | All dbt tests pass; zero critical failures | MUST |
| Row Count Validation | Quality | Source-to-target row counts match within tolerance (0.1%) | MUST |
| Pipeline Idempotency | Reliability | Re-running a pipeline produces the same result | MUST |
| Endorsement Labels | Governance | All production semantic models are Certified | MUST |
| **Referential Integrity** | **Quality** | **All fact foreign keys exist in their dimension tables** | **MUST** |
| **Identity Resolution** | **Quality** | **Zero unmatched licensed users in dim_user** | **MUST** |
| **Regression Tests** | **Quality** | **Every data quality bugfix includes a new dbt test** | **MUST** |
| Capacity Utilization | Cost | CU utilization stays below 80% sustained | SHOULD |
| Data Lineage | Governance | All Gold models have documented lineage from source | SHOULD |
| Query Performance | Performance | P95 dashboard queries complete in < 10s | SHOULD |
| **Response Time** | **Performance** | **Repeat page loads < 2s with caching enabled** | **SHOULD** |
| RLS Coverage | Security | All datasets with PII have RLS configured (if GQ-037) | MUST (conditional) |
| Sensitivity Labels | Compliance | All regulated data has Microsoft Purview labels | SHOULD |
| **Unresolved Identity Rate** | **Quality** | **< 5% unresolvable identities (external collaborators expected)** | **SHOULD** |
| **Alerting Coverage** | **Reliability** | **P1 alerts (pipeline failure, app down) active before go-live** | **MUST** |

---

## Deliverable Checklist

### Pre-Sales Phase

- [ ] Source system inventory with Mirroring/Shortcut eligibility
- [ ] Domain mapping (org structure → Fabric domains)
- [ ] Capacity sizing estimate
- [ ] Network assessment (private endpoints vs. Conditional Access)
- [ ] ROM with per-domain effort breakdown
- [ ] Governing questions tracker initialized

### Kickoff Phase

- [ ] Fabric capacity provisioned
- [ ] Workspace layout created (Bronze/Silver/Gold per domain)
- [ ] Network infrastructure deployed (gateways, private endpoints)
- [ ] dbt project scaffolded with CI/CD pipeline
- [ ] Data profiling results for all sources
- [ ] Governing questions (Setup phase) answered or deferred

### Per-Spec Phase

- [ ] Working pipeline with dbt tests passing
- [ ] Source-to-target validation results
- [ ] Semantic model with endorsement label
- [ ] Documentation (lineage, schema, SLA)
- [ ] Referential integrity tests passing (all fact-to-dim joins)
- [ ] Identity resolution tests passing (zero unmatched licensed users)
- [ ] Regression tests added for any data quality fixes

### Closeout Phase

- [ ] All pipelines in production with monitoring
- [ ] All semantic models Certified
- [ ] Capacity monitoring dashboard operational
- [ ] Operations runbook (failure handling, reprocessing, scaling)
- [ ] Training for data team (dbt, Fabric admin, Power BI governance)
- [ ] Governing questions tracker archived with all answers
- [ ] P1 and P2 alerting active (pipeline failures, dbt test failures, app health)
- [ ] Response caching validated (repeat page loads < 2s)
- [ ] Auth hardening complete (SSO, OBO, per-service controls)
- [ ] CSV export functional on all data tables

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | What to Do Instead |
|-------------|-------------|-------------------|
| Building without data profiling | Discover quality issues mid-development, causing rework | Profile every source in the first sprint (GQ-029). Document quality issues early. |
| Skipping domain organization | Monolithic workspace becomes ungovernable as teams grow | Map domains from org structure (GQ-005) before building workspaces. |
| Transforming in Bronze | Raw zone loses its "source of truth" property | All transforms go in dbt (Silver/Gold). Bronze stays raw. |
| SCD Type 2 everywhere | Massive storage and complexity for entities that rarely change | Only apply P2 where GQ-038 AND GQ-039 both say yes. |
| Ignoring capacity costs | Surprise bills when CU usage spikes | Monitor from day one. Set autoscale caps. Attribute costs per domain (GQ-006). |
| Direct Lake without validation | Deployment fails due to network or model constraints | Validate GQ-034 in setup phase. Have Import fallback. |
| Skipping endorsement labels | Users can't distinguish governed from exploratory data | Set up endorsement process in kickoff. Stewards own Certified labels (GQ-009). |
| SAS URLs to browser | Security risk; bypasses access controls | All blob access via API proxy. Never expose SAS tokens to client-side. |
| Designing for today's volume | Platform hits scaling walls within months | Design for 10x current volume (GQ-030). Use partitioning, incremental loads. |
| One giant monolithic dbt project | Hard to test, slow CI, team conflicts | Modular dbt projects per domain. Independent testing and deployment. |
| Fixture Warehouse as shared source | Hides real permissions, freshness, lineage, and OneLake failures | Use source-owned data plus domain source bridge Lakehouse shortcuts. Keep fixtures local/offline only. |
| Direct Fabric UI deployment as normal operations | Bypasses review, source control, summaries, and policy validation | Route routine Fabric/dbt changes through GitHub Actions; record temporary manual exceptions with follow-up automation work. |
| Running dbt before source bridge health checks | Fails late with confusing SQL or relation errors | Provision shortcuts first, run source table probes with retries, then run dbt build. |
| **Relying on single API endpoint for licensing** | **Cross-org users invisible; license counts underreported** | **Combine seat assignment + activity + directory. Cross-validate counts.** |
| **Case-sensitive identity joins** | **Silently drops matches; no error, just wrong numbers** | **All identity joins use LOWER() on both sides. All searches case-insensitive.** |
| **Client-side sort on paginated tables** | **Sorts only current page; misleading results** | **Server-side ORDER BY for all paginated tables. Client sort only for non-paginated.** |
| **Bare navigation for authenticated resources** | **Bypasses OAuth middleware; requests fail or leak tokens** | **All data fetches through apiGet()/apiDownload() helpers that attach bearer tokens.** |
| **Hardcoded platform rules** | **Breaks when new platform added; maintenance burden** | **Data-driven detection (window functions). Platforms self-describe their metric availability.** |
| **Filtering dimensions instead of flagging** | **Breaks referential integrity on historical fact rows** | **Keep all history in dim; add is_active flag; filter at consumption layer.** |
| **Treating data absence as zero** | **Misleads users; platforms without a metric show as "no usage"** | **Show N/A for unavailable data. Explain why. Exclude from charts.** |
| **Defaulting auth to CI/CD service principal** | **Breaks local dev; accidental privilege escalation** | **Opt-in auth. Explicit env vars to enable. Independent controls per service.** |
| **Skipping response caching** | **15+ second page loads; users abandon the tool** | **3-layer caching from day one: connection pool, response cache, HTTP headers.** |
