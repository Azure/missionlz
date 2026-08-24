from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge agent visual analysis into a video context manifest.")
    parser.add_argument("--manifest", required=True, help="Path to manifest.json")
    parser.add_argument("--analysis", required=True, help="Path to agent visual analysis JSON")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    analysis_path = Path(args.analysis)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    analysis = json.loads(analysis_path.read_text(encoding="utf-8"))

    rejected_event_ids: set[str] = set()
    events_by_id = {event["id"]: event for event in manifest.get("events", [])}
    for item in analysis.get("events", []):
        event_id = item.get("id")
        if event_id not in events_by_id:
            raise ValueError(f"Analysis references unknown event id: {event_id}")
        normalized = normalize_analysis(item)
        event = events_by_id[event_id]
        event["visual_analysis"] = normalized
        if normalized.get("status") == "rejected":
            event["status"] = "rejected"
            rejected_event_ids.add(event_id)
            event["rejection_reason"] = item.get("rejection_reason") or normalized.get("summary") or "rejected by agent-vision"

    prune_rejected_events(manifest, manifest_path.parent)
    prune_analysis_events(analysis, rejected_event_ids)
    refresh_counts(manifest)
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    analysis_path.write_text(json.dumps(analysis, indent=2), encoding="utf-8")
    write_context(manifest, manifest_path.parent / "context.md")
    update_completion_report(manifest, manifest_path.parent / "self-improvement.md")
    print(f"Updated {manifest_path}")
    print(f"Updated {analysis_path}")
    print(f"Updated {manifest_path.parent / 'context.md'}")
    return 0


def normalize_analysis(item: dict[str, Any]) -> dict[str, Any]:
    hierarchy = item.get("information_hierarchy") or []
    visible_text = item.get("visible_text") or ""
    summary = item.get("screen_summary") or item.get("summary") or ""
    warnings = item.get("warnings") or []
    key_observations = item.get("key_observations") or []
    if key_observations:
        hierarchy = [
            *hierarchy,
            *[
                {
                    "level": "observation",
                    "order": len(hierarchy) + index,
                    "text": observation,
                    "confidence": item.get("confidence"),
                }
                for index, observation in enumerate(key_observations, start=1)
            ],
        ]
    status = item.get("status") or "complete"
    rejection_reason = item.get("rejection_reason")
    if status == "rejected" and rejection_reason and not summary:
        summary = rejection_reason
    return {
        "status": status,
        "method": item.get("method") or "agent-vision",
        "summary": summary,
        "application_hint": item.get("application_hint") or "unknown",
        "visible_text": visible_text,
        "text_blocks": item.get("text_blocks") or [],
        "information_hierarchy": hierarchy,
        "warnings": warnings,
        "confidence": item.get("confidence"),
    }


def refresh_counts(manifest: dict[str, Any]) -> None:
    events = manifest.get("events", [])
    manifest["event_count"] = len(events)
    manifest["extracted_count"] = sum(1 for event in events if event.get("status") == "extracted")
    manifest["rejected_count"] = sum(1 for event in events if event.get("status") == "rejected")
    manifest["failed_count"] = sum(1 for event in events if event.get("status") == "failed")


def delete_relative_file(output_dir: Path, relative_path: str | None) -> bool:
    if not relative_path:
        return False
    output_root = output_dir.resolve()
    target = (output_dir / relative_path).resolve()
    try:
        target.relative_to(output_root)
    except ValueError:
        return False
    if target.is_file():
        target.unlink()
        return True
    return False


def prune_rejected_events(manifest: dict[str, Any], output_dir: Path) -> int:
    retained: list[dict[str, Any]] = []
    removed_count = 0
    for event in manifest.get("events", []):
        if event.get("status") != "rejected":
            retained.append(event)
            continue
        removed_count += 1
        delete_relative_file(output_dir, event.get("frame_path"))
    manifest["events"] = retained
    manifest["rejected_removed_count"] = int(manifest.get("rejected_removed_count", 0)) + removed_count
    return removed_count


