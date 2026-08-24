from __future__ import annotations

import argparse
import json
from pathlib import Path


INCOMPLETE_METHODS = {"none", "frame-only"}
INCOMPLETE_STATUSES = {"pending", "incomplete", "missing"}
FRAME_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate that a context package has completed visual analysis.")
    parser.add_argument("--manifest", required=True, help="Path to manifest.json")
    parser.add_argument(
        "--analysis",
        help="Path to agent visual analysis JSON (defaults to agent-visual-analysis.json beside the manifest)",
    )
    parser.add_argument(
        "--frames-dir",
        help="Path to the extracted frames directory (defaults to frames/ beside the manifest)",
    )
    parser.add_argument("--allow-incomplete", action="store_true", help="Report incomplete events but exit 0")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    package_dir = manifest_path.parent
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    failures: list[str] = []
    integrity_failures: list[str] = []

    retained_frames: set[Path] = set()
    for event in manifest.get("events", []):
        if event.get("status") == "rejected":
            integrity_failures.append(f"{event.get('id')}: rejected candidate remains in manifest; rerun pruning")
            continue
        frame_path = event.get("frame_path")
        if frame_path:
            resolved_frame = (package_dir / frame_path).resolve()
            retained_frames.add(resolved_frame)
            if not resolved_frame.is_file():
                integrity_failures.append(f"{event.get('id')}: referenced frame {frame_path} is missing")
        if event.get("status") != "extracted":
            continue
        analysis = event.get("visual_analysis") or {}
        method = analysis.get("method") or "none"
        status = analysis.get("status") or "missing"
        hierarchy = analysis.get("information_hierarchy") or []
        visible_text = analysis.get("visible_text") or ""
        if method in INCOMPLETE_METHODS or status in INCOMPLETE_STATUSES:
            failures.append(f"{event.get('id')}: incomplete analysis ({method}/{status})")
        elif not hierarchy and not visible_text:
            failures.append(f"{event.get('id')}: no visible_text or information_hierarchy")

    integrity_failures.extend(check_analysis_artifact(args.analysis, package_dir))
    integrity_failures.extend(check_orphan_frames(args.frames_dir, package_dir, retained_frames))

    if integrity_failures:
        print("Dirty context package:")
        for failure in integrity_failures:
            print(f"- {failure}")

    if failures:
        print("Incomplete visual analysis:")
        for failure in failures:
            print(f"- {failure}")

    if integrity_failures:
        return 1
    if failures:
        return 0 if args.allow_incomplete else 1

    print(
        "PASS: all retained extracted events have completed visual analysis; "
        "no rejected candidates or orphaned frames remain."
    )
    return 0


def check_analysis_artifact(analysis_arg: str | None, package_dir: Path) -> list[str]:
    analysis_path = Path(analysis_arg) if analysis_arg else package_dir / "agent-visual-analysis.json"
    if not analysis_path.is_file():
        return []
    try:
        analysis = json.loads(analysis_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return [f"{analysis_path.name}: invalid JSON ({error})"]
    failures: list[str] = []
    for event in analysis.get("events", []):
        if event.get("status") == "rejected":
            failures.append(
                f"{event.get('id')}: rejected entry remains in {analysis_path.name}; rerun the merge step"
            )
    return failures


def check_orphan_frames(frames_arg: str | None, package_dir: Path, retained_frames: set[Path]) -> list[str]:
    frames_dir = Path(frames_arg) if frames_arg else package_dir / "frames"
    if not frames_dir.is_dir():
        return []
    failures: list[str] = []
    for candidate in sorted(frames_dir.iterdir()):
        if not candidate.is_file() or candidate.suffix.lower() not in FRAME_SUFFIXES:
            continue
        if candidate.resolve() not in retained_frames:
            failures.append(
                f"{candidate.name}: orphaned frame not referenced by any retained event; rerun pruning"
            )
    return failures


if __name__ == "__main__":
    raise SystemExit(main())
