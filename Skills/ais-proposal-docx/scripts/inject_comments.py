# /// script
# dependencies = [
#   "python-docx>=1.1.0",
# ]
# requires-python = ">=3.10"
# ///

"""
Inject or update comments in a Word document.

Takes a .docx file and a JSON file containing comments, then adds or updates
comments at specified paragraph positions. Preserves existing comments.

Usage:
    uv run scripts/inject_comments.py --input document.docx --comments comments.json --output updated.docx
"""

import argparse
import json
import os
import sys
import zipfile
from datetime import datetime, timezone
from xml.etree import ElementTree as ET

NS_W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS_R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

# Register namespaces
for prefix, uri in [
    ("w", NS_W),
    ("r", NS_R),
    ("mc", "http://schemas.openxmlformats.org/markup-compatibility/2006"),
    ("w14", "http://schemas.microsoft.com/office/word/2010/wordml"),
    ("w15", "http://schemas.microsoft.com/office/word/2012/wordml"),
]:
    ET.register_namespace(prefix, uri)


def get_max_comment_id(docx_path: str) -> int:
    """Find the highest comment ID already used in the document."""
    max_id = -1
    with zipfile.ZipFile(docx_path, "r") as z:
        if "word/comments.xml" in z.namelist():
            comments_xml = z.read("word/comments.xml")
            root = ET.fromstring(comments_xml)
            for comment_el in root.findall(f"{{{NS_W}}}comment"):
                cid = comment_el.get(f"{{{NS_W}}}id", "0")
                try:
                    max_id = max(max_id, int(cid))
                except ValueError:
                    pass
    return max_id


def inject_comments(docx_path: str, comments_json_path: str, output_path: str):
    """Add comments from JSON into the document."""
    with open(comments_json_path, "r", encoding="utf-8") as f:
        new_comments = json.load(f)

    if not new_comments:
        print("No comments to inject.", file=sys.stderr)
        # Just copy the file
        if docx_path != output_path:
            import shutil
            shutil.copy2(docx_path, output_path)
        return

    max_existing_id = get_max_comment_id(docx_path)
    next_id = max(max_existing_id + 1, 200)

    with zipfile.ZipFile(docx_path, "r") as z:
        # Load existing comments.xml or create new
        if "word/comments.xml" in z.namelist():
            comments_root = ET.fromstring(z.read("word/comments.xml"))
        else:
            comments_root = ET.Element(f"{{{NS_W}}}comments")

        # Load document.xml
        doc_xml = z.read("word/document.xml")
        doc_root = ET.fromstring(doc_xml)
        body = doc_root.find(f"{{{NS_W}}}body")

        # Build paragraph list for anchoring
        paragraphs = []
        for child in body:
            tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
            if tag == "p":
                paragraphs.append(child)
            elif tag == "sdt":
                for p in child.findall(f".//{{{NS_W}}}p"):
                    paragraphs.append(p)

        # Add each new comment
        added = 0
        for comment_data in new_comments:
            anchor_idx = comment_data.get("anchor_paragraph_index", -1)
            if anchor_idx < 0 or anchor_idx >= len(paragraphs):
                print(
                    f"Warning: anchor_paragraph_index {anchor_idx} out of range "
                    f"(0-{len(paragraphs)-1}). Skipping comment.",
                    file=sys.stderr,
                )
                continue

            cid = str(next_id)
            next_id += 1
            author = comment_data.get("author", "AIS Proposal Generator")
            date = comment_data.get("date", datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:00Z"))
            text = comment_data.get("text", "")

            # Add to comments.xml
            comment_el = ET.SubElement(comments_root, f"{{{NS_W}}}comment")
            comment_el.set(f"{{{NS_W}}}id", cid)
            comment_el.set(f"{{{NS_W}}}author", author)
            comment_el.set(f"{{{NS_W}}}date", date)

            cp = ET.SubElement(comment_el, f"{{{NS_W}}}p")
            cr = ET.SubElement(cp, f"{{{NS_W}}}r")
            ct = ET.SubElement(cr, f"{{{NS_W}}}t")
            ct.text = text

            # Add anchors to the target paragraph
            para_elem = paragraphs[anchor_idx]

            range_start = ET.Element(f"{{{NS_W}}}commentRangeStart")
            range_start.set(f"{{{NS_W}}}id", cid)
            para_elem.insert(0, range_start)

            range_end = ET.SubElement(para_elem, f"{{{NS_W}}}commentRangeEnd")
            range_end.set(f"{{{NS_W}}}id", cid)

            ref_run = ET.SubElement(para_elem, f"{{{NS_W}}}r")
            ref_rpr = ET.SubElement(ref_run, f"{{{NS_W}}}rPr")
            ref_style = ET.SubElement(ref_rpr, f"{{{NS_W}}}rStyle")
            ref_style.set(f"{{{NS_W}}}val", "CommentReference")
            ref_ref = ET.SubElement(ref_run, f"{{{NS_W}}}commentReference")
            ref_ref.set(f"{{{NS_W}}}id", cid)

            added += 1

        # Write output
        comments_bytes = ET.tostring(
            comments_root, encoding="unicode", xml_declaration=True
        ).encode("utf-8")
        doc_bytes = ET.tostring(
            doc_root, encoding="unicode", xml_declaration=True
        ).encode("utf-8")

        with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zout:
            for item in z.infolist():
                if item.filename == "word/comments.xml":
                    zout.writestr(item, comments_bytes)
                elif item.filename == "word/document.xml":
                    zout.writestr(item, doc_bytes)
                else:
                    zout.writestr(item, z.read(item.filename))

    print(f"Injected {added} comments into {output_path}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Inject comments from JSON into a Word document."
    )
    parser.add_argument(
        "--input", required=True, help="Path to the source .docx file."
    )
    parser.add_argument(
        "--comments", required=True, help="Path to the JSON comments file."
    )
    parser.add_argument(
        "--output", required=True, help="Path for the output .docx file."
    )

    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(args.comments):
        print(f"Error: Comments file not found: {args.comments}", file=sys.stderr)
        sys.exit(1)

    inject_comments(args.input, args.comments, args.output)


if __name__ == "__main__":
    main()
