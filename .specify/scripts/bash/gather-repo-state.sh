#!/usr/bin/env bash
# gather-repo-state.sh — Collect all repo state into JSON for reporting
#
# Scans specs/ directories, parses frontmatter, checks git state, and
# aggregates into a single JSON document. All report commands call this,
# then format differently.
#
# Usage:
#   bash .specify/scripts/bash/gather-repo-state.sh --json
#
# Environment:
#   AIS_INCLUDE_PR_HISTORY=1  Also collect per-spec pull request history.
#   AIS_STRICT_GH=1           Treat GitHub CLI failures as fatal instead of
#                             degrading to empty results. Automation should set
#                             this; a report built from silently-empty GitHub
#                             data is indistinguishable from a quiet week.
#
# Output: JSON object with project-level and per-spec state

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root)
SPECS_DIR="$REPO_ROOT/specs"
HAS_GIT=$(has_git && echo "true" || echo "false")
STRICT_GH=false
case "${AIS_STRICT_GH:-}" in 1|true) STRICT_GH=true ;; esac
HAS_GH=false
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  HAS_GH=true
elif [[ "$STRICT_GH" == "true" ]]; then
  echo "gather-repo-state.sh: AIS_STRICT_GH is set but gh is unavailable or unauthenticated." >&2
  exit 1
fi
INCLUDE_PR_HISTORY="${AIS_INCLUDE_PR_HISTORY:-false}"

# Run a `gh` query. Under AIS_STRICT_GH a failure is recorded and aborts the
# script before any JSON is emitted; otherwise it degrades to the caller's
# fallback, which is what every interactive report expects.
#
# Failures are recorded to a file rather than exiting here on purpose: every
# caller runs this inside a command substitution, where `exit` would only end
# the subshell and the script would carry on with empty data.
GH_ERROR_LOG=""
GH_STDERR_TMP=$(mktemp)
trap 'rm -f "$GH_STDERR_TMP" ${GH_ERROR_LOG:+"$GH_ERROR_LOG"}' EXIT
if [[ "$STRICT_GH" == "true" ]]; then
  GH_ERROR_LOG=$(mktemp)
fi

gh_query() {
  local fallback="$1"; shift
  local out status
  set +e
  # stderr is captured separately: folding it into stdout would prepend any
  # `gh` notice to the JSON the accessors parse.
  out=$("$@" 2>"$GH_STDERR_TMP")
  status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    if [[ -n "$GH_ERROR_LOG" ]]; then
      { printf '%s\n' "failed (exit $status): $*"; cat "$GH_STDERR_TMP"; } >>"$GH_ERROR_LOG"
    fi
    printf '%s\n' "$fallback"
    return 0
  fi
  printf '%s\n' "$out"
}

# Abort if any `gh` query failed while strict mode was on.
assert_no_gh_failures() {
  [[ -n "$GH_ERROR_LOG" && -s "$GH_ERROR_LOG" ]] || return 0
  echo "gather-repo-state.sh: GitHub queries failed under AIS_STRICT_GH." >&2
  echo "Refusing to emit state that would silently under-report." >&2
  cat "$GH_ERROR_LOG" >&2
  exit 1
}

# Strict mode must not depend on the spec scan happening to issue a query.
# A detached checkout, or a repository whose specs carry no branch, reaches the
# end without calling `gh` at all, and a broken CLI would pass unnoticed. Probe
# once up front so the guarantee is unconditional.
if [[ "$STRICT_GH" == "true" && "$HAS_GH" == "true" ]]; then
  gh_query "[]" gh pr list --state open --json number --limit 1 >/dev/null
  assert_no_gh_failures
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
STALE_DAYS=14

# --- Helpers ---

# Check if a branch exists (local or remote)
branch_exists() {
  local spec_id="$1"
  if [[ "$HAS_GIT" != "true" ]]; then echo "false"; return; fi
  local pattern="${spec_id}-"
  if git branch -a 2>/dev/null | grep -Fq -- "$pattern"; then
    echo "true"
  else
    echo "false"
  fi
}

# Get branch name for a spec directory
get_branch_for_spec() {
  local dirname="$1"
  if [[ "$HAS_GIT" != "true" ]]; then echo ""; return; fi
  local pattern="$dirname"
  git branch -a 2>/dev/null | sed 's/^[* ]*//' | sed 's|remotes/origin/||' | grep -F -m1 -x -- "$pattern" || echo ""
}

