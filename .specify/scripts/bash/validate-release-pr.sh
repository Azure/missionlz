#!/usr/bin/env bash
# Validate PR release metadata for AIS Spec semantic releases.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

EVENT_PATH="${GITHUB_EVENT_PATH:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event)
      EVENT_PATH="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: validate-release-pr.sh [--event /path/to/github-event.json]"
      exit 0
      ;;
    *)
      release_fail "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$EVENT_PATH" ]] || release_fail "No event path provided. Set GITHUB_EVENT_PATH or pass --event."
[[ -f "$EVENT_PATH" ]] || release_fail "Event file not found: $EVENT_PATH"
require_command jq

tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

mapfile -t valid_release_labels < <(
  jq -r '.pull_request.labels[]?.name // empty' "$EVENT_PATH" \
    | grep -E '^release:(major|minor|patch)$' \
    || true
)

mapfile -t release_like_labels < <(
  jq -r '.pull_request.labels[]?.name // empty' "$EVENT_PATH" \
    | grep -E '^release:' \
    || true
)

if [[ ${#valid_release_labels[@]} -ne 1 || ${#release_like_labels[@]} -ne 1 ]]; then
  echo "Release metadata check failed." >&2
  echo "" >&2
  release_label_help >&2
  echo "" >&2
  if [[ ${#release_like_labels[@]} -eq 0 ]]; then
    echo "Current release labels: none" >&2
  else
    printf 'Current release labels: %s\n' "${release_like_labels[*]}" >&2
  fi
  exit 1
fi

release_label="${valid_release_labels[0]}"
pr_title="$(jq -r '.pull_request.title // ""' "$EVENT_PATH")"
jq -r '.pull_request.body // ""' "$EVENT_PATH" > "$tmp_body"

release_note="$(resolve_release_note "$tmp_body" "$pr_title" "$release_label" || true)"
if ! printf '%s\n' "$release_note" | has_release_note_content; then
  cat >&2 <<'MSG'
Release metadata check failed.

The PR body must include a non-empty "## Release note" section.
Dependabot patch PRs may omit this section when their generated body is intact.

Use a concise user-facing summary, for example:
  - release:patch: Clarifies contributor setup instructions.
  - release:minor: Adds automated semantic release enforcement.
  - release:major: BREAKING CHANGE: Renames generated command files.
MSG
  exit 1
fi

if [[ "$release_label" == "release:major" ]] \
  && ! printf '%s\n' "$release_note" | grep -q '^BREAKING CHANGE:'; then
  cat >&2 <<'MSG'
Release metadata check failed.

PRs labeled release:major must include a breaking-change callout in the
"## Release note" section.

Add a line that starts exactly like this:
  BREAKING CHANGE: Describe what downstream teams must change.
MSG
  exit 1
fi

echo "Release metadata is valid: $release_label"
