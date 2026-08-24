# /// script
# dependencies = [
#   "python-docx>=1.1.0",
# ]
# requires-python = ">=3.10"
# ///

"""
Extract comments from a Word document.

Reads a .docx file, extracts all comments with their metadata and anchor
positions, and outputs structured JSON to stdout.

Usage:
    uv run scripts/extract_comments.py --input document.docx
    uv run scripts/extract_comments.py --input document.docx --output comments.json
"""

import argparse
import json
import sys
import zipfile
from xml.etree import ElementTree as ET

NS_W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


def extract_comments(docx_path: str) -> list[dict]:
    """Extract all comments from a .docx file.

    Returns a list of comment objects with:
    - id: comment ID
    - author: comment author
    - date: comment date (ISO 8601)
    - text: comment text content
    - anchor_paragraph_index: index of the paragraph the comment is anchored to
    - anchor_text: text of the anchored paragraph (first 100 chars)
    - anchor_style: style of the anchored paragraph
    """
    comments = []

    with zipfile.ZipFile(docx_path, "r") as z:
        # Parse comments.xml
        if "word/comments.xml" not in z.namelist():
            return []

        comments_xml = z.read("word/comments.xml")
        comments_root = ET.fromstring(comments_xml)

        comment_map = {}
        for comment_el in comments_root.findall(f"{{{NS_W}}}comment"):
            cid = comment_el.get(f"{{{NS_W}}}id", "")
            author = comment_el.get(f"{{{NS_W}}}author", "")
            date = comment_el.get(f"{{{NS_W}}}date", "")

            texts = []
            for t in comment_el.findall(f".//{{{NS_W}}}t"):
                if t.text:
                    texts.append(t.text)
            text = " ".join(texts)

            comment_map[cid] = {
                "id": cid,
                "author": author,
                "date": date,
                "text": text,
            }

        # Parse document.xml to find anchor positions
        doc_xml = z.read("word/document.xml")
        doc_root = ET.fromstring(doc_xml)
        body = doc_root.find(f"{{{NS_W}}}body")

        # Build paragraph index, tracking which comments start in each
        para_idx = 0
        all_paragraphs = []

        for child in body:
            tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag

            if tag == "p":
                # Get style
                pPr = child.find(f"{{{NS_W}}}pPr")
                style = ""
                if pPr is not None:
                    pStyle = pPr.find(f"{{{NS_W}}}pStyle")
                    if pStyle is not None:
                        style = pStyle.get(f"{{{NS_W}}}val", "")

                # Get text
                texts = []
                for t in child.findall(f".//{{{NS_W}}}t"):
                    if t.text:
                        texts.append(t.text)
                text = "".join(texts)

                # Find commentRangeStart elements
                for cs in child.findall(f".//{{{NS_W}}}commentRangeStart"):
                    cid = cs.get(f"{{{NS_W}}}id", "")
                    if cid in comment_map:
                        comment_map[cid]["anchor_paragraph_index"] = para_idx
                        comment_map[cid]["anchor_text"] = text[:100]
                        comment_map[cid]["anchor_style"] = style

                para_idx += 1

            elif tag == "sdt":
                # Check inside SDT for comment anchors
                for p in child.findall(f".//{{{NS_W}}}p"):
                    pPr = p.find(f"{{{NS_W}}}pPr")
                    style = ""
                    if pPr is not None:
                        pStyle = pPr.find(f"{{{NS_W}}}pStyle")
                        if pStyle is not None:
                            style = pStyle.get(f"{{{NS_W}}}val", "")

                    texts = []
                    for t in p.findall(f".//{{{NS_W}}}t"):
                        if t.text:
                            texts.append(t.text)
                    text = "".join(texts)

                    for cs in p.findall(f".//{{{NS_W}}}commentRangeStart"):
                        cid = cs.get(f"{{{NS_W}}}id", "")
                        if cid in comment_map:
                            comment_map[cid]["anchor_paragraph_index"] = para_idx
                            comment_map[cid]["anchor_text"] = text[:100]
                            comment_map[cid]["anchor_style"] = style

                    para_idx += 1

    # Convert to sorted list
    for cid, cdata in sorted(comment_map.items(), key=lambda x: int(x[0]) if x[0].isdigit() else 0):
        # Set defaults for comments without anchors
        cdata.setdefault("anchor_paragraph_index", -1)
        cdata.setdefault("anchor_text", "")
        cdata.setdefault("anchor_style", "")
        comments.append(cdata)

    return comments


def main():
    parser = argparse.ArgumentParser(
        description="Extract comments from a Word document as JSON."
    )
    parser.add_argument(
        "--input", required=True, help="Path to the .docx file to extract comments from."
    )
    parser.add_argument(
        "--output",
        help="Path to write JSON output. If omitted, writes to stdout.",
    )

    args = parser.parse_args()

    comments = extract_comments(args.input)

    output_json = json.dumps(comments, indent=2, ensure_ascii=False)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_json)
        print(f"Extracted {len(comments)} comments to {args.output}", file=sys.stderr)
    else:
        print(output_json)
        print(f"Extracted {len(comments)} comments", file=sys.stderr)


if __name__ == "__main__":
    main()
