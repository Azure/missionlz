from __future__ import annotations

import importlib.util
import os
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
UPGRADE_SCRIPT = REPO_ROOT / "Skills" / "ais-spec-upgrade" / "scripts" / "upgrade_framework.py"
COLLECTION_VALIDATOR = REPO_ROOT / ".specify" / "scripts" / "bash" / "validate-test-collection.sh"
MODULE_SPEC = importlib.util.spec_from_file_location("upgrade_framework", UPGRADE_SCRIPT)
assert MODULE_SPEC is not None
assert MODULE_SPEC.loader is not None
upgrade_framework = importlib.util.module_from_spec(MODULE_SPEC)
sys.modules[MODULE_SPEC.name] = upgrade_framework
MODULE_SPEC.loader.exec_module(upgrade_framework)


def git(cwd: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-C", str(cwd), *args],
        check=True,
        capture_output=True,
        text=True,
    )


def to_bash_path(path: Path) -> str:
    path_text = path.as_posix()
    if len(path_text) > 2 and path_text[1:3] == ":/":
        return f"/mnt/{path_text[0].lower()}/{path_text[3:]}"
    return path_text


class UpgradeFrameworkGitAttributesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.source_root = Path(self.tmp.name) / "source"
        self.project_root = Path(self.tmp.name) / "project"
        for path in (self.source_root, self.project_root):
            path.mkdir()
            git(path, "init", "--quiet")
            git(path, "config", "user.email", "test@example.com")
            git(path, "config", "user.name", "Test User")

        (self.source_root / ".gitattributes").write_text("*.sh text eol=lf\n", encoding="utf-8")
        policy = self.source_root / ".specify" / "policies" / "owner-resolution.md"
        policy.parent.mkdir(parents=True)
        policy.write_text("# Owner Resolution Policy\n", encoding="utf-8")
        git(self.source_root, "add", ".gitattributes", ".specify")
        git(self.source_root, "commit", "--quiet", "-m", "Add attributes")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _managed_file(self) -> upgrade_framework.ManagedFile:
        return upgrade_framework.ManagedFile(".gitattributes", "framework-core")

    def _policy_managed_file(self) -> upgrade_framework.ManagedFile:
        return upgrade_framework.ManagedFile(
            ".specify/policies/owner-resolution.md",
            "framework-core",
        )

    def test_absent_git_attributes_is_added_and_safely_applied(self) -> None:
        result = upgrade_framework.classify_file(
            self._managed_file(),
            self.project_root,
            self.source_root,
            "HEAD",
            None,
        )

        self.assertEqual(result.status, "added")
        self.assertTrue(result.safe_apply)
        self.assertEqual(
            upgrade_framework.apply_safe_updates(
                self.project_root,
                self.source_root,
                "HEAD",
                [result],
            ),
            [".gitattributes"],
        )
        self.assertEqual(
            (self.project_root / ".gitattributes").read_bytes(),
            upgrade_framework.git_show(self.source_root, "HEAD", ".gitattributes"),
        )

    def test_customized_git_attributes_requires_manual_review(self) -> None:
        (self.project_root / ".gitattributes").write_text("*.ps1 text eol=crlf\n", encoding="utf-8")

        result = upgrade_framework.classify_file(
            self._managed_file(),
            self.project_root,
            self.source_root,
            "HEAD",
            None,
        )

        self.assertEqual(result.status, "manual-review")
        self.assertFalse(result.safe_apply)
        self.assertEqual(
            upgrade_framework.apply_safe_updates(
                self.project_root,
                self.source_root,
                "HEAD",
                [result],
            ),
            [],
        )
        self.assertEqual(
            (self.project_root / ".gitattributes").read_text(encoding="utf-8"),
            "*.ps1 text eol=crlf\n",
        )

    def test_owner_resolution_policy_is_added_to_projects(self) -> None:
        result = upgrade_framework.classify_file(
            self._policy_managed_file(),
            self.project_root,
            self.source_root,
            "HEAD",
            None,
        )

        self.assertEqual(result.status, "added")
        self.assertEqual(
            upgrade_framework.apply_safe_updates(
                self.project_root,
                self.source_root,
                "HEAD",
                [result],
            ),
            [".specify/policies/owner-resolution.md"],
        )
        self.assertEqual(
            (self.project_root / ".specify" / "policies" / "owner-resolution.md").read_text(
                encoding="utf-8"
            ),
            "# Owner Resolution Policy\n",
        )


