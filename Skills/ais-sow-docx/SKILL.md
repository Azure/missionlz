---
name: ais-sow-docx
description: Generate and validate versioned AIS Statement of Work Word documents from structured SOW JSON while preserving approved legal template regions, Word structures, and placeholder-only commercial fields. Use for AIS client FFP, Microsoft Solution Center FFP, AIS T&M, staff-augmentation retainer, or ECIF-generic original SOW DOCX creation, validation, template-version onboarding, or client-readiness review. Do not use for proposals, generic branded documents, or change orders.
---

# AIS SOW DOCX

Generate client-facing SOW Word files from immutable approved templates while
keeping `03-sow.md` canonical for delivery planning.

## Hard Boundaries

- Never insert numeric prices, rates, fees, totals, investment, extended
  amounts, or ECIF hours into a generated SOW. Use exactly
  `TBD - Commercial Review` in every commercial value cell.
- Do not rewrite fixed legal clauses. The generator modifies only declared
  content controls, exact cover placeholders, the approved narrative region,
  field-refresh settings, and template identity metadata.
- Microsoft Solution Center is an AIS delivery organization, not a funding
  model.
- Do not silently substitute a template when classification is unsupported or
  ambiguous.
- Do not generate POP-only or POP-plus-price change orders with this skill.
- Structural validity is not client readiness. Every page must be rendered and
  reviewed, and a qualified human must complete the content review, before
  `client_ready` can be true.
- Never place AIS-only commands, repository/spec paths, source IDs, QA/QC
  labels, green-sheet terminology, drafting notes, model/agent instructions, or
  review evidence in client-visible narrative.

## Inputs

Use a structured JSON file that conforms to
`assets/sow-content.schema.json`. Start from the closest synthetic file in
`examples/`, then replace all invented content with source-traced SOW content.
Every in-scope item, out-of-scope item, deliverable, milestone,
responsibility, and material assumption needs a unique `source_id`.

Read [references/template-profiles.md](references/template-profiles.md) before
selecting a profile or changing template versions.

Read [references/writing-guidance.md](references/writing-guidance.md) in full
before drafting, revising, or reviewing client-visible content. Apply it to the
structured JSON values that render into the DOCX. The guide does not authorize
changes to fixed legal clauses.

## Workflow

### 1. Classify

Classify `agreement_family`, `contract_form`, `delivery_organization`,
`delivery_pattern`, and `document_type` independently. Confirm the combination
matches exactly one manifest profile. If it does not, stop DOCX generation and
report the unresolved decision; preserve the Markdown SOW.

### 2. Draft and Review Client Content

Keep AIS-only planning and traceability controls in `03-sow.md`, bookmarks, or
evidence. Move only client-visible narrative into the structured JSON. Before
generation, apply the writing guide to audience, posture, grammar, defined
parties, commitments, outcomes, deliverables, acceptance, dependencies, risks,
change control, terminology, and the client-content boundary.

The generator screens a narrow set of high-confidence prohibited patterns. A
passing screen does not prove tone, grammar, factual accuracy, contractual
sufficiency, legal approval, or commercial approval.

### 3. Generate

Run from the skill or repository root with Python 3.12 and `lxml` 5.x:

```powershell
uv run --with lxml==5.* python Skills/ais-sow-docx/scripts/generate.py `
  --input specs/.presales/03-sow.json `
  --output specs/.presales/03-sow.docx `
  --evidence specs/.presales/03-sow.evidence.json
```

Generation verifies the source asset digest, rejects commercial numbers,
copies the selected DOCX, edits approved OOXML regions, validates the output,
and atomically publishes only a structurally valid file.

### 4. Inspect Structural Evidence

Do not bypass the generator's validation. Confirm the evidence reports all of
these checks as passed:

- required package parts and relationships;
- undeclared package parts preserved;
- fixed administrative region preserved;
- document protection preserved;
- template instructions and sample placeholders removed;
- commercial placeholders only;
- all source IDs traceable;
- high-confidence client-language policy screening passed;
- visible and machine-readable profile/version metadata; and
- Word fields marked to refresh.

### 5. Render Every Page

Use the installed document-rendering workflow to render the DOCX to PDF and
page PNGs. Inspect every page for clipping, overlap, broken or split tables,
typography, stale fields, headers, footers, page breaks, and signature-area
usability. Fix the source JSON or generator and repeat when defects exist.

If no compatible renderer is installed, stop the client-document gate and
report it as not ready. Do not claim visual QA passed based on XML inspection.

### 6. Complete the Human Content Review

Review the generated DOCX against the **Pre-Delivery Content Review** checklist
in `references/writing-guidance.md`. Review the actual client-visible document,
not only the JSON or Markdown source. Correct the source and regenerate when the
review fails.

### 7. Record Both Reviews

After page review, rerun validation with the real renderer name, page count,
result, and concise notes:

```powershell
uv run --with lxml==5.* python Skills/ais-sow-docx/scripts/validate.py `
  --input specs/.presales/03-sow.docx `
  --source specs/.presales/03-sow.json `
  --evidence specs/.presales/03-sow.evidence.json `
  --render-reviewed pass `
  --renderer "LibreOffice <version>" `
  --page-count <count> `
  --review-notes "Reviewed every rendered page; no layout defects found." `
  --content-reviewed pass `
  --content-reviewer "<reviewer role or name>" `
  --content-review-notes "Applied the AIS SOW writing checklist."
```

Client readiness passes only when structural validation, the recorded rendered
review, and the recorded human content review all pass. The content review does
not replace Contracts, legal, commercial, or client approval.

## Template Version Changes

Never replace an existing versioned asset. Add a new profile/version directory,
record the source identity and SHA-256 in `assets/template-manifest.json`, run
catalog and generation tests, render the profile fixture, obtain required
approval, and then change `active_version` explicitly. Historical versions
remain selectable and reproducible.

## Output Contract

Return the DOCX path, evidence path, selected profile, selected version,
structural result, rendered-review result, content-review result,
client-readiness result, and any blocking check. When this skill is invoked
from `/ais.presales.scope`, keep `specs/.presales/03-sow.md` available even if
the Word gate fails.
