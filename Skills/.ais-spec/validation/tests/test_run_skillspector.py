from __future__ import annotations

import json
import shlex
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[4]
RUNNER = REPO_ROOT / ".specify" / "scripts" / "bash" / "run-skillspector.sh"


class RunSkillSpectorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory(dir=REPO_ROOT)
        self.workspace = Path(self.tmp.name)
        self.relative_workspace = self.workspace.relative_to(REPO_ROOT).as_posix()
        self.target_dir = self.workspace / "Skills"
        self.skill_dir = self.target_dir / "sample-skill"
        self.skill_dir.mkdir(parents=True)
        (self.skill_dir / "SKILL.md").write_text("# Sample\n", encoding="utf-8")
        self.baseline_dir = self.workspace / "baselines"
        self.baseline_dir.mkdir()
        self.scanner = self.workspace / "scanner.sh"
        self.scanner.write_bytes(
            """#!/usr/bin/env bash
set -euo pipefail
args_file="$(dirname "$0")/scanner-args.txt"
printf '%s\n' "$@" > "$args_file"
while [[ $# -gt 0 ]]; do
  case "$1" in
    scan) skill_dir="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    --baseline) baseline="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ -n "${baseline:-}" ]] && grep -Fq 'version: [' "$baseline"; then
  echo "Invalid baseline: $baseline" >&2
  exit 2
fi
skill_name="$(basename "$skill_dir")"
if [[ -n "${SCANNER_REPORT_DIR:-}" && -f "$SCANNER_REPORT_DIR/$skill_name.json" ]]; then
  cat "$SCANNER_REPORT_DIR/$skill_name.json" > "$output"
else
  printf '{"skill":{"name":"%s"},"risk_assessment":{"score":0,"severity":"LOW","recommendation":"PASS"},"issues":[],"suppressed_count":0}\n' "$skill_name" > "$output"
fi
""".encode("utf-8"),
        )
        self.scanner.chmod(self.scanner.stat().st_mode | stat.S_IXUSR)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    @staticmethod
    def _bash_path(path: Path) -> str:
        path_text = path.as_posix()
        if len(path_text) > 2 and path_text[1:3] == ":/":
            return f"/mnt/{path_text[0].lower()}/{path_text[3:]}"
        return path_text

    def _run(
        self,
        baseline_dir: Path,
        *,
        expect_success: bool,
        absolute_paths: bool = False,
        output_dir: Path | None = None,
        scanner_reports: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        report_dir = output_dir or self.workspace / "reports"
        if absolute_paths:
            target_arg = self.target_dir.as_posix()
            baseline_arg = baseline_dir.as_posix()
            output_arg = report_dir.as_posix()
        else:
            target_arg = self.target_dir.relative_to(REPO_ROOT).as_posix()
            baseline_arg = baseline_dir.relative_to(REPO_ROOT).as_posix()
            output_arg = report_dir.relative_to(REPO_ROOT).as_posix()

        command_parts = [
            f"SKILLSPECTOR_CMD={shlex.quote(f'bash {self.relative_workspace}/scanner.sh')}",
        ]
        if scanner_reports:
            scanner_report_dir = self.workspace / "scanner-reports"
            scanner_report_dir.mkdir(exist_ok=True)
            for skill_name, report in scanner_reports.items():
                (scanner_report_dir / f"{skill_name}.json").write_text(
                    report,
                    encoding="utf-8",
                )
            command_parts.append(
                f"SCANNER_REPORT_DIR={shlex.quote(scanner_report_dir.relative_to(REPO_ROOT).as_posix())}"
            )
        command_parts.extend(
            [
                "bash",
                ".specify/scripts/bash/run-skillspector.sh",
                "--target",
                shlex.quote(target_arg),
                "--baseline-dir",
                shlex.quote(baseline_arg),
                "--output-dir",
                shlex.quote(output_arg),
            ]
        )
        command = " ".join(command_parts)
        result = subprocess.run(
            ["bash", "-c", command],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if expect_success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def _add_skill(self, skill_name: str) -> None:
        skill_dir = self.target_dir / skill_name
        skill_dir.mkdir()
        (skill_dir / "SKILL.md").write_text("# Sample\n", encoding="utf-8")

    @staticmethod
    def _valid_report(skill_name: str) -> str:
        return json.dumps(
            {
                "skill": {"name": skill_name},
                "risk_assessment": {
                    "score": 0,
                    "severity": "LOW",
                    "recommendation": "PASS",
                },
                "issues": [],
                "suppressed_count": 0,
            }
        )

    def _write_baseline(self, content: str | None = None) -> Path:
        baseline = self.baseline_dir / "sample-skill.yaml"
        baseline.write_text(
            content
            or "version: 1\nrules: []\nfingerprints: []\n",
            encoding="utf-8",
        )
        return baseline

    def test_uses_distributed_baseline_override_for_scans(self) -> None:
        self._write_baseline()
        legacy_report = self.workspace / "reports" / "missing-baselines.txt"
        legacy_report.parent.mkdir()
        legacy_report.write_text("outdated-skill\n", encoding="utf-8")

        self._run(self.baseline_dir, expect_success=True)

        self.assertFalse(legacy_report.exists())
        scanner_args = (self.workspace / "scanner-args.txt").read_text(encoding="utf-8")
        self.assertIn("--baseline", scanner_args)
        self.assertIn("sample-skill.yaml", scanner_args)
        self.assertIn(
            "Status: PASS",
            (self.workspace / "reports" / "summary.md").read_text(encoding="utf-8"),
        )

    def test_output_cleanup_preserves_unrelated_external_json(self) -> None:
        self._write_baseline()
        with tempfile.TemporaryDirectory() as temporary_directory:
            report_dir = Path(temporary_directory)
            unrelated = report_dir / "unrelated.json"
            stale_report = report_dir / "sample-skill.json"
            unrelated.write_text('{"owner":"external"}\n', encoding="utf-8")
            stale_report.write_text('{"stale":true}\n', encoding="utf-8")
            (report_dir / "summary.json").write_text('{"stale":true}\n', encoding="utf-8")
            (report_dir / "summary.md").write_text("stale\n", encoding="utf-8")
            (report_dir / "missing-baselines.txt").write_text("stale\n", encoding="utf-8")

            self._run(
                self.baseline_dir,
                expect_success=True,
                absolute_paths=True,
                output_dir=report_dir,
            )

            self.assertEqual(unrelated.read_text(encoding="utf-8"), '{"owner":"external"}\n')
            self.assertNotIn("stale", stale_report.read_text(encoding="utf-8"))
            self.assertNotIn("stale", (report_dir / "summary.json").read_text(encoding="utf-8"))
            self.assertNotIn("stale", (report_dir / "summary.md").read_text(encoding="utf-8"))
            self.assertFalse((report_dir / "missing-baselines.txt").exists())

    def test_accepts_absolute_directory_options(self) -> None:
        self._write_baseline()

        self._run(self.baseline_dir, expect_success=True, absolute_paths=True)

        scanner_args = (self.workspace / "scanner-args.txt").read_text(encoding="utf-8")
        self.assertIn(self._bash_path(self.baseline_dir), scanner_args)

    def test_fails_with_remediation_when_baseline_directory_is_missing(self) -> None:
        missing_dir = self.workspace / "missing-baselines"

        result = self._run(missing_dir, expect_success=False)

        self.assertIn("missing-baselines", result.stderr)
        self.assertIn("AIS Spec root-skills payload", result.stderr)

    def test_fails_with_remediation_when_required_policy_is_missing(self) -> None:
        result = self._run(self.baseline_dir, expect_success=False)

        self.assertIn("sample-skill.yaml", result.stderr)
        self.assertIn("complete --baseline-dir override", result.stderr)

    def test_fails_with_remediation_when_scanner_rejects_policy(self) -> None:
        self._write_baseline("version: [\n")

        result = self._run(self.baseline_dir, expect_success=False)

        self.assertIn("sample-skill.yaml", result.stderr)
        self.assertIn("SkillSpector scan errors", result.stderr)
        self.assertIn("AIS Spec root-skills payload", result.stderr)

    def test_scanner_errors_produce_error_summary_with_successful_reports(self) -> None:
        self._write_baseline("version: [\n")
        self._add_skill("valid-skill")
        (self.baseline_dir / "valid-skill.yaml").write_text(
            "version: 1\nrules: []\nfingerprints: []\n",
            encoding="utf-8",
        )

        result = self._run(self.baseline_dir, expect_success=False)

        report_dir = self.workspace / "reports"
        summary = json.loads((report_dir / "summary.json").read_text(encoding="utf-8"))
        self.assertEqual(summary["status"], "ERROR")
        self.assertEqual([row["report"] for row in summary["skills"]], ["valid-skill.json"])
        self.assertEqual(summary["errors"][0]["kind"], "scan")
        self.assertEqual(summary["errors"][0]["skill"], "sample-skill")
        self.assertEqual(summary["errors"][0]["exit_code"], 2)
        summary_markdown = (report_dir / "summary.md").read_text(encoding="utf-8")
        self.assertIn("Status: ERROR", summary_markdown)
        self.assertIn("sample-skill", summary_markdown)
        self.assertIn("SkillSpector scan errors", result.stderr)

    def test_invalid_reports_produce_structured_error_summaries(self) -> None:
        invalid_reports = {
            "empty-object": "{}",
            "array-root": "[]",
            "noninteger-score": json.dumps(
                {
                    "skill": {"name": "sample-skill"},
                    "risk_assessment": {
                        "score": 1.5,
                        "severity": "LOW",
                        "recommendation": "PASS",
                    },
                    "issues": [],
                    "suppressed_count": 0,
                }
            ),
            "wrong-types": json.dumps(
                {
                    "skill": {"name": "sample-skill"},
                    "risk_assessment": {
                        "score": 0,
                        "severity": [],
                        "recommendation": "PASS",
                    },
                    "issues": {},
                    "suppressed_count": True,
                }
            ),
        }
        self._write_baseline()

        for case_name, report in invalid_reports.items():
            with self.subTest(case_name):
                result = self._run(
                    self.baseline_dir,
                    expect_success=False,
                    scanner_reports={"sample-skill": report},
                )

                report_dir = self.workspace / "reports"
                summary = json.loads((report_dir / "summary.json").read_text(encoding="utf-8"))
                self.assertEqual(result.returncode, 2)
                self.assertEqual(summary["status"], "ERROR")
                self.assertEqual(summary["skills"], [])
                self.assertEqual(summary["errors"][0]["kind"], "invalid-report")
                self.assertEqual(summary["errors"][0]["skill"], "sample-skill")
                self.assertIn(
                    "Status: ERROR",
                    (report_dir / "summary.md").read_text(encoding="utf-8"),
                )

    def test_mixed_valid_and_invalid_reports_preserve_valid_rows(self) -> None:
        self._write_baseline()
        self._add_skill("valid-skill")
        (self.baseline_dir / "valid-skill.yaml").write_text(
            "version: 1\nrules: []\nfingerprints: []\n",
            encoding="utf-8",
        )

        result = self._run(
            self.baseline_dir,
            expect_success=False,
            scanner_reports={
                "sample-skill": "{}",
                "valid-skill": self._valid_report("valid-skill"),
            },
        )

        summary = json.loads((self.workspace / "reports" / "summary.json").read_text(encoding="utf-8"))
        self.assertEqual(result.returncode, 2)
        self.assertEqual(summary["status"], "ERROR")
        self.assertEqual([row["skill"] for row in summary["skills"]], ["valid-skill"])
        self.assertEqual(summary["errors"][0]["kind"], "invalid-report")

    def test_default_policy_namespace_is_distributed(self) -> None:
        source = RUNNER.read_text(encoding="utf-8")

        self.assertIn(
            'BASELINE_DIR="Skills/.ais-spec/validation/skillspector-baselines"',
            source,
        )
        self.assertIn('! -x "$abs_baseline_dir"', source)
        self.assertNotIn("import yaml", source)
        self.assertIn("managed_artifacts", source)
        self.assertNotIn("-name '*.json'", source)

    def test_every_framework_skill_has_exactly_one_reviewed_baseline(self) -> None:
        baseline_dir = REPO_ROOT / "Skills" / ".ais-spec" / "validation" / "skillspector-baselines"
        skill_names = sorted(
            path.parent.name
            for path in (REPO_ROOT / "Skills").glob("*/SKILL.md")
        )

        baseline_names = sorted(path.stem for path in baseline_dir.glob("*.yaml"))

        self.assertTrue(skill_names)
        missing_baselines = sorted(set(skill_names) - set(baseline_names))
        stale_baselines = sorted(set(baseline_names) - set(skill_names))
        self.assertFalse(
            missing_baselines,
            f"Missing SkillSpector baselines for: {', '.join(missing_baselines)}",
        )
        self.assertFalse(
            stale_baselines,
            f"SkillSpector baselines without a matching skill: {', '.join(stale_baselines)}",
        )
        self.assertEqual(
            baseline_names,
            skill_names,
        )

    def test_skill_authoring_guidance_requires_a_baseline(self) -> None:
        skills_readme = (REPO_ROOT / "Skills" / "README.md").read_text(encoding="utf-8")

        self.assertIn("requires a matching baseline; CI rejects missing", skills_readme)
        self.assertIn(
            "Skills/.ais-spec/validation/skillspector-baselines/<skill>.yaml",
            skills_readme,
        )


if __name__ == "__main__":
    unittest.main()
