#!/usr/bin/env bash
# generate-commands.sh — Build tool-specific command files from shared prompts
#
# Reads shared prompt bodies from .specify/prompts/ and generates:
#
#   Per-command:
#     .claude/commands/*.md                    Claude Code (YAML frontmatter + body)
#     .github/agents/*.agent.md               GitHub Copilot custom agents (name/description + body)
#     .cursor/skills/{name}/SKILL.md          Cursor Skills (plain markdown)
#     .agents/skills/{name}/SKILL.md          Codex Skills (skill frontmatter + body)
#
#   Repo-level instructions (from .specify/repo-instructions.md):
#     CLAUDE.md                                Claude Code
#     AGENTS.md                                GitHub Copilot Coding Agent and Codex
#
# Usage:
#   bash .specify/scripts/bash/generate-commands.sh           # generate all
#   bash .specify/scripts/bash/generate-commands.sh --check   # CI validation
#
# The --check flag compares generated output against committed files and exits
# non-zero if anything is stale. Useful as a pre-commit hook or CI step.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
  || REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

PROMPTS_DIR="$REPO_ROOT/.specify/prompts"
CLAUDE_OUT="$REPO_ROOT/.claude/commands"
COPILOT_OUT="$REPO_ROOT/.github/agents"
CURSOR_OUT="$REPO_ROOT/.cursor/skills"
CODEX_OUT="$REPO_ROOT/.agents/skills"

ENABLE_CLAUDE=false
ENABLE_COPILOT=false
ENABLE_CURSOR=false
ENABLE_CODEX=false

detect_enabled_tools() {
  if [[ -d "$REPO_ROOT/.claude" || -f "$REPO_ROOT/CLAUDE.md" ]]; then
    ENABLE_CLAUDE=true
  fi

  if [[ -d "$REPO_ROOT/.github/agents" ]]; then
    ENABLE_COPILOT=true
  fi

  if [[ -d "$REPO_ROOT/.cursor/skills" ]]; then
    ENABLE_CURSOR=true
  fi

  if [[ -d "$REPO_ROOT/.agents/skills" ]]; then
    ENABLE_CODEX=true
  fi
}

CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=true
fi

# Verify prompts directory exists
if [[ ! -d "$PROMPTS_DIR" ]]; then
  echo "ERROR: Prompts directory not found: $PROMPTS_DIR"
  echo "Expected shared prompt files at .specify/prompts/*.md"
  exit 1
fi