# Get last commit date for a path
last_commit_date() {
  local path="$1"
  if [[ "$HAS_GIT" != "true" ]]; then echo ""; return; fi
  git log -1 --date=short --format="%cd" -- "$path" 2>/dev/null || echo ""
}

# Get first commit datetime for a path
first_commit_datetime() {
  local path="$1"
  if [[ "$HAS_GIT" != "true" ]]; then echo ""; return; fi
  git log --reverse --format="%cI" -- "$path" 2>/dev/null | head -1 || echo ""
}

# Get last commit author for a path
last_commit_author() {
  local path="$1"
  if [[ "$HAS_GIT" != "true" ]]; then echo ""; return; fi
  git log -1 --format="%an" -- "$path" 2>/dev/null || echo ""
}

# Get contributors in last N days for a path
recent_contributors() {
  local path="$1" days="${2:-7}"
  if [[ "$HAS_GIT" != "true" ]]; then echo "[]"; return; fi
  local since
  since=$(date -d "-${days} days" +"%Y-%m-%d" 2>/dev/null || date -v-${days}d +"%Y-%m-%d" 2>/dev/null || echo "")
  if [[ -z "$since" ]]; then echo "[]"; return; fi
  local authors
  authors=$(git log --since="$since" --format="%an" -- "$path" 2>/dev/null | sort -u | head -20)
  local result="["
  local first=true
  while IFS= read -r author; do
    [[ -z "$author" ]] && continue
    if $first; then first=false; else result+=","; fi
    result+="\"$(json_escape "$author")\""
  done <<< "$authors"
  result+="]"
  echo "$result"
}

# Calculate days since a date
days_since() {
  local date_str="$1"
  [[ -z "$date_str" ]] && echo "" && return
  local then_ts now_ts
  then_ts=$(date -d "$date_str" +%s 2>/dev/null || date -jf "%Y-%m-%d" "$date_str" +%s 2>/dev/null || echo "")
  now_ts=$(date +%s)
  if [[ -n "$then_ts" ]]; then
    echo $(( (now_ts - then_ts) / 86400 ))
  else
    echo ""
  fi
}

# Check artifact existence and return inventory JSON
get_artifact_inventory() {
  local dir="$1"
  local spec_md="false" design_md="false" tasks_md="false" research_md="false"
  local implementation_plan="false" data_model="false" quickstart="false" contracts="false" checklists="false"
  local github_sync="false"

  [[ -f "$dir/spec.md" ]] && spec_md="true"
  [[ -f "$dir/design.md" ]] && design_md="true"
  [[ -f "$dir/implementation-plan.md" ]] && implementation_plan="true"
  [[ -f "$dir/tasks.md" ]] && tasks_md="true"
  [[ -f "$dir/research.md" ]] && research_md="true"
  [[ -f "$dir/data-model.md" ]] && data_model="true"
  [[ -f "$dir/quickstart.md" ]] && quickstart="true"
  [[ -d "$dir/contracts" ]] && contracts="true"
  [[ -d "$dir/checklists" ]] && checklists="true"
  [[ -f "$dir/.github-sync.json" ]] && github_sync="true"

  echo "{\"spec_md\":$spec_md,\"design_md\":$design_md,\"implementation_plan\":$implementation_plan,\"tasks_md\":$tasks_md,\"research_md\":$research_md,\"data_model\":$data_model,\"quickstart\":$quickstart,\"contracts\":$contracts,\"checklists\":$checklists,\"github_sync\":$github_sync}"
}

# Derive pipeline status from git/file state
derive_pipeline_status() {
  local dir="$1" spec_id="$2" fm_status="$3"

  # Blocked takes priority
  if [[ "$fm_status" == "blocked" ]]; then echo "blocked"; return; fi

  local has_spec=false has_design=false has_tasks=false
  [[ -f "$dir/spec.md" ]] && has_spec=true
  [[ -f "$dir/design.md" ]] && has_design=true
  [[ -f "$dir/tasks.md" ]] && has_tasks=true

  if $has_tasks; then
    local task_json
    task_json=$(count_tasks "$dir/tasks.md")
    local total completed
    total=$(echo "$task_json" | sed 's/.*"total":\([0-9]*\).*/\1/')
    completed=$(echo "$task_json" | sed 's/.*"done":\([0-9]*\).*/\1/')

    if [[ "$total" -gt 0 && "$completed" -ge "$total" ]]; then
      echo "complete"; return
    elif [[ "$completed" -gt 0 ]]; then
      echo "in-dev"; return
    else
      echo "ready"; return
    fi
  fi

  if $has_design; then echo "planning"; return; fi
  if $has_spec; then echo "defining"; return; fi
  echo "drafted"
}

