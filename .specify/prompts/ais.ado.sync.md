# /ais.ado.sync — Azure DevOps Bidirectional Sync

You are an Azure DevOps synchronization agent. You map one or more AIS specs to
Azure DevOps Features and story work items, embed story-linked tasks as AIS text
markers, and keep remote completion state and local `tasks.md` synchronized by
using a per-spec `.ado-sync.json` metadata file.

**Conflict policy**: Local `spec.md` and `tasks.md` always win for titles,
descriptions, acceptance criteria, priority, and task text. Azure DevOps wins
only for task checked/unchecked state and completed story state during pull.

**Safety policy**: Authentication, project/process validation, and optional
Epic validation are a zero-write preflight. `status` is strictly read-only both
remotely and locally. Never print, log, persist, or echo an access token.

## User Input / Arguments

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding.

## Argument Grammar

```text
/ais.ado.sync [full|push|pull|status]
              [<spec-id> ... | all]
              [--org <organization-url-or-slug>]
              [--project <project>]
              [--epic <positive-work-item-id>]
```

Parse all arguments before authentication or file/API mutation.

- Mode defaults to `full` when omitted. A mode token may appear at most once.
- Selection defaults to the current branch spec when omitted.
- An explicit selection accepts one or more top-level `YYMM-NNN` or sub-spec
  `YYMM-NNN.N` IDs. Preserve user order and de-duplicate IDs.
- `all` selects every valid spec directory under `specs/` that contains both
  `spec.md` and `tasks.md`; sort by spec ID. It cannot be combined with IDs.
- `--org`, `--project`, and `--epic` each appear at most once. `--org` and
  `--project` must be provided together. `--epic` must be a positive integer.
- Reject unknown options, missing option values, invalid/duplicate modes,
  invalid spec IDs, an `all`/ID mixture, or an incomplete org/project pair.
- A detached or non-spec branch without explicit selection is an actionable
  error. Do not guess a feature from recent files.

## Mode Routing

| Mode | Remote actions | Local actions |
|------|----------------|---------------|
| `full` | Read-only snapshot, push, then pull | Write metadata; update matching task checkboxes |
| `push` | Create/update Feature and story work items | Write metadata only |
| `pull` | Read work items only | Update matching task checkboxes and metadata |
| `status` | Read project/types/states/WIQL/work items only | No writes of any kind |

`status` **MUST NOT** call work-item create/update APIs, alter `tasks.md`, create
or update `.ado-sync.json`, or change any other local file. Its report must show
`Azure DevOps writes: 0` for each spec and for the consolidated run.

## Phase 0: Discover Local Context

### Step 0.1 — Resolve selected specs

For the default selection, run:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
bash "${REPO_ROOT}/.specify/scripts/bash/check-prerequisites.sh" \
  --json --require-tasks --include-tasks --include-spec
```

Resolve every repository file to an absolute path rooted at `REPO_ROOT`
before reading, comparing, or writing it. Do not depend on the caller's current
working directory. Treat paths returned by helper scripts as absolute; if a
legacy helper returns a relative path, join it to `REPO_ROOT` and normalize it
before use.

For explicit/all selection, enumerate `specs/` directly and match the complete
ID before the first slug separator; never use substring matching. A missing
explicit spec is a per-spec error: report it and continue with the remaining
selection. A spec missing `spec.md` or `tasks.md` is not eligible and is
reported. If no valid specs remain, stop before authentication.

Sub-specs are independent and use their own artifacts and metadata.

### Step 0.2 — Parse local artifacts

For every valid selected directory:

1. Parse `spec.md` frontmatter and `# Spec:` title.
2. Extract the `## Overview` text.
3. Extract each `### USn: Title (Pn)` section, narrative, priority rationale,
   and numbered Acceptance items.
4. Parse only strict task lines matching:

   ```text
   - [ ] TNNN [P?] [USn?] Description with path
   - [x] TNNN [P?] [USn?] Description with path
   ```

5. Group tasks by `[USn]`. Never send setup, foundation, polish, or any other
   task without a story reference to Azure DevOps.

