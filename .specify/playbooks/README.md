# Playbooks

Reusable domain knowledge for different engagement types. Playbooks capture patterns, risks, estimation heuristics, engagement-shape guidance, and typical spec decompositions that inform pre-sales proposals and delivery planning.

## What Playbooks Do

- **Pre-sales**: Inform discovery questions, spec decomposition, technology recommendations, ROM estimation, staffing inputs, and cost drivers during `/ais.presales.synthesize` and `/ais.presales.propose`
- **Setup**: Guide architecture patterns and spec decomposition during `/ais.setup.plan` and `/ais.setup.architecture`
- **Delivery**: Provide domain-specific risk patterns and quality gates that seed the constitution

## Available Playbooks

| Playbook | Engagement Type | When to Use |
|----------|----------------|-------------|
| [Agent & AI Builds](agent-ai-builds.md) | AI agents, copilots, RAG systems, ML pipelines | Client wants AI/ML capabilities |
| [Copilot Readiness](copilot-readiness.md) | M365 Copilot readiness, data security, Purview/DLP, AI governance | Client is rolling out Microsoft 365 Copilot and needs security + governance foundation |
| [Data Platforms](data-platforms.md) | Data warehouses, lakes, pipelines, analytics | Client needs data infrastructure |
| [Custom Applications](custom-applications.md) | Web apps, mobile apps, SaaS products | Client wants a bespoke application |
| [.NET Migration & Upgrade](dotnet-migration.md) | .NET version upgrades and .NET Framework → modern .NET migration across the full AIS lifecycle (pre-sales → setup → delivery), with optional application-architecture and UI modernization tracks, and tool-agnostic agent-driven modernization (Copilot/Claude Code/Cursor/Codex) | Client is upgrading .NET apps, modernizing their architecture/UI, or migrating them to Azure |
| [Integration Projects](integration-projects.md) | System integrations, API gateways, ETL | Client connecting existing systems |
| [Modernization](modernization.md) | Legacy migration, re-platforming, re-architecture | Client modernizing existing systems |
| [Ops Continuity](ops-continuity.md) | Post-delivery support, operations, enhancements, advisory reachback | Client needs reusable Base/Standard/Premium support options or an ops handoff playbook |

## Using a Playbook

Playbooks are automatically consumed by pre-sales and setup commands when relevant. You can also reference them explicitly:

```
/ais.presales.synthesize Use the agent-ai-builds playbook
/ais.setup.plan Reference data-platforms playbook for architecture patterns
```

## Creating a New Playbook

1. Copy `_playbook-template.md` to `{engagement-type}.md`
2. Fill in all sections with domain-specific knowledge
3. Add the playbook to the table above
4. Test by running a pre-sales flow referencing the new playbook

## Conventions

- **Underscore prefix** (`_playbook-template.md`) marks the template — not an active playbook
- Playbooks are **advisory, not prescriptive** — they inform recommendations, not mandate them
- Mermaid diagrams are encouraged for architecture patterns
- Effort estimates use T-shirt sizing (S/M/L/XL) consistent with spec effort fields
- Staffing guidance and cost drivers are inputs to green-sheet/business review, not approved pricing