# Get open PR for a branch (graceful degradation)
get_pr_status() {
  local branch="$1"
  if [[ "$HAS_GH" != "true" || -z "$branch" ]]; then echo "{}"; return; fi
  local pr_json
  pr_json=$(gh_query "[]" gh pr list --head "$branch" --json number,state,title,url --limit 1)
  if [[ "$pr_json" == "[]" || -z "$pr_json" ]]; then
    echo "{}"
  else
    echo "$pr_json" | sed 's/^\[//;s/\]$//'
  fi
}

# Get PR history for metrics evidence (graceful degradation)
get_pr_history_for_spec() {
  local branch="$1" spec_id="$2"
  if [[ "$HAS_GH" != "true" || ( "$INCLUDE_PR_HISTORY" != "1" && "$INCLUDE_PR_HISTORY" != "true" ) ]]; then
    echo "[]"
    return
  fi

  local pr_json="[]"
  if [[ -n "$branch" ]]; then
    pr_json=$(gh_query "[]" gh pr list \
      --state all \
      --head "$branch" \
      --json number,state,title,url,createdAt,updatedAt,mergedAt,baseRefName,headRefName,reviewDecision,additions,deletions,commits \
      --limit 10)
  fi

  if [[ "$pr_json" == "[]" || -z "$pr_json" ]]; then
    pr_json=$(gh_query "[]" gh pr list \
      --state all \
      --search "$spec_id" \
      --json number,state,title,url,createdAt,updatedAt,mergedAt,baseRefName,headRefName,reviewDecision,additions,deletions,commits \
      --limit 10)
  fi

  [[ -n "$pr_json" ]] && echo "$pr_json" || echo "[]"
}

# Count task lines that reference user stories like [US1]
count_story_task_refs() {
  local file="$1"
  [[ -f "$file" ]] || { echo "0"; return; }
  local count
  count=$(grep -Ec '\[US[0-9]+\]' "$file" 2>/dev/null || true)
  echo "${count:-0}"
}

# Return the latest report for a suffix, relative to repo root
latest_report_for_suffix() {
  local suffix="$1" reports_dir="$SPECS_DIR/.project-plan/reports"
  [[ -d "$reports_dir" ]] || { echo ""; return; }
  local latest
  latest=$(find "$reports_dir" -maxdepth 1 -type f -name "*-${suffix}.md" 2>/dev/null | sort | tail -1)
  [[ -n "$latest" ]] && echo "${latest#"$REPO_ROOT"/}" || echo ""
}

# Count reports for a suffix
count_reports_for_suffix() {
  local suffix="$1" reports_dir="$SPECS_DIR/.project-plan/reports"
  [[ -d "$reports_dir" ]] || { echo "0"; return; }
  find "$reports_dir" -maxdepth 1 -type f -name "*-${suffix}.md" 2>/dev/null | wc -l | tr -d ' '
}

# --- Main collection ---

spec_entries=""
spec_count=0
first_entry=true
metric_completed_specs=0
metric_specs_with_effort=0
metric_specs_with_source_authority=0
metric_specs_with_branch=0
metric_specs_with_pr_history=0
metric_specs_with_tasks=0
metric_specs_with_all_tasks_done=0
metric_specs_with_story_task_refs=0
metric_specs_with_github_sync=0

