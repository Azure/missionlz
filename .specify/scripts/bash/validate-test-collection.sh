#!/usr/bin/env bash
# Validate a managed optional-CI Python test collection before discovery.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 COLLECTION GROUP" >&2
  exit 2
fi

collection="$1"
group="$2"
python_bin="${PYTHON_BIN:-python3}"

if [[ ! -d "$collection" || ! -r "$collection" || ! -x "$collection" ]]; then
  echo "ERROR: Framework validation collection is missing or unreadable: $collection" >&2
  echo "Restore the matching AIS Spec $group payload before running optional CI." >&2
  exit 2
fi

if ! command -v "$python_bin" >/dev/null 2>&1; then
  echo "ERROR: Python interpreter is unavailable: $python_bin" >&2
  exit 2
fi

set +e
"$python_bin" - "$collection" <<'PY'
import sys
import unittest

collection = sys.argv[1]
loader = unittest.TestLoader()
suite = loader.discover(start_dir=collection, pattern="test_*.py")

if loader.errors:
    print(f"ERROR: Test discovery failed for {collection}:", file=sys.stderr)
    for error in loader.errors:
        print(error, file=sys.stderr)
    sys.exit(2)

if suite.countTestCases() == 0:
    print(
        f"ERROR: Framework validation collection contains no discoverable test cases: {collection}",
        file=sys.stderr,
    )
    sys.exit(2)
PY
discovery_status=$?
set -e

if [[ "$discovery_status" -ne 0 ]]; then
  echo "Restore the matching AIS Spec $group payload before running optional CI." >&2
  exit 2
fi
