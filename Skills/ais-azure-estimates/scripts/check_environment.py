# /// script
# dependencies = [
#   "jsonschema>=4.20.0",
# ]
# requires-python = ">=3.10"
# ///

"""Check local prerequisites for AIS Azure estimate scripts."""

from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
import urllib.request
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = SKILL_DIR.parent.parent
PRICING_URL = "https://prices.azure.com/api/retail/prices?$top=1"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", default=None, help="Directory to check for write access")
    parser.add_argument("--skip-network", action="store_true", help="Skip Retail Prices API connectivity check")
    args = parser.parse_args()

    checks: list[tuple[str, bool, str]] = []
    checks.append(_check_python_version())
    checks.append(_check_uv_available())
    checks.append(_check_jsonschema())
    checks.append(_check_schema_files())
    output_dir = Path(args.output_dir) if args.output_dir else Path(tempfile.gettempdir())
    checks.append(_check_write_access(output_dir))
    if args.skip_network:
        checks.append(("Azure Retail Prices API", True, "skipped by --skip-network"))
    else:
        checks.append(_check_network())

    failed = False
    for name, ok, detail in checks:
        status = "PASS" if ok else "FAIL"
        print(f"{status} {name}: {detail}")
        failed = failed or not ok

    return 1 if failed else 0


def _check_python_version() -> tuple[str, bool, str]:
    version = sys.version_info
    ok = version >= (3, 10)
    return ("Python version", ok, f"{version.major}.{version.minor}.{version.micro}")


def _check_uv_available() -> tuple[str, bool, str]:
    candidates = [
        shutil.which("uv"),
        str(REPO_ROOT / ".venv" / "Scripts" / "uv.exe"),
        str(REPO_ROOT / ".venv" / "bin" / "uv"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return ("uv executable", True, candidate)
    return ("uv executable", False, "uv not found on PATH or in repo .venv")


def _check_jsonschema() -> tuple[str, bool, str]:
    try:
        import jsonschema  # noqa: PLC0415
    except Exception as exc:  # noqa: BLE001 - report dependency import failure.
        return ("jsonschema dependency", False, str(exc))
    return ("jsonschema dependency", True, getattr(jsonschema, "__version__", "installed"))


def _check_schema_files() -> tuple[str, bool, str]:
    required = [
        SKILL_DIR / "assets" / "estimate-input.schema.json",
        SKILL_DIR / "assets" / "estimate-output.schema.json",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        return ("schema files", False, ", ".join(missing))
    return ("schema files", True, "input and output schemas found")


def _check_write_access(directory: Path) -> tuple[str, bool, str]:
    try:
        directory.mkdir(parents=True, exist_ok=True)
        probe = directory / ".ais-azure-estimates-write-check"
        probe.write_text("ok", encoding="utf-8")
        probe.unlink()
    except Exception as exc:  # noqa: BLE001 - report filesystem failure.
        return ("output write access", False, f"{directory}: {exc}")
    return ("output write access", True, str(directory))


def _check_network() -> tuple[str, bool, str]:
    try:
        with urllib.request.urlopen(PRICING_URL, timeout=15) as response:  # noqa: S310 - public Microsoft pricing endpoint.
            return ("Azure Retail Prices API", response.status == 200, f"HTTP {response.status}")
    except Exception as exc:  # noqa: BLE001 - report network failure.
        return ("Azure Retail Prices API", False, str(exc))


if __name__ == "__main__":
    raise SystemExit(main())