if [[ -d "$SPECS_DIR" ]]; then
  for spec_dir in "$SPECS_DIR"/*/; do
    [[ -d "$spec_dir" ]] || continue
    dirname=$(basename "$spec_dir")

    # Skip hidden directories (.project-plan, .architecture, .presales)
    [[ "$dirname" == .* ]] && continue

    spec_id=$(get_spec_id_from_dir "$dirname")
    [[ -z "$spec_id" ]] && continue

    spec_count=$((spec_count + 1))

    # Frontmatter fields
    local_spec="$spec_dir/spec.md"
    fm_title=""
    fm_status="draft"
    fm_created=""
    fm_updated=""
    fm_owner=""
    fm_parent=""
    fm_priority=""
    fm_effort=""
    fm_deps="[]"
    fm_phase="1"
    fm_tags="[]"
    fm_source=""

    if [[ -f "$local_spec" ]]; then
      fm_title=$(get_frontmatter_field "$local_spec" "title")
      fm_status_raw=$(get_frontmatter_field "$local_spec" "status")
      [[ -n "$fm_status_raw" ]] && fm_status="$fm_status_raw"
      fm_created=$(get_frontmatter_field "$local_spec" "created")
      fm_updated=$(get_frontmatter_field "$local_spec" "updated")
      fm_owner=$(get_frontmatter_field "$local_spec" "owner")
      fm_parent=$(get_frontmatter_field "$local_spec" "parent")
      fm_priority=$(get_frontmatter_field "$local_spec" "priority")
      fm_effort=$(get_frontmatter_field "$local_spec" "effort")
      fm_deps=$(get_frontmatter_field "$local_spec" "dependencies")
      fm_phase=$(get_frontmatter_field "$local_spec" "phase")
      fm_tags=$(get_frontmatter_field "$local_spec" "tags")
      fm_source=$(get_frontmatter_field "$local_spec" "source-authority")
    fi
    [[ "$fm_phase" =~ ^[0-9]+$ ]] || fm_phase="1"

    # Derived status
    derived_status=$(derive_pipeline_status "$spec_dir" "$spec_id" "$fm_status")

    # Artifact inventory
    artifacts=$(get_artifact_inventory "$spec_dir")

    # Task completion
    task_stats='{"total":0,"done":0,"remaining":0}'
    if [[ -f "$spec_dir/tasks.md" ]]; then
      task_stats=$(count_tasks "$spec_dir/tasks.md")
    fi
    task_total=$(echo "$task_stats" | sed 's/.*"total":\([0-9]*\).*/\1/')
    task_done=$(echo "$task_stats" | sed 's/.*"done":\([0-9]*\).*/\1/')
    story_task_refs=0
    if [[ -f "$spec_dir/tasks.md" ]]; then
      story_task_refs=$(count_story_task_refs "$spec_dir/tasks.md")
    fi

    # Activity
    last_date=$(last_commit_date "$spec_dir")
    last_author=$(last_commit_author "$spec_dir")
    first_spec_commit=$(first_commit_datetime "$spec_dir/spec.md")
    first_design_commit=$(first_commit_datetime "$spec_dir/design.md")
    first_tasks_commit=$(first_commit_datetime "$spec_dir/tasks.md")
    contributors=$(recent_contributors "$spec_dir" 7)
    staleness=""
    if [[ -n "$last_date" ]]; then
      days=$(days_since "$last_date")
      if [[ -n "$days" && "$days" -ge "$STALE_DAYS" && "$derived_status" != "complete" ]]; then
        staleness="$days"
      fi
    fi

    # Branch & PR
    branch_name=$(get_branch_for_spec "$dirname")
    has_branch=$(branch_exists "$spec_id")
    pr_info="{}"
    if [[ -n "$branch_name" ]]; then
      pr_info=$(get_pr_status "$branch_name")
    fi
    pr_history=$(get_pr_history_for_spec "$branch_name" "$spec_id")

    # Sub-spec detection
    is_sub="false"
    parent_id=""
    if is_sub_spec "$spec_id"; then
      is_sub="true"
      parent_id=$(get_parent_id "$spec_id")
    fi

    # Sub-specs of this spec
    sub_specs="[]"
    if [[ "$is_sub" == "false" ]]; then
      subs="["
      sfirst=true
      for sub_dir in "$SPECS_DIR"/${spec_id}.*/; do
        [[ -d "$sub_dir" ]] || continue
        sub_name=$(basename "$sub_dir")
        sub_id=$(get_spec_id_from_dir "$sub_name")
        [[ -z "$sub_id" ]] && continue
        if $sfirst; then sfirst=false; else subs+=","; fi
        subs+="\"$sub_id\""
      done
      subs+="]"
      sub_specs="$subs"
    fi

    # Warnings
    warnings="["
    wfirst=true
    # Stale warning
    if [[ -n "$staleness" ]]; then
      wfirst=false
      warnings+="\"stale: no commits in ${staleness} days\""
    fi
    # Unassigned warning — only for activated specs (ready or in-dev);
    # shaping (drafted/defining/planning), backlog, and complete are not flagged.
    if [[ -z "$fm_owner" && ( "$derived_status" == "ready" || "$derived_status" == "in-dev" ) ]]; then
      if $wfirst; then wfirst=false; else warnings+=","; fi
      warnings+="\"unassigned: no owner set\""
    fi
    warnings+="]"

    # Metrics evidence rollups
    if [[ "$derived_status" == "complete" ]]; then
      metric_completed_specs=$((metric_completed_specs + 1))
    fi
    if [[ -n "$fm_effort" ]]; then
      metric_specs_with_effort=$((metric_specs_with_effort + 1))
    fi
    if [[ -n "$fm_source" ]]; then
      metric_specs_with_source_authority=$((metric_specs_with_source_authority + 1))
    fi
    if [[ "$has_branch" == "true" ]]; then
      metric_specs_with_branch=$((metric_specs_with_branch + 1))
    fi
    if [[ "$pr_history" != "[]" && -n "$pr_history" ]]; then
      metric_specs_with_pr_history=$((metric_specs_with_pr_history + 1))
    fi
    if [[ "$task_total" -gt 0 ]]; then
      metric_specs_with_tasks=$((metric_specs_with_tasks + 1))
      if [[ "$task_done" -ge "$task_total" ]]; then
        metric_specs_with_all_tasks_done=$((metric_specs_with_all_tasks_done + 1))
      fi
    fi
    if [[ "$story_task_refs" -gt 0 ]]; then
      metric_specs_with_story_task_refs=$((metric_specs_with_story_task_refs + 1))
    fi
    if [[ -f "$spec_dir/.github-sync.json" ]]; then
      metric_specs_with_github_sync=$((metric_specs_with_github_sync + 1))
    fi

    # Build JSON entry
    if $first_entry; then first_entry=false; else spec_entries+=","; fi
    spec_entries+="{"
    spec_entries+="\"id\":\"$(json_escape "$spec_id")\","
    spec_entries+="\"title\":\"$(json_escape "$fm_title")\","
    spec_entries+="\"directory\":\"$(json_escape "$dirname")\","
    spec_entries+="\"branch\":\"$(json_escape "$branch_name")\","
    spec_entries+="\"has_branch\":$has_branch,"
    spec_entries+="\"frontmatter\":{\"status\":\"$(json_escape "$fm_status")\",\"created\":\"$(json_escape "$fm_created")\",\"updated\":\"$(json_escape "$fm_updated")\",\"owner\":\"$(json_escape "$fm_owner")\",\"parent\":\"$(json_escape "$fm_parent")\",\"priority\":\"$(json_escape "$fm_priority")\",\"effort\":\"$(json_escape "$fm_effort")\",\"dependencies\":\"$(json_escape "$fm_deps")\",\"phase\":$fm_phase,\"tags\":\"$(json_escape "$fm_tags")\",\"source_authority\":\"$(json_escape "$fm_source")\"},"
    spec_entries+="\"derived_status\":\"$(json_escape "$derived_status")\","
    spec_entries+="\"artifacts\":$artifacts,"
    spec_entries+="\"tasks\":$task_stats,"
    spec_entries+="\"activity\":{\"last_commit_date\":\"$(json_escape "$last_date")\",\"last_commit_author\":\"$(json_escape "$last_author")\",\"recent_contributors\":$contributors},"
    spec_entries+="\"staleness_days\":${staleness:-null},"
    spec_entries+="\"pr\":$pr_info,"
    spec_entries+="\"pr_history\":$pr_history,"
    spec_entries+="\"metrics_evidence\":{\"first_spec_commit\":\"$(json_escape "$first_spec_commit")\",\"first_design_commit\":\"$(json_escape "$first_design_commit")\",\"first_tasks_commit\":\"$(json_escape "$first_tasks_commit")\",\"story_task_refs\":$story_task_refs},"
    spec_entries+="\"is_sub_spec\":$is_sub,"
    spec_entries+="\"parent_id\":\"$(json_escape "$parent_id")\","
    spec_entries+="\"sub_specs\":$sub_specs,"
    spec_entries+="\"warnings\":$warnings"
    spec_entries+="}"
  done