def prune_analysis_events(analysis: dict[str, Any], rejected_event_ids: set[str]) -> int:
    events = analysis.get("events", [])
    retained = [
        event
        for event in events
        if event.get("id") not in rejected_event_ids and event.get("status") != "rejected"
    ]
    analysis["events"] = retained
    return len(events) - len(retained)


def write_context(manifest: dict[str, Any], path: Path) -> None:
    lines = [
        "# Video Context Package",
        "",
        f"- **Created**: {manifest.get('created_at', '')}",
        f"- **Video**: `{manifest.get('video_path', '')}`",
        f"- **Transcript**: `{manifest.get('transcript_path', '')}`",
        f"- **Transcript segments parsed**: {manifest.get('segment_count', 0)}",
        f"- **Transcript cue candidates**: {manifest.get('candidate_segment_count', 0)}",
        f"- **Visual transition candidates**: {manifest.get('transition_candidate_count', 0)}",
        f"- **Contact sheets**: {manifest.get('contact_sheet_count', 0)}",
        f"- **Contact-sheet thumbnails**: {manifest.get('contact_sheet_frame_count', 0)}",
        f"- **Contact-sheet selections**: {manifest.get('contact_sheet_selection_count', 0)}",
        f"- **Extraction events**: {manifest.get('event_count', 0)}",
        f"- **Extracted frames**: {manifest.get('extracted_count', 0)}",
        f"- **Failed frames**: {manifest.get('failed_count', 0)}",
        "",
        "## Index",
        "",
        "| Event | Timestamp | Status | Source | Analysis | Summary |",
        "|-------|-----------|--------|--------|----------|---------|",
    ]
    for event in manifest.get("events", []):
        analysis = event.get("visual_analysis") or {}
        lines.append(
            f"| {event.get('id')} | {event.get('timestamp')} | {event.get('status')} | "
            f"{event.get('selection_source', 'unknown')} | "
            f"{analysis.get('method', 'none')} / {analysis.get('status', 'missing')} | "
            f"{escape_table(analysis.get('summary') or event.get('transcript_excerpt', ''))} |"
        )

    lines.extend(["", "## Accepted Keyframes", ""])
    accepted_events = [event for event in manifest.get("events", []) if event.get("status") == "extracted"]
    if not accepted_events:
        lines.extend(["No accepted keyframes were extracted.", ""])
    for event in accepted_events:
        analysis = event.get("visual_analysis") or {}
        lines.extend(
            [
                f"### {event.get('id')} - {event.get('timestamp')}",
                "",
                f"- **Status**: {event.get('status')}",
                f"- **Selection source**: {event.get('selection_source', 'unknown')}",
                f"- **Selection reasons**: {', '.join(event.get('selection_reasons') or []) or 'None'}",
                f"- **Score**: {event.get('score')}",
                f"- **Trigger reasons**: {', '.join(event.get('trigger_reasons') or [])}",
                f"- **Visual analysis**: {analysis.get('method', 'none')} / {analysis.get('status', 'missing')}",
                f"- **Application hint**: {analysis.get('application_hint', 'unknown')}",
                "",
                "**Transcript excerpt**",
                "",
                event.get("transcript_excerpt") or "",
                "",
                "**Visible Information Extraction**",
                "",
            ]
        )
        if analysis.get("summary"):
            lines.extend([analysis["summary"], ""])
        if analysis.get("visible_text"):
            lines.extend(["```text", analysis["visible_text"], "```", ""])
        hierarchy = analysis.get("information_hierarchy") or []
        if hierarchy:
            lines.extend(["**Information hierarchy**", ""])
            for item in hierarchy:
                confidence = item.get("confidence")
                confidence_text = "" if confidence is None else f" (confidence: {confidence})"
                lines.append(
                    f"- {item.get('level', 'item')} {item.get('order', '')}: "
                    f"{str(item.get('text', '')).strip()}{confidence_text}"
                )
            lines.append("")
        warnings = analysis.get("warnings") or []
        if warnings:
            lines.extend(["**Analysis warnings**", ""])
            for warning in warnings:
                lines.append(f"- {warning}")
            lines.append("")
        if event.get("frame_path"):
            lines.extend([f"![{event.get('id')}]({event.get('frame_path')})", ""])

    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def escape_table(value: str) -> str:
    text = " ".join(str(value).split())
    if len(text) > 180:
        text = text[:177].rstrip() + "..."
    return text.replace("|", "\\|")


