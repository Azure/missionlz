---
name: ais-spec-upgrade
description: >-
  Upgrade an existing project repo that copied AIS Spec framework files. Use
  when asked to compare AIS Spec versions, read the changelog, detect framework
  file drift, decide what can be safely updated, or apply a conservative AIS
  Spec framework upgrade.
license: Proprietary
compatibility: Requires Python 3.10+, Git, and uv (https://docs.astral.sh/uv/)
metadata:
  author: ais-internal
  version: "1.0"
---

# AIS Spec Upgrade

Use this skill inside a project repo that already copied AIS Spec framework
files. The workflow compares the project version to an AIS Spec source repo,
reports changelog impact and file drift, asks the user what to do, and only
then applies approved upgrade steps.

## Guardrails

- Do not modify files before the user chooses an upgrade action.
- Treat `.specify/VERSION` as the copied framework version. Use root `VERSION`
  only as a fallback.
- Treat root `Skills/` as versioned framework payload.
- Treat `.specify/validation/` as `framework-core` and
  `Skills/.ais-spec/validation/` as `root-skills`. They are the two explicit
  portable optional-CI collections; do not add root `tests/` or
  `Skills/*/tests/` to the managed validation scope.
- Do not copy `docs/`, `specs/`, `README.md`, or `.project-context/` from AIS
  Spec into project repos by default.
- Preserve project-specific edits. Drifted files require manual review or an
  explicit replace/merge decision.

## Source Selection

Use the first available AIS Spec source:

1. User-provided path, tag, branch, or commit.
2. `AIS_SPEC_SOURCE` environment variable.
3. A local clone the user points to.
4. The script default, which clones/fetches `ais-internal/AIS-spec` into an
   untracked cache under the project repo's `.git/` directory.

Use `origin/main` as the target ref unless the user chooses a release tag or
branch.

## Workflow

### 1. Generate the upgrade report

From the project repo:

```bash
uv run Skills/ais-spec-upgrade/scripts/upgrade_framework.py \
  --project . \
  --source "$AIS_SPEC_SOURCE" \
  --target-ref origin/main
```

If the project does not have this skill yet, run the script from the AIS Spec
source checkout and pass both `--project /path/to/project` and
`--source /path/to/ais-spec`.

Review the report for:

- current and target framework versions
- changelog entries between those versions
- files that can be safely updated
- files that can stay as-is
- files needing manual review
- missing root `Skills/` payload
- missing `.specify/validation/` or `Skills/.ais-spec/validation/` payloads

### 2. Ask for a decision

Present a structured decision prompt when the host supports one. Otherwise use
this compact chat prompt and wait:

| Option | Action | Effect |
| --- | --- | --- |
| Report only | Stop after analysis | No files changed |
| Apply safe updates | Copy only `source-updated` and `added` files | Drifted files stay untouched |
| Choose groups | Apply safe updates for selected groups | User selects groups such as `framework-core`, `root-skills`, or `tool-codex` |
| Cancel | Stop | No files changed |

Never infer approval from silence.

### 3. Apply approved safe updates

For the safe-update path:

```bash
uv run Skills/ais-spec-upgrade/scripts/upgrade_framework.py \
  --project . \
  --source "$AIS_SPEC_SOURCE" \
  --target-ref origin/main \
  --mode apply-safe
```

For selected groups:

```bash
uv run Skills/ais-spec-upgrade/scripts/upgrade_framework.py \
  --project . \
  --source "$AIS_SPEC_SOURCE" \
  --target-ref origin/main \
  --mode apply-safe \
  --groups framework-core,root-skills,tool-codex
```

The script refuses to apply changes in a dirty git worktree unless the user has
explicitly approved and `--allow-dirty` is passed.

### 4. Review manual items

For `manual-review`, `project-customized`, `missing`, and `removed-or-obsolete`
files, inspect diffs before editing. Use the upgrade guide for the drift model:
`docs/guides/upgrade.md`.

### 5. Validate and summarize

After applying changes, run relevant checks:

```bash
git status --short
git diff --stat
bash .specify/scripts/bash/generate-commands.sh --check
bash .specify/scripts/bash/validate-frontmatter.sh
```

When an optional CI payload is missing, restore the group that owns it:
`.specify/validation/` through `framework-core` and
`Skills/.ais-spec/validation/` through `root-skills`. Keep root `tests/`,
root `.skillspector-baselines/`, and skill-local `Skills/<skill>/tests/`
project-owned.

Report changed files, skipped files, manual review items, validation results,
and recommended commit/PR next steps.

## Script

- `scripts/upgrade_framework.py` - builds the version/changelog/drift report
  and applies non-conflicting updates when requested.
