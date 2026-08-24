#!/usr/bin/env bash
# Update agent context files with information from design.md
#
# Usage:
#   ./update-agent-context.sh [agent-type]
#
# If agent-type is omitted, updates all existing agent files.
# Valid types: claude, gemini, copilot, cursor-agent, qwen, opencode, codex,
#   windsurf, kilocode, auggie, roo, codebuddy, amp, shai, q, agy, bob, qoder
#
# For this repo, Codex support uses AGENTS.md for repo-wide instructions.
# Reusable Codex workflow skills live in .agents/skills/ and are generated
# separately from shared prompts by generate-commands.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

AGENT_TYPE="${1:-}"

# Validate agent type if provided
VALID_TYPES="claude gemini copilot cursor-agent qwen opencode codex windsurf kilocode auggie roo codebuddy amp shai q agy bob qoder"
if [[ -n "$AGENT_TYPE" ]]; then
  valid=false
  for t in $VALID_TYPES; do
    [[ "$t" == "$AGENT_TYPE" ]] && { valid=true; break; }
  done
  if ! $valid; then
    echo "ERROR: Unknown agent type '$AGENT_TYPE'" >&2
    echo "Expected: $VALID_TYPES" >&2
    exit 1
  fi
fi

set_feature_paths

DESIGN_FILE="$DESIGN"
NEW_PLAN="$DESIGN_FILE"

# Agent file paths
CLAUDE_FILE="$REPO_ROOT/CLAUDE.md"
GEMINI_FILE="$REPO_ROOT/GEMINI.md"
COPILOT_FILE="$REPO_ROOT/.github/agents/copilot-instructions.md"
CURSOR_FILE="$REPO_ROOT/.cursor/rules/specify-rules.mdc"
QWEN_FILE="$REPO_ROOT/QWEN.md"
AGENTS_FILE="$REPO_ROOT/AGENTS.md"
WINDSURF_FILE="$REPO_ROOT/.windsurf/rules/specify-rules.md"
KILOCODE_FILE="$REPO_ROOT/.kilocode/rules/specify-rules.md"
AUGGIE_FILE="$REPO_ROOT/.augment/rules/specify-rules.md"
ROO_FILE="$REPO_ROOT/.roo/rules/specify-rules.md"
CODEBUDDY_FILE="$REPO_ROOT/CODEBUDDY.md"
QODER_FILE="$REPO_ROOT/QODER.md"
AMP_FILE="$REPO_ROOT/AGENTS.md"
SHAI_FILE="$REPO_ROOT/SHAI.md"
Q_FILE="$REPO_ROOT/AGENTS.md"
AGY_FILE="$REPO_ROOT/.agent/rules/specify-rules.md"
BOB_FILE="$REPO_ROOT/AGENTS.md"

TEMPLATE_FILE="$REPO_ROOT/.specify/templates/agent-file-template.md"

# Parsed plan data
NEW_LANG=""
NEW_FRAMEWORK=""
NEW_DB=""
NEW_PROJECT_TYPE=""

info()    { echo "INFO: $1"; }
success() { echo "✓ $1"; }
warn_msg(){ echo "WARNING: $1" >&2; }
err()     { echo "ERROR: $1" >&2; }

validate_environment() {
  if [[ -z "$CURRENT_BRANCH" ]]; then
    err "Unable to determine current feature"
    if [[ "$HAS_GIT" == "true" ]]; then
      info "Make sure you're on a feature branch"
    else
      info "Set SPECIFY_FEATURE environment variable or create a feature first"
    fi
    exit 1
  fi
  if [[ ! -f "$NEW_PLAN" ]]; then
    err "No design.md found at $NEW_PLAN"
    info "Ensure you are working on a feature with a corresponding spec directory"
    if [[ "$HAS_GIT" != "true" ]]; then
      info "Use: export SPECIFY_FEATURE=your-feature-name or create a new feature first"
    fi
    exit 1
  fi
  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    warn_msg "Template file not found at $TEMPLATE_FILE — will use inline fallback for new agent files."
  fi
}

extract_plan_field() {
  local field_pattern="$1" plan_file="$2"
  [[ -f "$plan_file" ]] || return 0
  grep "^\*\*${field_pattern}\*\*: " "$plan_file" 2>/dev/null \
    | head -1 \
    | sed "s|^\*\*${field_pattern}\*\*: ||" \
    | while IFS= read -r val; do
        val="${val# }"
        val="${val% }"
        if [[ "$val" != "NEEDS CLARIFICATION" && "$val" != "N/A" ]]; then
          echo "$val"
        fi
      done
}

