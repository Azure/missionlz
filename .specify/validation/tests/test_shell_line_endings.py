from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]


def git_output(*args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(REPO_ROOT), "-c", "core.attributesFile=", *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


class ShellLineEndingTests(unittest.TestCase):
    def test_tracked_shell_scripts_are_lf_only(self) -> None:
        shell_scripts = [path for path in git_output("ls-files", "*.sh").splitlines() if path]

        self.assertTrue(shell_scripts)
        for relative_path in shell_scripts:
            content = (REPO_ROOT / relative_path).read_bytes()
            self.assertNotIn(b"\r\n", content, relative_path)
            self.assertNotIn(b"\r", content, relative_path)

    def test_git_attributes_scope_lf_to_shell_scripts(self) -> None:
        shell_attribute = git_output(
            "check-attr",
            "eol",
            "--",
            ".specify/scripts/bash/check-prerequisites.sh",
        ).strip()
        powershell_attribute = git_output("check-attr", "eol", "--", "example.ps1").strip()

        self.assertEqual(
            shell_attribute,
            ".specify/scripts/bash/check-prerequisites.sh: eol: lf",
        )
        self.assertEqual(powershell_attribute, "example.ps1: eol: unspecified")
