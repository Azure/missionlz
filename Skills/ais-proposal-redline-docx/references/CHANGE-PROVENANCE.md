# Change Provenance

## Why explanation belongs on the change

The first version of this skill generated comments only from
`comment_replies[]`, and every reply required a `comment_id`. Explanation was
therefore coupled to the *trigger* — a reviewer comment — rather than to the
*change*. Any change that came from a review call, a compliance rule, or an
internal quality pass had nowhere to say so, and arrived in the red draft as an
unexplained tracked revision.

That is the wrong coupling. A reviewer reading a red draft is asking "why is
this different?" about each change they encounter, not "which of my comments
did this answer?". The fix inverts the relationship: an operation carries its
own explanation, and the applier anchors that explanation to the range it
changed.

## Required fields

Every enabled operation carries:

| Field | Required | Purpose |
|-------|----------|---------|
| `rationale` | yes | What changed and why, in reviewer language |
| `source` | yes | Where the change came from |
| `theme` | no | Reference to a `themes[]` entry |

Operations with `"enabled": false` are exempt. Nothing reaches the document, so
there is nothing to explain.

## The source grammar

`source` is a closed grammar, not free text:

| Form | Meaning |
|------|---------|
| `reviewer_comment:<id>` | Answers a specific comment in the pink draft |
| `review_call:<id>` | Came out of a review meeting or working session |
| `compliance:<rule-id>` | Required by an RFP/solicitation rule, e.g. a page limit |
| `internal_qa` | Internal quality pass with no external driver |

The grammar is closed so the applier can report a truthful breakdown of where
the redline came from. Free text would let an entire class of unexplained
change hide behind inconsistent labels — "review", "reviewer", "call notes" —
and the count would stop meaning anything.

Treat a large `internal_qa` count as a signal worth checking. Internal quality
changes are legitimate, but a red draft that is mostly internal churn is a
different conversation with the pursuit lead than one that is mostly reviewer
response.

## Rationale checks

The validator reports mechanical facts rather than grading writing quality. It
rejects whole-string stock replies (`Addressed.`, `Done.`, `Resolved.`, and
similar) and reports the exact word count when a rationale has fewer than four
words. A complete explanation may contain those words in prose; for example,
`The page-limit concern is addressed in the revision by tabulating the phase
detail.` is not treated as a stock reply.

A one-word rationale carries no more information than no rationale at all, and
accepting it would let the requirement be satisfied without being met — the
worst outcome for a quality gate, because it produces a green check over an
unexplained document.

## Themes

Some decisions apply across the document: a terminology change, a reframing, a
compression pass to hold a page limit. Attaching an identical rationale to
fifteen operations produces fifteen identical comments, and reviewers stop
reading comments that repeat.

A theme states the decision once:

```json
"themes": [
  {
    "id": "integrated-operating-model",
    "rationale": "The review call asked for one integrated operating-model story rather than separate platform and data narratives.",
    "source": "review_call:2026-06-12",
    "anchor_paragraph_index": 18
  }
]
```

Member operations reference it:

```json
{ "type": "replace_paragraph_text", "paragraph_index": 27, "text": "...",
  "rationale": "Reframes DataLance as a supporting layer.",
  "source": "review_call:2026-06-12",
  "theme": "integrated-operating-model" }
```

Behaviour:

- A themed operation produces **no** per-change comment. Its `rationale` stays
  in the plan as the change record.
- Each referenced theme produces **exactly one** comment, anchored at
  `anchor_paragraph_index`, stating the decision and how many changes it
  covers.
- A theme that no operation references is an error — it is either a leftover
  from an abandoned edit or a sign that operations forgot to reference it.
- Referencing a theme that is not declared is an error.
- Theme ids must be unique. A repeated id replaces the earlier declaration, so
  every operation in that theme would be explained by the wrong rationale.
- Repeating the same rationale on multiple unthemed operations is an error. A
  repeated decision is a theme and must produce one explanation, not comment
  spam.

`replace_paragraph_text` comments anchor to the changed paragraph, and
`insert_paragraph_after` comments anchor to the inserted paragraph. Word cannot
anchor a comment to a table, so an `insert_table_after` explanation anchors to
the unchanged paragraph immediately above the table. This placement is
intentional and is covered by the applier's regression tests.

Comments do not count against proposal page limits: a page limit such as `F-1`
is measured with revisions accepted and comments removed. The constraint that
themes exist to protect is reviewer attention, not page count.

## Validate before mutate

The applier validates the entire plan before writing anything. Two reasons:

1. A partial DOCX is worse than no DOCX. Failing halfway through leaves an
   output file whose relationship to the plan is unknown.
2. Reporting every problem at once means the operator fixes them in one pass
   instead of discovering them one run at a time.

Malformed structure is reported the same way rather than raised. A validator
that throws on a bad plan hands back a stack trace where the caller asked for a
list of problems, and the operator learns about one fault at a time.

The validator applies the same contract and document-relative anchor checks as
the applier. A draft created with `--allow-unexplained-changes` must pass the
same flag to the validator; the waiver is draft-only and should not be used for
a deliverable-ready redline.

## Run summary

The applier returns provenance counts alongside the usual results:

```json
{
  "operations_applied": 12,
  "explanation_comments_added": 7,
  "theme_comments_added": 2,
  "provenance_counts": {
    "reviewer_comment": 6,
    "review_call": 4,
    "compliance": 1,
    "internal_qa": 1
  }
}
```

Use this in the recovery report's change ledger rather than recounting by hand.

## Author pinning

`settings.author` is pinned to `AIS Specify`. The merge plan is a carrier: every
applier resolves `settings.get("author") or DEFAULT_RESPONSE_AUTHOR`, so a plan
built by a stale or misconfigured skill copy keeps producing the wrong identity
in the deliverable even after the skill itself is corrected. Validating the
plan's author closes that path.

When a different identity is genuinely required, pass
`--allow-author-override`. The override is recorded in the run result and in
the validator summary so the deviation is visible rather than assumed.
