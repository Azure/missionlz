#!/usr/bin/env bash
# Common bash functions for specify scripts

get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null \
    || (cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
}

get_current_branch() {
  # First check SPECIFY_FEATURE environment variable
  if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
    echo "$SPECIFY_FEATURE"
    return
  fi

  # Then check git
  local branch
  if branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
    echo "$branch"
    return
  fi

  # For non-git repos, find the latest feature directory
  local repo_root specs_dir
  repo_root=$(get_repo_root)
  specs_dir="$repo_root/specs"

  if [[ -d "$specs_dir" ]]; then
    local latest_feature="" latest_prefix=""
    for dir in "$specs_dir"/*/; do
      [[ -d "$dir" ]] || continue
      local name
      name=$(basename "$dir")
      if [[ "$name" =~ ^([0-9]{4}-[0-9]{3}(\.[0-9]+)?)- ]]; then
        local prefix="${BASH_REMATCH[1]}"
        if [[ "$prefix" > "$latest_prefix" ]]; then
          latest_prefix="$prefix"
          latest_feature="$name"
        fi
      fi
    done
    if [[ -n "$latest_feature" ]]; then
      echo "$latest_feature"
      return
    fi
  fi

  echo "main"
}

has_git() {
  git rev-parse --show-toplevel >/dev/null 2>&1
}

test_feature_branch() {
  local branch="$1"
  local has_git_flag="${2:-true}"

  if [[ "$has_git_flag" != "true" ]]; then
    echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
    return 0
  fi

  if [[ ! "$branch" =~ ^[0-9]{4}-[0-9]{3}(\.[0-9]+)?- ]]; then
    echo "ERROR: Not on a feature branch. Current branch: $branch"
    echo "Feature branches should be named like: 2602-001-feature-name or 2602-001.1-feature-name (YYMM-NNN[.N] format)"
    return 1
  fi
  return 0
}

get_feature_dir() {
  echo "$1/specs/$2"
}

# Sets global variables for feature paths
set_feature_paths() {
  REPO_ROOT=$(get_repo_root)
  CURRENT_BRANCH=$(get_current_branch)
  HAS_GIT=$(has_git && echo "true" || echo "false")
  FEATURE_DIR=$(get_feature_dir "$REPO_ROOT" "$CURRENT_BRANCH")
  FEATURE_SPEC="$FEATURE_DIR/spec.md"
  DESIGN="$FEATURE_DIR/design.md"
  IMPLEMENTATION_PLAN="$FEATURE_DIR/implementation-plan.md"
  TASKS="$FEATURE_DIR/tasks.md"
  RESEARCH="$FEATURE_DIR/research.md"
  DATA_MODEL="$FEATURE_DIR/data-model.md"
  QUICKSTART="$FEATURE_DIR/quickstart.md"
  CONTRACTS_DIR="$FEATURE_DIR/contracts"
}

test_file_exists() {
  local path="$1" description="$2"
  if [[ -f "$path" ]]; then
    echo "  ✓ $description"
    return 0
  else
    echo "  ✗ $description"
    return 1
  fi
}

test_dir_has_files() {
  local path="$1" description="$2"
  if [[ -d "$path" ]] && [[ -n "$(ls -A "$path" 2>/dev/null)" ]]; then
    echo "  ✓ $description"
    return 0
  else
    echo "  ✗ $description"
    return 1
  fi
}

# JSON string escape helper
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  echo "$s"
}

# --- Frontmatter parsing utilities ---

# Extract YAML frontmatter block from a markdown file (between --- delimiters)
# Usage: parse_frontmatter /path/to/file.md
# Returns: raw YAML frontmatter lines (without --- delimiters)
parse_frontmatter() {
  local file="$1"
  [[ -f "$file" ]] || return 1

  local in_frontmatter=false
  local started=false
  while IFS= read -r line; do
    line="${line%$'\r'}"
    if [[ "$line" == "---" ]]; then
      if $in_frontmatter; then
        return 0  # end of frontmatter
      elif ! $started; then
        in_frontmatter=true
        started=true
        continue
      fi
    fi
    if $in_frontmatter; then
      printf '%s\n' "$line"
    fi
  done < "$file"
}

# Get a single frontmatter field value from a markdown file
# Usage: get_frontmatter_field /path/to/file.md "status"
# Returns: field value (unquoted), or empty string if not found
get_frontmatter_field() {
  local file="$1"
  local field="$2"
  local line value=""

  while IFS= read -r line; do
    [[ "$line" == "$field:"* ]] || continue
    value="${line#"$field:"}"
    value="${value#"${value%%[![:space:]]*}"}"
    if [[ "$value" =~ ^\"(.*)\"[[:space:]]*(#.*)?$ ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ^\'(.*)\'[[:space:]]*(#.*)?$ ]]; then
      value="${BASH_REMATCH[1]}"
    else
      value="${value%%[[:space:]]#*}"
    fi
    printf '%s\n' "$value"
    return
  done < <(parse_frontmatter "$file")

  printf '\n'
}

# Count tasks in a tasks.md file
# Usage: count_tasks /path/to/tasks.md
# Returns: JSON object {"total": N, "done": N, "remaining": N}
count_tasks() {
  local file="$1"
  [[ -f "$file" ]] || { echo '{"total":0,"done":0,"remaining":0}'; return; }

  local total=0 done=0
  local in_fence=false
  local fence_regex='^[[:space:]]*(```|~~~)'
  while IFS= read -r line; do
    if [[ "$line" =~ $fence_regex ]]; then
      if $in_fence; then
        in_fence=false
      else
        in_fence=true
      fi
      continue
    fi

    if $in_fence; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]xX]\] ]]; then
      total=$((total + 1))
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[xX]\] ]]; then
        done=$((done + 1))
      fi
    fi
  done < "$file"

  local remaining=$((total - done))
  echo "{\"total\":$total,\"done\":$done,\"remaining\":$remaining}"
}

# Extract YYMM-NNN or YYMM-NNN.N spec ID from a directory name
# Usage: get_spec_id_from_dir "2602-001.1-user-auth"
# Returns: the spec ID or empty if not a spec directory
get_spec_id_from_dir() {
  local dirname="$1"
  if [[ "$dirname" =~ ^([0-9]{4}-[0-9]{3}(\.[0-9]+)?)(-.+)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

# Check if a spec ID is a sub-spec (has .N suffix)
# Usage: is_sub_spec "2602-001.1"
# Returns: 0 (true) or 1 (false)
is_sub_spec() {
  local spec_id="$1"
  [[ "$spec_id" =~ ^[0-9]{4}-[0-9]{3}\.[0-9]+$ ]]
}

# Get parent ID from a sub-spec ID
# Usage: get_parent_id "2602-001.1"
# Returns: "2602-001" or empty if not a sub-spec
get_parent_id() {
  local spec_id="$1"
  if is_sub_spec "$spec_id"; then
    echo "${spec_id%.*}"
  fi
}