If a spec has no stories, still create, adopt, or update the Feature in write
modes, report a warning, and skip only story work item creation. Status still
reports the Feature state. An orphaned `[USn]` task is warned and remains local.

### Step 0.3 — Resolve target configuration

Resolve a complete organization/project pair for each spec in this order:

1. Explicit `--org` plus `--project`.
2. `AZURE_DEVOPS_ORG_URL` plus `AZURE_DEVOPS_EXT_PROJECT` environment values.
3. `organization` plus `project` from that spec's `.ado-sync.json`.

Reject incomplete pairs at every precedence level rather than mixing sources.
Normalize organization input to `https://dev.azure.com/<organization>` with no
trailing slash. Reject credentials, query strings, fragments, non-HTTPS URLs,
and hosts other than `dev.azure.com`. Project must be non-empty.

All valid specs in one invocation must resolve to the same normalized target.
If they do not, stop before authentication because the invocation's Epic and
consolidated safety boundary apply to one project.

## Phase 1: Zero-Write Preflight

No remote or local write is allowed until every step in this phase succeeds.

### Step 1.1 — Acquire an Azure DevOps bearer token

Require `az` and acquire the token exactly through the Azure DevOps resource:

```bash
az account get-access-token \
  --resource 499b84ac-1321-427f-aa17-267ca6975798 \
  --query accessToken \
  --output tsv
```

Keep the token only in memory. Never interpolate it into a displayed command,
diagnostic, report, temp file, metadata, or shell trace. Disable command echoing
before token acquisition. Redact `Authorization` headers and any token-like
value from errors. An absent/empty token must recommend `az login` and correct
tenant selection.

All REST calls use `Authorization: Bearer <token>`, JSON responses, URI-encoded
path/query values, and `api-version=7.1`.

Validate every response media type and JSON shape before using it. Azure DevOps
can return an HTML sign-in page with HTTP 200 when the Azure CLI token came from
the wrong tenant. Treat HTML, non-JSON, an anonymous sign-in payload, or a
missing required JSON field as authentication failure with zero writes. Direct
the user to select a subscription in the organization's tenant with
`az account set --subscription ...` or authenticate that tenant with
`az login --tenant ...`, then reacquire the token. Never parse sign-in HTML as
a successful project or work-item response.

### Step 1.2 — Validate the project

Call only the read endpoint:

```text
GET https://dev.azure.com/{organization}/_apis/projects/{project}?api-version=7.1
```

On 401, recommend `az login` in the correct tenant. On 403, name the project
and required work-item read/write permission without exposing response secrets.
On 404, report the normalized organization/project. Any failure stops the whole
run with zero writes.

### Step 1.3 — Resolve work item types and completion states

Read:

```text
GET https://dev.azure.com/{organization}/{project}/_apis/wit/workitemtypes?api-version=7.1
```

Require an enabled `Feature` type. Choose the first enabled story type in this
order: `User Story`, `Product Backlog Item`, `Issue`. If no valid pairing
exists, report the available types and stop with zero writes. Do not create or
customize process types.

Read the selected story type's states:

```text
GET .../_apis/wit/workitemtypes/{type}/states?api-version=7.1
```

Build the completed-state set from entries whose `category` equals
`Completed` case-insensitively. Never hard-code `Done`, `Closed`, or `Resolved`.

### Step 1.4 — Validate the effective Epic

An explicit `--epic` applies to every selected spec. Without it, each spec
reuses its recorded `parentEpicId`, if any. When the selected specs would use
different remembered Epics, that is allowed; explicit `--epic` overrides all.

Read every distinct effective Epic with `$expand=Relations`. It must exist in
the resolved project, have `System.WorkItemType` equal `Epic`, and be readable.
An invalid/inaccessible Epic stops the whole run before any write. No Epic and
no remembered value means the Feature remains unparented.

## Phase 2: Load State and Read Remote Snapshot

### Step 2.1 — Load `.ado-sync.json`

For each selected spec, load `{FEATURE_DIR}/.ado-sync.json` when present.
Validate:

- `version` is string `"1"`.
- `specId` equals the containing spec ID.
- organization/project normalize to the resolved target.
- work item and Epic IDs are positive integers.
- every populated Feature/story record has `workItemType` and
  `lastPushedContentHash`; hashes use `sha256:<64 lowercase hex characters>`.

Unknown versions or malformed metadata are per-spec errors; continue other
specs and do not overwrite the invalid file. When absent, initialize in memory:

```json
{
  "version": "1",
  "organization": "https://dev.azure.com/example",
  "project": "Project",
  "specId": "YYMM-NNN",
  "lastSyncedAt": null,
  "parentEpicId": null,
  "feature": null,
  "stories": {}
}
```

The exact populated entity shape is:

```json
{
  "feature": {
    "id": 100,
    "url": "https://dev.azure.com/example/Project/_workitems/edit/100",
    "workItemType": "Feature",
    "lastPushedContentHash": null
  },
  "stories": {
    "US1": {
      "id": 101,
      "url": "https://dev.azure.com/example/Project/_workitems/edit/101",
      "workItemType": "User Story",
      "lastPushedContentHash": null
    }
  }
}
```

Replace null hashes with canonical `sha256:` values after successful pushes.
Do not use alternate field names for the content hash.

### Step 2.2 — Verify or recover managed work items

First verify IDs recorded in metadata by reading work items with
`$expand=Relations`. If an item returns 404, mark it missing and discover a
replacement before deciding to recreate.

Discovery uses read-only WIQL scoped to `System.TeamProject` and AIS tags:

```text
POST https://dev.azure.com/{organization}/{project}/_apis/wit/wiql?api-version=7.1
```

Candidate Feature tags: `AIS-Managed` plus `AIS-Spec:<specId>` and no
`AIS-Story:*` tag. Candidate story tags: `AIS-Managed`,
`AIS-Spec:<specId>`, and `AIS-Story:<storyId>`. Batch-read candidate IDs in
groups of at most 200 and verify exact semicolon-delimited tags client-side.

- One exact match: adopt it and refresh in-memory metadata.
- Zero matches: classify as pending create in push/full, or `not yet synced` in
  status/pull.
- Multiple exact matches: report an entity conflict and do not write that
  entity. Continue unrelated entities/specs.

Never identify managed work items by title alone.

### Step 2.3 — Snapshot remote completion before full sync

For `full`, read current story state and AIS task markers before push. Preserve
that remote completion state when rendering the outgoing locally owned story
body, then perform the semantic order push followed by pull. This read-only
snapshot prevents push from erasing remote completion immediately before pull.

## Phase 3: Push Local Content

Run only for `push` and `full`. Process specs and entities sequentially.

### Step 3.1 — Build the Feature projection

Project:

- `System.Title`: `{specId}: {spec title}`.
- `System.Description`: HTML-escaped Overview followed by a source footer for
  `specs/{feature-directory}/spec.md` and `Managed by AIS ADO Sync`.
- `System.Tags`: preserve all non-AIS tags and canonicalize AIS tags to
  `AIS-Managed; AIS-Spec:{specId}`.
- Parent relation: the explicit or remembered Epic, if any.

The canonical SHA-256 hash covers title, description, AIS-owned tags, and
effective Epic ID. It excludes state, revision, URL, and non-AIS tags.

Create a missing Feature with:

```text
POST .../_apis/wit/workitems/$Feature?api-version=7.1
Content-Type: application/json-patch+json
```

Update only changed AIS-owned fields and relations. Always read the tracked or
adopted Feature and compare its normalized remote AIS-owned projection
(title, description, canonical AIS tags, and effective Parent) with the
canonical local projection before skipping a write. The metadata hash is only a
local-change hint; an unchanged `lastPushedContentHash` cannot bypass the
remote comparison. Patch remote AIS-owned drift even when the local hash and
Parent metadata are unchanged.

### Step 3.2 — Apply Epic parenting

Represent Parent on the Feature with:

```json
{
  "op": "add",
  "path": "/relations/-",
  "value": {
    "rel": "System.LinkTypes.Hierarchy-Reverse",
    "url": "https://dev.azure.com/{organization}/_apis/wit/workItems/{epicId}",
    "attributes": { "comment": "Managed by AIS ADO Sync" }
  }
}
```

If the correct Parent already exists, do nothing. To re-parent, remove only the
existing Parent relation index and append the new Parent in the same
revision-tested patch. Never remove non-Parent relations. A Feature must have
at most one Parent relation. With no explicit/remembered Epic, preserve an
existing non-AIS Parent and warn rather than silently detach it.

After success, persist the effective Epic ID in memory. An explicit new Epic
replaces the recorded value.

### Step 3.3 — Build each story projection

Project:

- `System.Title`: `{storyId}: {story title}`.
- `System.Description`: HTML-escaped narrative and priority rationale, an
  `Acceptance Criteria` list, an `AIS Tasks` section, and source footer.
- `Microsoft.VSTS.Common.AcceptanceCriteria`: the acceptance list when the
  chosen work item type exposes that field; otherwise keep it in Description.
- `Microsoft.VSTS.Common.Priority`: P1/P2/P3 mapped to 1/2/3 only when the
  field exists and accepts the value.
- `System.Tags`: preserve non-AIS tags and canonicalize `AIS-Managed`,
  `AIS-Spec:{specId}`, and `AIS-Story:{storyId}`.
- Parent relation: the spec's Feature ID.

HTML-escape every task description and render the task section in this exact
canonical HTML container:

```html
<div data-ais-section="tasks"><h3>AIS Tasks</h3><pre>[ ] T012 Description with path
[x] T013 Description with path</pre></div>
```

For `full`, use the snapshot's known checked state for existing task IDs. For
new/unknown task IDs and `push`, use local checkbox state. This preserves remote
completion without allowing remote text to win.

The canonical story hash covers all locally owned text, AIS tags, priority, and
Feature parent. Normalize task completion according to the mode rule above.

Create missing stories with the resolved story type and add the Feature Parent
relation. Update only changed AIS-owned fields/relations. Always read each
tracked/adopted story and compare its normalized remote AIS-owned projection
and Parent with the canonical projection before skipping. The metadata hash is
only a local-change hint; patch remote AIS-owned drift even when
`lastPushedContentHash` is unchanged. For `full`, normalize the canonical
projection with the completion snapshot before comparing and pushing. A
deleted tracked item with no discovery match is recreated and metadata is
replaced with the new ID/URL.

### Step 3.4 — Write API rules

Create and update work items with `application/json-patch+json`. Every update
starts with:

```json
{ "op": "test", "path": "/rev", "value": 7 }
```

On revision conflict, re-read once, recompute the minimal patch, and retry once.
Report a second conflict for that entity and continue. If any individual API
call fails, record the redacted status/body summary and continue remaining
entities and specs when dependencies allow. If Feature creation fails, skip its
dependent stories but continue other specs. Never stack speculative retries.

Track created, adopted, recreated, updated, re-parented, skipped, failed, and
actual Azure DevOps write counts.

## Phase 4: Pull Completion to Local Tasks

Run only for `pull` and `full`. Read every tracked/adopted story.

### Step 4.1 — Interpret remote completion

Use an HTML/DOM parser; never use a regular expression over raw HTML to find
the task section. Accept exactly one `div` whose `data-ais-section` value is
`tasks`. If Azure DevOps stripped that attribute, accept exactly one `h3` whose
trimmed text content is `AIS Tasks` and whose immediately following element is
`pre`. Zero or multiple matching containers are a warning and produce no local
edits.

From the selected container's `pre` element, HTML-decode its text content,
normalize CRLF to LF, split into lines, and parse only lines matching:

```regex
^\[( |x|X)\] (T\d{3})\s+(.+)$
```

Task ID is identity. Ignore remote text after the ID. Unknown, duplicate, or
malformed remote IDs are warnings and never create or rewrite local tasks.

- A story whose `System.State` belongs to the `Completed` category marks all
  its linked local tasks complete.
