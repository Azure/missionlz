# /// script
# dependencies = [
#   "jsonschema>=4.20.0",
# ]
# requires-python = ">=3.10"
# ///

"""Validate an AIS Azure estimate input file."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from estimate_model import load_json, split_issues, validate_estimate


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Path to estimate input JSON")
    args = parser.parse_args()

    input_path = Path(args.input)
    try:
        data = load_json(input_path)
    except Exception as exc:  # noqa: BLE001 - CLI should report load failures clearly.
        print(f"ERROR input_load: {exc}", file=sys.stderr)
        return 2

    errors, warnings = split_issues(validate_estimate(data))
    for warning in warnings:
        print(warning.format())
    for error in errors:
        print(error.format(), file=sys.stderr)

    if errors:
        print(f"Validation failed: {len(errors)} error(s), {len(warnings)} warning(s).", file=sys.stderr)
        return 1

    print(f"Validation passed: {len(warnings)} warning(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())