#!/usr/bin/env bash
# Resolves a provider login without ever promoting Git identity to owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

stage=""
spec_path=""

usage_error() {
  echo "Usage: resolve-owner.sh --stage <shaping|build|reassign> [--spec <path>] [--json]" >&2
  exit 2
}

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

has_control_characters() {
  local value="$1" character code index
  local LC_ALL=C
  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    printf -v code '%d' "'$character"
    if ((code < 32 || code == 127)); then
      return 0
    fi
  done
  return 1
}

has_malformed_utf8() {
  local value="$1" character code next_code index offset length expected first_min first_max
  local LC_ALL=C
  length=${#value}

  for ((index = 0; index < length; index += expected + 1)); do
    character="${value:index:1}"
    printf -v code '%d' "'$character"
    expected=0
    first_min=128
    first_max=191

    if ((code < 128)); then
      continue
    elif ((code >= 194 && code <= 223)); then
      expected=1
    elif ((code == 224)); then
      expected=2
      first_min=160
    elif ((code >= 225 && code <= 236 || code >= 238 && code <= 239)); then
      expected=2
    elif ((code == 237)); then
      expected=2
      first_max=159
    elif ((code == 240)); then
      expected=3
      first_min=144
    elif ((code >= 241 && code <= 243)); then
      expected=3
    elif ((code == 244)); then
      expected=3
      first_max=143
    else
      return 0
    fi

    if ((index + expected >= length)); then
      return 0
    fi
    for ((offset = 1; offset <= expected; offset++)); do
      character="${value:index + offset:1}"
      printf -v next_code '%d' "'$character"
      if ((offset == 1)); then
        ((next_code >= first_min && next_code <= first_max)) || return 0
      elif ((next_code < 128 || next_code > 191)); then
        return 0
      fi
    done
  done
  return 1
}

normalize_owner_candidate() {
  local raw_value="$1" source_label="$2" result_variable="$3" trimmed_value
  if has_malformed_utf8 "$raw_value"; then
    append_reason "$source_label contains malformed UTF-8; ignored"
    printf -v "$result_variable" '%s' ""
    return
  fi

  trimmed_value=$(trim_value "$raw_value")

  if [[ -z "$trimmed_value" ]]; then
    printf -v "$result_variable" '%s' ""
  elif has_control_characters "$raw_value"; then
    append_reason "$source_label contains control characters; ignored"
    printf -v "$result_variable" '%s' ""
  else
    printf -v "$result_variable" '%s' "$trimmed_value"
  fi
}

json_string() {
  local value escaped="" character code index
  value="$1"

  if has_malformed_utf8 "$value"; then
    printf '"\\ufffd"'
    return
  fi

  # Bash variables cannot contain NUL. Escape every other JSON control byte.
  local LC_ALL=C
  for ((index = 0; index < ${#value}; index++)); do
    character="${value:index:1}"
    case "$character" in
      '"') escaped+='\"' ;;
      '\') escaped+='\\' ;;
      $'\b') escaped+='\b' ;;
      $'\f') escaped+='\f' ;;
      $'\n') escaped+='\n' ;;
      $'\r') escaped+='\r' ;;
      $'\t') escaped+='\t' ;;
      *)
        printf -v code '%d' "'$character"
        if ((code < 32)); then
          printf -v escaped '%s\\u%04x' "$escaped" "$code"
        else
          escaped+="$character"
        fi
        ;;
    esac
  done
  printf '"%s"' "$escaped"
}

append_reason() {
  local detail="$1"
  if [[ -z "$reason" ]]; then
    reason="$detail"
  else
    reason="$reason; $detail"
  fi
}

while (($#)); do
  case "$1" in
    --stage)
      (($# >= 2)) || usage_error
      stage="$2"
      shift 2
      ;;
    --spec)
      (($# >= 2)) || usage_error
      spec_path="$2"
      shift 2
      ;;
    --json)
      shift
      ;;
    *)
      usage_error
      ;;
  esac
done

case "$stage" in
  shaping|build|reassign) ;;
  *) usage_error ;;
esac

repo_root=$(get_repo_root)
provider="none"
login=""
source_name="none"
status=""
git_identity_hint=""
current_owner=""
current_owner_raw=""
policy_found=false
reason=""

if [[ -f "$repo_root/.specify/policies/owner-resolution.md" ]]; then
  policy_found=true
