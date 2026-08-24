# /// script
# dependencies = [
#   "python-docx>=1.1.0",
# ]
# requires-python = ">=3.10"
# ///

"""
Validate that a generated .docx uses only styles from the template.

Compares the styles in a generated document against a reference template
to detect any styles that were inadvertently created during generation.

Usage:
    uv run scripts/validate_styles.py --generated output.docx
    uv run scripts/validate_styles.py --generated output.docx --template assets/template.docx
"""

import argparse
import json
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

NS_W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

SKILL_DIR = Path(__file__).resolve().parent.parent
DEFAULT_TEMPLATE = SKILL_DIR / "assets" / "template.docx"


def extract_style_ids(docx_path: str) -> dict[str, set[str]]:
    """Extract all style IDs from a .docx file, grouped by type."""
    styles = {"paragraph": set(), "character": set(), "table": set(), "numbering": set()}

    with zipfile.ZipFile(docx_path, "r") as z:
        if "word/styles.xml" not in z.namelist():
            return styles

        styles_xml = z.read("word/styles.xml")
        root = ET.fromstring(styles_xml)

        for style_el in root.findall(f"{{{NS_W}}}style"):
            sid = style_el.get(f"{{{NS_W}}}styleId", "")
            stype = style_el.get(f"{{{NS_W}}}type", "")
            if sid and stype in styles:
                styles[stype].add(sid)

    return styles


def extract_used_styles(docx_path: str) -> set[str]:
    """Extract all style IDs actually referenced in paragraphs."""
    used = set()

    with zipfile.ZipFile(docx_path, "r") as z:
        doc_xml = z.read("word/document.xml")
        root = ET.fromstring(doc_xml)

        for pStyle in root.findall(f".//{{{NS_W}}}pStyle"):
            val = pStyle.get(f"{{{NS_W}}}val", "")
            if val:
                used.add(val)

        for rStyle in root.findall(f".//{{{NS_W}}}rStyle"):
            val = rStyle.get(f"{{{NS_W}}}val", "")
            if val:
                used.add(val)

        for tblStyle in root.findall(f".//{{{NS_W}}}tblStyle"):
            val = tblStyle.get(f"{{{NS_W}}}val", "")
            if val:
                used.add(val)

    return used


def validate(generated_path: str, template_path: str) -> dict:
    """Compare styles between generated doc and template.

    Returns a result dict with:
    - passed: bool
    - new_styles: list of style IDs in generated but not in template
    - missing_styles: list of style IDs in template but not in generated
    - used_styles: list of style IDs used in generated document
    - template_styles: count of styles in template
    - generated_styles: count of styles in generated
    """
    template_styles = extract_style_ids(template_path)
    generated_styles = extract_style_ids(generated_path)
    used = extract_used_styles(generated_path)

    # All style IDs across all types
    template_all = set()
    generated_all = set()
    for stype in template_styles:
        template_all.update(template_styles[stype])
        generated_all.update(generated_styles.get(stype, set()))

    new_styles = sorted(generated_all - template_all)
    missing_styles = sorted(template_all - generated_all)

    # Check if any used styles are not in the template
    used_but_not_in_template = sorted(used - template_all)

    passed = len(new_styles) == 0 and len(used_but_not_in_template) == 0

    return {
        "passed": passed,
        "new_styles": new_styles,
        "missing_styles": missing_styles,
        "used_but_not_in_template": used_but_not_in_template,
        "used_styles": sorted(used),
        "template_style_count": len(template_all),
        "generated_style_count": len(generated_all),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Validate that generated .docx uses only template styles."
    )
    parser.add_argument(
        "--generated", required=True, help="Path to the generated .docx file."
    )
    parser.add_argument(
        "--template",
        default=str(DEFAULT_TEMPLATE),
        help="Path to the reference template .docx. Defaults to assets/template.docx.",
    )
    parser.add_argument(
        "--json", action="store_true", help="Output results as JSON."
    )

    args = parser.parse_args()

    result = validate(args.generated, args.template)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if result["passed"]:
            print("PASSED: No new styles were created.")
            print(f"  Template styles: {result['template_style_count']}")
            print(f"  Generated styles: {result['generated_style_count']}")
            print(f"  Styles used: {len(result['used_styles'])}")
        else:
            print("FAILED: Style validation issues detected.")
            if result["new_styles"]:
                print(f"\n  New styles created (not in template):")
                for s in result["new_styles"]:
                    print(f"    - {s}")
            if result["used_but_not_in_template"]:
                print(f"\n  Styles used but not defined in template:")
                for s in result["used_but_not_in_template"]:
                    print(f"    - {s}")
            print(f"\n  Template styles: {result['template_style_count']}")
            print(f"  Generated styles: {result['generated_style_count']}")

    sys.exit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
