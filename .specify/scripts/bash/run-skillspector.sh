#!/usr/bin/env bash
# Run SkillSpector against AIS Specify skills with per-skill baselines.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(get_repo_root)
TARGET_DIR="Skills"
BASELINE_DIR="Skills/.ais-spec/validation/skillspector-baselines"
OUTPUT_DIR="artifacts/skillspector"
THRESHOLD="${SKILLSPECTOR_THRESHOLD:-50}"
SKILLSPECTOR_PACKAGE="${SKILLSPECTOR_PACKAGE:-git+https://github.com/NVIDIA/skillspector.git@326a2b489411a20ed742ff13701be39ba00063c8}"
SHOW_SUPPRESSED=false

usage() {
  cat <<'EOF'
Usage: run-skillspector.sh [options]

Options:
  --target DIR        Skill collection directory to scan, relative to the repo
                      root or absolute (default: Skills)
  --baseline-dir DIR  Directory containing per-skill baseline YAML files
                      relative to the repo root or absolute
                      (default: Skills/.ais-spec/validation/skillspector-baselines)
  --output-dir DIR    Directory for JSON and summary reports, relative to the
                      repo root or absolute (default: artifacts/skillspector)
  --threshold N       Fail when any unsuppressed skill score is greater than N
                      (default: 50)
  --show-suppressed   Include suppressed findings in per-skill JSON reports
  --help              Show this help text

Environment:
  SKILLSPECTOR_CMD        Override the scanner command, for example:
                          "uvx --from <package> skillspector"
  SKILLSPECTOR_PACKAGE    Package used with uvx when SKILLSPECTOR_CMD is omitted
  SKILLSPECTOR_THRESHOLD  Default threshold when --threshold is omitted
EOF
}

