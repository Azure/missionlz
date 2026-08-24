#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
JSON=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
INCLUDE_SPEC=false
PATHS_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=true; shift ;;
    --require-tasks) REQUIRE_TASKS=true; shift ;;
    --include-tasks) INCLUDE_TASKS=true; shift ;;
    --include-spec) INCLUDE_SPEC=true; shift ;;
    --paths-only) PATHS_ONLY=true; shift ;;
    --help|-h)
      cat <<'HELP'
Usage: check-prerequisites.sh [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  --json               Output in JSON format
  --require-tasks      Require tasks.md to exist (for implementation phase)
  --include-tasks      Include tasks.md in AVAILABLE_DOCS list
  --include-spec       Include spec.md in AVAILABLE_DOCS list
  --paths-only         Only output path variables (no prerequisite validation)
  --help, -h           Show this help message

EXAMPLES:
  check-prerequisites.sh --json
  check-prerequisites.sh --json --require-tasks --include-tasks
  check-prerequisites.sh --json --require-tasks --include-tasks --include-spec
  check-prerequisites.sh --paths-only
HELP
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

set_feature_paths

test_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

# Paths-only mode
if $PATHS_ONLY; then
  if $JSON; then
    echo "{\"REPO_ROOT\":\"$(json_escape "$REPO_ROOT")\",\"BRANCH\":\"$(json_escape "$CURRENT_BRANCH")\",\"FEATURE_DIR\":\"$(json_escape "$FEATURE_DIR")\",\"FEATURE_SPEC\":\"$(json_escape "$FEATURE_SPEC")\",\"DESIGN\":\"$(json_escape "$DESIGN")\",\"IMPLEMENTATION_PLAN\":\"$(json_escape "$IMPLEMENTATION_PLAN")\",\"TASKS\":\"$(json_escape "$TASKS")\"}"
  else
    echo "REPO_ROOT: $REPO_ROOT"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "FEATURE_DIR: $FEATURE_DIR"
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "DESIGN: $DESIGN"
    echo "IMPLEMENTATION_PLAN: $IMPLEMENTATION_PLAN"
    echo "TASKS: $TASKS"
  fi
  exit 0
fi

# Validate required directories and files
if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "ERROR: Feature directory not found: $FEATURE_DIR"
  echo "Run /ais.spec.specify first to create the feature structure."
  exit 1
fi

if [[ ! -f "$DESIGN" ]]; then
  echo "ERROR: design.md not found in $FEATURE_DIR"
  echo "Run /ais.spec.design first to create the technical design."
  exit 1
fi

if $REQUIRE_TASKS && [[ ! -f "$TASKS" ]]; then
  echo "ERROR: tasks.md not found in $FEATURE_DIR"
  echo "Run /ais.spec.tasks first to create the task list."
  exit 1
fi

# Build list of available documents
docs=()
[[ -f "$RESEARCH" ]] && docs+=("research.md")
[[ -f "$DATA_MODEL" ]] && docs+=("data-model.md")
[[ -d "$CONTRACTS_DIR" ]] && [[ -n "$(ls -A "$CONTRACTS_DIR" 2>/dev/null)" ]] && docs+=("contracts/")
[[ -f "$QUICKSTART" ]] && docs+=("quickstart.md")
[[ -f "$IMPLEMENTATION_PLAN" ]] && docs+=("implementation-plan.md")
$INCLUDE_TASKS && [[ -f "$TASKS" ]] && docs+=("tasks.md")
$INCLUDE_SPEC && [[ -f "$FEATURE_SPEC" ]] && docs+=("spec.md")

# Output
if $JSON; then
  docs_json="["
  for i in "${!docs[@]}"; do
    [[ $i -gt 0 ]] && docs_json+=","
    docs_json+="\"${docs[$i]}\""
  done
  docs_json+="]"
  echo "{\"FEATURE_DIR\":\"$(json_escape "$FEATURE_DIR")\",\"AVAILABLE_DOCS\":$docs_json}"
else
  echo "FEATURE_DIR:$FEATURE_DIR"
  echo "AVAILABLE_DOCS:"
  test_file_exists "$RESEARCH" "research.md" || true
  test_file_exists "$DATA_MODEL" "data-model.md" || true
  test_dir_has_files "$CONTRACTS_DIR" "contracts/" || true
  test_file_exists "$QUICKSTART" "quickstart.md" || true
  test_file_exists "$IMPLEMENTATION_PLAN" "implementation-plan.md" || true
  $INCLUDE_TASKS && { test_file_exists "$TASKS" "tasks.md" || true; }
  $INCLUDE_SPEC && { test_file_exists "$FEATURE_SPEC" "spec.md" || true; }
fi