fi

# Project-level info
has_project_plan="false"
has_architecture="false"
has_presales="false"
has_constitution="false"
has_previous_metrics_reports="false"
has_deployment_events="false"
has_incident_inputs="false"
has_cost_inputs="false"
latest_metrics_report=""
metrics_report_count=0
repository_url=""

[[ -d "$SPECS_DIR/.project-plan" ]] && has_project_plan="true"
[[ -d "$SPECS_DIR/.architecture" ]] && has_architecture="true"
[[ -d "$SPECS_DIR/.presales" ]] && has_presales="true"
[[ -f "$REPO_ROOT/specs/constitution.md" ]] && has_constitution="true"

metrics_report_count=$(count_reports_for_suffix "metrics")
latest_metrics_report=$(latest_report_for_suffix "metrics")
if [[ "$metrics_report_count" -gt 0 ]]; then
  has_previous_metrics_reports="true"
fi

if [[ -d "$SPECS_DIR" ]] && grep -RiqE '(^|[[:space:]])deployed_at:' "$SPECS_DIR" 2>/dev/null; then
  has_deployment_events="true"
fi
if [[ -d "$SPECS_DIR" ]] && grep -RiqE '(type:bug|type:defect|escaped|prod|defect|bug|incident)' "$SPECS_DIR" 2>/dev/null; then
  has_incident_inputs="true"
