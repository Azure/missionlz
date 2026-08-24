#!/usr/bin/env python3
"""Validate an AIS SOW DOCX and record render and content reviews."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from sow_docx import (
    SowDocxError,
    compute_client_ready,
    load_manifest,
    resolve_template,
    validate_generated_document,
    validate_input,
)


SKILL_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = SKILL_ROOT / "assets" / "template-manifest.json"


def _write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Generated DOCX")
    parser.add_argument("--source", required=True, type=Path, help="Source SOW JSON")
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--render-reviewed", choices=("pass", "fail"))
    parser.add_argument("--renderer", help="Renderer name/version used")
    parser.add_argument("--page-count", type=int)
    parser.add_argument("--review-notes", default="")
    parser.add_argument("--content-reviewed", choices=("pass", "fail"))
    parser.add_argument("--content-reviewer")
    parser.add_argument("--content-review-notes", default="")
    args = parser.parse_args()
    try:
        data = json.loads(args.source.read_text(encoding="utf-8"))
        manifest = load_manifest(args.manifest)
        validate_input(data, manifest)
        profile, version = resolve_template(
            manifest,
            data["classification"],
            data.get("template_version"),
            SKILL_ROOT,
        )
        evidence = validate_generated_document(
            args.input, data, manifest, profile, version, SKILL_ROOT
        )
        if args.render_reviewed:
            if not args.renderer:
                raise SowDocxError("--renderer is required for a rendered review")
            if not args.page_count or args.page_count < 1:
                raise SowDocxError("--page-count must be positive for a rendered review")
            evidence["render"] = {
                "renderer": args.renderer,
                "page_count": args.page_count,
                "reviewed": True,
                "passed": args.render_reviewed == "pass",
                "notes": args.review_notes,
            }
        elif args.renderer or args.page_count is not None or args.review_notes:
            raise SowDocxError(
                "--render-reviewed is required when rendered review details are supplied"
            )
        if args.content_reviewed:
            reviewer = (args.content_reviewer or "").strip()
            if not reviewer:
                raise SowDocxError(
                    "--content-reviewer is required for a human content review"
                )
            evidence["content_review"] = {
                "reviewer": reviewer,
                "reviewed": True,
                "passed": args.content_reviewed == "pass",
                "notes": args.content_review_notes,
            }
        elif args.content_reviewer or args.content_review_notes:
            raise SowDocxError(
                "--content-reviewed is required when content review details are supplied"
            )
        evidence["client_ready"] = compute_client_ready(evidence)
        _write_json(args.evidence, evidence)
    except (OSError, json.JSONDecodeError, SowDocxError) as exc:
        print(f"SOW validation failed: {exc}", file=sys.stderr)
        return 2
    print(f"Structural validation: {'PASS' if evidence['structural_valid'] else 'FAIL'}")
    print(
        "Content review: "
        f"{'PASS' if evidence['content_review']['passed'] else 'NOT READY'}"
    )
    print(f"Client readiness: {'PASS' if evidence['client_ready'] else 'NOT READY'}")
    if not evidence["structural_valid"]:
        return 3
    if args.render_reviewed or args.content_reviewed:
        return 0 if evidence["client_ready"] else 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
