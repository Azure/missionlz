#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
JSON=false
SHORT_NAME=""
NUMBER=0
REMAINING_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=true; shift ;;
    --short-name) SHORT_NAME="$2"; shift 2 ;;
    --number) NUMBER="$2"; shift 2 ;;
    --help|-h)
      cat <<'HELP'
Usage: create-new-feature.sh [--json] [--short-name <name>] [--number N] <feature description>

Options:
  --json               Output in JSON format
  --short-name <name>  Provide a custom short name (2-4 words) for the branch
  --number N           Specify sequence number manually (overrides auto-detection)
  --help               Show this help message

Examples:
  create-new-feature.sh 'Add user authentication system' --short-name 'user-auth'
  create-new-feature.sh 'Implement OAuth2 integration for API'
HELP
      exit 0
      ;;
    *) REMAINING_ARGS+=("$1"); shift ;;
  esac
done

FEATURE_DESC="${REMAINING_ARGS[*]:-}"
FEATURE_DESC="${FEATURE_DESC# }"

if [[ -z "$FEATURE_DESC" ]]; then
  echo "Usage: create-new-feature.sh [--json] [--short-name <name>] <feature description>" >&2
  exit 1
fi

# --- Helper functions ---

find_repository_root() {
  local current="$1"
  while true; do
    for marker in .git .specify; do
      [[ -e "$current/$marker" ]] && { echo "$current"; return 0; }
    done
    local parent
    parent=$(dirname "$current")
    [[ "$parent" == "$current" ]] && return 1
    current="$parent"
  done
}

