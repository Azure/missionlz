#!/usr/bin/env python3
"""Generate a validated AIS SOW DOCX from structured JSON."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from sow_docx import SowDocxError, generate_document


SKILL_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = SKILL_ROOT / "assets" / "template-manifest.json"


def _write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="SOW JSON input")
    parser.add_argument("--output", required=True, type=Path, help="Output DOCX path")
    parser.add_argument("--evidence", type=Path, help="Output evidence JSON path")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()
    evidence_path = args.evidence or args.output.with_suffix(".evidence.json")
    try:
        data = json.loads(args.input.read_text(encoding="utf-8"))
        evidence = generate_document(data, args.output, args.manifest, SKILL_ROOT)
        if not evidence["structural_valid"]:
            raise SowDocxError("Structural validation did not pass")
        _write_json(evidence_path, evidence)
    except (OSError, json.JSONDecodeError, SowDocxError) as exc:
        print(f"SOW generation failed: {exc}", file=sys.stderr)
        return 2
    print(f"Generated: {args.output}")
    print(f"Evidence: {evidence_path}")
    print("Structural validation: PASS")
    print("Client readiness: PENDING rendered page and human content reviews")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
