# Owner Resolution Policy

Resolve `owner` consistently for every artifact-creating command. `owner` is the
accountable source-control provider login, not the person editing the file. Do
not derive it from Git authorship.

## Procedure

1. Resolve the repository root, then run the helper through its absolute path:

   ```bash
   repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   bash "$repo_root/.specify/scripts/bash/resolve-owner.sh" --stage <stage> --spec <absolute-spec-path> --json
   ```

2. If `policy_found` is `false`, report the missing policy and leave `owner`
   unchanged.
3. Apply the caller decision table below. Resolution `status` reports available
   evidence; it never grants permission to overwrite an existing owner.
4. Before writing a new owner, validate the raw value: it must be valid UTF-8,
   contain no C0 or DEL control characters, and remain non-empty after trimming.
   Reject invalid typed input or a confirmed Git hint rather than sanitizing it.
   Preserve invalid legacy owners until a user explicitly confirms a valid
   replacement.
5. If the result is `resolved` and `owner` is empty, write `login` to `owner`
   and report `provider`, `login`, and `source`.
6. If `owner` is empty and the result is `needs-user-input`, offer an
   assign-or-continue choice:
   - A validated typed provider login sets `owner` and is reported as
     `source: user-input`.
   - A validated, confirmed `git_identity_hint` sets `owner` and is reported
     as `source: git-identity`; the hint is non-authoritative until confirmed.
   - If prompting is unavailable or the user declines, leave `owner` empty and
     report `reason`. Do not show this choice for an existing owner unless the
     user first confirms replacement at `reassign`.
7. If the result is `unresolved` and `owner` is empty, leave it empty and report
   `reason`.

## Caller Decision Table

| Policy | Current owner | Result | Caller action |
|--------|---------------|--------|---------------|
| Missing | Any | Any | Preserve `owner`; report the missing policy. |
| Present | Non-empty | `reassign` with a resolved, different `login` | Offer to keep the current owner (default) or explicitly confirm the validated replacement. |
| Present | Non-empty | Any other result | Preserve without prompting. An equal, missing, or unresolved identity is not reassignment evidence. |
| Present | Empty | `resolved` | Write the validated `login` and report its source. |
| Present | Empty | `needs-user-input` | Offer assign-or-continue; write only a validated typed value or confirmed hint. |
| Present | Empty | `unresolved` | Leave empty and report the reason. |

## Resolution Order

The resolver returns the first non-empty, non-whitespace value in this order:

1. Authenticated provider CLI for the detected remote host.
2. `AIS_OWNER`.
3. Provider CI actor variable.
4. No automatic value.

Git `user.name` and `user.email` are returned only as a non-authoritative hint;
they are never an automatic result.

## Stages

| Stage | Use |
|-------|-----|
| `shaping` | Resolve silently; do not offer assignment. |
| `build` | Resolve automatically, otherwise offer assignment when `owner` is empty. |
| `reassign` | Preserve the existing owner by default; replace it only after explicit confirmation. |

The resolver is read-only, never prompts, and reports provenance only for the
current command run. `owner` remains the sole persisted value.
