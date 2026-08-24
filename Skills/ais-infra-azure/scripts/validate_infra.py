#!/usr/bin/env python3
"""Validate Azure infrastructure files against AIS standards.

Supports both Bicep and Terraform. Auto-detects language from file extensions
or accepts explicit --lang flag.

Checks (both languages):
- Lint pass (Bicep: az bicep lint / Terraform: terraform validate + tflint)
- AVM modules are version-pinned
- No non-AVM module references without matching ADR
- Required tags present in resource definitions
- No hardcoded secrets or connection strings

Additional Terraform checks:
- No committed .tfstate files
- Remote backend configured
- Provider versions pinned

Exit codes:
  0  No errors (warnings may be present)
  1  One or more errors found, or unexpected failure

Usage:
    python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/
    python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --lang bicep
    python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --lang terraform
    python3 Skills/ais-infra-azure/scripts/validate_infra.py --path infra/ --json
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


# --- Constants ---

# Bicep patterns
BICEP_AVM_VERSIONED = re.compile(
    r"'br/public:avm/(res|ptn|utl)/[^']+:[\d]+\.[\d]+\.[\d]+'"
)
# Matches an AVM ref that has no version suffix (no colon followed by digits)
BICEP_AVM_UNVERSIONED = re.compile(
    r"'br/public:avm/(res|ptn|utl)/[^':]+'"
)
BICEP_MODULE_REF = re.compile(r"module\s+\w+\s+'([^']+)'")
BICEP_COMMENT = re.compile(r"^\s*//")

# Terraform patterns
TF_MODULE_SOURCE = re.compile(r'source\s*=\s*"([^"]+)"')
TF_MODULE_VERSION = re.compile(r'version\s*=\s*"([^"]+)"')
TF_AVM_SOURCE = re.compile(r'"Azure/avm-(res|ptn|utl)-[^"]+/azurerm"')
TF_MODULE_BLOCK = re.compile(r'module\s+"[^"]+"\s*\{')
TF_BACKEND_BLOCK = re.compile(r'backend\s+"azurerm"')
TF_PROVIDER_VERSION = re.compile(r'version\s*=\s*"[~><=!]*\s*[\d.]+"')

# Common patterns
# Must match CAF-TAG-001 in standards/naming-tagging.md
REQUIRED_TAGS = {"environment", "project", "owner", "cost-center", "managed-by"}
SECRET_PATTERNS = [
    re.compile(r"password\s*[:=]\s*['\"][^'\"]+['\"]", re.IGNORECASE),
    re.compile(r"secret\s*[:=]\s*['\"][^'\"]+['\"]", re.IGNORECASE),
    re.compile(r"connection.?string\s*[:=]\s*['\"][^'\"]+['\"]", re.IGNORECASE),
    re.compile(r"account.?key\s*[:=]\s*['\"][^'\"]+['\"]", re.IGNORECASE),
]


def detect_language(path: Path) -> str:
    """Auto-detect IaC language from file extensions."""
    bicep_files = list(path.rglob("*.bicep"))
    tf_files = list(path.rglob("*.tf"))
    if bicep_files and not tf_files:
        return "bicep"
    if tf_files and not bicep_files:
        return "terraform"
    if bicep_files and tf_files:
        # Mixed — flag as issue but proceed with majority
        if len(tf_files) >= len(bicep_files):
            return "terraform"
        return "bicep"
    return "unknown"


# --- Bicep Checks ---


def find_bicep_files(path: Path) -> list[Path]:
    """Find all .bicep files recursively."""
    return sorted(path.rglob("*.bicep"))


def run_bicep_lint(file: Path) -> list[dict]:
    """Run az bicep lint on a file and return issues."""
    issues = []
    try:
        result = subprocess.run(
            ["az", "bicep", "lint", "--file", str(file)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            issues.append(
                {
                    "file": str(file),
                    "rule": "bicep-lint",
                    "severity": "error",
                    "message": result.stderr.strip() or "Bicep lint failed",
                }
            )
    except FileNotFoundError:
        issues.append(
            {
                "file": str(file),
                "rule": "bicep-lint",
                "severity": "warning",
                "message": "az CLI not found — skipping lint",
            }
        )
    except subprocess.TimeoutExpired:
        issues.append(
            {
                "file": str(file),
                "rule": "bicep-lint",
                "severity": "warning",
                "message": "Bicep lint timed out",
            }
        )
    return issues


def check_bicep_avm_versioning(file: Path, content: str) -> list[dict]:
    """Check that all Bicep AVM module references are version-pinned."""
    issues = []
    for i, line in enumerate(content.splitlines(), 1):
        # Skip comments
        if BICEP_COMMENT.match(line):
            continue
        if BICEP_AVM_UNVERSIONED.search(line) and not BICEP_AVM_VERSIONED.search(line):
            issues.append(
                {
                    "file": str(file),
                    "line": i,
                    "rule": "avm-version-pin",
                    "severity": "error",
                    "message": f"AVM module reference missing version pin: {line.strip()}",
                }
            )
    return issues


def check_bicep_non_avm_modules(file: Path, content: str, adr_dir: Path) -> list[dict]:
    """Check that non-AVM Bicep module references have a matching ADR."""
    issues = []
    for i, line in enumerate(content.splitlines(), 1):
        # Skip comments
        if BICEP_COMMENT.match(line):
            continue
        match = BICEP_MODULE_REF.search(line)
        if not match:
            continue
        module_ref = match.group(1)
        if "avm/" in module_ref:
            continue
        # Local or registry custom module — require ADR
        if not _has_adr_for_custom_module(module_ref, adr_dir):
            issues.append(
                {
                    "file": str(file),
                    "line": i,
                    "rule": "avm-first",
                    "severity": "error",
                    "message": (
                        f"Custom module '{module_ref}' used without ADR justification. "
                        "Create an ADR explaining why AVM is insufficient."
                    ),
                }
            )
    return issues


# --- Terraform Checks ---


def find_tf_files(path: Path) -> list[Path]:
    """Find all .tf files recursively."""
    return sorted(path.rglob("*.tf"))


def run_terraform_validate(path: Path) -> list[dict]:
    """Run terraform init (no backend) then terraform validate and return issues."""
    issues = []
    try:
        # init with -backend=false so no credentials needed in CI
        init_result = subprocess.run(
            ["terraform", "init", "-backend=false", "-input=false"],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=str(path),
        )
        if init_result.returncode != 0:
            issues.append(
                {
                    "file": str(path),
                    "rule": "terraform-validate",
                    "severity": "error",
                    "message": f"terraform init failed: {init_result.stderr.strip()[:200]}",
                }
            )
            return issues

        result = subprocess.run(
            ["terraform", "validate", "-json"],
            capture_output=True,
            text=True,
            timeout=60,
            cwd=str(path),
        )
        if result.returncode != 0:
            try:
                output = json.loads(result.stdout)
                for diag in output.get("diagnostics", []):
                    issues.append(
                        {
                            "file": str(path),
                            "rule": "terraform-validate",
                            "severity": "error",
                            "message": diag.get("summary", "Terraform validate failed"),
                        }
                    )
            except json.JSONDecodeError:
                issues.append(
                    {
                        "file": str(path),
                        "rule": "terraform-validate",
                        "severity": "error",
                        "message": result.stderr.strip() or "Terraform validate failed",
                    }
                )
    except FileNotFoundError:
        issues.append(
            {
                "file": str(path),
                "rule": "terraform-validate",
                "severity": "warning",
                "message": "terraform CLI not found — skipping validate",
            }
        )
    except subprocess.TimeoutExpired:
        issues.append(
            {
                "file": str(path),
                "rule": "terraform-validate",
                "severity": "warning",
                "message": "Terraform init/validate timed out",
            }
        )
    return issues


def check_tf_avm_versioning(file: Path, content: str) -> list[dict]:
    """Check that Terraform AVM module references are version-pinned."""
    issues = []
    lines = content.splitlines()
    in_module = False
    module_start_line = 0
    has_source = False
    has_version = False
    is_avm = False
    source_line = ""
    brace_depth = 0

    for i, line in enumerate(lines, 1):
        if TF_MODULE_BLOCK.search(line):
            # Flush previous module if unclosed
            if in_module and is_avm and has_source and not has_version:
                issues.append(
                    {
                        "file": str(file),
                        "line": module_start_line,
                        "rule": "avm-version-pin",
                        "severity": "error",
                        "message": f"AVM module missing version pin: {source_line.strip()}",
                    }
                )
            in_module = True
            module_start_line = i
            has_source = False
            has_version = False
            is_avm = False
            source_line = ""
            brace_depth = line.count("{") - line.count("}")
        elif in_module:
            brace_depth += line.count("{") - line.count("}")
            source_match = TF_MODULE_SOURCE.search(line)
            if source_match:
                has_source = True
                source_line = line
                if TF_AVM_SOURCE.search(line):
                    is_avm = True
            if TF_MODULE_VERSION.search(line):
                has_version = True
            if brace_depth <= 0:
                if is_avm and has_source and not has_version:
                    issues.append(
                        {
                            "file": str(file),
                            "line": module_start_line,
                            "rule": "avm-version-pin",
                            "severity": "error",
                            "message": f"AVM module missing version pin: {source_line.strip()}",
                        }
                    )
                in_module = False

    return issues


def check_tf_non_avm_modules(file: Path, content: str, adr_dir: Path) -> list[dict]:
    """Check that non-AVM Terraform module references have a matching ADR."""
    issues = []
    lines = content.splitlines()
    in_module = False
    module_start_line = 0
    brace_depth = 0

    for i, line in enumerate(lines, 1):
        if TF_MODULE_BLOCK.search(line):
            in_module = True
            module_start_line = i
            brace_depth = line.count("{") - line.count("}")
        elif in_module:
            brace_depth += line.count("{") - line.count("}")
            source_match = TF_MODULE_SOURCE.search(line)
            if source_match:
                source = source_match.group(1)
                if not ("avm-" in source or "avm/" in source):
                    if not _has_adr_for_custom_module(source, adr_dir):
                        issues.append(
                            {
                                "file": str(file),
                                "line": module_start_line,
                                "rule": "avm-first",
                                "severity": "error",
                                "message": (
                                    f"Non-AVM module '{source}' used without ADR justification. "
                                    "Create an ADR explaining why AVM is insufficient."
                                ),
                            }
                        )
            if brace_depth <= 0:
                in_module = False

    return issues


def check_tf_state_files(path: Path) -> list[dict]:
    """Check for committed .tfstate files."""
    issues = []
    for state_file in path.rglob("*.tfstate*"):
        issues.append(
            {
                "file": str(state_file),
                "rule": "no-local-state",
                "severity": "error",
                "message": "Terraform state file found in repository. Use remote backend.",
            }
        )
    return issues


def check_tf_backend(path: Path) -> list[dict]:
    """Check that a remote backend is configured."""
    issues = []
    backend_found = False
    for tf_file in path.rglob("*.tf"):
        content = tf_file.read_text(encoding="utf-8", errors="ignore")
        if TF_BACKEND_BLOCK.search(content):
            backend_found = True
            break
    if not backend_found:
        # Only warn if there are .tf files (not an empty project)
        tf_files = list(path.rglob("*.tf"))
        if tf_files:
            issues.append(
                {
                    "file": str(path),
                    "rule": "remote-backend",
                    "severity": "warning",
                    "message": "No remote backend configured. Configure azurerm backend for state management.",
                }
            )
    return issues


def check_tf_provider_pinning(path: Path) -> list[dict]:
    """Check that provider versions are pinned."""
    issues = []
    for tf_file in path.rglob("*.tf"):
        content = tf_file.read_text(encoding="utf-8", errors="ignore")
        if "required_providers" in content and "azurerm" in content:
            if not TF_PROVIDER_VERSION.search(content):
                issues.append(
                    {
                        "file": str(tf_file),
                        "rule": "provider-version-pin",
                        "severity": "error",
                        "message": "azurerm provider version not pinned in required_providers block.",
                    }
                )
    return issues


# --- Common Checks ---


def _has_adr_for_custom_module(module_ref: str, adr_dir: Path) -> bool:
    """Check if an ADR exists justifying a custom module."""
    if not adr_dir.exists():
        return False
    module_name = Path(module_ref).stem
    for adr_file in adr_dir.rglob("*.md"):  # rglob to find ADRs in subdirectories
        content = adr_file.read_text(encoding="utf-8", errors="ignore")
        if module_name in content.lower() or "custom module" in content.lower():
            return True
    return False


def check_secrets(file: Path, content: str) -> list[dict]:
    """Check for hardcoded secrets."""
    issues = []
    for i, line in enumerate(content.splitlines(), 1):
        # Skip comments
        stripped = line.strip()
        if stripped.startswith("#") or stripped.startswith("//"):
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(line):
                issues.append(
                    {
                        "file": str(file),
                        "line": i,
                        "rule": "no-hardcoded-secrets",
                        "severity": "error",
                        "message": f"Possible hardcoded secret: {line.strip()[:80]}",
                    }
                )
                break
    return issues


def check_tags(file: Path, content: str, lang: str) -> list[dict]:
    """Check that resource definitions reference all required tag keys.

    Looks for each required tag key as a quoted string or object key in the
    file. Note: this is a per-file check. If tags are defined in a shared
    variables.tf or locals.tf, they won't be detected in the resource file.
    False negatives are possible when tags are passed as a variable reference
    (e.g. `tags = var.tags`). This is a warning, not an error.
    """
    issues = []
    # Only flag files that actually define resources or modules
    has_resources = "module " in content or "resource " in content
    if not has_resources:
        return issues

    # If the file uses a tag variable reference, skip per-key check
    # (tags defined in another file and passed as a variable)
    tag_var_pattern = re.compile(r'tags\s*[=:]\s*(?:var\.|local\.|module\.)', re.IGNORECASE)
    if tag_var_pattern.search(content):
        return issues

    missing = []
    for tag in sorted(REQUIRED_TAGS):
        # Match the tag key as a quoted string or unquoted object key
        pattern = re.compile(
            r'(?:' + re.escape(f"'{tag}'") + r'|' + re.escape(f'"{tag}"') + r'|\b' + re.escape(tag) + r'\s*[=:])',
            re.IGNORECASE,
        )
        if not pattern.search(content):
            missing.append(tag)

    if missing:
        issues.append(
            {
                "file": str(file),
                "rule": "required-tags",
                "severity": "warning",
                "message": (
                    f"Missing required tag key(s): {', '.join(missing)}. "
                    f"All resources must include: {', '.join(sorted(REQUIRED_TAGS))}"
                ),
            }
        )
    return issues


# --- Main Validation ---


def validate(path: Path, lang: str | None = None, output_json: bool = False) -> int:
    """Run all validation checks and report results."""
    infra_path = Path(path)
    if not infra_path.exists():
        print(f"ERROR: Path '{infra_path}' does not exist", file=sys.stderr)
        return 1

    # Detect or validate language
    detected = detect_language(infra_path)
    if lang is None:
        lang = detected
    if lang == "unknown":
        print(f"No .bicep or .tf files found in '{infra_path}'", file=sys.stderr)
        return 0

    # Look for ADR directory
    adr_dir = infra_path.parent / "specs" / ".architecture"
    if not adr_dir.exists():
        adr_dir = infra_path.parent / "docs" / "adrs"

    all_issues: list[dict] = []

    if lang == "bicep":
        bicep_files = find_bicep_files(infra_path)
        if not bicep_files:
            print(f"No .bicep files found in '{infra_path}'", file=sys.stderr)
            return 0

        for file in bicep_files:
            content = file.read_text(encoding="utf-8", errors="ignore")
            all_issues.extend(check_bicep_avm_versioning(file, content))
            all_issues.extend(check_bicep_non_avm_modules(file, content, adr_dir))
            all_issues.extend(check_secrets(file, content))
            all_issues.extend(check_tags(file, content, lang))
            all_issues.extend(run_bicep_lint(file))

        files_checked = len(bicep_files)

    elif lang == "terraform":
        tf_files = find_tf_files(infra_path)
        if not tf_files:
            print(f"No .tf files found in '{infra_path}'", file=sys.stderr)
            return 0

        for file in tf_files:
            content = file.read_text(encoding="utf-8", errors="ignore")
            all_issues.extend(check_tf_avm_versioning(file, content))
            all_issues.extend(check_tf_non_avm_modules(file, content, adr_dir))
            all_issues.extend(check_secrets(file, content))
            all_issues.extend(check_tags(file, content, lang))

        # Directory-level checks
        all_issues.extend(check_tf_state_files(infra_path))
        all_issues.extend(check_tf_backend(infra_path))
        all_issues.extend(check_tf_provider_pinning(infra_path))
        all_issues.extend(run_terraform_validate(infra_path))

        files_checked = len(tf_files)
    else:
        print(f"Unsupported language: {lang}", file=sys.stderr)
        return 1

    # Report results
    errors = [i for i in all_issues if i["severity"] == "error"]
    warnings = [i for i in all_issues if i["severity"] == "warning"]

    if output_json:
        print(
            json.dumps(
                {
                    "language": lang,
                    "files_checked": files_checked,
                    "errors": len(errors),
                    "warnings": len(warnings),
                    "issues": all_issues,
                },
                indent=2,
            )
        )
    else:
        print(f"\n[{lang.upper()}] Checked {files_checked} file(s)")
        print(f"Errors: {len(errors)} | Warnings: {len(warnings)}\n")

        for issue in all_issues:
            severity = issue["severity"].upper()
            location = issue["file"]
            if "line" in issue:
                location += f":{issue['line']}"
            print(f"  [{severity}] {location}")
            print(f"    Rule: {issue['rule']}")
            print(f"    {issue['message']}\n")

        if not all_issues:
            print("  All checks passed.\n")

    return 1 if errors else 0


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate Azure infrastructure against AIS standards (Bicep + Terraform)"
    )
    parser.add_argument(
        "--path",
        required=True,
        help="Path to the infrastructure directory (e.g., infra/)",
    )
    parser.add_argument(
        "--lang",
        choices=["bicep", "terraform"],
        default=None,
        help="IaC language (auto-detected if omitted)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )
    args = parser.parse_args()

    sys.exit(validate(Path(args.path), lang=args.lang, output_json=args.json))


if __name__ == "__main__":
    main()