fi
if [[ -d "$SPECS_DIR" ]] && grep -RiqE '(^|[[:space:]])(actual_cost|estimated_cost|actual_hours|blended_rate|cost_basis|capacity_cost):' "$SPECS_DIR" 2>/dev/null; then
  has_cost_inputs="true"
fi

# Current branch
current_branch="main"
if [[ "$HAS_GIT" == "true" ]]; then
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  repository_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
fi

# Aggregate stats
total_tasks=0
done_tasks=0
if [[ -d "$SPECS_DIR" ]]; then
  for spec_dir in "$SPECS_DIR"/*/; do
    [[ -d "$spec_dir" ]] || continue
    dirname=$(basename "$spec_dir")
    [[ "$dirname" == .* ]] && continue
    if [[ -f "$spec_dir/tasks.md" ]]; then
      local_stats=$(count_tasks "$spec_dir/tasks.md")
      t=$(echo "$local_stats" | sed 's/.*"total":\([0-9]*\).*/\1/')
      d=$(echo "$local_stats" | sed 's/.*"done":\([0-9]*\).*/\1/')
      total_tasks=$((total_tasks + t))
      done_tasks=$((done_tasks + d))
    fi
  done
fi

# Output
assert_no_gh_failures
cat <<EOJSON
{
  "generated_at": "$NOW",
  "repo_root": "$(json_escape "$REPO_ROOT")",
  "current_branch": "$(json_escape "$current_branch")",
  "has_git": $HAS_GIT,
  "has_gh_cli": $HAS_GH,
  "project": {
    "has_project_plan": $has_project_plan,
    "has_architecture": $has_architecture,
    "has_presales": $has_presales,
    "has_constitution": $has_constitution
  },
  "summary": {
    "spec_count": $spec_count,
    "total_tasks": $total_tasks,
    "done_tasks": $done_tasks,
    "progress_pct": $(if [[ $total_tasks -gt 0 ]]; then echo "$(( (done_tasks * 100) / total_tasks ))"; else echo "0"; fi)
  },
  "metrics": {
    "source_capabilities": {
      "has_git": $HAS_GIT,
      "has_gh_cli": $HAS_GH,
      "has_project_plan": $has_project_plan,
      "has_previous_metrics_reports": $has_previous_metrics_reports,
      "has_deployment_events": $has_deployment_events,
      "has_incident_inputs": $has_incident_inputs,
      "has_cost_inputs": $has_cost_inputs
    },
    "report_history": {
      "metrics_report_count": $metrics_report_count,
      "latest_metrics_report": "$(json_escape "$latest_metrics_report")"
    },
    "evidence_summary": {
      "repository_url": "$(json_escape "$repository_url")",
      "completed_specs": $metric_completed_specs,
      "delivered_specs": $metric_completed_specs,
      "specs_with_effort": $metric_specs_with_effort,
      "specs_with_source_authority": $metric_specs_with_source_authority,
      "specs_with_branch": $metric_specs_with_branch,
      "specs_with_pr_history": $metric_specs_with_pr_history,
      "specs_with_tasks": $metric_specs_with_tasks,
      "specs_with_all_tasks_done": $metric_specs_with_all_tasks_done,
      "specs_with_story_task_refs": $metric_specs_with_story_task_refs,
      "specs_with_github_sync": $metric_specs_with_github_sync
    }
  },
  "specs": [$spec_entries]
}
EOJSON