get_highest_number_from_specs() {
  local specs_dir="$1" year_month="$2"
  local highest=0
  if [[ -d "$specs_dir" ]]; then
    for dir in "$specs_dir"/*/; do
      [[ -d "$dir" ]] || continue
      local name
      name=$(basename "$dir")
      if [[ "$name" =~ ^${year_month}-([0-9]{3}) ]]; then
        local num=$((10#${BASH_REMATCH[1]}))
        (( num > highest )) && highest=$num
      fi
    done
  fi
  echo "$highest"
}

get_highest_number_from_branches() {
  local year_month="$1"
  local highest=0
  local branches
  branches=$(git branch -a 2>/dev/null) || { echo "0"; return; }
  while IFS= read -r branch; do
    branch="${branch#\* }"
    branch="${branch## }"
    branch="${branch#remotes/*/}"
    if [[ "$branch" =~ ^${year_month}-([0-9]{3}) ]]; then
      local num=$((10#${BASH_REMATCH[1]}))
      (( num > highest )) && highest=$num
    fi
  done <<< "$branches"
  echo "$highest"
}

get_default_remote_ref() {
  local ref
  if ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null); then
    echo "${ref#refs/remotes/}"
    return 0
  fi
  local candidate
  for candidate in origin/main origin/master; do
    if git rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# A branch cut from a stale main sees neither the merged spec directory nor the
# already-deleted branch that carried it, so allocation must read the default
# branch's specs tree directly.
get_highest_number_from_remote_specs() {
  local year_month="$1"
  local highest=0 remote_ref entries
  remote_ref=$(get_default_remote_ref) || { echo "0"; return; }
  # The trailing slash on specs/ is load-bearing: without it ls-tree returns the
  # single "specs" tree entry instead of the directories inside it.
  entries=$(git ls-tree --name-only "$remote_ref" -- specs/ 2>/dev/null) || { echo "0"; return; }
  while IFS= read -r entry; do
    entry="${entry#specs/}"
    entry="${entry%/}"
    if [[ "$entry" =~ ^${year_month}-([0-9]{3}) ]]; then
      local num=$((10#${BASH_REMATCH[1]}))
      (( num > highest )) && highest=$num
    fi
  done <<< "$entries"
  echo "$highest"
}

get_next_branch_number() {
  local specs_dir="$1" year_month="$2"
  # Keep allocation best-effort when offline or credentials are unavailable.
  # Disable terminal prompts everywhere and bound the fetch where coreutils
  # timeout is available (including CI and standard Git Bash installations).
  if command -v timeout >/dev/null 2>&1; then
    GIT_TERMINAL_PROMPT=0 timeout 15s git fetch --all --prune 2>/dev/null || true
  else
    GIT_TERMINAL_PROMPT=0 git fetch --all --prune 2>/dev/null || true
  fi
  local highest_branch highest_spec highest_remote max_num
  highest_branch=$(get_highest_number_from_branches "$year_month")
  highest_spec=$(get_highest_number_from_specs "$specs_dir" "$year_month")
  highest_remote=$(get_highest_number_from_remote_specs "$year_month")
  max_num=$(( highest_branch > highest_spec ? highest_branch : highest_spec ))
  (( highest_remote > max_num )) && max_num=$highest_remote
  echo $(( max_num + 1 ))
}

clean_branch_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//'
}

get_branch_name() {
  local description="$1"
  local stop_words="i a an the to for of in on at by with from is are was were be been being have has had do does did will would should could can may might must shall this that these those my your our their want need add get set"

  local clean_name
  clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g')

  local -a meaningful_words=()
  for word in $clean_name; do
    local is_stop=false
    for sw in $stop_words; do
      [[ "$word" == "$sw" ]] && { is_stop=true; break; }
    done
    $is_stop && continue

    if [[ ${#word} -ge 3 ]]; then
      meaningful_words+=("$word")
    elif echo "$description" | grep -qw "$(echo "$word" | tr '[:lower:]' '[:upper:]')"; then
      meaningful_words+=("$word")
    fi
  done

  if [[ ${#meaningful_words[@]} -gt 0 ]]; then
    local max_words=3
    [[ ${#meaningful_words[@]} -eq 4 ]] && max_words=4
    local result="" count=0
    for word in "${meaningful_words[@]}"; do
      (( count >= max_words )) && break
      [[ -n "$result" ]] && result="$result-"
      result="$result$word"
      count=$((count + 1))
    done
    echo "$result"
  else
    local result
    result=$(clean_branch_name "$description")
    local -a words=()
    IFS='-' read -ra words <<< "$result"
    local out="" count=0
    for word in "${words[@]}"; do
      [[ -z "$word" ]] && continue
      (( count >= 3 )) && break
      [[ -n "$out" ]] && out="$out-"
      out="$out$word"
      count=$((count + 1))
    done
    echo "$out"
  fi
}

# --- Main logic ---

fallback_root=$(find_repository_root "$SCRIPT_DIR") || {
  echo "Error: Could not determine repository root." >&2
  exit 1
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) && has_git_flag=true || {
  repo_root="$fallback_root"
  has_git_flag=false
}

cd "$repo_root"

specs_dir="$repo_root/specs"
mkdir -p "$specs_dir"

# Generate branch suffix
if [[ -n "$SHORT_NAME" ]]; then
  branch_suffix=$(clean_branch_name "$SHORT_NAME")
else
  branch_suffix=$(get_branch_name "$FEATURE_DESC")
fi

# Determine YYMM prefix
yymm=$(date +%y%m)

# Determine branch number
if [[ "$NUMBER" -eq 0 ]]; then
  if $has_git_flag; then
    NUMBER=$(get_next_branch_number "$specs_dir" "$yymm")
  else
    NUMBER=$(( $(get_highest_number_from_specs "$specs_dir" "$yymm") + 1 ))
  fi
fi

feature_num=$(printf '%s-%03d' "$yymm" "$NUMBER")
branch_name="$feature_num-$branch_suffix"

# Validate branch name length (GitHub 244-byte limit)
max_branch_length=244
if [[ ${#branch_name} -gt $max_branch_length ]]; then
  max_suffix_length=$(( max_branch_length - 9 ))
  truncated_suffix="${branch_suffix:0:$max_suffix_length}"
  truncated_suffix="${truncated_suffix%-}"
  original_branch_name="$branch_name"
  branch_name="$feature_num-$truncated_suffix"
  echo "[specify] Branch name exceeded GitHub's 244-byte limit" >&2
  echo "[specify] Original: $original_branch_name (${#original_branch_name} bytes)" >&2
  echo "[specify] Truncated to: $branch_name (${#branch_name} bytes)" >&2
fi

# Create git branch
if $has_git_flag; then
  git checkout -b "$branch_name" 2>/dev/null \
    || echo "WARNING: Failed to create git branch: $branch_name" >&2
else
  echo "[specify] Warning: Git repository not detected; skipped branch creation for $branch_name" >&2
fi

feature_dir="$specs_dir/$branch_name"
mkdir -p "$feature_dir"

template="$repo_root/.specify/templates/spec-template.md"
spec_file="$feature_dir/spec.md"
if [[ -f "$template" ]]; then
  cp "$template" "$spec_file"
else
  touch "$spec_file"
fi

# Set environment variable for current session
export SPECIFY_FEATURE="$branch_name"

if $JSON; then
  echo "{\"BRANCH\":\"$(json_escape "$branch_name")\",\"SPEC_FILE\":\"$(json_escape "$spec_file")\",\"FEATURE_NUM\":\"$(json_escape "$feature_num")\",\"HAS_GIT\":$has_git_flag}"
else
  echo "BRANCH: $branch_name"
  echo "SPEC_FILE: $spec_file"
  echo "FEATURE_NUM: $feature_num"
  echo "HAS_GIT: $has_git_flag"
  echo "SPECIFY_FEATURE environment variable set to: $branch_name"
fi