# Count prompt files (exclude sidecar yaml files)
prompt_count=0
for f in "$PROMPTS_DIR"/*.md; do
  [[ -f "$f" ]] && prompt_count=$((prompt_count + 1))
done

if [[ $prompt_count -eq 0 ]]; then
  echo "ERROR: No prompt files found in $PROMPTS_DIR"
  exit 1
fi

detect_enabled_tools

# Keep compatibility with legacy repos that only have AGENTS.md.
if [[ -f "$REPO_ROOT/AGENTS.md" ]] && ! $ENABLE_COPILOT && ! $ENABLE_CODEX; then
  ENABLE_COPILOT=true
  ENABLE_CODEX=true
fi

if ! $ENABLE_CLAUDE && ! $ENABLE_COPILOT && ! $ENABLE_CURSOR && ! $ENABLE_CODEX; then
  echo "No AI tool outputs detected (.claude, .github/agents, .cursor/skills, .agents/skills)."
  if $CHECK_MODE; then
    echo "Skipping generated command drift check for tool-specific outputs."
  else
    echo "Nothing to generate for tool-specific outputs."
  fi
  exit 0
fi

$ENABLE_CLAUDE && mkdir -p "$CLAUDE_OUT"
$ENABLE_COPILOT && mkdir -p "$COPILOT_OUT"
$ENABLE_CURSOR && mkdir -p "$CURSOR_OUT"
$ENABLE_CODEX && mkdir -p "$CODEX_OUT"

stale=0
generated=0

# Helper: compare tmp file against output, report stale or copy
check_or_generate() {
  local label="$1" tmp_file="$2" out_file="$3"
  if $CHECK_MODE; then
    if [[ ! -f "$out_file" ]]; then
      echo "MISSING: $label"
      stale=1
    elif ! diff -q <(tr -d '\r' < "$tmp_file") <(tr -d '\r' < "$out_file") >/dev/null 2>&1; then
      echo "STALE:   $label"
      stale=1
    fi
  else
    mkdir -p "$(dirname "$out_file")"
    if [[ -f "$out_file" ]] && grep -q $'\r' "$out_file"; then
      tr -d '\r' < "$tmp_file" | sed 's/$/\r/' > "$out_file"
    else
      tr -d '\r' < "$tmp_file" > "$out_file"
    fi
  fi
}

# --- Generate per-command files ---

for prompt_file in "$PROMPTS_DIR"/*.md; do
  [[ -f "$prompt_file" ]] || continue

  name="$(basename "$prompt_file" .md)"
  claude_yaml="$PROMPTS_DIR/$name.claude.yaml"
  copilot_yaml="$PROMPTS_DIR/$name.copilot.yaml"
  claude_out_file="$CLAUDE_OUT/$name.md"
  copilot_out_file="$COPILOT_OUT/$name.agent.md"
  cursor_out_file="$CURSOR_OUT/$name/SKILL.md"
  codex_out_file="$CODEX_OUT/$name/SKILL.md"

  # Extract description from claude.yaml (first description: line)
  description=""
  if [[ -f "$claude_yaml" ]]; then
    description="$(tr -d '\r' < "$claude_yaml" | grep -m1 '^description:' | sed 's/^description:[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//')"
  fi

  # Derive Copilot agent name: dots → hyphens (e.g., ais.spec.specify → ais-spec-specify)
  agent_name="${name//./-}"

  # Map the Claude model-tier shorthand (model: haiku|sonnet|opus in the
  # claude.yaml) to the Copilot model-picker display name. Honored by Copilot
  # in VS Code/JetBrains/Eclipse/Xcode; the Copilot CLI and cloud agent ignore
  # it (cloud agent picks the model at task launch). Update display names here
  # when GitHub rotates supported models. Cursor and Codex skills have no
  # per-skill model support, so no mapping is emitted for them.
  copilot_model=""
  if [[ -f "$claude_yaml" ]]; then
    claude_model="$(tr -d '\r' < "$claude_yaml" | sed -n 's/^model:[[:space:]]*//p' | head -1)"
    case "$claude_model" in
      haiku)  copilot_model="Claude Haiku 4.5" ;;
      sonnet) copilot_model="Claude Sonnet 4.6" ;;
      opus)   copilot_model="Claude Opus 4.8" ;;
    esac
  fi

  # Build Claude command: YAML frontmatter + prompt body
  build_claude() {
    if [[ -f "$claude_yaml" ]]; then
      echo "---"
      cat "$claude_yaml"
      echo "---"
    fi
    echo ""
    echo "<!-- Generated from .specify/prompts/$name.md — do not edit directly -->"
    echo ""
    cat "$prompt_file"
  }

  # Build Copilot agent: name/description/handoffs frontmatter + prompt body
  build_copilot() {
    echo "---"
    if [[ -f "$copilot_yaml" ]]; then
      cat "$copilot_yaml"
    else
      echo "name: \"$agent_name\""
      [[ -n "$copilot_model" ]] && echo "model: ${copilot_model}"
      if [[ -f "$claude_yaml" ]]; then
        # Reuse description and handoffs from the Claude sidecar.
        # Strip allowed-tools and the Claude-shorthand model key (translated
        # to a Copilot display name above) and convert agent name dots to
        # hyphens in handoff entries.
        sed -e '/^allowed-tools:/d' \
            -e '/^model:/d' \
            -e '/^    agent: /s/\./-/g' \
            "$claude_yaml"
      else
        echo "description: \"$description\""
      fi
    fi
    echo "---"
    echo ""
    echo "<!-- Generated from .specify/prompts/$name.md — do not edit directly -->"
    echo ""
    cat "$prompt_file"
  }

  # Build Cursor skill: plain markdown (no frontmatter)
  build_cursor() {
    echo "<!-- Generated from .specify/prompts/$name.md — do not edit directly -->"
    echo ""
    cat "$prompt_file"
  }

  # Build Codex skill: skill frontmatter + prompt body
  build_codex() {
    echo "---"
    echo "name: $name"
    echo "description: $description"
    echo "---"
    echo ""
    echo "<!-- Generated from .specify/prompts/$name.md — do not edit directly -->"
    echo ""
    cat "$prompt_file"
  }

  tmp_claude=$(mktemp)
  tmp_copilot=$(mktemp)
  tmp_cursor=$(mktemp)
  tmp_codex=$(mktemp)

  build_claude > "$tmp_claude"
  build_copilot > "$tmp_copilot"
  build_cursor > "$tmp_cursor"
  build_codex > "$tmp_codex"

  $ENABLE_CLAUDE && check_or_generate ".claude/commands/$name.md" "$tmp_claude" "$claude_out_file"
  $ENABLE_COPILOT && check_or_generate ".github/agents/$name.agent.md" "$tmp_copilot" "$copilot_out_file"
  $ENABLE_CURSOR && check_or_generate ".cursor/skills/$name/SKILL.md" "$tmp_cursor" "$cursor_out_file"
  $ENABLE_CODEX && check_or_generate ".agents/skills/$name/SKILL.md" "$tmp_codex" "$codex_out_file"

  rm -f "$tmp_claude" "$tmp_copilot" "$tmp_cursor" "$tmp_codex"

  if ! $CHECK_MODE; then
    generated=$((generated + 1))
    echo "  $name"
  fi