resolve_directory() {
  local directory="$1"
  local drive
  local remainder
  local wsl_mount

  if [[ "$directory" =~ ^([[:alpha:]]):[/\\](.*)$ ]]; then
    drive="${BASH_REMATCH[1],,}"
    remainder="${BASH_REMATCH[2]//\\//}"
    wsl_mount="/mnt/$drive"
    if [[ -d "$wsl_mount" ]]; then
      printf '%s/%s\n' "$wsl_mount" "$remainder"
    else
      printf '%s\n' "$directory"
    fi
  elif [[ "$directory" == /* ]]; then
    printf '%s\n' "$directory"
  else
    printf '%s\n' "$REPO_ROOT/$directory"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="${2:?Missing value for --target}"
      shift 2
      ;;
    --baseline-dir)
      BASELINE_DIR="${2:?Missing value for --baseline-dir}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:?Missing value for --output-dir}"
      shift 2
      ;;
    --threshold)
      THRESHOLD="${2:?Missing value for --threshold}"
      shift 2
      ;;
    --show-suppressed)
      SHOW_SUPPRESSED=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option '$1'" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --threshold must be an integer, got '$THRESHOLD'" >&2
  exit 2
fi

abs_target=$(resolve_directory "$TARGET_DIR")
abs_baseline_dir=$(resolve_directory "$BASELINE_DIR")
abs_output_dir=$(resolve_directory "$OUTPUT_DIR")

if [[ ! -d "$abs_target" ]]; then
  echo "ERROR: Skill target directory not found: $TARGET_DIR" >&2
  exit 2
fi

if [[ ! -d "$abs_baseline_dir" || ! -r "$abs_baseline_dir" || ! -x "$abs_baseline_dir" ]]; then
  echo "ERROR: Framework SkillSpector baseline directory is missing or unreadable: $BASELINE_DIR" >&2
  echo "Restore the matching AIS Spec root-skills payload or pass --baseline-dir with a valid policy directory." >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required to generate SkillSpector reports." >&2
  exit 2
fi

mapfile -t skill_dirs < <(
  find "$abs_target" -mindepth 2 -maxdepth 2 -name SKILL.md -exec dirname {} \; \
    | sort
)

if [[ "${#skill_dirs[@]}" -eq 0 ]]; then
  echo "ERROR: No SKILL.md files found under $TARGET_DIR" >&2
  exit 2
fi

report_paths=()
report_manifest=()
declare -A report_owners=()

for skill_dir in "${skill_dirs[@]}"; do
  skill_name=$(basename "$skill_dir")
  safe_name="${skill_name//[^[:alnum:]_.-]/_}"
  report_name="$safe_name.json"
  report_path="$abs_output_dir/$report_name"
  baseline_path="$abs_baseline_dir/$skill_name.yaml"
  if [[ "$report_name" == "summary.json" || -n "${report_owners[$report_name]:-}" ]]; then
    echo "ERROR: Skill report output name collision: $report_name" >&2
    exit 2
  fi
  report_owners["$report_name"]="$skill_name"
  report_paths+=("$report_path")
  report_manifest+=("$skill_name" "$report_path" "$baseline_path")
  if [[ ! -f "$baseline_path" ]]; then
    echo "ERROR: Required framework SkillSpector baseline is missing: $baseline_path" >&2
    echo "Restore the matching AIS Spec root-skills payload or provide a complete --baseline-dir override." >&2
    exit 2
  fi
  if [[ ! -r "$baseline_path" ]]; then
    echo "ERROR: Required framework SkillSpector baseline is unreadable: $baseline_path" >&2
    echo "Restore readable permissions for the AIS Spec root-skills payload or provide a complete --baseline-dir override." >&2
    exit 2
  fi
done

if [[ -n "${SKILLSPECTOR_CMD:-}" ]]; then
  read -r -a scanner_cmd <<< "$SKILLSPECTOR_CMD"
elif command -v uv >/dev/null 2>&1; then
  scanner_cmd=(uvx --from "$SKILLSPECTOR_PACKAGE" skillspector)
elif command -v skillspector >/dev/null 2>&1; then
  scanner_cmd=(skillspector)
else
  echo "ERROR: uv and SkillSpector are unavailable." >&2
  echo "Install uv, install SkillSpector, or set SKILLSPECTOR_CMD." >&2
  exit 2
fi

mkdir -p "$abs_output_dir"
managed_artifacts=(
  "${report_paths[@]}"
  "$abs_output_dir/summary.md"
  "$abs_output_dir/summary.json"
  "$abs_output_dir/missing-baselines.txt"
)
for artifact_path in "${managed_artifacts[@]}"; do
  if [[ -e "$artifact_path" && ! -f "$artifact_path" ]]; then
    echo "ERROR: Managed SkillSpector output path is not a file: $artifact_path" >&2
    exit 2
  fi
  rm -f -- "$artifact_path"
done

scan_error_fields=()

echo "Running SkillSpector static scans for ${#skill_dirs[@]} skill(s)"
echo "Target: $TARGET_DIR"
echo "Threshold: score > $THRESHOLD fails"
echo "Scanner: ${scanner_cmd[*]}"

for index in "${!skill_dirs[@]}"; do
  skill_dir="${skill_dirs[$index]}"
  skill_name=$(basename "$skill_dir")
  report_path="${report_paths[$index]}"
  baseline_path="$abs_baseline_dir/$skill_name.yaml"

  scan_args=(scan "$skill_dir" --no-llm --format json --output "$report_path")
  scan_args+=(--baseline "$baseline_path")
  if [[ "$SHOW_SUPPRESSED" == "true" ]]; then
    scan_args+=(--show-suppressed)
  fi

  echo "::group::SkillSpector $skill_name"
  set +e
  "${scanner_cmd[@]}" "${scan_args[@]}"
  scan_status=$?
  set -e
  echo "::endgroup::"

  if [[ "$scan_status" -gt 1 ]]; then
    scan_error_fields+=("$skill_name" "$scan_status" "$report_path" "$baseline_path")
  elif [[ ! -s "$report_path" ]]; then
    scan_error_fields+=("$skill_name" "missing-report" "$report_path" "$baseline_path")
  fi
done

summary_md="$abs_output_dir/summary.md"
summary_json="$abs_output_dir/summary.json"

set +e
python3 - "$THRESHOLD" "$TARGET_DIR" "$summary_md" "$summary_json" \
  "${#skill_dirs[@]}" "${#scan_error_fields[@]}" \
  "${report_manifest[@]}" "${scan_error_fields[@]}" <<'PY'
import json
import sys
from pathlib import Path

threshold = int(sys.argv[1])
target_dir = sys.argv[2]
summary_md = Path(sys.argv[3])
summary_json = Path(sys.argv[4])
manifest_count = int(sys.argv[5])
error_field_count = int(sys.argv[6])
manifest_fields = sys.argv[7 : 7 + manifest_count * 3]
error_fields = sys.argv[7 + manifest_count * 3 :]

if len(manifest_fields) != manifest_count * 3 or len(error_fields) != error_field_count:
    raise ValueError("SkillSpector summary argument manifest is incomplete")
if error_field_count % 4 != 0:
    raise ValueError("SkillSpector summary error manifest is malformed")

manifest = [
    {
        "skill": manifest_fields[index],
        "report_path": Path(manifest_fields[index + 1]),
        "baseline_path": manifest_fields[index + 2],
    }
    for index in range(0, len(manifest_fields), 3)
]
errors = []
error_reports = set()
for index in range(0, len(error_fields), 4):
    skill, exit_code, report_path, baseline_path = error_fields[index : index + 4]
    error_reports.add(report_path)
    errors.append(
        {
            "kind": "scan" if exit_code.isdigit() else exit_code,
            "skill": skill,
            "exit_code": int(exit_code) if exit_code.isdigit() else None,
            "report": Path(report_path).name,
            "baseline": baseline_path,
        }
    )


class InvalidReportError(ValueError):
    """Raised when a scanner report does not match the pinned report contract."""


def require_mapping(value, field):
    if not isinstance(value, dict):
        raise InvalidReportError(f"{field} must be an object")
    return value


def require_string(value, field):
    if not isinstance(value, str) or not value:
        raise InvalidReportError(f"{field} must be a nonempty string")
    return value


def require_nonnegative_integer(value, field):
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise InvalidReportError(f"{field} must be a nonnegative integer")
    return value


def validate_report(data, item):
    report = require_mapping(data, "report")
    skill = require_mapping(report.get("skill"), "skill")
    skill_name = require_string(skill.get("name"), "skill.name")
    if skill_name != item["skill"]:
        raise InvalidReportError(
            f"skill.name {skill_name!r} does not match manifest skill {item['skill']!r}"
        )
    risk = require_mapping(report.get("risk_assessment"), "risk_assessment")
    score = require_nonnegative_integer(risk.get("score"), "risk_assessment.score")
    severity = require_string(risk.get("severity"), "risk_assessment.severity")
    recommendation = require_string(
        risk.get("recommendation"), "risk_assessment.recommendation"
    )
    issues = report.get("issues")
    if not isinstance(issues, list):
        raise InvalidReportError("issues must be an array")
    suppressed = require_nonnegative_integer(
        report.get("suppressed_count"), "suppressed_count"
    )
    return {
        "skill": skill_name,
        "score": score,
        "severity": severity,
        "recommendation": recommendation,
        "findings": len(issues),
        "suppressed": suppressed,
        "report": item["report_path"].name,
    }


rows = []
for item in manifest:
    path = item["report_path"]
    if str(path) in error_reports:
        continue
    if not path.is_file():
        errors.append(
            {
                "kind": "missing-report",
                "skill": item["skill"],
                "exit_code": None,
                "report": path.name,
                "baseline": item["baseline_path"],
            }
        )
        continue
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(
            {
                "kind": "invalid-report",
                "skill": item["skill"],
                "exit_code": None,
                "report": path.name,
                "baseline": item["baseline_path"],
                "detail": str(error),
            }
        )
        continue
    try:
        rows.append(validate_report(data, item))
    except InvalidReportError as error:
        errors.append(
            {
                "kind": "invalid-report",
                "skill": item["skill"],
                "exit_code": None,
                "report": path.name,
                "baseline": item["baseline_path"],
                "detail": str(error),
            }
        )

rows.sort(key=lambda item: (-item["score"], item["skill"]))
max_score = max((row["score"] for row in rows), default=0)
failing = [row for row in rows if row["score"] > threshold]
status = "ERROR" if errors else "FAIL" if failing else "PASS"

summary = {
    "status": status,
    "target": target_dir,
    "mode": "static --no-llm",
    "threshold": threshold,
    "max_score": max_score,
    "skills": rows,
}
if errors:
    summary["errors"] = errors
summary_json.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

lines = [
    "### SkillSpector Static Scan",
    "",
    f"- Status: {status}",
    f"- Target: `{target_dir}`",
    "- Mode: static `--no-llm`",
    f"- Failure rule: fail when any unsuppressed skill score is greater than {threshold}",
    f"- Max unsuppressed score: {max_score}",
    "",
]

lines.extend(
    [
        "| Skill | Score | Severity | Recommendation | Findings | Suppressed | Report |",
        "|-------|------:|----------|----------------|---------:|-----------:|--------|",
    ]
)

for row in rows:
    lines.append(
        "| {skill} | {score} | {severity} | {recommendation} | {findings} | "
        "{suppressed} | `{report}` |".format(**row)
    )

if failing:
    lines.extend(["", "Blocking findings:"])
    for row in failing:
        lines.append(
            f"- `{row['skill']}` scored {row['score']} "
            f"({row['severity']}, {row['recommendation']})"
        )

if errors:
    lines.extend(["", "Errors:"])
    for error in errors:
        detail = f"; {error['detail']}" if "detail" in error else ""
        exit_code = (
            f" exit code {error['exit_code']}" if error["exit_code"] is not None else ""
        )
        lines.append(
            f"- `{error['skill']}`: {error['kind']}{exit_code}; "
            f"report `{error['report']}`; baseline `{error['baseline']}`{detail}"
        )

summary_md.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"SkillSpector summary written to {summary_md}")
sys.exit({"PASS": 0, "FAIL": 1, "ERROR": 2}[status])
PY
summary_status=$?
set -e

if [[ -n "${GITHUB_STEP_SUMMARY:-}" && -f "$summary_md" ]]; then
  cat "$summary_md" >> "$GITHUB_STEP_SUMMARY"
fi

if [[ -f "$summary_md" ]]; then
  cat "$summary_md"
fi

if [[ "${#scan_error_fields[@]}" -gt 0 ]]; then
  echo "ERROR: SkillSpector scan errors prevented a complete summary." >&2
  echo "Inspect the listed policy paths and restore the matching AIS Spec root-skills payload if needed." >&2
  exit 2
fi

exit "$summary_status"
