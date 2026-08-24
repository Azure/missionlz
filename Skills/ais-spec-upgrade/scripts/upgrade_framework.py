# /// script
# dependencies = []
# requires-python = ">=3.10"
# ///

"""Plan and apply conservative AIS Spec framework upgrades."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


DEFAULT_REMOTE = "https://github.com/ais-internal/AIS-spec.git"

CORE_PATHS = [
    ".specify",
    "PLANS.md",
    "CONTRIBUTING.md",
    ".gitattributes",
    ".gitignore",
    ".markdownlint.jsonc",
]

ROOT_SKILLS_PATHS = ["Skills"]

TOOL_PATHS = {
    "claude": [".claude/commands", "CLAUDE.md"],
    "copilot": [".github/agents", "AGENTS.md"],
    "codex": ["AGENTS.md", ".agents/skills"],
    "cursor": [".cursor/skills"],
}

OPTIONAL_GITHUB_PATHS = [
    ".github/workflows/ci.yml",
    ".github/pull_request_template.md",
]

SAFE_APPLY_STATUSES = {"source-updated", "added"}
DEFAULT_MAX_FILES = 30


@dataclass(frozen=True)
class ManagedFile:
    path: str
    group: str


@dataclass
class FileResult:
    path: str
    group: str
    status: str
    safe_apply: bool
    reason: str


def run(
    args: list[str],
    cwd: Path | None = None,
    check: bool = True,
    text: bool = True,
) -> subprocess.CompletedProcess:
    result = subprocess.run(
        args,
        cwd=cwd,
        capture_output=True,
        text=text,
        check=False,
    )
    if check and result.returncode != 0:
        stderr = result.stderr if text else result.stderr.decode("utf-8", "replace")
        raise RuntimeError(f"{' '.join(args)} failed: {stderr.strip()}")
    return result


def git(cwd: Path, *args: str, check: bool = True, text: bool = True):
    return run(["git", "-C", str(cwd), *args], check=check, text=text)


def git_root(path: Path) -> Path | None:
    result = git(path, "rev-parse", "--show-toplevel", check=False)
    if result.returncode != 0:
        return None
    return Path(result.stdout.strip())


def is_dirty_git_repo(path: Path) -> bool:
    root = git_root(path)
    if root is None:
        return False
    result = git(root, "status", "--porcelain", check=True)
    return bool(result.stdout.strip())


def ensure_source_repo(
    project_root: Path,
    source_arg: str | None,
    no_fetch: bool,
) -> Path:
    source = source_arg or os.environ.get("AIS_SPEC_SOURCE")
    if source:
        source_path = Path(source).expanduser().resolve()
        if not source_path.exists():
            raise RuntimeError(f"AIS Spec source path does not exist: {source_path}")
        source_root = git_root(source_path)
        if source_root is None:
            raise RuntimeError(f"AIS Spec source is not a git repo: {source_path}")
        if not no_fetch:
            git(source_root, "fetch", "--tags", "--prune", check=False)
        return source_root

    project_git = project_root / ".git"
    if not project_git.exists():
        raise RuntimeError(
            "No AIS Spec source provided and project has no .git cache location. "
            "Pass --source /path/to/ais-spec."
        )

    cache_root = project_git / "ais-spec-upgrade" / "source"
    if cache_root.exists():
        if not no_fetch:
            git(cache_root, "fetch", "--tags", "--prune", "origin", check=True)
    else:
        cache_root.parent.mkdir(parents=True, exist_ok=True)
        run(["git", "clone", "--filter=blob:none", DEFAULT_REMOTE, str(cache_root)])
        if not no_fetch:
            git(cache_root, "fetch", "--tags", "--prune", "origin", check=False)
    return cache_root


def resolve_target_ref(source_root: Path, target_ref: str | None) -> str:
    if target_ref:
        return target_ref
    if git(source_root, "rev-parse", "--verify", "origin/main", check=False).returncode == 0:
        return "origin/main"
    return "main"


def git_show(source_root: Path, ref: str, rel_path: str) -> bytes | None:
    result = git(source_root, "show", f"{ref}:{rel_path}", check=False, text=False)
    if result.returncode != 0:
        return None
    return result.stdout


def git_file_exists(source_root: Path, ref: str, rel_path: str) -> bool:
    return git(source_root, "cat-file", "-e", f"{ref}:{rel_path}", check=False).returncode == 0


def list_ref_files(source_root: Path, ref: str, rel_path: str) -> list[str]:
    result = git(
        source_root,
        "ls-tree",
        "-r",
        "--name-only",
        ref,
        "--",
        rel_path,
        check=False,
    )
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def list_project_files(project_root: Path, rel_path: str) -> list[str]:
    path = project_root / rel_path
    if path.is_file():
        return [rel_path]
    if not path.is_dir():
        return []
    files: list[str] = []
    for child in path.rglob("*"):
        if child.is_file():
            files.append(child.relative_to(project_root).as_posix())
    return sorted(files)


def read_project_file(project_root: Path, rel_path: str) -> bytes | None:
    path = project_root / rel_path
    if not path.is_file():
        return None
    return path.read_bytes()


def text_from_bytes(value: bytes | None) -> str:
    if value is None:
        return ""
    return value.decode("utf-8", "replace").strip()


def read_project_version(project_root: Path) -> tuple[str, str]:
    for rel_path in [".specify/VERSION", "VERSION"]:
        value = read_project_file(project_root, rel_path)
        if value is not None:
            return text_from_bytes(value), rel_path
    return "", ""


def source_versions(source_root: Path, ref: str) -> tuple[str, str]:
    specify_version = text_from_bytes(git_show(source_root, ref, ".specify/VERSION"))
    root_version = text_from_bytes(git_show(source_root, ref, "VERSION"))
    return specify_version, root_version


def parse_version(version: str) -> tuple[int, int, int] | None:
    match = re.match(r"^v?([0-9]+)\.([0-9]+)\.([0-9]+)$", version.strip())
    if not match:
        return None
    return tuple(int(part) for part in match.groups())


def version_gt(left: str, right: str) -> bool:
    parsed_left = parse_version(left)
    parsed_right = parse_version(right)
    if parsed_left is None or parsed_right is None:
        return left > right
    return parsed_left > parsed_right


def version_lte(left: str, right: str) -> bool:
    parsed_left = parse_version(left)
    parsed_right = parse_version(right)
    if parsed_left is None or parsed_right is None:
        return left <= right
    return parsed_left <= parsed_right


def parse_changelog(changelog: str, current: str, target: str) -> list[dict]:
    sections: list[dict] = []
    current_section: dict | None = None
    heading = re.compile(r"^## \[([0-9]+\.[0-9]+\.[0-9]+)\] - (.+)$")

    for line in changelog.splitlines():
        match = heading.match(line)
        if match:
            if current_section is not None:
                sections.append(current_section)
            current_section = {
                "version": match.group(1),
                "date": match.group(2),
                "body": [],
            }
            continue
        if current_section is not None:
            current_section["body"].append(line)

    if current_section is not None:
        sections.append(current_section)

    if not target:
        return []

    selected = []
    for section in sections:
        version = section["version"]
        if current and not version_gt(version, current):
            continue
        if not version_lte(version, target):
            continue
        body = "\n".join(section["body"]).strip()
        selected.append(
            {
                "version": version,
                "date": section["date"],
                "body": body,
            }
        )
    return selected


def detect_tools(project_root: Path) -> set[str]:
    tools = set()
    if (project_root / ".claude/commands").exists() or (project_root / "CLAUDE.md").exists():
        tools.add("claude")
    if (project_root / ".github/agents").exists() or (project_root / "AGENTS.md").exists():
        tools.add("copilot")
    if (project_root / ".agents/skills").exists() or (project_root / "AGENTS.md").exists():
        tools.add("codex")
    if (project_root / ".cursor/skills").exists():
        tools.add("cursor")
    return tools


def parse_tools(value: str, project_root: Path) -> set[str]:
    if value == "auto":
        return detect_tools(project_root)
    if value == "all":
        return set(TOOL_PATHS)
    tools = {item.strip() for item in value.split(",") if item.strip()}
    unknown = tools - set(TOOL_PATHS)
    if unknown:
        raise RuntimeError(f"Unknown tool(s): {', '.join(sorted(unknown))}")
    return tools


def selected_groups(
    value: str | None,
    selected_tools: set[str],
    include_optional_github: bool,
    project_root: Path,
) -> set[str]:
    groups = {"framework-core", "root-skills"}
    groups.update(f"tool-{tool}" for tool in selected_tools)
    optional_present = any((project_root / path).exists() for path in OPTIONAL_GITHUB_PATHS)
    if include_optional_github or optional_present:
        groups.add("optional-github")
    if not value:
        return groups

    requested = {item.strip() for item in value.split(",") if item.strip()}
    unknown = requested - groups
    if unknown:
        raise RuntimeError(
            "Requested group(s) are unavailable for this run: "
            + ", ".join(sorted(unknown))
            + ". Available groups: "
            + ", ".join(sorted(groups))
        )
    return requested


def group_paths(selected_tools: set[str], include_optional_github: bool, project_root: Path):
    groups: dict[str, list[str]] = {
        "framework-core": CORE_PATHS,
        "root-skills": ROOT_SKILLS_PATHS,
    }
    for tool in sorted(selected_tools):
        groups[f"tool-{tool}"] = TOOL_PATHS[tool]

    optional_present = any((project_root / path).exists() for path in OPTIONAL_GITHUB_PATHS)
    if include_optional_github or optional_present:
        groups["optional-github"] = OPTIONAL_GITHUB_PATHS
    return groups


def build_managed_files(
    project_root: Path,
    source_root: Path,
    target_ref: str,
    baseline_ref: str | None,
    groups: dict[str, list[str]],
    selected_group_names: set[str],
) -> list[ManagedFile]:
    files: dict[str, str] = {}

    for group, paths in groups.items():
        if group not in selected_group_names:
            continue
        for rel_path in paths:
            source_files = list_ref_files(source_root, target_ref, rel_path)
            project_files = list_project_files(project_root, rel_path)
            baseline_files: list[str] = []
            if baseline_ref:
                baseline_files = list_ref_files(source_root, baseline_ref, rel_path)
            if git_file_exists(source_root, target_ref, rel_path) and not source_files:
                source_files = [rel_path]
            if baseline_ref and git_file_exists(source_root, baseline_ref, rel_path) and not baseline_files:
                baseline_files = [rel_path]

            for file_path in sorted(set(source_files + project_files + baseline_files)):
                files.setdefault(file_path, group)

    return [ManagedFile(path=path, group=group) for path, group in sorted(files.items())]


def classify_file(
    managed: ManagedFile,
    project_root: Path,
    source_root: Path,
    target_ref: str,
    baseline_ref: str | None,
) -> FileResult:
    source_content = git_show(source_root, target_ref, managed.path)
    project_content = read_project_file(project_root, managed.path)
    baseline_content = git_show(source_root, baseline_ref, managed.path) if baseline_ref else None

    if source_content is None and project_content is None:
        status = "not-applicable"
        reason = "File is absent from both project and target source."
    elif source_content is None:
        status = "removed-or-obsolete"
        reason = "Project has a managed file that no longer exists in target source."
    elif project_content is None:
        if baseline_content is None:
            status = "added"
            reason = "Target source added a managed file missing from the project."
        else:
            status = "missing"
            reason = "Project deleted or never copied a file that existed in its baseline."
    elif project_content == source_content:
        status = "unchanged"
        reason = "Project already matches target source."
    elif baseline_ref is None:
        status = "manual-review"
        reason = "No recorded baseline tag was available for drift comparison."
    elif baseline_content is None:
        status = "manual-review"
        reason = "File did not exist in the recorded baseline but exists in both project and target."
    elif project_content == baseline_content:
        status = "source-updated"
        reason = "Project file matches baseline and target source changed it."
    elif source_content == baseline_content:
        status = "project-customized"
        reason = "Project changed this file while target source did not."
    else:
        status = "manual-review"
        reason = "Project and target source both changed this file since the baseline."

    return FileResult(
        path=managed.path,
        group=managed.group,
        status=status,
        safe_apply=status in SAFE_APPLY_STATUSES,
        reason=reason,
    )


def baseline_ref_for_version(source_root: Path, version: str) -> str | None:
    if not version:
        return None
    tag = f"v{version.lstrip('v')}"
    result = git(source_root, "rev-parse", "--verify", f"refs/tags/{tag}", check=False)
    if result.returncode == 0:
        return tag
    return None


def summarize_files(files: list[FileResult]) -> dict[str, int]:
    summary: dict[str, int] = {}
    for item in files:
        summary[item.status] = summary.get(item.status, 0) + 1
    return dict(sorted(summary.items()))


def apply_safe_updates(
    project_root: Path,
    source_root: Path,
    target_ref: str,
    files: list[FileResult],
) -> list[str]:
    changed: list[str] = []
    safe_files = [item for item in files if item.safe_apply]
    version_files = [item for item in safe_files if item.path == ".specify/VERSION"]
    non_version_files = [item for item in safe_files if item.path != ".specify/VERSION"]

    for item in non_version_files + version_files:
        if not item.safe_apply:
            continue
        content = git_show(source_root, target_ref, item.path)
        if content is None:
            continue
        output_path = project_root / item.path
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(content)
        changed.append(item.path)
    return changed


def build_report(
    project_root: Path,
    source_root: Path,
    target_ref: str,
    tools: set[str],
    group_names: set[str],
    include_optional_github: bool,
    max_files: int,
) -> dict:
    current_version, current_version_path = read_project_version(project_root)
    source_specify_version, source_root_version = source_versions(source_root, target_ref)
    target_version = source_specify_version or source_root_version
    baseline_ref = baseline_ref_for_version(source_root, current_version)
    warnings = []

    if not current_version:
        warnings.append("Project version not found in .specify/VERSION or VERSION.")
    if source_specify_version and source_root_version and source_specify_version != source_root_version:
        warnings.append(
            "AIS Spec source .specify/VERSION and VERSION disagree: "
            f"{source_specify_version} vs {source_root_version}."
        )
    if current_version and not baseline_ref:
        warnings.append(f"No AIS Spec release tag found for project version v{current_version}.")
    if current_version and target_version and not version_gt(target_version, current_version):
        warnings.append(
            f"Target version {target_version} is not newer than project version {current_version}."
        )

    groups = group_paths(tools, include_optional_github, project_root)
    managed_files = build_managed_files(
        project_root,
        source_root,
        target_ref,
        baseline_ref,
        groups,
        group_names,
    )
    file_results = [
        classify_file(item, project_root, source_root, target_ref, baseline_ref)
        for item in managed_files
    ]

    changelog_text = text_from_bytes(git_show(source_root, target_ref, "CHANGELOG.md"))
    changelog = parse_changelog(changelog_text, current_version, target_version)

    return {
        "project_root": str(project_root),
        "source_root": str(source_root),
        "target_ref": target_ref,
        "current_version": current_version,
        "current_version_path": current_version_path,
        "target_version": target_version,
        "source_specify_version": source_specify_version,
        "source_root_version": source_root_version,
        "root_version_policy": "Project-owned fallback; not copied by default.",
        "baseline_ref": baseline_ref,
        "selected_tools": sorted(tools),
        "selected_groups": sorted(group_names),
        "warnings": warnings,
        "changelog": changelog,
        "summary": summarize_files(file_results),
        "files": [item.__dict__ for item in file_results],
        "max_files": max_files,
    }


def render_markdown(report: dict, changed_files: list[str] | None = None) -> str:
    changed_files = changed_files or []
    lines = [
        "# AIS Spec Upgrade Report",
        "",
        f"- Project: `{report['project_root']}`",
        f"- AIS Spec source: `{report['source_root']}`",
        f"- Target ref: `{report['target_ref']}`",
        f"- Current version: `{report['current_version'] or 'unknown'}`"
        + (
            f" from `{report['current_version_path']}`"
            if report["current_version_path"]
            else ""
        ),
        f"- Target version: `{report['target_version'] or 'unknown'}`",
        f"- Root `VERSION`: {report['root_version_policy']}",
        f"- Baseline ref: `{report['baseline_ref'] or 'unavailable'}`",
        f"- Selected tools: `{', '.join(report['selected_tools']) or 'none'}`",
        f"- Selected groups: `{', '.join(report['selected_groups'])}`",
        "",
    ]

    if report["warnings"]:
        lines.extend(["## Warnings", ""])
        lines.extend(f"- {warning}" for warning in report["warnings"])
        lines.append("")

    lines.extend(["## Changelog", ""])
    if report["changelog"]:
        for entry in report["changelog"]:
            lines.append(f"### {entry['version']} - {entry['date']}")
            lines.append("")
            lines.append(entry["body"] or "_No details recorded._")
            lines.append("")
    else:
        lines.extend(["No changelog entries found between current and target versions.", ""])

    lines.extend(["## File Summary", "", "| Status | Count |", "| --- | ---: |"])
    for status, count in report["summary"].items():
        lines.append(f"| `{status}` | {count} |")
    lines.append("")

    files = report["files"]
    max_files = report["max_files"]
    for status in [
        "source-updated",
        "added",
        "manual-review",
        "project-customized",
        "missing",
        "removed-or-obsolete",
        "unchanged",
    ]:
        matching = [item for item in files if item["status"] == status]
        if not matching:
            continue
        lines.extend([f"## {status}", ""])
        for item in matching[:max_files]:
            lines.append(f"- `{item['path']}` ({item['group']}) - {item['reason']}")
        if len(matching) > max_files:
            lines.append(f"- ... {len(matching) - max_files} more")
        lines.append("")

    lines.extend(
        [
            "## Decision Options",
            "",
            "1. Report only - no files changed.",
            "2. Apply safe updates - copy only `source-updated` and `added` files.",
            "3. Choose groups - rerun with `--groups` and `--mode apply-safe`.",
            "4. Cancel - stop without changes.",
            "",
        ]
    )

    if changed_files:
        lines.extend(["## Applied Changes", ""])
        for path in changed_files:
            lines.append(f"- `{path}`")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Plan or apply a conservative AIS Spec framework upgrade."
    )
    parser.add_argument("--project", default=".", help="Project repo to inspect or upgrade.")
    parser.add_argument(
        "--source",
        help="AIS Spec source repo path. Defaults to AIS_SPEC_SOURCE or a cached clone.",
    )
    parser.add_argument(
        "--target-ref",
        help="AIS Spec target ref, such as origin/main, main, v0.14.0, or a commit SHA.",
    )
    parser.add_argument(
        "--tools",
        default="auto",
        help="AI tool surfaces to include: auto, all, or comma list of claude,copilot,codex,cursor.",
    )
    parser.add_argument(
        "--groups",
        help="Comma-separated groups to include, such as framework-core,root-skills,tool-codex.",
    )
    parser.add_argument(
        "--include-optional-github",
        action="store_true",
        help="Include optional .github CI and PR template files even if missing from the project.",
    )
    parser.add_argument(
        "--mode",
        choices=["report", "apply-safe"],
        default="report",
        help="Report only or apply non-conflicting updates.",
    )
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow apply-safe in a dirty git worktree after explicit user approval.",
    )
    parser.add_argument("--json", action="store_true", help="Write JSON output.")
    parser.add_argument("--no-fetch", action="store_true", help="Do not fetch source repo refs.")
    parser.add_argument(
        "--max-files",
        type=int,
        default=DEFAULT_MAX_FILES,
        help="Maximum file paths to show per status in markdown output.",
    )
    args = parser.parse_args()

    try:
        project_root = Path(args.project).expanduser().resolve()
        if not project_root.exists():
            raise RuntimeError(f"Project path does not exist: {project_root}")
        project_root = git_root(project_root) or project_root

        source_root = ensure_source_repo(project_root, args.source, args.no_fetch)
        target_ref = resolve_target_ref(source_root, args.target_ref)
        tools = parse_tools(args.tools, project_root)
        groups = selected_groups(
            args.groups,
            tools,
            args.include_optional_github,
            project_root,
        )

        report = build_report(
            project_root=project_root,
            source_root=source_root,
            target_ref=target_ref,
            tools=tools,
            group_names=groups,
            include_optional_github=args.include_optional_github,
            max_files=args.max_files,
        )

        changed_files: list[str] = []
        if args.mode == "apply-safe":
            if is_dirty_git_repo(project_root) and not args.allow_dirty:
                raise RuntimeError(
                    "Project worktree is dirty. Review git status, create an "
                    "upgrade branch, or rerun with --allow-dirty after approval."
                )
            file_results = [FileResult(**item) for item in report["files"]]
            changed_files = apply_safe_updates(
                project_root,
                source_root,
                target_ref,
                file_results,
            )
            report["applied_files"] = changed_files

        if args.json:
            print(json.dumps(report, indent=2))
        else:
            print(render_markdown(report, changed_files=changed_files))
        return 0
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
