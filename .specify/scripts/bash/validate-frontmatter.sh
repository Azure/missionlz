#!/usr/bin/env bash
# validate-frontmatter.sh — Validate YAML frontmatter in spec.md files
#
# Checks all specs/*/spec.md files for:
#   - Required fields present
#   - Field values match allowed enums
#   - Spec ID format (YYMM-NNN or YYMM-NNN.N)
#   - Date format (YYYY-MM-DD)
#   - Dependency references resolve to existing spec IDs
#
# Usage:
#   bash .specify/scripts/bash/validate-frontmatter.sh          # validate all
#   bash .specify/scripts/bash/validate-frontmatter.sh --json   # JSON output
#
# Exit codes:
#   0 — all specs valid
#   1 — validation errors found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root)
SPECS_DIR="$REPO_ROOT/specs"
JSON_MODE=false
ERRORS=()
WARNINGS=()
CHECKED=0
PASSED=0

for arg in "$@"; do
  case "$arg" in
    --json) JSON_MODE=true ;;
  esac
done

# --- Validation helpers ---

add_error() {
  local file="$1" field="$2" message="$3"
  ERRORS+=("${file}|${field}|${message}")
}

add_warning() {
  local file="$1" field="$2" message="$3"
  WARNINGS+=("${file}|${field}|${message}")
}

validate_enum() {
  local file="$1" field="$2" value="$3"
  shift 3
  local allowed=("$@")

  if [[ -z "$value" ]]; then
    return 0  # empty is handled by required-field check
  fi

  for v in "${allowed[@]}"; do
    if [[ "$value" == "$v" ]]; then
      return 0
    fi
  done

  add_error "$file" "$field" "Invalid value '$value'. Allowed: ${allowed[*]}"
}

