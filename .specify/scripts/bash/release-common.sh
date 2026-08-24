#!/usr/bin/env bash
# Shared helpers for AIS Spec release automation.

release_fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 \
    || release_fail "Required command not found: $command_name"
}

validate_semver() {
  local version="$1"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

release_label_to_bump() {
  local label="$1"
  case "$label" in
    release:major) echo "major" ;;
    release:minor) echo "minor" ;;
    release:patch) echo "patch" ;;
    *) return 1 ;;
  esac
}

next_semver() {
  local version="$1" bump="$2"
  validate_semver "$version" || release_fail "Invalid VERSION '$version'. Expected MAJOR.MINOR.PATCH."

  IFS='.' read -r major minor patch <<< "$version"

  case "$bump" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      release_fail "Invalid bump '$bump'. Expected major, minor, or patch."
      ;;
  esac

  echo "${major}.${minor}.${patch}"
}

extract_release_note() {
  local body_file="$1"

  awk '
    BEGIN { in_section = 0 }
    /^[[:space:]]*##[[:space:]]+Release note[[:space:]]*$/ {
      in_section = 1
      next
    }
    /^[[:space:]]*##[[:space:]]+/ && in_section {
      exit
    }
    /^[[:space:]]*Bumps[[:space:]]+\[/ && in_section {
      exit
    }
    in_section {
      print
    }
  ' "$body_file" \
    | sed '/^[[:space:]]*<!--.*-->[[:space:]]*$/d' \
    | awk '
      /^[[:space:]]*$/ && !seen {
        next
      }
      {
        lines[++count] = $0
        seen = 1
        if ($0 !~ /^[[:space:]]*$/) {
          last_content = count
        }
      }
      END {
        for (i = 1; i <= last_content; i++) {
          print lines[i]
        }
      }
    '
}

has_release_note_content() {
  sed '/^[[:space:]]*$/d' | grep -q .
}

is_dependabot_body() {
  local body_file="$1"
  grep -q 'dependabot-automerge-start' "$body_file" \
    || grep -q '^Bumps \[.*\].* from .* to .*\.$' "$body_file"
}

dependabot_release_note_from_title() {
  local title="$1"
  local update="$title"

  # Strip the configured commit-message prefix, if present.
  update="${update#chore: }"
  update="${update#chore(deps): }"

  # Dependabot has shipped both "bump" and "Bump" for the same update type, so
  # match the verb case-insensitively instead of stripping a literal prefix.
  local lowered="${update,,}"
  [[ "$lowered" == "bump "* ]] || return 1
  # Drop the matched verb by length so every case variant is stripped, not just
  # the ones a case-sensitive glob would cover.
  update="${update:5}"

  [[ -n "$update" ]] || return 1
  printf 'Updates %s.\n' "$update"
}

resolve_release_note() {
  local body_file="$1" title="${2:-}" label="${3:-}"
  local release_note

  release_note="$(extract_release_note "$body_file")"
  if printf '%s\n' "$release_note" | has_release_note_content; then
    printf '%s\n' "$release_note"
    return 0
  fi

  if [[ "$label" == "release:patch" ]] && is_dependabot_body "$body_file"; then
    dependabot_release_note_from_title "$title"
    return $?
  fi

  return 1
}

release_label_help() {
  cat <<'HELP'
Every pull request must declare exactly one release label:
  - release:patch  Small fixes, docs, generated output refreshes, and routine maintenance
  - release:minor  New backwards-compatible commands, templates, playbooks, workflows, or behavior
  - release:major  Breaking workflow, prompt, template, command, file layout, or CI contract changes

How to fix:
  1. Add exactly one release:* label to the PR.
  2. Fill in the "Release note" section of the PR body.
  3. For release:major, include a line that starts with "BREAKING CHANGE:".
HELP
}
