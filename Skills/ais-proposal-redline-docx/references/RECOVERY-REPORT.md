# Recovery Report

A recovery report accompanies the recovered draft for the current Shipley-style
gate transition when the draft changes after review feedback, QA findings,
page-fit work, or late evidence updates. It is a gate handoff artifact: concise
enough for a pursuit lead to scan, but complete enough to explain what content
changed, what impact it had, and whether the document is ready for the next
gate.

Name the transition explicitly. Examples include Pink-to-Red, Red-to-Gold,
Gold-to-White-Glove, and White-Glove-to-Final. For Pink-to-Red recovery, the
report should focus on Pink reviewer comment disposition and content changes in
the recovered Red draft.

## When to Create It

Create a recovery report when any of these are true:

- reviewer comments required substantive content changes
- a draft had to be regenerated due to page compliance, formatting, or
  validation issues that affect reviewability
- image/table/layout changes were made to stay within page constraints
- new evidence or past performance content was added after a gate
- any change could affect compliance, evaluation scoring, page count, or final
  production readiness

## Required Sections

1. **Recovery Summary**: one paragraph naming the transition, source draft,
   recovered draft, recovery reason, and current readiness state.
2. **Gate Context and Recovery Trigger**: identify the current Shipley-style
   transition (Pink-to-Red, Red-to-Gold, Gold-to-White-Glove,
   White-Glove-to-Final) and what triggered recovery.
3. **Change Ledger**: table with change ID, location, change type, driver,
   summary, and reviewer/comment reference if applicable.
4. **Impact Assessment**: table covering compliance, evaluation theme, page
   count, formatting, comments/threading, tracked changes, evidence support, and
   production risk. Each row should state impact and mitigation.
5. **Validation Evidence**: commands, Word checks, manual checks, and key
   observations used to prove the recovered draft is safe to advance.
6. **Open Items**: owner/action/date for anything not closed. If there are no
   blockers, say so explicitly.
7. **Recommended Gate Decision**: advance, advance with watch items, hold, or
   return to recovery.

## Branding and Format

When the recovery report accompanies a proposal redline, produce the report as a
Word document using the proposal-branded DOCX workflow (`ais-proposal-docx`) or
the current proposal template. The report should use the same cover page,
headers/footers, and approved proposal styles as the response package. Do not
create ad hoc Word styles for the recovery report.

## File Naming

Name the recovery report from the recovered draft filename so the package stays
sortable and traceable. Preserve the recovered draft's gate prefix (`Red`,
`Gold`, `Final`, etc.) and include the HubSpot/opportunity ID when it is known
from project context, source metadata, or the draft filename. If the ID is not
known, do not invent one; keep the gate prefix and draft title.

Pattern when the ID is known:

```text
<Gate Prefix> - <HubSpot/Opportunity ID> - <Draft Title> - Recovery Report.docx
```

Pattern when the ID is not known:

```text
<Gate Prefix> - <Draft Title> - Recovery Report.docx
```

Example:

```text
Red - 60353159195 - USDA AI Assisted Dev RFI Solution Brief - Recovery Report.docx
```

## Change Impact Categories

Use these categories consistently:

- **Compliance**: affects stated requirements, RFI response coverage, or
  submission instructions.
- **Evaluation**: strengthens or weakens win themes, differentiators, proof, or
  evaluator readability.
- **Evidence**: introduces customer names, dates, metrics, or technical claims
  that require source backing.
- **Page/Format**: affects page limits, figure/table placement, styles, or
  readability.
- **Review Traceability**: affects original comments, threaded replies, tracked
  changes, or reviewer closure.
- **Production**: affects final PDF/Word production, lock files, images,
  references, or handoff readiness.

## Gate Decision Guidance

- **Advance**: all required changes are made, page budget holds, no blockers,
  and validation evidence is current.
- **Advance with watch items**: no blocker remains, but a non-critical item
  needs owner follow-up before final submission.
- **Hold**: evidence, compliance, page count, comment traceability, or formatting
  remains unresolved.
- **Return to recovery**: the draft must be regenerated or substantively repaired
  before another gate review.

## Notes

- Do not bury validation failures. State what failed, what changed, and what now
  proves recovery.
- Do not include internal tool-debugging history unless it materially affects
  submission risk, review traceability, or production readiness.
- Do not invent impact. If a change has no known compliance impact, say "No
  compliance impact identified" and list the validation basis.
- Keep customer/proof-point additions evidence-gated. If the source was provided
  by the pursuit team, cite that fact in the report.