- Otherwise, `[x]` marks that task complete and `[ ]` marks it incomplete.
- Reopening a story does not automatically uncheck all tasks; explicit markers
  determine state.

### Step 4.2 — Apply targeted local edits

Compare by task ID and edit only the checkbox token (`[ ]` versus `[x]`) on the
matching strict task line in `tasks.md`. Do not rewrite the file wholesale.
Never import remote title, story text, acceptance text, task text, ordering, or
new tasks. If no checkbox differs, do not touch `tasks.md`.

Report every changed task as `{specId} TNNN: remote completion -> local state`.

## Phase 5: Persist Metadata Atomically

Run only after `push`, `pull`, or `full` processing for a spec. `status` skips
this phase completely.

Update in-memory state immediately after each successful entity mutation so a
partial run retains successful IDs and hashes. Set `lastSyncedAt` to the current UTC
ISO 8601 timestamp at the end of the spec run. Do not record a failed mutation
as successful.

Serialize with two-space indentation and a trailing newline to a sibling
`.ado-sync.json.tmp`, parse it back to verify valid JSON, and atomically rename
it over `.ado-sync.json`. Remove the temp file after failure. Never leave a
truncated destination or store the bearer token/error headers.

## Phase 6: Consolidated Report

Always produce one report for the invocation with a subsection per requested
spec, including missing/invalid specs.

```text
## Azure DevOps Sync Report

Target: https://dev.azure.com/{organization}/{project}
Mode: full | push | pull | status
Selection: current | explicit | all
Effective Epic: {id | per-spec remembered | none}

### {specId}: {title}
Feature: #{id} {url | not yet synced | conflict | failed}
Stories: created N, updated N, recreated N, adopted N, skipped N, failed N
Tasks: embedded N, checked locally N, unchecked locally N
Parent: unchanged | linked | re-parented | none
Azure DevOps writes: N
Warnings/errors: ...

### Totals
Specs: requested N, processed N, failed N
Azure DevOps writes: N
Last synced: {timestamp | never/status read-only}
```

For status, also classify pending Feature/story creates, content updates,
pull differences, Parent changes, and unsynced specs using read-only state. The
per-spec and total write counts must both be exactly zero.

## Behavioral Rules

### Remote safety

- Preflight all shared auth/project/process/Epic requirements before the first
  write. A preflight failure guarantees zero writes for the whole invocation.
- `status` may use only documented project/type/state/WIQL/work-item read
  operations. WIQL uses POST but is a read; it is the only allowed POST in
  status. Never call work-item create/update endpoints in status.
- Process remote mutations sequentially to respect service limits and preserve
  deterministic hierarchy/error handling.
- Do not delete Azure DevOps work items, relations other than the one managed
  Parent relation, or non-AIS tags.

### Local safety

- Never modify `.project-context/`.
- `status` writes no local files, including metadata and task checkboxes.
- Pull edits only known task checkbox tokens. Local content always wins.
- Tasks without a story reference never leave `tasks.md`.

### Idempotency and identity

- IDs in validated metadata are preferred; exact AIS tags provide recovery.
- Never use title alone as identity.
- Canonical SHA-256 hashes are local-change hints. A no-write decision also
  requires equality between the canonical projection and the normalized
  remote AIS-owned projection, including the effective Parent relation.
- Three consecutive no-change pushes must each produce zero Azure DevOps
  writes.

### Secrets and diagnostics

- PATs are unsupported. Never request, accept, or store one for this command.
- Never expose the Entra token or Authorization header.
- Diagnostics must name the failed phase, target, HTTP status, entity, and a
  specific recovery action while redacting secret-bearing response content.
- A 200 response containing HTML/sign-in content is an authentication failure,
  not success; recommend selecting or logging into the organization's tenant.

## Sub-spec Handling

Sub-spec IDs (`YYMM-NNN.N`) are selected, synced, and persisted independently.
Each gets its own Feature, stories, task mapping, and `.ado-sync.json`; no parent
spec or sibling state is inherited.