done

# --- Generate repo-level instructions from .specify/repo-instructions.md ---

REPO_INSTRUCTIONS="$REPO_ROOT/.specify/repo-instructions.md"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
AGENTS_MD="$REPO_ROOT/AGENTS.md"

if [[ -f "$REPO_INSTRUCTIONS" ]]; then
  HTML_HEADER="<!-- Generated from .specify/repo-instructions.md by generate-commands.sh — do not edit directly -->"

  build_with_html_header() {
    echo "$HTML_HEADER"
    echo ""
    cat "$REPO_INSTRUCTIONS"
  }

  if $ENABLE_CLAUDE || [[ -f "$CLAUDE_MD" ]]; then
    tmp=$(mktemp)
    build_with_html_header > "$tmp"
    check_or_generate "CLAUDE.md" "$tmp" "$CLAUDE_MD"
    if ! $CHECK_MODE; then echo "  CLAUDE.md"; fi
    rm -f "$tmp"
  fi

  if $ENABLE_COPILOT || $ENABLE_CODEX || [[ -f "$AGENTS_MD" ]]; then
    tmp=$(mktemp)
    build_with_html_header > "$tmp"
    check_or_generate "AGENTS.md" "$tmp" "$AGENTS_MD"
    if ! $CHECK_MODE; then echo "  AGENTS.md"; fi
    rm -f "$tmp"
  fi

else
  echo "WARNING: .specify/repo-instructions.md not found — skipping repo-level instructions"
fi

# --- Report ---

if $CHECK_MODE; then
  if [[ $stale -eq 1 ]]; then
    echo ""
    echo "Generated command files are out of date."
    echo "Run: bash .specify/scripts/bash/generate-commands.sh"
    exit 1
  else
    echo "All generated command files are up to date."
  fi
else
  echo ""
  echo "Generated $generated command(s) for configured AI tools."
  $ENABLE_CLAUDE && echo "  Claude:  .claude/commands/"
  $ENABLE_COPILOT && echo "  Copilot: .github/agents/"
  $ENABLE_CURSOR && echo "  Cursor:  .cursor/skills/"
  $ENABLE_CODEX && echo "  Codex:   .agents/skills/"

  # Clean up old .cursor/rules/*.mdc files (migrated to Skills)
  if [[ -d "$REPO_ROOT/.cursor/rules" ]]; then
    rm -f "$REPO_ROOT/.cursor/rules"/*.mdc
    rmdir "$REPO_ROOT/.cursor/rules" 2>/dev/null || true
  fi
fi