parse_plan_data() {
  local plan_file="$1"
  if [[ ! -f "$plan_file" ]]; then
    err "Plan file not found: $plan_file"
    return 1
  fi
  info "Parsing plan data from $plan_file"
  NEW_LANG=$(extract_plan_field "Language/Version" "$plan_file")
  NEW_FRAMEWORK=$(extract_plan_field "Primary Dependencies" "$plan_file")
  NEW_DB=$(extract_plan_field "Storage" "$plan_file")
  NEW_PROJECT_TYPE=$(extract_plan_field "Project Type" "$plan_file")

  [[ -n "$NEW_LANG" ]] && info "Found language: $NEW_LANG" || warn_msg "No language information found in plan"
  [[ -n "$NEW_FRAMEWORK" ]] && info "Found framework: $NEW_FRAMEWORK" || true
  [[ -n "$NEW_DB" && "$NEW_DB" != "N/A" ]] && info "Found database: $NEW_DB" || true
  [[ -n "$NEW_PROJECT_TYPE" ]] && info "Found project type: $NEW_PROJECT_TYPE" || true
  return 0
}

format_technology_stack() {
  local lang="${1:-}" framework="${2:-}"
  local -a parts=()
  [[ -n "$lang" && "$lang" != "NEEDS CLARIFICATION" ]] && parts+=("$lang")
  [[ -n "$framework" && "$framework" != "NEEDS CLARIFICATION" && "$framework" != "N/A" ]] && parts+=("$framework")
  [[ ${#parts[@]} -eq 0 ]] && return
  local IFS=" + "
  echo "${parts[*]}"
}

get_project_structure() {
  if [[ "${1:-}" == *web* ]]; then
    printf 'backend/\nfrontend/\ntests/'
  else
    printf 'src/\ntests/'
  fi
}

get_commands_for_language() {
  case "${1:-}" in
    *Python*)                    echo "cd src; pytest; ruff check ." ;;
    *Rust*)                      echo "cargo test; cargo clippy" ;;
    *JavaScript*|*TypeScript*)   echo "npm test; npm run lint" ;;
    *)                           echo "# Add commands for ${1:-unknown}" ;;
  esac
}

get_language_conventions() {
  if [[ -n "${1:-}" ]]; then
    echo "$1: Follow standard conventions"
  else
    echo "General: Follow standard conventions"
  fi
}

new_agent_file() {
  local target_file="$1" project_name="$2" date_str="$3"

  local tech_entry=""
  if [[ -n "$NEW_LANG" && -n "$NEW_FRAMEWORK" ]]; then
    tech_entry="- $NEW_LANG + $NEW_FRAMEWORK ($CURRENT_BRANCH)"
  elif [[ -n "$NEW_LANG" ]]; then
    tech_entry="- $NEW_LANG ($CURRENT_BRANCH)"
  elif [[ -n "$NEW_FRAMEWORK" ]]; then
    tech_entry="- $NEW_FRAMEWORK ($CURRENT_BRANCH)"
  fi

  local change_entry=""
  if [[ -n "$NEW_LANG" && -n "$NEW_FRAMEWORK" ]]; then
    change_entry="- ${CURRENT_BRANCH}: Added ${NEW_LANG} + ${NEW_FRAMEWORK}"
  elif [[ -n "$NEW_LANG" ]]; then
    change_entry="- ${CURRENT_BRANCH}: Added ${NEW_LANG}"
  elif [[ -n "$NEW_FRAMEWORK" ]]; then
    change_entry="- ${CURRENT_BRANCH}: Added ${NEW_FRAMEWORK}"
  fi

  local content
  if [[ -f "$TEMPLATE_FILE" ]]; then
    content=$(<"$TEMPLATE_FILE")
    local project_structure commands language_conventions
    project_structure=$(get_project_structure "$NEW_PROJECT_TYPE")
    commands=$(get_commands_for_language "$NEW_LANG")
    language_conventions=$(get_language_conventions "$NEW_LANG")

    content="${content//\[PROJECT NAME\]/$project_name}"
    content="${content//\[DATE\]/$date_str}"
    content="${content//\[EXTRACTED FROM ALL PLAN.MD FILES\]/$tech_entry}"
    content="${content//\[ACTUAL STRUCTURE FROM PLANS\]/$project_structure}"
    content="${content//\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]/$commands}"
    content="${content//\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]/$language_conventions}"
    content="${content//\[LAST 3 FEATURES AND WHAT THEY ADDED\]/$change_entry}"
  else
    content="# $project_name - Agent Context

## Active Technologies
"
    [[ -n "$tech_entry" ]] && content+="
$tech_entry"
    content+="

## Recent Changes
"
    [[ -n "$change_entry" ]] && content+="
$change_entry"
    content+="

**Last updated**: $date_str"
  fi

  local parent
  parent=$(dirname "$target_file")
  mkdir -p "$parent"
  printf '%s' "$content" > "$target_file"
}

