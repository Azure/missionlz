#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=true; shift ;;
    --help|-h)
      echo "Usage: setup-design.sh [--json] [--help]"
      echo "  --json     Output results in JSON format"
      echo "  --help     Show this help message"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

set_feature_paths

test_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1

mkdir -p "$FEATURE_DIR"

template="$REPO_ROOT/.specify/templates/design-template.md"
if [[ -f "$template" ]]; then
  cp "$template" "$DESIGN"
  echo "Copied design template to $DESIGN"
else
  echo "WARNING: Design template not found at $template" >&2
  touch "$DESIGN"
fi

if $JSON; then
  echo "{\"FEATURE_SPEC\":\"$(json_escape "$FEATURE_SPEC")\",\"DESIGN\":\"$(json_escape "$DESIGN")\",\"FEATURE_DIR\":\"$(json_escape "$FEATURE_DIR")\",\"BRANCH\":\"$(json_escape "$CURRENT_BRANCH")\",\"HAS_GIT\":$HAS_GIT}"
else
  echo "FEATURE_SPEC: $FEATURE_SPEC"
  echo "DESIGN: $DESIGN"
  echo "FEATURE_DIR: $FEATURE_DIR"
  echo "BRANCH: $CURRENT_BRANCH"
  echo "HAS_GIT: $HAS_GIT"
fi
