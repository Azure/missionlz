#!/usr/bin/env bash
# Apply the VERSION and CHANGELOG update for a merged PR.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=release-common.sh
source "$SCRIPT_DIR/release-common.sh"

REPO_ROOT="$(git -C "$SCRIPT_DIR/../../.." rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../../.." && pwd))"
LABEL=""
PR_NUMBER=""
PR_TITLE=""
PR_URL=""
BODY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)
      LABEL="$2"
      shift 2
      ;;
    --pr-number)
      PR_NUMBER="$2"
      shift 2
      ;;
    --pr-title)
      PR_TITLE="$2"
      shift 2
      ;;
    --pr-url)
      PR_URL="$2"
      shift 2
      ;;
    --body-file)
      BODY_FILE="$2"
      shift 2
      ;;
    --help|-h)
      cat <<'HELP'
Usage: apply-release-bump.sh --label release:patch --pr-number N --pr-title TITLE --pr-url URL --body-file FILE
HELP
      exit 0
      ;;
    *)
      release_fail "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$LABEL" ]] || release_fail "Missing --label."
[[ -n "$PR_NUMBER" ]] || release_fail "Missing --pr-number."
[[ -n "$PR_TITLE" ]] || release_fail "Missing --pr-title."
[[ -n "$PR_URL" ]] || release_fail "Missing --pr-url."
[[ -n "$BODY_FILE" && -f "$BODY_FILE" ]] || release_fail "Missing or invalid --body-file."

bump="$(release_label_to_bump "$LABEL")" \
  || release_fail "Invalid release label '$LABEL'. Expected release:major, release:minor, or release:patch."

version_file="$REPO_ROOT/VERSION"
specify_version_file="$REPO_ROOT/.specify/VERSION"
changelog_file="$REPO_ROOT/CHANGELOG.md"
[[ -f "$version_file" ]] || release_fail "VERSION file not found."
[[ -f "$specify_version_file" ]] || release_fail ".specify/VERSION file not found."
[[ -f "$changelog_file" ]] || release_fail "CHANGELOG.md file not found."

current_version="$(tr -d '[:space:]' < "$version_file")"
new_version="$(next_semver "$current_version" "$bump")"

if grep -q "^## \\[$new_version\\]" "$changelog_file"; then
  release_fail "CHANGELOG.md already contains an entry for $new_version."
fi

release_note="$(resolve_release_note "$BODY_FILE" "$PR_TITLE" "$LABEL" || true)"
if ! printf '%s\n' "$release_note" | has_release_note_content; then
  release_fail "PR release note is empty."
fi

if [[ "$LABEL" == "release:major" ]] \
  && ! printf '%s\n' "$release_note" | grep -q '^BREAKING CHANGE:'; then
  release_fail "release:major requires a release note line starting with BREAKING CHANGE:."
fi

case "$bump" in
  major) section_title="Breaking Changes" ;;
  minor) section_title="Added" ;;
  patch) section_title="Changed" ;;
esac

release_date="$(date -u +%Y-%m-%d)"
entry_file="$(mktemp)"
tmp_changelog="$(mktemp)"
clean_changelog="$(mktemp)"
trap 'rm -f "$entry_file" "$tmp_changelog" "$clean_changelog"' EXIT

cat > "$entry_file" <<ENTRY
## [$new_version] - $release_date

### $section_title

- $PR_TITLE ([#$PR_NUMBER]($PR_URL))

$release_note
ENTRY

printf '%s\n' "$new_version" > "$version_file"
printf '%s\n' "$new_version" > "$specify_version_file"

awk -v entry_file="$entry_file" '
  BEGIN { inserted = 0 }
  !inserted && /^## \[[0-9]+\.[0-9]+\.[0-9]+\]/ {
    while ((getline line < entry_file) > 0) {
      print line
    }
    print ""
    inserted = 1
  }
  { print }
  END {
    if (!inserted) {
      print ""
      while ((getline line < entry_file) > 0) {
        print line
      }
    }
  }
' "$changelog_file" > "$tmp_changelog"

awk '
  /^[[:space:]]*$/ {
    blank_count++
    if (blank_count <= 1) {
      print ""
    }
    next
  }
  {
    blank_count = 0
    print
  }
' "$tmp_changelog" > "$clean_changelog"

mv "$clean_changelog" "$changelog_file"
echo "Applied release bump: $current_version -> $new_version ($LABEL)"