update_existing_agent_file() {
  local target_file="$1" date_str="$2"
  if [[ ! -f "$target_file" ]]; then
    new_agent_file "$target_file" "$(basename "$REPO_ROOT")" "$date_str"
    return
  fi

  local tech_stack
  tech_stack=$(format_technology_stack "$NEW_LANG" "$NEW_FRAMEWORK")

  local -a new_tech_entries=()
  if [[ -n "$tech_stack" ]] && ! grep -qF "$tech_stack" "$target_file"; then
    new_tech_entries+=("- $tech_stack ($CURRENT_BRANCH)")
  fi
  if [[ -n "$NEW_DB" && "$NEW_DB" != "N/A" && "$NEW_DB" != "NEEDS CLARIFICATION" ]] \
     && ! grep -qF "$NEW_DB" "$target_file"; then
    new_tech_entries+=("- $NEW_DB ($CURRENT_BRANCH)")
  fi

  local new_change_entry=""
  if [[ -n "$tech_stack" ]]; then
    new_change_entry="- ${CURRENT_BRANCH}: Added ${tech_stack}"
  elif [[ -n "$NEW_DB" && "$NEW_DB" != "N/A" && "$NEW_DB" != "NEEDS CLARIFICATION" ]]; then
    new_change_entry="- ${CURRENT_BRANCH}: Added ${NEW_DB}"
  fi

  # Process file line by line
  local -a output_lines=()
  local in_tech=false in_changes=false tech_added=false change_added=false
  local existing_changes=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "## Active Technologies" ]]; then
      output_lines+=("$line")
      in_tech=true
      continue
    fi
    if $in_tech && [[ "$line" =~ ^##\  ]]; then
      if ! $tech_added && [[ ${#new_tech_entries[@]} -gt 0 ]]; then
        for entry in "${new_tech_entries[@]}"; do output_lines+=("$entry"); done
        tech_added=true
      fi
      output_lines+=("$line")
      in_tech=false
      continue
    fi
    if $in_tech && [[ -z "${line// }" ]]; then
      if ! $tech_added && [[ ${#new_tech_entries[@]} -gt 0 ]]; then
        for entry in "${new_tech_entries[@]}"; do output_lines+=("$entry"); done
        tech_added=true
      fi
      output_lines+=("$line")
      continue
    fi
    if [[ "$line" == "## Recent Changes" ]]; then
      output_lines+=("$line")
      if [[ -n "$new_change_entry" ]]; then
        output_lines+=("$new_change_entry")
        change_added=true
      fi
      in_changes=true
      continue
    fi
    if $in_changes && [[ "$line" =~ ^##\  ]]; then
      output_lines+=("$line")
      in_changes=false
      continue
    fi
    if $in_changes && [[ "$line" =~ ^-\  ]]; then
      if [[ $existing_changes -lt 2 ]]; then
        output_lines+=("$line")
        existing_changes=$((existing_changes + 1))
      fi
      continue
    fi
    if [[ "$line" =~ \*\*Last\ updated\*\*:.*[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
      output_lines+=("$(echo "$line" | sed "s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/$date_str/")")
      continue
    fi
    output_lines+=("$line")
  done < "$target_file"

  # Post-loop: still in tech section?
  if $in_tech && ! $tech_added && [[ ${#new_tech_entries[@]} -gt 0 ]]; then
    for entry in "${new_tech_entries[@]}"; do output_lines+=("$entry"); done
  fi

  printf '%s\n' "${output_lines[@]}" > "$target_file"
}

update_agent_file() {
  local target_file="$1" agent_name="$2"
  [[ -z "$target_file" || -z "$agent_name" ]] && { err "update_agent_file requires target_file and agent_name"; return 1; }
  info "Updating $agent_name context file: $target_file"
  local project_name date_str
  project_name=$(basename "$REPO_ROOT")
  date_str=$(date +%Y-%m-%d)

  mkdir -p "$(dirname "$target_file")"

  if [[ ! -f "$target_file" ]]; then
    new_agent_file "$target_file" "$project_name" "$date_str" \
      && success "Created new $agent_name context file" \
      || { err "Failed to create new agent file"; return 1; }
  else
    update_existing_agent_file "$target_file" "$date_str" \
      && success "Updated existing $agent_name context file" \
      || { err "Failed to update agent file"; return 1; }
  fi
}

update_specific_agent() {
  case "$1" in
    claude)       update_agent_file "$CLAUDE_FILE"   "Claude Code" ;;
    gemini)       update_agent_file "$GEMINI_FILE"   "Gemini CLI" ;;
    copilot)      update_agent_file "$COPILOT_FILE"  "GitHub Copilot" ;;
    cursor-agent) update_agent_file "$CURSOR_FILE"   "Cursor IDE" ;;
    qwen)         update_agent_file "$QWEN_FILE"     "Qwen Code" ;;
    opencode)     update_agent_file "$AGENTS_FILE"   "opencode" ;;
    codex)        update_agent_file "$AGENTS_FILE"   "Codex CLI" ;;
    windsurf)     update_agent_file "$WINDSURF_FILE" "Windsurf" ;;
    kilocode)     update_agent_file "$KILOCODE_FILE" "Kilo Code" ;;
    auggie)       update_agent_file "$AUGGIE_FILE"   "Auggie CLI" ;;
    roo)          update_agent_file "$ROO_FILE"      "Roo Code" ;;
    codebuddy)    update_agent_file "$CODEBUDDY_FILE" "CodeBuddy CLI" ;;
    qoder)        update_agent_file "$QODER_FILE"    "Qoder CLI" ;;
    amp)          update_agent_file "$AMP_FILE"      "Amp" ;;
    shai)         update_agent_file "$SHAI_FILE"     "SHAI" ;;
    q)            update_agent_file "$Q_FILE"        "Amazon Q Developer CLI" ;;
    agy)          update_agent_file "$AGY_FILE"      "Antigravity" ;;
    bob)          update_agent_file "$BOB_FILE"      "IBM Bob" ;;
    *)            err "Unknown agent type '$1'"; return 1 ;;
  esac
}