class ValidationCollectionPreflightTests(unittest.TestCase):
    def _run_validator(self, collection: Path, group: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "bash",
                "-c",
                " ".join(
                    [
                        "bash",
                        shlex.quote(to_bash_path(COLLECTION_VALIDATOR)),
                        shlex.quote(to_bash_path(collection)),
                        shlex.quote(group),
                    ]
                ),
            ],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_managed_collections_require_accessible_test_modules(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for group in ("framework-core", "root-skills"):
                missing = root / f"{group}-missing"
                missing_result = self._run_validator(missing, group)
                self.assertEqual(missing_result.returncode, 2, missing_result.stderr)
                self.assertIn(group, missing_result.stderr)

                empty = root / f"{group}-empty"
                empty.mkdir()
                empty_result = self._run_validator(empty, group)
                self.assertEqual(empty_result.returncode, 2, empty_result.stderr)
                self.assertIn(group, empty_result.stderr)

                non_matching = root / f"{group}-non-matching"
                non_matching.mkdir()
                (non_matching / "payload.py").write_text(
                    "import unittest\n",
                    encoding="utf-8",
                )
                non_matching_result = self._run_validator(non_matching, group)
                self.assertEqual(non_matching_result.returncode, 2, non_matching_result.stderr)
                self.assertIn("no discoverable test cases", non_matching_result.stderr)

                non_package = root / f"{group}-non-package"
                nested = non_package / "nested"
                nested.mkdir(parents=True)
                (nested / "test_payload.py").write_text(
                    "import unittest\n",
                    encoding="utf-8",
                )
                non_package_result = self._run_validator(non_package, group)
                self.assertEqual(non_package_result.returncode, 2, non_package_result.stderr)
                self.assertIn("no discoverable test cases", non_package_result.stderr)

                empty_package = root / f"{group}-empty-package"
                package = empty_package / "nested"
                package.mkdir(parents=True)
                (package / "__init__.py").write_text("", encoding="utf-8")
                (package / "test_payload.py").write_text(
                    "import unittest\n",
                    encoding="utf-8",
                )
                empty_package_result = self._run_validator(empty_package, group)
                self.assertEqual(empty_package_result.returncode, 2, empty_package_result.stderr)
                self.assertIn("no discoverable test cases", empty_package_result.stderr)

                discovery_error = root / f"{group}-discovery-error"
                discovery_error.mkdir()
                (discovery_error / "test_broken.py").write_text(
                    "raise RuntimeError('broken test import')\n",
                    encoding="utf-8",
                )
                discovery_error_result = self._run_validator(discovery_error, group)
                self.assertEqual(discovery_error_result.returncode, 2, discovery_error_result.stderr)
                self.assertIn("Test discovery failed", discovery_error_result.stderr)

                populated = root / f"{group}-populated"
                package = populated / "nested"
                package.mkdir(parents=True)
                (package / "__init__.py").write_text("", encoding="utf-8")
                (package / "test_payload.py").write_text(
                    "import unittest\n\n"
                    "class PayloadTests(unittest.TestCase):\n"
                    "    def test_payload(self):\n"
                    "        self.assertTrue(True)\n",
                    encoding="utf-8",
                )
                populated_result = self._run_validator(populated, group)
                self.assertEqual(populated_result.returncode, 0, populated_result.stderr)

    def test_validator_requires_directory_traversal_permission(self) -> None:
        source = COLLECTION_VALIDATOR.read_text(encoding="utf-8")

        self.assertIn('! -x "$collection"', source)


class UpgradeFrameworkValidationPayloadTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.source_root = Path(self.tmp.name) / "source"
        self.project_root = Path(self.tmp.name) / "project"
        for path in (self.source_root, self.project_root):
            path.mkdir()
            git(path, "init", "--quiet")
            git(path, "config", "user.email", "test@example.com")
            git(path, "config", "user.name", "Test User")

        self.framework_validation_path = ".specify/validation/tests/test_payload.py"
        self.skill_validation_path = "Skills/.ais-spec/validation/tests/test_payload.py"
        for validation_path in (
            self.framework_validation_path,
            self.skill_validation_path,
        ):
            source_file = self.source_root / validation_path
            source_file.parent.mkdir(parents=True)
            source_file.write_text(f"print('{validation_path}')\n", encoding="utf-8")
        git(self.source_root, "add", ".specify", "Skills")
        git(self.source_root, "commit", "--quiet", "-m", "Add validation payload")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_validation_payloads_are_grouped_and_safely_applied(self) -> None:
        framework_file = upgrade_framework.ManagedFile(
            self.framework_validation_path,
            "framework-core",
        )
        skill_file = upgrade_framework.ManagedFile(
            self.skill_validation_path,
            "root-skills",
        )
        managed = upgrade_framework.build_managed_files(
            self.project_root,
            self.source_root,
            "HEAD",
            None,
            upgrade_framework.group_paths(set(), False, self.project_root),
            {"framework-core", "root-skills"},
        )

        self.assertIn(framework_file, managed)
        self.assertIn(skill_file, managed)
        results = [
            upgrade_framework.classify_file(
                managed_file,
                self.project_root,
                self.source_root,
                "HEAD",
                None,
            )
            for managed_file in (framework_file, skill_file)
        ]
        self.assertTrue(all(result.status == "added" for result in results))
        self.assertTrue(all(result.safe_apply for result in results))
        self.assertEqual(
            upgrade_framework.apply_safe_updates(
                self.project_root,
                self.source_root,
                "HEAD",
                results,
            ),
            [self.framework_validation_path, self.skill_validation_path],
        )
        for validation_path in (
            self.framework_validation_path,
            self.skill_validation_path,
        ):
            self.assertEqual(
                (self.project_root / validation_path).read_text(encoding="utf-8"),
                f"print('{validation_path}')\n",
            )

    def test_legacy_root_validation_paths_remain_project_owned(self) -> None:
        legacy_test = self.project_root / "tests" / "test_project.py"
        legacy_baseline = self.project_root / ".skillspector-baselines" / "project.yaml"
        legacy_test.parent.mkdir()
        legacy_baseline.parent.mkdir()
        legacy_test.write_text("print('project test')\n", encoding="utf-8")
        legacy_baseline.write_text("version: 1\n", encoding="utf-8")

        managed = upgrade_framework.build_managed_files(
            self.project_root,
            self.source_root,
            "HEAD",
            None,
            {"root-skills": ["Skills"]},
            {"root-skills"},
        )

        self.assertNotIn(
            upgrade_framework.ManagedFile("tests/test_project.py", "root-skills"),
            managed,
        )
        self.assertNotIn(
            upgrade_framework.ManagedFile(".skillspector-baselines/project.yaml", "root-skills"),
            managed,
        )
        self.assertEqual(legacy_test.read_text(encoding="utf-8"), "print('project test')\n")
        self.assertEqual(legacy_baseline.read_text(encoding="utf-8"), "version: 1\n")


class DownstreamValidationIsolationTests(unittest.TestCase):
    def test_managed_payload_runs_without_discovering_project_tests(self) -> None:
        if os.environ.get("AIS_SPEC_DOWNSTREAM_SIMULATION") == "1":
            self.skipTest("Avoid recursively launching the downstream simulation.")

        with tempfile.TemporaryDirectory() as temporary_directory:
            project_root = Path(temporary_directory) / "project"
            project_root.mkdir()
            shutil.copytree(REPO_ROOT / "Skills", project_root / "Skills")
            shutil.copytree(REPO_ROOT / ".specify", project_root / ".specify")
            shutil.copy2(REPO_ROOT / ".gitattributes", project_root / ".gitattributes")
            workflow_path = project_root / ".github" / "workflows" / "ci.yml"
            workflow_path.parent.mkdir(parents=True)
            shutil.copy2(REPO_ROOT / ".github" / "workflows" / "ci.yml", workflow_path)
            project_test = project_root / "tests" / "test_project.py"
            project_test.parent.mkdir()
            project_test.write_text(
                "raise AssertionError('Project test must not be discovered')\n",
                encoding="utf-8",
            )
            skill_local_test = (
                project_root
                / "Skills"
                / "ais-azure-estimates"
                / "tests"
                / "test_project.py"
            )
            skill_local_test.write_text(
                "raise AssertionError('Skill-local test must not be discovered')\n",
                encoding="utf-8",
            )
            scanner = project_root / "scanner.sh"
            scanner.write_text(
                """#!/usr/bin/env bash
set -euo pipefail
while [[ $# -gt 0 ]]; do
  case "$1" in
    scan) skill_dir="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
skill_name="$(basename "$skill_dir")"
printf '{"skill":{"name":"%s"},"risk_assessment":{"score":0,"severity":"LOW","recommendation":"PASS"},"issues":[],"suppressed_count":0}\n' "$skill_name" > "$output"
""",
                encoding="utf-8",
newline="\n",
            )
            scanner.chmod(scanner.stat().st_mode | stat.S_IXUSR)
            git(project_root, "init", "--quiet")
            git(project_root, "config", "user.email", "test@example.com")
            git(project_root, "config", "user.name", "Test User")
            git(project_root, "add", ".")
            git(project_root, "commit", "--quiet", "-m", "Set up downstream project")

            environment = os.environ.copy()
            environment["AIS_SPEC_DOWNSTREAM_SIMULATION"] = "1"
            for collection, group in (
                (".specify/validation/tests", "framework-core"),
                ("Skills/.ais-spec/validation/tests", "root-skills"),
            ):
                preflight_command = " ".join(
                    [
                        f"PYTHON_BIN={shlex.quote(to_bash_path(Path(sys.executable)))}",
                        "bash",
                        ".specify/scripts/bash/validate-test-collection.sh",
                        shlex.quote(collection),
                        shlex.quote(group),
                    ]
                )
                preflight_result = subprocess.run(
                    [
                        "bash",
                        "-c",
                        preflight_command,
                    ],
                    cwd=project_root,
                    env=environment,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                preflight_output = preflight_result.stdout + preflight_result.stderr
                self.assertEqual(preflight_result.returncode, 0, preflight_output)

                result = subprocess.run(
                    [
                        sys.executable,
                        "-m",
                        "unittest",
                        "discover",
                        "-s",
                        collection,
                        "-p",
                        "test_*.py",
                    ],
                    cwd=project_root,
                    env=environment,
                    capture_output=True,
                    text=True,
                    check=False,
                )

                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output)
                self.assertNotIn("Project test must not be discovered", output)
                self.assertNotIn("Skill-local test must not be discovered", output)

            skillspector_result = subprocess.run(
                [
                    "bash",
                    "-c",
                    "SKILLSPECTOR_CMD='bash scanner.sh' "
                    "bash .specify/scripts/bash/run-skillspector.sh",
                ],
                cwd=project_root,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
            skillspector_output = skillspector_result.stdout + skillspector_result.stderr
            self.assertEqual(skillspector_result.returncode, 0, skillspector_output)
            self.assertIn("Target: Skills", skillspector_output)
            self.assertTrue(
                (project_root / "artifacts" / "skillspector" / "summary.json").is_file()
            )

            workflow = workflow_path.read_text(encoding="utf-8")
            self.assertIn(
                'framework_core_tests=".specify/validation/tests"',
                workflow,
            )
            self.assertIn(
                'skill_validation_tests="Skills/.ais-spec/validation/tests"',
                workflow,
            )
            self.assertIn(
                "bash .specify/scripts/bash/validate-test-collection.sh",
                workflow,
            )
            self.assertIn(
                '"$framework_core_tests" "framework-core"',
                workflow,
            )
            self.assertIn(
                '"$skill_validation_tests" "root-skills"',
                workflow,
            )
            self.assertIn("PYTHON_BIN=python", workflow)
            self.assertTrue(
                (
                    project_root
                    / ".specify"
                    / "scripts"
                    / "bash"
                    / "validate-test-collection.sh"
                ).is_file()
            )
            self.assertNotIn('discover -s tests -p "test_*.py"', workflow)
