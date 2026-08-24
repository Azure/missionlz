#!/usr/bin/env bash
# report-token-costs.sh — Report estimated LLM token cost of context-bearing files
#
# Counts estimated tokens (bytes / 4 heuristic) for every file the framework
# injects into model context, grouped by category:
#   - prompts:      .specify/prompts/*.md (source of generated commands)
#   - templates:    .specify/templates/** (read by commands at runtime)
#   - playbooks:    .specify/playbooks/** (read by pre-sales commands)
#   - instructions: .specify/repo-instructions.md (source of CLAUDE.md/AGENTS.md)
#
# Each category has a per-file token budget (declared below). In --check mode
# the script exits non-zero if any file exceeds its category budget, so CI can
# gate context growth the same way it gates generated-command drift. To raise a
# budget, change the constant here in the same PR — that makes the cost
# decision visible to the reviewer.
#
# Usage:
#   bash .specify/scripts/bash/report-token-costs.sh                 # table
#   bash .specify/scripts/bash/report-token-costs.sh --json          # JSON
#   bash .specify/scripts/bash/report-token-costs.sh --check         # enforce budgets
#   bash .specify/scripts/bash/report-token-costs.sh --base REF      # add delta vs git REF
#   bash .specify/scripts/bash/report-token-costs.sh --check --base origin/main
#
# Exit codes:
#   0 — within budgets (or report-only mode)
#   1 — one or more files exceed their category budget (--check only)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root)
cd "$REPO_ROOT"

# --- Per-file token budgets (estimated tokens = bytes / 4) ---------------
# Set above the current maxima at introduction; tighten deliberately over time.
BUDGET_PROMPTS=12000
BUDGET_TEMPLATES=4000
BUDGET_PLAYBOOKS=16000
BUDGET_INSTRUCTIONS=2500

JSON=false
CHECK=false
BASE_REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=true; shift ;;
    --check) CHECK=true; shift ;;
    --base) BASE_REF="${2:-}"; shift 2 ;;
    --help|-h)
      grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' | sed -n '2,26p'
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -n "$BASE_REF" ]] && ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  echo "WARN: base ref '$BASE_REF' not found; reporting without deltas" >&2
  BASE_REF=""
fi

tokens_of_file() { # path -> estimated tokens in working tree
  local bytes
  bytes=$(wc -c < "$1")
  echo $((bytes / 4))
}

tokens_of_blob() { # ref path -> estimated tokens at ref, or -1 if absent
  local bytes
  if bytes=$(git cat-file -s "$1:$2" 2>/dev/null); then
    echo $((bytes / 4))
  else
    echo "-1"
  fi
}

budget_for() { # category -> budget
  case "$1" in
    prompts) echo "$BUDGET_PROMPTS" ;;
    templates) echo "$BUDGET_TEMPLATES" ;;
    playbooks) echo "$BUDGET_PLAYBOOKS" ;;
    instructions) echo "$BUDGET_INSTRUCTIONS" ;;
    *) echo 0 ;;
  esac
}

list_category_files() { # category -> newline-separated repo-relative paths
  case "$1" in
    prompts) find .specify/prompts -maxdepth 1 -name '*.md' -type f | sort ;;
    templates) find .specify/templates -type f | sort ;;
    playbooks) find .specify/playbooks -type f | sort ;;
    instructions) [[ -f .specify/repo-instructions.md ]] && echo ".specify/repo-instructions.md" ;;
  esac
}

# --- Collect rows: category|path|tokens|budget|delta ---------------------
ROWS=()
FAILURES=()
for category in prompts templates playbooks instructions; do
  budget=$(budget_for "$category")
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    tok=$(tokens_of_file "$path")
    delta=""
    if [[ -n "$BASE_REF" ]]; then
      base_tok=$(tokens_of_blob "$BASE_REF" "$path")
      if [[ "$base_tok" -lt 0 ]]; then
        delta="+${tok} (new)"
      elif [[ "$tok" -ne "$base_tok" ]]; then
        diff=$((tok - base_tok))
        [[ "$diff" -gt 0 ]] && delta="+${diff}" || delta="${diff}"
      fi
    fi
    ROWS+=("${category}|${path}|${tok}|${budget}|${delta}")
    if [[ "$tok" -gt "$budget" ]]; then
      FAILURES+=("${path} is ~${tok} tokens (budget for ${category}: ${budget})")
    fi
  done < <(list_category_files "$category")
done

# Deleted files (present at base ref, gone from working tree) — delta only
DELETED_ROWS=()
if [[ -n "$BASE_REF" ]]; then
  while IFS= read -r path; do
    [[ -f "$path" ]] && continue
    base_tok=$(tokens_of_blob "$BASE_REF" "$path")
    [[ "$base_tok" -lt 0 ]] && continue
    DELETED_ROWS+=("deleted|${path}|0|0|-${base_tok} (deleted)")
  done < <(git ls-tree -r --name-only "$BASE_REF" -- .specify/prompts .specify/templates .specify/playbooks .specify/repo-instructions.md 2>/dev/null \
            | grep -Ev '\.claude\.yaml$|\.copilot\.yaml$' | sort)
fi

# --- Output ---------------------------------------------------------------
if [[ "$JSON" == true ]]; then
  printf '{\n  "files": [\n'
  first=true
  for row in "${ROWS[@]}" "${DELETED_ROWS[@]:-}"; do
    [[ -z "$row" ]] && continue
    IFS='|' read -r category path tok budget delta <<< "$row"
    [[ "$first" == true ]] && first=false || printf ',\n'
    printf '    {"category": "%s", "path": "%s", "tokens": %s, "budget": %s, "delta": "%s"}' \
      "$category" "$path" "$tok" "$budget" "$delta"
  done
  printf '\n  ],\n  "over_budget": %d\n}\n' "${#FAILURES[@]}"
else
  if [[ -n "$BASE_REF" ]]; then
    printf '%-14s %-62s %8s %8s  %s\n' "CATEGORY" "FILE" "TOKENS" "BUDGET" "DELTA vs ${BASE_REF}"
  else
    printf '%-14s %-62s %8s %8s\n' "CATEGORY" "FILE" "TOKENS" "BUDGET"
  fi
  total=0
  for row in "${ROWS[@]}" "${DELETED_ROWS[@]:-}"; do
    [[ -z "$row" ]] && continue
    IFS='|' read -r category path tok budget delta <<< "$row"
    total=$((total + tok))
    printf '%-14s %-62s %8s %8s  %s\n' "$category" "$path" "$tok" "$budget" "$delta"
  done
  printf '%-14s %-62s %8s\n' "TOTAL" "(estimated tokens, bytes/4 heuristic)" "$total"
fi

if [[ "$CHECK" == true && "${#FAILURES[@]}" -gt 0 ]]; then
  echo "" >&2
  echo "Token budget check FAILED:" >&2
  for f in "${FAILURES[@]}"; do
    echo "  - $f" >&2
  done
  echo "Raise the budget constant in $(basename "${BASH_SOURCE[0]}") in this PR if the growth is intentional." >&2
  exit 1
fi