def update_completion_report(manifest: dict[str, Any], path: Path) -> None:
    if not path.exists():
        return
    events = [event for event in manifest.get("events", []) if event.get("status") == "extracted"]
    completed = [
        event
        for event in events
        if (event.get("visual_analysis") or {}).get("status") == "complete"
        and (event.get("visual_analysis") or {}).get("method") not in {"none", "frame-only", None}
    ]
    marker = "## Agent-Vision Completion"
    existing = path.read_text(encoding="utf-8")
    base = existing.split(marker, 1)[0].rstrip()
    base = refresh_report_counts(base, manifest)
    if events and len(completed) == len(events):
        base = remove_pending_visual_analysis_finding(base)
    section = [
        marker,
        "",
        f"- **Completed visual analyses**: {len(completed)} of {len(events)} extracted events",
        "- **Primary analyzer**: agent visual inspection (`agent-vision`)",
    ]
    path.write_text(base + "\n\n" + "\n".join(section).rstrip() + "\n", encoding="utf-8")


def refresh_report_counts(report_text: str, manifest: dict[str, Any]) -> str:
    replacements = {
        "Events selected": manifest.get("event_count", 0),
        "Events retained": manifest.get("event_count", 0),
        "Contact sheets": manifest.get("contact_sheet_count", 0),
        "Contact-sheet thumbnails": manifest.get("contact_sheet_frame_count", 0),
        "Contact-sheet selections": manifest.get("contact_sheet_selection_count", 0),
        "Frames extracted": manifest.get("extracted_count", 0),
        "Rejected candidates": manifest.get("rejected_count", 0),
        "Rejected candidates removed": manifest.get("rejected_removed_count", 0),
        "Frame failures": manifest.get("failed_count", 0),
    }
    updated = report_text
    for label, value in replacements.items():
        updated = re.sub(rf"- \*\*{re.escape(label)}\*\*: \d+", f"- **{label}**: {value}", updated)
    updated = re.sub(
        r"\*\*Evidence\*\*: \d+ extraction events were selected; \d+ accepted and \d+ rejected\.",
        (
            f"**Evidence**: {manifest.get('event_count', 0)} retained extraction events were selected; "
            f"{manifest.get('extracted_count', 0)} accepted, {manifest.get('failed_count', 0)} failed, "
            f"and {manifest.get('rejected_removed_count', 0)} rejected candidates were deleted."
        ),
        updated,
    )
    updated = re.sub(
        r"\*\*Evidence\*\*: \d+ retained extraction events were selected; \d+ accepted, \d+ failed, and \d+ rejected candidates were deleted\.",
        (
            f"**Evidence**: {manifest.get('event_count', 0)} retained extraction events were selected; "
            f"{manifest.get('extracted_count', 0)} accepted, {manifest.get('failed_count', 0)} failed, "
            f"and {manifest.get('rejected_removed_count', 0)} rejected candidates were deleted."
        ),
        updated,
    )
    return updated


def remove_pending_visual_analysis_finding(report_text: str) -> str:
    lines = report_text.splitlines()
    filtered: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.startswith("### ") and ": visual-analysis" in line:
            index += 1
            while index < len(lines) and not lines[index].startswith("### ") and not lines[index].startswith("## "):
                index += 1
            continue
        filtered.append(line)
        index += 1

    finding_count = 0
    for index, line in enumerate(filtered):
        if line.startswith("### F") and ":" in line:
            finding_count += 1
            filtered[index] = f"### F{finding_count:03d}:{line.split(':', 1)[1]}"
    return "\n".join(filtered).rstrip()


if __name__ == "__main__":
    raise SystemExit(main())
