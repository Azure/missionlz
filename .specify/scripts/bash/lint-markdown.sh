#!/usr/bin/env bash
# Lint and optionally fix markdown files using markdownlint-cli2
#
# Usage:
#   lint-markdown.sh [--fix] [--check] <file-or-dir> [<file-or-dir> ...]
#
# Options:
#   --fix     Auto-fix fixable lint issues (runs twice for full effect)
#   --check   Check mode: exit with error if files don't pass linting (default)
#   --quiet   Suppress output (only exit code matters)
#
# Returns:
#   0 if all files pass linting (or were fixed)
#   1 if linting errors remain after checking/fixing

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root)

# Parse arguments
FIX_MODE=false
QUIET_MODE=false
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix)
      FIX_MODE=true
      shift
      ;;
    --quiet)
      QUIET_MODE=true
      shift
      ;;
    --check)
      # Default mode, just skip it
      shift
      ;;
    *)
      FILES+=("$1")
      shift
      ;;
  esac
done

# Validate we have files to check
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "Error: No files or directories specified" >&2
  exit 1
fi

# Check if markdownlint-cli2 is available (via npx or global install)
if ! command -v markdownlint-cli2 &>/dev/null && ! command -v npx &>/dev/null; then
  echo "Warning: markdownlint-cli2 and npx not found. Skipping markdown linting." >&2
  echo "Install Node.js and run: npm install -g markdownlint-cli2" >&2
  exit 0
fi

# Determine how to run markdownlint-cli2
if command -v markdownlint-cli2 &>/dev/null; then
  MARKDOWN_LINT_CMD="markdownlint-cli2"
else
  MARKDOWN_LINT_CMD="npx markdownlint-cli2"
fi

# Build file patterns for markdownlint-cli2
PATTERNS=()
for item in "${FILES[@]}"; do
  if [[ -d "$item" ]]; then
    # For directories, add glob pattern to match .md files recursively
    PATTERNS+=("$item/**/*.md")
  elif [[ -f "$item" ]]; then
    # For files, use as-is
    PATTERNS+=("$item")
  else
    echo "Warning: Path does not exist: $item" >&2
  fi
done

# Run markdownlint-cli2
# Note: The tool by default fails on errors, so we need to capture that
cd "$REPO_ROOT"

if [[ "$FIX_MODE" == true ]]; then
  if [[ "$QUIET_MODE" != true ]]; then
    echo "Linting and fixing markdown files..."
  fi
  
  # Run with --fix flag (may need to run twice for full effect)
  # We capture the output to avoid showing it in quiet mode
  if ! $MARKDOWN_LINT_CMD --fix "${PATTERNS[@]}" 2>&1 | {
    if [[ "$QUIET_MODE" != true ]]; then
      cat
    else
      grep -i "error" || true
    fi
  }; then
    # First pass fixed some issues; try again to catch cascading fixes
    if ! $MARKDOWN_LINT_CMD --fix "${PATTERNS[@]}" >/dev/null 2>&1; then
      if [[ "$QUIET_MODE" != true ]]; then
        echo "✓ Markdown linting and fixes applied (some warnings may remain)"
      fi
    fi
  fi
  
  # After fixing, validate that files pass
  if $MARKDOWN_LINT_CMD "${PATTERNS[@]}" >/dev/null 2>&1; then
    if [[ "$QUIET_MODE" != true ]]; then
      echo "✓ All markdown files pass linting"
    fi
    exit 0
  else
    if [[ "$QUIET_MODE" != true ]]; then
      echo "✗ Markdown linting errors remain after --fix:"
      $MARKDOWN_LINT_CMD "${PATTERNS[@]}" || true
    fi
    exit 1
  fi
else
  # Check-only mode
  if [[ "$QUIET_MODE" != true ]]; then
    echo "Checking markdown files..."
  fi
  
  if $MARKDOWN_LINT_CMD "${PATTERNS[@]}" 2>&1 | {
    if [[ "$QUIET_MODE" != true ]]; then
      cat
    else
      cat >/dev/null
    fi
  }; then
    if [[ "$QUIET_MODE" != true ]]; then
      echo "✓ All markdown files pass linting"
    fi
    exit 0
  else
    if [[ "$QUIET_MODE" != true ]]; then
      echo "✗ Markdown linting errors found"
      echo "To fix: bash .specify/scripts/bash/lint-markdown.sh --fix <file-or-dir>"
    fi
    exit 1
  fi
fi