update_all_existing_agents() {
  local found=false ok=true

  local -a agent_pairs=(
    "$CLAUDE_FILE|Claude Code"
    "$GEMINI_FILE|Gemini CLI"
    "$COPILOT_FILE|GitHub Copilot"
    "$CURSOR_FILE|Cursor IDE"
    "$QWEN_FILE|Qwen Code"
    "$AGENTS_FILE|Codex/opencode"
    "$WINDSURF_FILE|Windsurf"
    "$KILOCODE_FILE|Kilo Code"
    "$AUGGIE_FILE|Auggie CLI"
    "$ROO_FILE|Roo Code"
    "$CODEBUDDY_FILE|CodeBuddy CLI"
    "$QODER_FILE|Qoder CLI"
    "$SHAI_FILE|SHAI"
    "$Q_FILE|Amazon Q Developer CLI"
    "$AGY_FILE|Antigravity"
    "$BOB_FILE|IBM Bob"
  )

  for pair in "${agent_pairs[@]}"; do
    local file="${pair%%|*}" name="${pair#*|}"
    if [[ -f "$file" ]]; then
      update_agent_file "$file" "$name" || ok=false
      found=true
    fi
  done

  if ! $found; then
    info "No existing agent files found; skipping agent context updates."
    info "Tip: bootstrap tool-specific files first (e.g., setup-project.sh --ai ...)."
  fi
  $ok
}

print_summary() {
  echo ""
  info "Summary of changes:"
  [[ -n "$NEW_LANG" ]] && echo "  - Added language: $NEW_LANG"
  [[ -n "$NEW_FRAMEWORK" ]] && echo "  - Added framework: $NEW_FRAMEWORK"
  [[ -n "$NEW_DB" && "$NEW_DB" != "N/A" ]] && echo "  - Added database: $NEW_DB"
  echo ""
  info "Usage: update-agent-context.sh [claude|gemini|copilot|cursor-agent|qwen|opencode|codex|windsurf|kilocode|auggie|roo|codebuddy|amp|shai|q|agy|bob|qoder]"
}

main() {
  validate_environment
  info "=== Updating agent context files for feature $CURRENT_BRANCH ==="
  parse_plan_data "$NEW_PLAN" || { err "Failed to parse plan data"; exit 1; }

  local success_flag=true
  if [[ -n "$AGENT_TYPE" ]]; then
    info "Updating specific agent: $AGENT_TYPE"
    update_specific_agent "$AGENT_TYPE" || success_flag=false
  else
    info "No agent specified, updating all existing agent files..."
    update_all_existing_agents || success_flag=false
  fi

  print_summary
  if $success_flag; then
    success "Agent context update completed successfully"
  else
    err "Agent context update completed with errors"
    exit 1
  fi
}

main
