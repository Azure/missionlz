# SOW Template Profiles

## Selection Axes

Profiles match all five classification values exactly. Do not infer an
unsupported form and do not treat Microsoft Solution Center as funding.

| Profile | Agreement family | Contract form | Delivery organization | Delivery pattern | Document type |
|---------|------------------|---------------|-----------------------|------------------|---------------|
| `ais-client-ffp` | client | ffp | ais | fixed-deliverables | original-sow |
| `msc-ffp` | client | ffp | microsoft-solution-center | fixed-deliverables | original-sow |
| `ais-client-tm` | client | time-and-materials | ais | managed-capacity | original-sow |
| `staff-augmentation-retainer` | client | retainer | ais | staff-augmentation | original-sow |
| `ecif-generic` | ecif | ffp | ais | fixed-deliverables | original-sow |

POP-only and POP-plus-price change orders are not supported by these profiles.

## Editable and Preserve-Only Regions

The generator may update only declared metadata content controls, exact cover
placeholders, custom properties, the Word field-refresh setting, and the body
region after the preserved introductory agreement paragraph and before the
`Administrative` heading. The `Administrative` heading and every body element
after it are preserve-only except for declared metadata content controls.

Generation normalizes declared editable content controls before comparing the
fixed-region hash. All other fixed-region text and structure must match the
approved template.

## Version Policy

Each immutable asset is stored under
`assets/templates/<profile>/<YYYY-MM>/template.docx`. The manifest records the
approved source identity and SHA-256 digest. An active version is a pointer, not
a mutable file.

To onboard a version:

1. Add a new version directory; never replace an existing asset.
2. Compute SHA-256 from the copied approved source file.
3. Add the version entry without changing `active_version`.
4. Run catalog tests, all profile fixtures, structural validation, and rendered
   page review.
5. Change `active_version` in a separate explicit manifest edit after approval.

ECIF currently reuses the immutable generic AIS FFP shell. The two profiles
have separate selectors and visible labels but intentionally share an asset
digest.

## Commercial Policy

The only permitted commercial value is `TBD - Commercial Review`. Input that
contains a numeric, currency, percentage, hourly, or rate value in the
commercial object is rejected before a DOCX is created. Each profile keeps its
commercial vocabulary, but every value cell receives the controlled
placeholder.

## Readiness

Structural validation, rendered page review, and human content review are
separate gates. If a renderer or qualified content reviewer is unavailable,
preserve the Markdown SOW and generated DOCX/evidence, but report
`client_ready` as false.