else
  append_reason "owner resolution policy not found"
fi

if [[ -n "$spec_path" && -f "$spec_path" ]]; then
  current_owner_raw=$(get_frontmatter_field "$spec_path" owner || true)
  if has_malformed_utf8 "$current_owner_raw"; then
    current_owner="$current_owner_raw"
    append_reason "current owner contains malformed UTF-8; displayed safely"
  else
    current_owner=$(trim_value "$current_owner_raw")
  fi
fi

remote_url=""
if git remote get-url origin >/dev/null 2>&1; then
  remote_url=$(git remote get-url origin 2>/dev/null || true)
else
  first_remote=$(git remote 2>/dev/null | sort | head -n 1 || true)
  if [[ -n "$first_remote" ]]; then
    remote_url=$(git remote get-url "$first_remote" 2>/dev/null || true)
  fi
fi
remote_url=$(trim_value "$remote_url")

detect_provider() {
  local remote="$1" authority
  remote_host=""
  if [[ "$remote" =~ ^[^/@:]+@([^/:]+): ]]; then
    remote_host="${BASH_REMATCH[1]}"
  elif [[ "$remote" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
    authority="${remote#*://}"
    authority="${authority%%/*}"
    authority="${authority##*@}"
    remote_host="${authority%%:*}"
  fi
  remote_host=$(printf '%s' "$remote_host" | tr '[:upper:]' '[:lower:]')

  if [[ -n "${AIS_OWNER_PROVIDER:-}" ]]; then
    case "$(trim_value "${AIS_OWNER_PROVIDER}")" in
      github|azure-devops|gitlab)
        provider="$(trim_value "${AIS_OWNER_PROVIDER}")"
        return
        ;;
      *)
        append_reason "invalid AIS_OWNER_PROVIDER ignored"
        ;;
    esac
  fi

  if [[ -z "$remote" ]]; then
    provider="none"
  elif [[ "$remote_host" == "dev.azure.com" || "$remote_host" == "ssh.dev.azure.com" ||
    "$remote_host" == *.visualstudio.com ]]; then
    provider="azure-devops"
  elif [[ "$remote_host" == "github.com" ]]; then
    provider="github"
  elif [[ "$remote_host" == "gitlab.com" ]]; then
    provider="gitlab"
  else
    provider="unknown"
  fi
}

select_timeout_command() {
  timeout_command=""
  if command -v timeout >/dev/null 2>&1; then
    timeout_command="timeout"
  elif command -v gtimeout >/dev/null 2>&1; then
    timeout_command="gtimeout"
  else
    return 1
  fi
}

run_bounded() {
  local output_file="$1"
  shift
  "$timeout_command" -k 1 5 "$@" </dev/null >"$output_file" 2>/dev/null
}

contains_nul_byte() {
  local output_file="$1" bytes
  bytes=$(LC_ALL=C od -An -v -tx1 "$output_file") || return 1
  [[ "$bytes" =~ (^|[[:space:]])00($|[[:space:]]) ]]
}

resolve_github() {
  local output_file="$1" arguments=(api)
  if [[ -n "$remote_host" ]]; then
    arguments+=(--hostname "$remote_host")
  fi
  arguments+=(user --jq .login)

  GIT_TERMINAL_PROMPT=0 GH_PROMPT_DISABLED=1 GH_NO_UPDATE_NOTIFIER=1 \
    GH_PAGER=cat NO_COLOR=1 run_bounded "$output_file" gh "${arguments[@]}"
}

resolve_azure_devops() {
  local output_file="$1"
  GIT_TERMINAL_PROMPT=0 AZURE_CORE_ONLY_SHOW_ERRORS=true NO_COLOR=1 \
    run_bounded "$output_file" az account show --query user.name -o tsv --only-show-errors
}

resolve_gitlab() {
  local output_file="$1"
  GIT_TERMINAL_PROMPT=0 NO_COLOR=1 run_bounded "$output_file" glab api user
}

extract_gitlab_login() {
  printf '%s\n' "$1" |
    sed -n 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    head -n 1
}

