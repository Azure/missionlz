#!/usr/bin/env bash
# Fails when a change introduces a new YYMM-NNN spec identifier collision.
#
# Allocation reads the local specs tree, local and remote branches, and the
# default branch's specs tree. All of those can still be stale at the moment a
# branch is cut, so collisions remain possible. They are cheap to fix before
# merge and expensive afterwards, once cross-references point at an ambiguous
# identifier.
#
# With --base, only collisions this change introduces are fatal. Pre-existing
# collisions on the base branch are reported but do not fail: a gate that fires
# on day one for inherited debt gets switched off, and then catches nothing.
set -euo pipefail

BASE_REF=""
FAIL_ON_EXISTING=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      if [[ $# -lt 2 ]]; then
        echo "Error: --base requires a ref argument." >&2
        echo "Usage: check-spec-id-uniqueness.sh [--base <ref>] [--strict]" >&2
        exit 1
      fi
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: --base requires a ref argument." >&2
        echo "Usage: check-spec-id-uniqueness.sh [--base <ref>] [--strict]" >&2
        exit 1
      fi
      BASE_REF="$2"
      shift 2
      ;;
    --strict) FAIL_ON_EXISTING=true; shift ;;
    --help|-h)
      cat <<'HELP'
Usage: check-spec-id-uniqueness.sh [--base <ref>] [--strict]

Options:
  --base <ref>  Baseline against the specs tree at <ref> (e.g. origin/main).
                Collisions that already exist there are reported, not fatal.
  --strict      Fail on pre-existing collisions too.
  --help        Show this help message
HELP
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository." >&2
  exit 1
}
cd "$repo_root"

[[ -d "$repo_root/specs" ]] || { echo "No specs/ directory; nothing to check."; exit 0; }

# Spec IDs are YYMM-NNN with an optional .N sub-spec suffix. The sub-spec
# suffix is part of the identity, so 2608-001 and 2608-001.1 do not collide.
spec_id() {
  if [[ "$1" =~ ^([0-9]{4}-[0-9]{3}(\.[0-9]+)?)- ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

# Emits "<id> <dirname>" pairs for a listing of spec directory names.
id_pairs() {
  local name id
  while IFS= read -r name; do
    name="${name#specs/}"
    name="${name%/}"
    [[ -n "$name" ]] || continue
    id=$(spec_id "$name")
    [[ -n "$id" ]] || continue
    echo "$id $name"
  done
}

# Emits the IDs that more than one distinct directory claims.
collisions_from() {
  sort -u | awk 'NF == 2 { count[$1]++ } END { for (id in count) if (count[id] > 1) print id }' | sort
}

# printf '%s\n' "" still emits a newline, which would feed comm a blank line.
# Nothing downstream breaks on it today, but only because command substitution
# strips it back off again. Emit nothing for an empty list so the comparison
# does not depend on that.
emit_lines() {
  if [[ -n "$1" ]]; then
    printf '%s\n' "$1"
  fi
}

head_pairs=$(find specs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | id_pairs | sort -u)
head_collisions=$(printf '%s\n' "$head_pairs" | collisions_from)

base_pairs=""
base_resolved=false
if [[ -n "$BASE_REF" ]]; then
  if git rev-parse --verify --quiet "$BASE_REF" >/dev/null 2>&1; then
    # Trailing slash on specs/ is load-bearing: without it ls-tree returns the
    # single "specs" tree entry rather than the directories inside it, which
    # would leave base_pairs empty and make inherited collisions look new.
    base_pairs=$(git ls-tree --name-only "$BASE_REF" -- specs/ 2>/dev/null | id_pairs | sort -u)
    base_resolved=true
  else
    # Without a baseline there is no way to tell an inherited collision from a
    # new one. Failing here would fail every pull request for debt the branch
    # did not create, which is the outcome the baseline exists to avoid, so the
    # gate reports and stands down instead of guessing.
    echo "[specify] Warning: base ref '$BASE_REF' not found. Cannot separate new" >&2
    echo "collisions from pre-existing ones, so this run is informational only." >&2
    echo "" >&2
  fi
fi

if $FAIL_ON_EXISTING || [[ -z "$BASE_REF" ]]; then
  fatal="$head_collisions"
  inherited=""
elif ! $base_resolved; then
  fatal=""
  inherited="$head_collisions"
else
  # A collision is new when any directory claiming that ID is absent from the
  # base, even if the ID was already duplicated there. Comparing only the sets
  # of colliding IDs would miss a third owner added to an inherited collision.
  new_pairs=$(comm -23 <(emit_lines "$head_pairs") <(emit_lines "$base_pairs"))
  new_owner_ids=$(printf '%s\n' "$new_pairs" | awk 'NF == 2 { print $1 }' | sort -u)
  fatal=$(comm -12 <(emit_lines "$head_collisions") <(emit_lines "$new_owner_ids"))
  inherited=$(comm -23 <(emit_lines "$head_collisions") <(emit_lines "$fatal"))
fi

report() {
  local id owners
  for id in $1; do
    [[ -n "$id" ]] || continue
    owners=$(printf '%s\n' "$head_pairs" | awk -v id="$id" '$1 == id { printf "%s ", $2 }')
    echo "  - $id: ${owners% }" >&2
  done
}

if [[ -n "${inherited// /}" ]]; then
  if $base_resolved; then
    echo "[specify] Pre-existing spec identifier collisions on $BASE_REF (not blocking):" >&2
  else
    echo "[specify] Spec identifier collisions found (not blocking):" >&2
  fi
  report "$inherited"
  echo "" >&2
fi

if [[ -n "${fatal// /}" ]]; then
  if [[ -n "$BASE_REF" ]] && ! $FAIL_ON_EXISTING; then
    echo "[specify] New spec identifier collisions introduced by this change:" >&2
  else
    echo "[specify] Spec identifier collisions:" >&2
  fi
  report "$fatal"
  echo "" >&2
  echo "Rename the newer spec directory and its branch to the next free" >&2
  echo "YYMM-NNN, then update references to it." >&2
  exit 1
fi

echo "[specify] No new spec identifier collisions."
