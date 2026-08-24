# Skills

This directory contains [Agent Skills](https://agentskills.io) — portable, version-controlled folders that give AI agents specialized capabilities. Each skill bundles instructions, scripts, reference materials, and assets that an agent loads on demand to perform a specific task.

## Format

Skills follow the open [Agent Skills specification](https://agentskills.io/specification):

```text
skill-name/
├── SKILL.md          # Required: metadata (name, description) + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, schemas, resources
└── ...               # Any additional files
```

Agents discover skills by reading the `name` and `description` from each `SKILL.md` frontmatter at startup. When a task matches, the agent loads the full instructions and executes the skill's workflow — scripts, file reads, and all.

## Available Skills

| Skill | Description |
|-------|-------------|
| [`ais-azure-estimates`](ais-azure-estimates/SKILL.md) | Develop proposal-grade Azure cloud consumption estimates from structured JSON inputs with traceable pricing evidence, manual overrides, caveats, and Markdown/CSV/XLSX/JSON outputs. |
| [`ais-branding-docx`](ais-branding-docx/SKILL.md) | Generate AIS-branded Word documents (.docx) from structured JSON input. Supports 13 content types including TOC, tables, code blocks, and nested lists. |
| [`ais-sow-docx`](ais-sow-docx/SKILL.md) | Generate and validate versioned AIS SOW Word documents while preserving approved legal regions and enforcing placeholder-only commercial fields. |
| [`ais-branding-pptx`](ais-branding-pptx/SKILL.md) | *Implicit* — Always active when creating presentations or documents. Enforces AIS brand identity: color palette, typography, logo placement, layout system, and premium design standards. |
| [`ais-proposal-docx`](ais-proposal-docx/SKILL.md) | Generate AIS-branded proposal Word documents (.docx) from structured JSON input. Fills a branded template preserving exact formatting and built-in styles. |
| [`ais-proposal-redline-docx`](ais-proposal-redline-docx/SKILL.md) | Modify existing proposal Word drafts by merging red-draft content into pink DOCX forms while preserving formatting, reviewer comments, tracked changes, and comment-response traceability. |
| [`ais-spec-upgrade`](ais-spec-upgrade/SKILL.md) | Upgrade copied AIS Spec framework files in an existing project repo by comparing versions, reading the changelog, detecting drift, prompting for a decision, and applying safe updates. |
| [`ais-infra-azure`](ais-infra-azure/SKILL.md) | Enforce Azure infrastructure best practices for all IaC work. Mandates AVM as the default module source, CAF naming/tagging, and WAF alignment. Supports both Bicep and Terraform. Load when a spec touches infrastructure or cloud provisioning. |
| [`video-context-parser`](video-context-parser/SKILL.md) | Extract visual context from video or screen-share recordings with paired transcripts and use agent vision to merge screen observations into context packages. |

## Creating a New Skill

1. Create a directory under `Skills/` matching the skill name (lowercase, hyphens only).
2. Add a `SKILL.md` with required frontmatter (`name`, `description`) and instructions.
3. Bundle any scripts, references, or assets the skill needs.
4. Create and review `Skills/.ais-spec/validation/skillspector-baselines/<skill>.yaml`
   with `skillspector baseline Skills/<skill> --no-llm`. Every
   `Skills/<skill>/SKILL.md` requires a matching baseline; CI rejects missing
   or extra policy files.
5. Test with a compatible agent (e.g., Claude Code, GitHub Copilot, Cursor).
6. Update the table above.

See the [Agent Skills quickstart](https://agentskills.io/skill-creation/quickstart) and [best practices](https://agentskills.io/skill-creation/best-practices) for guidance.

## Validation Test Placement

Portable optional-CI regression tests for Skills belong in
`Skills/.ais-spec/validation/tests/`; framework-core regression tests belong in
`.specify/validation/tests/`. Generic optional CI runs those two collections
explicitly and never recursively discovers `Skills/*/tests/`.

SkillSpector scans every `Skills/<skill>/SKILL.md` and requires a reviewed
baseline at `Skills/.ais-spec/validation/skillspector-baselines/<skill>.yaml`.
Use the scanner-generated baseline only after reviewing its suppressed findings;
an empty baseline is valid when the scan has no findings to suppress.

Place a skill-local unit suite beside its skill when it has a skill-specific
runner or dependencies. Run it using the command documented by that skill
instead of adding it to generic optional CI.