detect_provider "$remote_url"
case "$provider" in
  github|azure-devops|gitlab)
    if select_timeout_command; then
      adapter_output=$(mktemp "${TMPDIR:-/tmp}/resolve-owner.XXXXXX" 2>/dev/null || true)
      if [[ -z "$adapter_output" ]]; then
        append_reason "could not create provider output capture; provider CLI skipped"
      else
        trap 'rm -f -- "$adapter_output"' EXIT
        if case "$provider" in
          github) resolve_github "$adapter_output" ;;
          azure-devops) resolve_azure_devops "$adapter_output" ;;
          gitlab) resolve_gitlab "$adapter_output" ;;
        esac
        then
          if contains_nul_byte "$adapter_output"; then
            append_reason "provider CLI result contains NUL bytes; ignored"
          else
            raw_adapter_output=$(<"$adapter_output")
            case "$provider" in
              gitlab) raw_login=$(extract_gitlab_login "$raw_adapter_output") ;;
              *) raw_login="$raw_adapter_output" ;;
            esac
            normalize_owner_candidate "$raw_login" "provider CLI result" login
          fi
        fi
      fi
    else
      append_reason "no timeout primitive available; provider CLI skipped"
    fi
    ;;
  unknown)
    append_reason "no provider adapter for remote host"
    ;;
  none)
    append_reason "no git remote configured"
    ;;
esac

if [[ -n "$login" ]]; then
  source_name="provider-cli"
else
  normalize_owner_candidate "${AIS_OWNER:-}" "AIS_OWNER" login
  if [[ -n "$login" ]]; then
    source_name="explicit-config"
  else
    ci_actor=""
    ci_candidates=()
    case "$provider" in
      github) ci_candidates=("${GITHUB_ACTOR:-}") ;;
      gitlab) ci_candidates=("${GITLAB_USER_LOGIN:-}") ;;
      azure-devops) ci_candidates=("${BUILD_REQUESTEDFOREMAIL:-}") ;;
      *) ci_candidates=("${GITHUB_ACTOR:-}" "${GITLAB_USER_LOGIN:-}" "${BUILD_REQUESTEDFOREMAIL:-}") ;;
    esac

    for candidate in "${ci_candidates[@]}"; do
      normalize_owner_candidate "$candidate" "CI actor" candidate
      if [[ -n "$candidate" ]]; then
        ci_actor="$candidate"
        break
      fi
    done
    login="$ci_actor"
    if [[ -n "$login" ]]; then
      source_name="ci-actor"
    fi
  fi
fi

if [[ -n "$login" ]]; then
  status="resolved"
else
  source_name="none"
  if [[ "$stage" == "shaping" ]]; then
    status="unresolved"
  else
    status="needs-user-input"
  fi
  if [[ -z "$reason" ]]; then
    append_reason "no provider login, AIS_OWNER, or CI actor available"
  fi
fi

if [[ "$stage" != "shaping" ]]; then
  git_name=""
  git_email=""
  git_name_raw=$(git config user.name 2>/dev/null || true)
  git_email_raw=$(git config user.email 2>/dev/null || true)
  if has_malformed_utf8 "$git_name_raw" || has_malformed_utf8 "$git_email_raw"; then
    append_reason "Git identity hint contains malformed UTF-8; ignored"
  else
    git_name=$(trim_value "$git_name_raw")
    git_email=$(trim_value "$git_email_raw")
  fi
  if [[ -n "${git_name:-}" || -n "${git_email:-}" ]] &&
    { has_control_characters "$git_name_raw" || has_control_characters "$git_email_raw"; }; then
    append_reason "Git identity hint contains control characters; ignored"
  elif [[ -n "$git_name" && -n "$git_email" ]]; then
    git_identity_hint="$git_name <$git_email>"
  elif [[ -n "$git_name" ]]; then
    git_identity_hint="$git_name"
  elif [[ -n "$git_email" ]]; then
    git_identity_hint="$git_email"
  fi
fi

printf '{'
printf '"provider":%s,' "$(json_string "$provider")"
printf '"login":%s,' "$(json_string "$login")"
printf '"source":%s,' "$(json_string "$source_name")"
printf '"status":%s,' "$(json_string "$status")"
printf '"stage":%s,' "$(json_string "$stage")"
printf '"git_identity_hint":%s,' "$(json_string "$git_identity_hint")"
printf '"current_owner":%s,' "$(json_string "$current_owner")"
printf '"policy_found":%s,' "$policy_found"
printf '"reason":%s' "$(json_string "$reason")"
printf '}\n'
