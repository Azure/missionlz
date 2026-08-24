# Statement of Work Template Router

Use this router before generating `specs/.presales/03-sow.md`. Do not output
this router as the SOW. Classify the opportunity, load the selected templates,
and generate one coherent Markdown SOW from the applicable sections.

> **AIS-only authoring artifact**: This router and the generated Markdown may
> contain classification, source, readiness, and delivery-planning controls.
> Do not copy those controls into client-deliverable prose. Apply
> `Skills/ais-sow-docx/references/writing-guidance.md` to the client-visible
> narrative used for the generated DOCX.

---

## Classification Summary

| Field | Value |
|-------|-------|
| **Agreement Family** | End Customer Investment Funds (ECIF) / Client / Unknown |
| **Contract Form** | FFP / Time and materials / Retainer / Unknown |
| **Delivery Organization** | AIS / Microsoft Solution Center / Unknown |
| **Delivery Pattern** | Fixed deliverables / Outcome-driven / Managed capacity / Staff augmentation / Unknown |
| **Document Type** | Original SOW / Unknown |
| **Engagement Funding** | Customer-funded / Microsoft-funded / Microsoft-program-funded / Unknown |
| **Ops Continuity Signal** | None / Base / Standard / Premium / Decision needed |
| **Classification Evidence** | [Files, sections, or stakeholder statements used] |
| **Open Decision** | [None or QC item required before final SOW] |

If a required classification axis is unknown, carry the uncertainty into the
SOW as a visible QC item. Do not silently choose the wrong structure. Microsoft
Solution Center is an AIS delivery organization, not a funding model.

When post-delivery support, managed operations, advisory reachback, onboarding,
bug fixes, or enhancements are in scope, load
`.specify/playbooks/ops-continuity.md` and use
`.specify/templates/ops-service-offering-template.md` or
`.specify/templates/ops-playbook-template.md` as supporting structure. Keep the
generated SOW connector-neutral unless a connector implementation is separately
scoped.

---

## Agreement Family Selection

### Microsoft ECIF

Use `.specify/templates/sow/ecif-template.md` when the sources explicitly show
Microsoft ECIF structure or funding, including any of these signals:

- "ECIF Supplier Agreement", "ECIF", or Microsoft-funded supplier agreement
  language
- Microsoft as payer, funder, or agreement counterparty for services delivered
  to a named customer
- CAS, REQ, supplier agreement, proof-of-execution, or Microsoft milestone
  payment language
- A required milestone table with service description, amount, hours, and due
  date columns

Do not add a separate client commercial stub unless source material also asks
for a client-facing scope exhibit.

### Client SOW

Use `.specify/templates/sow/client-template.md` when the sources show direct
client contracting, MSA-backed SOW language, customer-funded delivery, or a
standard AIS client SOW pattern.

After loading the client SOW template, load exactly one commercial-model stub:

| Commercial Model | Use When | Template |
|------------------|----------|----------|
| FFP | Scope is fixed around named deliverables, phases, milestones, or a fixed fee | `.specify/templates/sow/commercial-ffp-template.md` |
| Outcome-driven | Commercial terms or delivery framing emphasize measurable business outcomes over effort | `.specify/templates/sow/commercial-outcome-template.md` |
| Managed capacity | Client is buying a named team, role capacity, throughput, or operating cadence | `.specify/templates/sow/commercial-managed-capacity-template.md` |
| Time and materials | Work is governed by roles, hours, burn, and rate-card reference | `.specify/templates/sow/commercial-time-and-materials-template.md` |
| Unknown | Signals conflict or are absent | Add a QC item and include a short "Commercial Model Decision Needed" section |

---

## Placeholder-Only Commercial Policy

- Do not place numeric rates, prices, fees, totals, investment, payment terms,
  profitability, or customer cost values in generated SOW artifacts, even when
  source material contains approved values.
- Use exactly `TBD - Commercial Review` in every commercial value cell.
- For ECIF, keep required milestone amount and hours columns, but populate both
  with `TBD - Commercial Review`.
- For client SOWs, reference external pricing, green-sheet, rate-card,
  profitability, and payment artifacts by owner/status only.
- Staffing hours are planning inputs. They are not elapsed duration and they
  are not pricing by themselves.

---

## Output Rules

- Generate one SOW using
  `Skills/ais-sow-docx/references/writing-guidance.md`: neutral,
  delivery-focused, and specific about outcomes, responsibilities, acceptance,
  dependencies, and exclusions.
- Include only core scope content. Do not generate legal boilerplate,
  signature blocks, Microsoft terms, audit terms, limitation of liability, or
  master agreement text.
- Preserve source-stated milestone dates, period-of-performance dates,
  acceptance periods, warranty/support windows, and funding dates. Mark missing
  values `TBD`.
- Make all classification uncertainty, commercial gaps, and SOW-readiness gaps
  visible as QC items.
- When all classification axes match an approved profile, generate
  `03-sow.json`, `03-sow.docx`, and `03-sow.evidence.json` with
  `$ais-sow-docx`. Keep `03-sow.md` canonical for delivery planning and report
  the DOCX client-document gate separately.
