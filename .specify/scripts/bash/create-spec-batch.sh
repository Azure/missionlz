#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
JSON_INPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_INPUT=true; shift ;;
    --help|-h)
      cat <<'HELP'
Usage: create-spec-batch.sh [--json]

Reads a JSON array from stdin and creates spec directories in batch.
Does NOT create git branches — directories stay on the current branch.

Options:
  --json    Required flag to confirm JSON input mode

Input (stdin):
  [
    {"title": "Core API Data Model", "short_name": "core-api-data-model"},
    {"title": "Dashboard UI", "short_name": "dashboard-ui"}
  ]

Output (stdout):
  JSON array with created spec info:
  [
    {"id": "2603-001", "dir": "specs/2603-001-core-api-data-model", "spec_file": "specs/2603-001-core-api-data-model/spec.md"},
    ...
  ]
HELP
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if ! $JSON_INPUT; then
  echo "Usage: echo '\$JSON_ARRAY' | bash create-spec-batch.sh --json" >&2
  exit 1
fi

# --- Helper functions (reused from create-new-feature.sh) ---

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

clean_branch_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//'
}

detect_python_cmd() {
  if command -v python3 >/dev/null 2>&1 && python3 -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(python3)
    return 0
  fi

  if command -v python >/dev/null 2>&1 && python -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(python)
    return 0
  fi

  if command -v py >/dev/null 2>&1 && py -3 -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(py -3)
    return 0
  fi

  if command -v py >/dev/null 2>&1 && py -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD=(py)
    return 0
  fi

  return 1
}

# --- Main logic ---

fallback_root=$(find_repository_root "$SCRIPT_DIR") || {
  echo "Error: Could not determine repository root." >&2
  exit 1
}

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) && has_git=true || {
  repo_root="$fallback_root"
  has_git=false
}

cd "$repo_root"

specs_dir="$repo_root/specs"
mkdir -p "$specs_dir"

# Determine YYMM prefix
yymm=$(date +%y%m)

# Find the starting number
if $has_git; then
  git fetch --all --prune 2>/dev/null || true
  highest_branch=$(get_highest_number_from_branches "$yymm")
  highest_spec=$(get_highest_number_from_specs "$specs_dir" "$yymm")
  start_num=$(( highest_branch > highest_spec ? highest_branch : highest_spec ))
else
  start_num=$(get_highest_number_from_specs "$specs_dir" "$yymm")
fi

# Read JSON from stdin
input_json=$(cat)

if ! detect_python_cmd; then
  echo "Error: Could not find a runnable Python interpreter. Tried: python3, python, py -3, py" >&2
  exit 1
fi

# Validate input is a JSON array
if ! echo "$input_json" | "${PYTHON_CMD[@]}" -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  echo "Error: Invalid JSON input" >&2
  exit 1
fi

# Extract entries count
entry_count=$(echo "$input_json" | "${PYTHON_CMD[@]}" -c "import sys,json; print(len(json.load(sys.stdin)))")

if [[ "$entry_count" -eq 0 ]]; then
  echo "[]"
  exit 0
fi

template="$repo_root/.specify/templates/spec-template.md"

# Process each entry and build output
current_num=$start_num
output="["
first=true

for i in $(seq 0 $((entry_count - 1))); do
  current_num=$((current_num + 1))

  # Extract title and short_name
  title=$(echo "$input_json" | "${PYTHON_CMD[@]}" -c "import sys,json; print(json.load(sys.stdin)[$i]['title'])")
  short_name=$(echo "$input_json" | "${PYTHON_CMD[@]}" -c "import sys,json; print(json.load(sys.stdin)[$i]['short_name'])")

  # Clean the short name
  short_name=$(clean_branch_name "$short_name")

  # Build the spec ID and directory name
  spec_id=$(printf '%s-%03d' "$yymm" "$current_num")
  dir_name="$spec_id-$short_name"
  feature_dir="$specs_dir/$dir_name"
  spec_file="$feature_dir/spec.md"

  # Create directory
  mkdir -p "$feature_dir"

  # Copy template
  if [[ -f "$template" ]]; then
    cp "$template" "$spec_file"
  else
    touch "$spec_file"
  fi

  # Build JSON output entry
  if ! $first; then
    output="$output,"
  fi
  first=false

  output="$output{\"id\":\"$(json_escape "$spec_id")\",\"title\":\"$(json_escape "$title")\",\"dir\":\"specs/$(json_escape "$dir_name")\",\"spec_file\":\"specs/$(json_escape "$dir_name")/spec.md\"}"

  echo "[specify] Created $feature_dir" >&2
done

output="$output]"
echo "$output"