validate_date() {
  local file="$1" field="$2" value="$3"

  if [[ -z "$value" ]]; then
    return 0
  fi

  if [[ ! "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    add_error "$file" "$field" "Invalid date format '$value'. Expected YYYY-MM-DD"
  fi
}

validate_spec_id() {
  local file="$1" value="$2"

  if [[ -z "$value" ]]; then
    add_error "$file" "id" "Missing required field 'id'"
    return
  fi

  if [[ ! "$value" =~ ^[0-9]{4}-[0-9]{3}(\.[0-9]+)?$ ]]; then
    add_error "$file" "id" "Invalid spec ID format '$value'. Expected YYMM-NNN or YYMM-NNN.N"
  fi
}

# Collect all valid spec IDs for dependency resolution
collect_spec_ids() {
  local ids=()
  for dir in "$SPECS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local dirname
    dirname=$(basename "$dir")
    local sid
    sid=$(get_spec_id_from_dir "$dirname")
    if [[ -n "$sid" ]]; then
      ids+=("$sid")
    fi
  done
  echo "${ids[@]}"
}

validate_dependencies() {
  local file="$1" deps_raw="$2"
  local known_ids
  known_ids=$(collect_spec_ids)

  # Strip brackets and split by comma
  deps_raw="${deps_raw#[}"
  deps_raw="${deps_raw%]}"
  deps_raw=$(echo "$deps_raw" | tr -d '"' | tr -d "'")

  if [[ -z "$deps_raw" ]]; then
    return 0
  fi

  IFS=',' read -ra deps <<< "$deps_raw"
  for dep in "${deps[@]}"; do
    dep=$(echo "$dep" | xargs)  # trim whitespace
    [[ -z "$dep" ]] && continue

    if [[ ! "$dep" =~ ^[0-9]{4}-[0-9]{3}(\.[0-9]+)?$ ]]; then
      add_error "$file" "dependencies" "Invalid dependency format '$dep'. Expected YYMM-NNN or YYMM-NNN.N"
      continue
    fi

    local found=false
    for kid in $known_ids; do
      if [[ "$kid" == "$dep" ]]; then
        found=true
        break
      fi
    done

    if [[ "$found" != "true" ]]; then
      add_warning "$file" "dependencies" "Dependency '$dep' does not match any known spec directory"
    fi
  done
}

# --- Main validation ---

validate_spec() {
  local file="$1"
  local rel_path="${file#"$REPO_ROOT/"}"

  # Check frontmatter exists
  local fm
  fm=$(parse_frontmatter "$file")
  if [[ -z "$fm" ]]; then
    add_error "$rel_path" "frontmatter" "No YAML frontmatter found (missing --- delimiters)"
    return
  fi

  # Required fields
  local required_fields=("id" "title" "status" "created" "updated")
  for field in "${required_fields[@]}"; do
    local value
    value=$(get_frontmatter_field "$file" "$field")
    if [[ -z "$value" ]]; then
      add_error "$rel_path" "$field" "Missing required field '$field'"
    fi
  done

  # Spec ID format
  local id
  id=$(get_frontmatter_field "$file" "id")
  validate_spec_id "$rel_path" "$id"

  # Spec ID matches directory name
  local dir_name
  dir_name=$(basename "$(dirname "$file")")
  local dir_id
  dir_id=$(get_spec_id_from_dir "$dir_name")
  if [[ -n "$id" && -n "$dir_id" && "$id" != "$dir_id" ]]; then
    add_error "$rel_path" "id" "Spec ID '$id' does not match directory ID '$dir_id'"
  fi

  # Status enum
  local status
  status=$(get_frontmatter_field "$file" "status")
  validate_enum "$rel_path" "status" "$status" \
    "draft" "defining" "planning" "ready" "in-dev" "complete" "blocked"

  # Priority enum (optional but must be valid if present)
  local priority
  priority=$(get_frontmatter_field "$file" "priority")
  if [[ -n "$priority" ]]; then
    validate_enum "$rel_path" "priority" "$priority" \
      "P1" "P2" "P3" "backlog"
  fi

  # Effort enum (optional but must be valid if present)
  local effort
  effort=$(get_frontmatter_field "$file" "effort")
  if [[ -n "$effort" ]]; then
    validate_enum "$rel_path" "effort" "$effort" \
      "S" "M" "L" "XL"
  fi

  # Source authority enum (optional but must be valid if present)
  local authority
  authority=$(get_frontmatter_field "$file" "source-authority")
  if [[ -n "$authority" ]]; then
    validate_enum "$rel_path" "source-authority" "$authority" \
      "T1" "T2" "T3" "T4" "T5" "T6"
  fi

  # Date formats
  local created updated
  created=$(get_frontmatter_field "$file" "created")
  updated=$(get_frontmatter_field "$file" "updated")
  validate_date "$rel_path" "created" "$created"
  validate_date "$rel_path" "updated" "$updated"

  # Dependencies resolve
  local deps_raw
  deps_raw=$(parse_frontmatter "$file" | grep -m1 "^dependencies:" | sed 's/^dependencies:[[:space:]]*//' || true)
  if [[ -n "$deps_raw" ]]; then
    validate_dependencies "$rel_path" "$deps_raw"
  fi
}

# Find and validate all spec.md files
spec_files=()
for dir in "$SPECS_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  local_name=$(basename "$dir")

  # Skip hidden directories (.presales, .project-plan, .architecture)
  [[ "$local_name" == .* ]] && continue

  spec_file="${dir}spec.md"
  if [[ -f "$spec_file" ]]; then
    spec_files+=("$spec_file")
  fi
done

for spec_file in "${spec_files[@]}"; do
  CHECKED=$((CHECKED + 1))
  validate_spec "$spec_file"
done

# Count errors per file to determine passed count
declare -A file_errors
for err in "${ERRORS[@]}"; do
  IFS='|' read -r efile _ _ <<< "$err"
  file_errors["$efile"]=1
done
for spec_file in "${spec_files[@]}"; do
  rel="${spec_file#"$REPO_ROOT/"}"
  if [[ -z "${file_errors[$rel]:-}" ]]; then
    PASSED=$((PASSED + 1))
  fi
done

# --- Output ---

error_count=${#ERRORS[@]}
warning_count=${#WARNINGS[@]}

if $JSON_MODE; then
  echo "{"
  echo "  \"checked\": $CHECKED,"
  echo "  \"passed\": $PASSED,"
  echo "  \"errors\": $error_count,"
  echo "  \"warnings\": $warning_count,"

  echo "  \"details\": ["
  first=true
  for err in "${ERRORS[@]}"; do
    IFS='|' read -r efile efield emsg <<< "$err"
    $first || echo ","
    first=false
    printf '    {"level":"error","file":"%s","field":"%s","message":"%s"}' \
      "$(json_escape "$efile")" "$(json_escape "$efield")" "$(json_escape "$emsg")"
  done
  for warn in "${WARNINGS[@]}"; do
    IFS='|' read -r wfile wfield wmsg <<< "$warn"
    $first || echo ","
    first=false
    printf '    {"level":"warning","file":"%s","field":"%s","message":"%s"}' \
      "$(json_escape "$wfile")" "$(json_escape "$wfield")" "$(json_escape "$wmsg")"
  done
  echo ""
  echo "  ]"
  echo "}"
else
  echo ""
  echo "=== Spec Frontmatter Validation ==="
  echo ""

  if [[ $CHECKED -eq 0 ]]; then
    echo "No spec.md files found in specs/*/"
    echo ""
    exit 0
  fi

  if [[ $error_count -gt 0 ]]; then
    echo "ERRORS:"
    for err in "${ERRORS[@]}"; do
      IFS='|' read -r efile efield emsg <<< "$err"
      echo "  ✗ $efile → $efield: $emsg"
    done
    echo ""
  fi

  if [[ $warning_count -gt 0 ]]; then
    echo "WARNINGS:"
    for warn in "${WARNINGS[@]}"; do
      IFS='|' read -r wfile wfield wmsg <<< "$warn"
      echo "  ⚠ $wfile → $wfield: $wmsg"
    done
    echo ""
  fi

  echo "Checked: $CHECKED | Passed: $PASSED | Errors: $error_count | Warnings: $warning_count"
  echo ""

  if [[ $error_count -gt 0 ]]; then
    echo "FAILED — fix errors above before merging"
  else
    echo "PASSED"
  fi
fi

# Exit with error if validation failed
if [[ $error_count -gt 0 ]]; then
  exit 1
fi
