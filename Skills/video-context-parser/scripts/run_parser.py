from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from collections import Counter
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


TIMESTAMP_RE = re.compile(
    r"(?P<start>(?:\d{2}:)?\d{2}:\d{2}[.,]\d{3})\s+-->\s+"
    r"(?P<end>(?:\d{2}:)?\d{2}:\d{2}[.,]\d{3})"
)
VOICE_RE = re.compile(r"<v\s+([^>]+)>(.*?)</v>", re.IGNORECASE | re.DOTALL)
TAG_RE = re.compile(r"<[^>]+>")
SCENE_PTS_RE = re.compile(r"pts_time:(?P<time>\d+(?:\.\d+)?)")
SCENE_SCORE_RE = re.compile(r"lavfi\.scene_score=(?P<score>\d+(?:\.\d+)?)")
CUE_WEIGHTS: dict[str, int] = {
    "as you can see": 5,
    "you can see": 4,
    "on the screen": 5,
    "on my screen": 5,
    "share my screen": 5,
    "screen share": 5,
    "let me show": 5,
    "show you": 4,
    "pull up": 4,
    "bring up": 4,
    "look at": 4,
    "shown here": 4,
    "right here": 3,
    "this screen": 4,
    "this slide": 4,
    "this diagram": 5,
    "this view": 4,
    "this page": 4,
    "slide": 3,
    "diagram": 4,
    "architecture": 3,
    "portal": 4,
    "dashboard": 3,
    "blade": 3,
    "tab": 2,
    "click": 2,
    "scroll": 2,
    "dropdown": 2,
    "management group": 5,
    "management groups": 5,
    "subscription": 4,
    "subscriptions": 4,
    "resource group": 4,
    "resource groups": 4,
    "tenant": 2,
    "environment": 2,
    "pipeline": 2,
    "repository": 2,
    "repo": 2,
    "powerpoint": 4,
    "foundry": 7,
    "ai foundry": 8,
    "azure openai": 6,
    "openai endpoints": 6,
    "model": 4,
    "models": 5,
    "model configuration": 6,
    "deployment type": 5,
    "agent": 5,
    "agents": 6,
    "agent service": 7,
    "agent servers": 6,
    "hosted agent": 6,
    "data agent": 7,
    "lakehouse": 5,
    "orchestration": 5,
    "instructions": 4,
    "knowledge": 4,
    "tools": 3,
    "tool calls": 5,
    "semantic models": 5,
    "household hub foundry": 8,
}
INCOMPLETE_METHODS = {"none", "frame-only"}
INCOMPLETE_STATUSES = {"pending", "incomplete", "missing"}


class DependencyError(RuntimeError):
    pass


class FrameExtractionError(RuntimeError):
    pass


class VttParseError(ValueError):
    pass


@dataclass
class TranscriptSegment:
    index: int
    start_seconds: float
    end_seconds: float
    text: str
    speaker: str | None = None
    score: int = 0
    cue_matches: list[str] = field(default_factory=list)

    @property
    def midpoint_seconds(self) -> float:
        return (self.start_seconds + self.end_seconds) / 2


@dataclass
class VisualAnalysis:
    status: str = "pending"
    method: str = "none"
    summary: str = ""
    application_hint: str = "unknown"
    visible_text: str = ""
    text_blocks: list[dict[str, Any]] = field(default_factory=list)
    information_hierarchy: list[dict[str, Any]] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


@dataclass
class FrameQuality:
    status: str = "unknown"
    rejection_reason: str | None = None
    mean_luma: float | None = None
    luma_stddev: float | None = None
    edge_mean: float | None = None
    rich_tile_ratio: float | None = None
    duplicate_hash: str | None = None
    duplicate_of: str | None = None
    notes: list[str] = field(default_factory=list)


@dataclass
class ExtractionEvent:
    id: str
    start_seconds: float
    end_seconds: float
    representative_seconds: float
    transcript_excerpt: str
    trigger_reasons: list[str]
    score: int
    segments: list[int]
    selection_source: str = "transcript-cue"
    selection_reasons: list[str] = field(default_factory=list)
    frame_path: str | None = None
    image_width: int | None = None
    image_height: int | None = None
    frame_quality: FrameQuality = field(default_factory=FrameQuality)
    visual_analysis: VisualAnalysis = field(default_factory=VisualAnalysis)
    status: str = "candidate"
    rejection_reason: str | None = None
    error: str | None = None


@dataclass(frozen=True)
class ParserSettings:
    score_threshold: int = 4
    cluster_window_seconds: float = 35.0
    timestamp_offset_seconds: float = 0.0
    max_frames: int = 25
    ffmpeg_path: str | None = None
    overwrite: bool = False
    transition_scan: bool = True
    scene_threshold: float = 0.18
    transition_min_gap_seconds: float = 20.0
    transition_capture_offset_seconds: float = 1.0
    max_transition_candidates: int = 80
    event_merge_window_seconds: float = 12.0
    min_primary_edge_mean: float = 10.0
    min_rich_tile_ratio: float = 0.45
    duplicate_hamming_threshold: int = 8
    contact_sheet_scan: bool = True
    contact_sheet_interval_seconds: float = 20.0
    contact_sheet_max_thumbnails: int = 240
    contact_sheet_columns: int = 5
    contact_sheet_rows: int = 4
    contact_sheet_thumb_width: int = 320
    contact_sheet_selection_path: str | None = None


@dataclass
class ParserRun:
    video_path: Path
    transcript_path: Path
    output_dir: Path
    created_at: str
    settings: ParserSettings
    segment_count: int
    candidate_segment_count: int
    transition_candidate_count: int
    rejected_removed_count: int
    contact_sheet_count: int
    contact_sheet_frame_count: int
    contact_sheet_selection_count: int
    low_confidence_candidates: list[TranscriptSegment]
    cue_match_counts: dict[str, int]
    events: list[ExtractionEvent]
    outputs: dict[str, str] = field(default_factory=dict)

    @property
    def extracted_count(self) -> int:
        return sum(1 for event in self.events if event.status == "extracted")

    @property
    def failed_count(self) -> int:
        return sum(1 for event in self.events if event.status == "failed")

    @property
    def rejected_count(self) -> int:
        return sum(1 for event in self.events if event.status == "rejected")


def path_and_parents(start: Path) -> list[Path]:
    path = start.resolve()
    if path.is_file():
        path = path.parent
    return [path, *path.parents]


def find_project_root(script_path: Path) -> Path:
    seen: set[Path] = set()
    for start in (Path.cwd(), script_path):
        for path in path_and_parents(start):
            if path in seen:
                continue
            seen.add(path)
            if (path / ".git").exists() or (path / ".project-context").is_dir() or (path / "specs").is_dir():
                return path
    return Path.cwd().resolve()


def sanitize_run_id(value: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", value.strip()).strip("-._").lower()
    return slug[:96] or "video-context-run"


def default_output_dir(
    *,
    project_root: Path,
    project_context_root: str | None,
    run_id: str | None,
    video_path: str,
    transcript_path: str,
) -> Path:
    if project_context_root:
        root = Path(project_context_root)
        if not root.is_absolute():
            root = project_root / root
    else:
        root = project_root / ".project-context"

    if run_id:
        slug = sanitize_run_id(run_id)
    else:
        source_name = Path(video_path).stem or Path(transcript_path).stem or "video-context"
        stamp = datetime.now(UTC).strftime("%Y%m%d-%H%M%S")
        slug = sanitize_run_id(f"{source_name}-{stamp}")

    return root / "generated" / "video-context" / slug


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Extract transcript-guided video context.")
    parser.add_argument("--video", required=True, help="Path to the MP4 recording.")
    parser.add_argument("--transcript", required=True, help="Path to the WebVTT transcript.")
    parser.add_argument(
        "--output",
        help="Output directory for context package. Defaults to .project-context/generated/video-context/<run-id>.",
    )
    parser.add_argument("--project-context-root", help="Project context root for default output; relative paths resolve from the detected project root.")
    parser.add_argument("--run-id", help="Stable folder name under generated/video-context/.")
    parser.add_argument("--ffmpeg-path", help="Explicit FFmpeg executable path.")
    parser.add_argument("--threshold", type=int, default=4, help="Minimum visual cue score.")
    parser.add_argument("--cluster-window", type=float, default=35.0, help="Merge window in seconds.")
    parser.add_argument("--timestamp-offset", type=float, default=0.0, help="Seconds added before frame extraction.")
    parser.add_argument("--max-frames", type=int, default=25, help="Maximum extraction events to attempt.")
    parser.add_argument("--no-transition-scan", action="store_true", help="Disable FFmpeg scene-change transition candidates.")
    parser.add_argument("--scene-threshold", type=float, default=0.18, help="FFmpeg scene score threshold for visual transition candidates.")
    parser.add_argument("--transition-min-gap", type=float, default=20.0, help="Minimum seconds between transition candidates.")
    parser.add_argument("--transition-capture-offset", type=float, default=1.0, help="Seconds after a scene change to capture a stable frame.")
    parser.add_argument("--max-transition-candidates", type=int, default=80, help="Maximum scene-change candidates to consider before quality filtering.")
    parser.add_argument("--event-merge-window", type=float, default=12.0, help="Merge transcript and transition candidates within this many seconds.")
    parser.add_argument("--min-primary-edge-mean", type=float, default=10.0, help="Reject frames with lower primary-region edge density.")
    parser.add_argument("--min-rich-tile-ratio", type=float, default=0.45, help="Reject frames with lower primary-region rich tile ratio.")
    parser.add_argument("--duplicate-hamming-threshold", type=int, default=8, help="Reject visually duplicate frames at or below this perceptual hash distance.")
    parser.add_argument("--no-contact-sheet-scan", action="store_true", help="Disable contact-sheet thumbnail sampling.")
    parser.add_argument("--contact-sheet-selection", help="JSON file containing agent-selected thumbnail ids or timestamps.")
    parser.add_argument("--contact-sheet-interval", type=float, default=20.0, help="Seconds between sampled contact-sheet thumbnails.")
    parser.add_argument("--contact-sheet-max-thumbnails", type=int, default=240, help="Maximum thumbnails to sample into contact sheets.")
    parser.add_argument("--contact-sheet-columns", type=int, default=5, help="Contact-sheet tile columns.")
    parser.add_argument("--contact-sheet-rows", type=int, default=4, help="Contact-sheet tile rows.")
    parser.add_argument("--contact-sheet-thumb-width", type=int, default=320, help="Contact-sheet thumbnail width in pixels.")
    parser.add_argument("--overwrite", action="store_true", help="Allow writing into an existing output directory.")
    parser.add_argument("--self-improve", action="store_true", help="Write a self-improvement report.")
    parser.add_argument("--compare-manifest", help="Previous manifest for before/after comparison.")
    return parser


def main(argv: list[str] | None = None) -> int:
    project_root = find_project_root(Path(__file__).resolve())
    parser = build_parser()
    args = parser.parse_args(argv)
    if not args.output:
        args.output = str(
            default_output_dir(
                project_root=project_root,
                project_context_root=args.project_context_root,
                run_id=args.run_id,
                video_path=args.video,
                transcript_path=args.transcript,
            )
        )

    try:
        run = execute(args)
    except (DependencyError, FrameExtractionError, VttParseError, ValueError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"manifest: {run.output_dir / 'manifest.json'}")
    print(f"context: {run.output_dir / 'context.md'}")
    if run.contact_sheet_count:
        print(f"contact_sheet_review: {run.output_dir / 'contact-sheet-review.md'}")
    if args.self_improve:
        print(f"self_improvement: {run.output_dir / 'self-improvement.md'}")
    print(
        f"events: {len(run.events)}, extracted: {run.extracted_count}, "
        f"rejected_removed: {run.rejected_removed_count}, failed: {run.failed_count}"
    )
    return 0


def execute(args: argparse.Namespace) -> ParserRun:
    video_path = required_file(args.video, "video")
    transcript_path = required_file(args.transcript, "transcript")
    output_dir = Path(args.output)
    validate_settings(args)
    prepare_output_dir(output_dir, overwrite=args.overwrite)

    ffmpeg_path = resolve_ffmpeg(args.ffmpeg_path)
    compare_path = optional_file(args.compare_manifest, "comparison manifest") if args.compare_manifest else None
    contact_sheet_selection_path = optional_file(args.contact_sheet_selection, "contact sheet selection") if args.contact_sheet_selection else None
    settings = ParserSettings(
        score_threshold=args.threshold,
        cluster_window_seconds=args.cluster_window,
        timestamp_offset_seconds=args.timestamp_offset,
        max_frames=args.max_frames,
        ffmpeg_path=str(ffmpeg_path),
        overwrite=args.overwrite,
        transition_scan=not args.no_transition_scan,
        scene_threshold=args.scene_threshold,
        transition_min_gap_seconds=args.transition_min_gap,
        transition_capture_offset_seconds=args.transition_capture_offset,
        max_transition_candidates=args.max_transition_candidates,
        event_merge_window_seconds=args.event_merge_window,
        min_primary_edge_mean=args.min_primary_edge_mean,
        min_rich_tile_ratio=args.min_rich_tile_ratio,
        duplicate_hamming_threshold=args.duplicate_hamming_threshold,
        contact_sheet_scan=not args.no_contact_sheet_scan,
        contact_sheet_interval_seconds=args.contact_sheet_interval,
        contact_sheet_max_thumbnails=args.contact_sheet_max_thumbnails,
        contact_sheet_columns=args.contact_sheet_columns,
        contact_sheet_rows=args.contact_sheet_rows,
        contact_sheet_thumb_width=args.contact_sheet_thumb_width,
        contact_sheet_selection_path=str(contact_sheet_selection_path) if contact_sheet_selection_path else None,
    )

    segments = parse_vtt(transcript_path)
    score_segments(segments)
    contact_manifest = generate_contact_sheets(
        ffmpeg_path=ffmpeg_path,
        video_path=video_path,
        segments=segments,
        output_dir=output_dir,
        settings=settings,
    )
    selected_contact_frames: list[dict[str, Any]] = []
    if contact_sheet_selection_path:
        selected_contact_frames = load_contact_sheet_selection(contact_sheet_selection_path, contact_manifest)
        events = build_contact_sheet_events(selected_contact_frames, segments, settings.max_frames)
    else:
        transcript_events = cluster_segments(
            segments,
            threshold=settings.score_threshold,
            cluster_window_seconds=settings.cluster_window_seconds,
            timestamp_offset_seconds=settings.timestamp_offset_seconds,
            max_frames=max(settings.max_frames * 3, settings.max_frames),
        )
        transition_events = (
            build_transition_events(
                ffmpeg_path=ffmpeg_path,
                video_path=video_path,
                segments=segments,
                scene_threshold=settings.scene_threshold,
                min_gap_seconds=settings.transition_min_gap_seconds,
                capture_offset_seconds=settings.transition_capture_offset_seconds,
                max_candidates=settings.max_transition_candidates,
            )
            if settings.transition_scan
            else []
        )
        events = select_events(
            transcript_events=transcript_events,
            transition_events=transition_events,
            max_frames=settings.max_frames,
            merge_window_seconds=settings.event_merge_window_seconds,
        )

    frames_dir = output_dir / "frames"
    accepted_hashes: list[tuple[str, str]] = []
    for event in events:
        frame_path = frames_dir / f"{event.id}.jpg"
        try:
            extract_frame(
                ffmpeg_path=ffmpeg_path,
                video_path=video_path,
                timestamp_seconds=event.representative_seconds,
                destination=frame_path,
            )
            width, height = image_dimensions(frame_path)
            event.frame_path = frame_path.relative_to(output_dir).as_posix()
            event.image_width = width
            event.image_height = height
            event.frame_quality = assess_frame_quality(
                frame_path,
                min_primary_edge_mean=settings.min_primary_edge_mean,
                min_rich_tile_ratio=settings.min_rich_tile_ratio,
            )
            duplicate_of = find_duplicate(event.frame_quality.duplicate_hash, accepted_hashes, settings.duplicate_hamming_threshold)
            if duplicate_of:
                event.frame_quality.status = "rejected"
                event.frame_quality.rejection_reason = f"near-duplicate of {duplicate_of}"
                event.frame_quality.duplicate_of = duplicate_of
            if event.frame_quality.status == "rejected":
                event.status = "rejected"
                event.rejection_reason = event.frame_quality.rejection_reason
                event.visual_analysis = build_rejected_agent_analysis(event)
            else:
                event.visual_analysis = build_pending_agent_analysis(event)
                event.status = "extracted"
                if event.frame_quality.duplicate_hash:
                    accepted_hashes.append((event.id, event.frame_quality.duplicate_hash))
        except (FrameExtractionError, OSError) as exc:
            event.status = "failed"
            event.error = str(exc)

    events, rejected_removed_count = prune_rejected_events(events, output_dir)

    run = ParserRun(
        video_path=video_path,
        transcript_path=transcript_path,
        output_dir=output_dir,
        created_at=datetime.now(UTC).isoformat(timespec="seconds"),
        settings=settings,
        segment_count=len(segments),
        candidate_segment_count=sum(1 for segment in segments if segment.score >= settings.score_threshold),
        transition_candidate_count=len(transition_events),
        rejected_removed_count=rejected_removed_count,
        contact_sheet_count=len(contact_manifest.get("sheets", [])),
        contact_sheet_frame_count=int(contact_manifest.get("frame_count", 0)),
        contact_sheet_selection_count=len(selected_contact_frames),
        low_confidence_candidates=low_confidence_candidates(segments, threshold=settings.score_threshold),
        cue_match_counts=cue_counts(segments),
        events=events,
    )
    if contact_manifest.get("sheets"):
        run.outputs["contact_sheet_manifest"] = "contact-sheet-manifest.json"
        run.outputs["contact_sheet_review"] = "contact-sheet-review.md"

    context_path = write_context_markdown(run)
    findings = build_findings(run)
    comparison = compare_manifest(compare_path, run) if compare_path else None
    if args.self_improve:
        write_improvement_report(run, findings=findings, comparison=comparison)
    manifest_path = write_manifest(run)
    validate_output_paths(run.output_dir, [context_path, manifest_path])
    return run


def parse_timestamp(value: str) -> float:
    normalized = value.replace(",", ".")
    parts = normalized.split(":")
    if len(parts) == 2:
        hours = 0
        minutes = int(parts[0])
        seconds = float(parts[1])
    elif len(parts) == 3:
        hours = int(parts[0])
        minutes = int(parts[1])
        seconds = float(parts[2])
    else:
        raise VttParseError(f"Invalid VTT timestamp: {value}")
    return hours * 3600 + minutes * 60 + seconds


def parse_vtt(path: Path) -> list[TranscriptSegment]:
    text = path.read_text(encoding="utf-8-sig")
    segments: list[TranscriptSegment] = []
    lines = text.splitlines()
    index = 0
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        match = TIMESTAMP_RE.search(line)
        if not match:
            i += 1
            continue
        start = parse_timestamp(match.group("start"))
        end = parse_timestamp(match.group("end"))
        i += 1
        cue_lines: list[str] = []
        while i < len(lines) and lines[i].strip():
            cue_lines.append(lines[i].strip())
            i += 1
        cleaned, speaker = clean_cue_text(" ".join(cue_lines))
        if cleaned:
            segments.append(TranscriptSegment(index=index, start_seconds=start, end_seconds=end, text=cleaned, speaker=speaker))
            index += 1
    if not segments:
        raise VttParseError(f"No transcript cues found in {path}")
    return segments


def clean_cue_text(raw: str) -> tuple[str, str | None]:
    speaker: str | None = None
    voice_match = VOICE_RE.search(raw)
    if voice_match:
        speaker = voice_match.group(1).strip()
        raw = voice_match.group(2)
    normalized = re.sub(r"\s+", " ", TAG_RE.sub("", raw)).strip()
    speaker_match = re.match(r"^([^:]{2,60}):\s+(.+)$", normalized)
    if speaker_match:
        possible_speaker = speaker_match.group(1).strip()
        if not re.search(r"[.!?]$", possible_speaker):
            speaker = speaker or possible_speaker
            normalized = speaker_match.group(2).strip()
    return normalized, speaker


def score_segments(segments: list[TranscriptSegment]) -> None:
    for segment in segments:
        score, matches = score_text(segment.text)
        segment.score = score
        segment.cue_matches = matches


def score_text(text: str) -> tuple[int, list[str]]:
    lowered = text.lower()
    score = 0
    matches: list[str] = []
    for cue, weight in CUE_WEIGHTS.items():
        if re.search(rf"(?<!\w){re.escape(cue)}(?!\w)", lowered):
            score += weight
            matches.append(cue)
    return score, matches


def cluster_segments(
    segments: list[TranscriptSegment],
    *,
    threshold: int,
    cluster_window_seconds: float,
    timestamp_offset_seconds: float,
    max_frames: int,
) -> list[ExtractionEvent]:
    candidates = [segment for segment in segments if segment.score >= threshold]
    if not candidates:
        return []

    clusters: list[list[TranscriptSegment]] = []
    current: list[TranscriptSegment] = []
    for segment in candidates:
        if not current:
            current = [segment]
        elif segment.start_seconds - current[-1].end_seconds <= cluster_window_seconds:
            current.append(segment)
        else:
            clusters.append(current)
            current = [segment]
    if current:
        clusters.append(current)

    ranked = sorted(clusters, key=lambda cluster: sum(s.score for s in cluster), reverse=True)
    selected = sorted(ranked[:max_frames], key=lambda cluster: cluster[0].start_seconds)
    events: list[ExtractionEvent] = []
    for idx, cluster in enumerate(selected, start=1):
        best = max(cluster, key=lambda segment: (segment.score, -segment.index))
        excerpt = " ".join(segment.text for segment in cluster)
        if len(excerpt) > 900:
            excerpt = excerpt[:897].rstrip() + "..."
        events.append(
            ExtractionEvent(
                id=f"event-{idx:03d}",
                start_seconds=cluster[0].start_seconds,
                end_seconds=cluster[-1].end_seconds,
                representative_seconds=max(0.0, best.midpoint_seconds + timestamp_offset_seconds),
                transcript_excerpt=excerpt,
                trigger_reasons=sorted({match for segment in cluster for match in segment.cue_matches}),
                score=sum(segment.score for segment in cluster),
                segments=[segment.index for segment in cluster],
                selection_source="transcript-cue",
                selection_reasons=sorted({match for segment in cluster for match in segment.cue_matches}),
            )
        )
    return events


def build_transition_events(
    *,
    ffmpeg_path: Path,
    video_path: Path,
    segments: list[TranscriptSegment],
    scene_threshold: float,
    min_gap_seconds: float,
    capture_offset_seconds: float,
    max_candidates: int,
) -> list[ExtractionEvent]:
    changes = detect_scene_changes(
        ffmpeg_path=ffmpeg_path,
        video_path=video_path,
        scene_threshold=scene_threshold,
        min_gap_seconds=min_gap_seconds,
        max_candidates=max_candidates,
    )
    events: list[ExtractionEvent] = []
    for idx, (scene_time, scene_score) in enumerate(changes, start=1):
        capture_time = max(0.0, scene_time + capture_offset_seconds)
        nearby = nearby_transcript_segments(segments, capture_time, window_seconds=22.0)
        excerpt = " ".join(segment.text for segment in nearby)
        if len(excerpt) > 900:
            excerpt = excerpt[:897].rstrip() + "..."
        cue_matches = sorted({match for segment in nearby for match in segment.cue_matches})
        reasons = [f"scene-change:{scene_score:.3f}", *cue_matches]
        events.append(
            ExtractionEvent(
                id=f"transition-{idx:03d}",
                start_seconds=nearby[0].start_seconds if nearby else scene_time,
                end_seconds=nearby[-1].end_seconds if nearby else scene_time,
                representative_seconds=capture_time,
                transcript_excerpt=excerpt or f"Visual scene transition detected at {seconds_to_timestamp(scene_time)}.",
                trigger_reasons=reasons,
                score=max(1, int(round(scene_score * 10))) + sum(segment.score for segment in nearby),
                segments=[segment.index for segment in nearby],
                selection_source="visual-transition",
                selection_reasons=reasons,
            )
        )
    return events


def generate_contact_sheets(
    *,
    ffmpeg_path: Path,
    video_path: Path,
    segments: list[TranscriptSegment],
    output_dir: Path,
    settings: ParserSettings,
) -> dict[str, Any]:
    if not settings.contact_sheet_scan:
        return {"sheets": [], "frames": [], "frame_count": 0}
    try:
        from PIL import Image, ImageDraw
    except ImportError as exc:
        raise FrameExtractionError(
            "Pillow is required for contact-sheet generation. Install it with "
            "`python -m pip install Pillow` or pass --no-contact-sheet-scan to skip contact sheets."
        ) from exc

    sheets_dir = output_dir / "contact-sheets"
    sheets_dir.mkdir(parents=True, exist_ok=True)
    thumbs_dir = sheets_dir / "_thumbs"
    if thumbs_dir.exists():
        delete_directory_inside_output(output_dir, thumbs_dir)
    thumbs_dir.mkdir(parents=True, exist_ok=True)

    command = [
        str(ffmpeg_path),
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        str(video_path),
        "-vf",
        f"fps=1/{settings.contact_sheet_interval_seconds},scale={settings.contact_sheet_thumb_width}:-1",
        "-frames:v",
        str(settings.contact_sheet_max_thumbnails),
        "-q:v",
        "3",
        "-y",
        str(thumbs_dir / "thumb-%04d.jpg"),
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=600)
    thumb_paths = sorted(thumbs_dir.glob("thumb-*.jpg"))
    if result.returncode != 0 or not thumb_paths:
        detail = (result.stderr or result.stdout or "FFmpeg did not create contact-sheet thumbnails").strip()
        raise FrameExtractionError(detail)

    tiles_per_sheet = settings.contact_sheet_columns * settings.contact_sheet_rows
    sheets: list[dict[str, Any]] = []
    frames: list[dict[str, Any]] = []
    for sheet_index, group_start in enumerate(range(0, len(thumb_paths), tiles_per_sheet), start=1):
        group = thumb_paths[group_start : group_start + tiles_per_sheet]
        opened = [Image.open(path).convert("RGB") for path in group]
        thumb_width = max(image.width for image in opened)
        thumb_height = max(image.height for image in opened)
        sheet_id = f"sheet-{sheet_index:03d}"
        sheet_path = sheets_dir / f"{sheet_id}.jpg"
        canvas = Image.new("RGB", (settings.contact_sheet_columns * thumb_width, settings.contact_sheet_rows * thumb_height), (18, 18, 18))
        draw = ImageDraw.Draw(canvas)
        sheet_frames: list[dict[str, Any]] = []
        for offset, image in enumerate(opened):
            absolute_index = group_start + offset + 1
            frame_id = f"thumb-{absolute_index:04d}"
            timestamp_seconds = round((absolute_index - 1) * settings.contact_sheet_interval_seconds, 3)
            row = offset // settings.contact_sheet_columns
            column = offset % settings.contact_sheet_columns
            x = column * thumb_width
            y = row * thumb_height
            canvas.paste(image, (x, y))
            label = f"{frame_id}  {seconds_to_timestamp(timestamp_seconds)}"
            draw.rectangle((x, y, x + min(thumb_width, 250), y + 28), fill=(0, 0, 0))
            draw.text((x + 6, y + 6), label, fill=(255, 255, 255))
            nearby = nearby_transcript_segments(segments, timestamp_seconds, window_seconds=18.0)
            excerpt = " ".join(segment.text for segment in nearby)
            if len(excerpt) > 500:
                excerpt = excerpt[:497].rstrip() + "..."
            frame = {
                "id": frame_id,
                "timestamp_seconds": timestamp_seconds,
                "timestamp": seconds_to_timestamp(timestamp_seconds),
                "sheet_id": sheet_id,
                "sheet_path": sheet_path.relative_to(output_dir).as_posix(),
                "row": row + 1,
                "column": column + 1,
                "position": offset + 1,
                "transcript_excerpt": excerpt,
                "segments": [segment.index for segment in nearby],
                "cue_matches": sorted({match for segment in nearby for match in segment.cue_matches}),
            }
            sheet_frames.append(frame)
            frames.append(frame)
        canvas.save(sheet_path, quality=92)
        for image in opened:
            image.close()
        sheets.append(
            {
                "id": sheet_id,
                "path": sheet_path.relative_to(output_dir).as_posix(),
                "frame_count": len(sheet_frames),
                "frames": sheet_frames,
            }
        )

    delete_directory_inside_output(output_dir, thumbs_dir)
    manifest = {
        "created_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "sampling_interval_seconds": settings.contact_sheet_interval_seconds,
        "max_thumbnails": settings.contact_sheet_max_thumbnails,
        "columns": settings.contact_sheet_columns,
        "rows": settings.contact_sheet_rows,
        "thumb_width": settings.contact_sheet_thumb_width,
        "frame_count": len(frames),
        "sheets": sheets,
        "frames": frames,
    }
    manifest_path = output_dir / "contact-sheet-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    write_contact_sheet_review(output_dir, manifest)
    return manifest


def write_contact_sheet_review(output_dir: Path, manifest: dict[str, Any]) -> Path:
    path = output_dir / "contact-sheet-review.md"
    lines = [
        "# Contact Sheet Review",
        "",
        "Inspect the contact sheets and select only visually useful project-context frames.",
        "Prefer screens that show architecture, Azure AI Foundry models, Azure AI Foundry agents, deployment/configuration, repository/IaC, Fabric/data sources, diagrams, tables, or decision-relevant UI state.",
        "Skip meeting gallery, webcam-only, blank, loading, repeated, or purely transitional frames.",
        "",
        "Write selected frames to `contact-sheet-selection.json` using this shape:",
        "",
        "```json",
        '{ "selected_frames": [ { "id": "thumb-0001", "reason": "why this visible screen matters" } ] }',
        "```",
        "",
        "## Sheets",
        "",
    ]
    for sheet in manifest.get("sheets", []):
        lines.extend(
            [
                f"### {sheet['id']}",
                "",
                f"![{sheet['id']}]({sheet['path']})",
                "",
            ]
        )
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    return path


def load_contact_sheet_selection(selection_path: Path, contact_manifest: dict[str, Any]) -> list[dict[str, Any]]:
    selection = json.loads(selection_path.read_text(encoding="utf-8"))
    frames_by_id = {frame["id"]: frame for frame in contact_manifest.get("frames", [])}
    selected_items = selection.get("selected_frames") or selection.get("frames") or selection.get("events") or []
    selected: list[dict[str, Any]] = []
    seen: set[str] = set()
    for item in selected_items:
        frame: dict[str, Any] | None = None
        item_id = item.get("id") or item.get("thumbnail_id") or item.get("frame_id")
        if item_id:
            frame = frames_by_id.get(str(item_id))
            if frame is None:
                raise ValueError(f"Contact-sheet selection references unknown thumbnail id: {item_id}")
        elif "timestamp_seconds" in item:
            timestamp_seconds = float(item["timestamp_seconds"])
            frame = min(
                contact_manifest.get("frames", []),
                key=lambda candidate: abs(float(candidate["timestamp_seconds"]) - timestamp_seconds),
            )
        else:
            raise ValueError("Each contact-sheet selection item must include id or timestamp_seconds")
        if frame["id"] in seen:
            continue
        seen.add(frame["id"])
        selected.append({**frame, "selection_reason": item.get("reason") or item.get("selection_reason") or "selected from contact sheet"})
    return selected


def build_contact_sheet_events(selected_frames: list[dict[str, Any]], segments: list[TranscriptSegment], max_frames: int) -> list[ExtractionEvent]:
    events: list[ExtractionEvent] = []
    for idx, frame in enumerate(selected_frames[:max_frames], start=1):
        timestamp_seconds = float(frame["timestamp_seconds"])
        nearby = nearby_transcript_segments(segments, timestamp_seconds, window_seconds=22.0)
        excerpt = frame.get("transcript_excerpt") or " ".join(segment.text for segment in nearby)
        if len(excerpt) > 900:
            excerpt = excerpt[:897].rstrip() + "..."
        cue_matches = sorted({match for segment in nearby for match in segment.cue_matches})
        reasons = [
            "contact-sheet-selection",
            f"thumbnail:{frame['id']}",
            f"{frame.get('sheet_id', 'sheet-unknown')} row {frame.get('row', '?')} column {frame.get('column', '?')}",
            frame.get("selection_reason", "selected from contact sheet"),
            *cue_matches,
        ]
        events.append(
            ExtractionEvent(
                id=f"event-{idx:03d}",
                start_seconds=nearby[0].start_seconds if nearby else timestamp_seconds,
                end_seconds=nearby[-1].end_seconds if nearby else timestamp_seconds,
                representative_seconds=timestamp_seconds,
                transcript_excerpt=excerpt or f"Contact-sheet-selected frame at {seconds_to_timestamp(timestamp_seconds)}.",
                trigger_reasons=reasons,
                score=max(1, 100 - idx),
                segments=[segment.index for segment in nearby],
                selection_source="contact-sheet-selection",
                selection_reasons=reasons,
            )
        )
    return events


def detect_scene_changes(
    *,
    ffmpeg_path: Path,
    video_path: Path,
    scene_threshold: float,
    min_gap_seconds: float,
    max_candidates: int,
) -> list[tuple[float, float]]:
    if max_candidates == 0:
        return []
    command = [
        str(ffmpeg_path),
        "-hide_banner",
        "-i",
        str(video_path),
        "-vf",
        f"select='gt(scene,{scene_threshold})',metadata=print",
        "-an",
        "-f",
        "null",
        "-",
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=300)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "FFmpeg scene detection failed").strip()
        raise FrameExtractionError(detail)

    changes: list[tuple[float, float]] = []
    current_time: float | None = None
    for line in f"{result.stdout}\n{result.stderr}".splitlines():
        time_match = SCENE_PTS_RE.search(line)
        if time_match:
            current_time = float(time_match.group("time"))
            continue
        score_match = SCENE_SCORE_RE.search(line)
        if score_match and current_time is not None:
            changes.append((current_time, float(score_match.group("score"))))
            current_time = None

    filtered: list[tuple[float, float]] = []
    for scene_time, scene_score in sorted(changes):
        if not filtered or scene_time - filtered[-1][0] >= min_gap_seconds:
            filtered.append((scene_time, scene_score))
        elif scene_score > filtered[-1][1]:
            filtered[-1] = (scene_time, scene_score)
    return filtered[:max_candidates]


def nearby_transcript_segments(
    segments: list[TranscriptSegment],
    timestamp_seconds: float,
    *,
    window_seconds: float,
    fallback_count: int = 2,
) -> list[TranscriptSegment]:
    nearby = [
        segment
        for segment in segments
        if segment.start_seconds <= timestamp_seconds + window_seconds and segment.end_seconds >= timestamp_seconds - window_seconds
    ]
    if nearby:
        return nearby
    return sorted(segments, key=lambda segment: abs(segment.midpoint_seconds - timestamp_seconds))[:fallback_count]


def select_events(
    *,
    transcript_events: list[ExtractionEvent],
    transition_events: list[ExtractionEvent],
    max_frames: int,
    merge_window_seconds: float,
) -> list[ExtractionEvent]:
    candidates = sorted([*transcript_events, *transition_events], key=lambda event: event.representative_seconds)
    if not candidates:
        return []

    groups: list[list[ExtractionEvent]] = []
    current: list[ExtractionEvent] = []
    for candidate in candidates:
        if not current:
            current = [candidate]
        elif candidate.representative_seconds - current[-1].representative_seconds <= merge_window_seconds:
            current.append(candidate)
        else:
            groups.append(current)
            current = [candidate]
    if current:
        groups.append(current)

    merged = [merge_candidate_group(group) for group in groups]
    ranked = sorted(merged, key=event_rank, reverse=True)
    selected = sorted(ranked[:max_frames], key=lambda event: event.representative_seconds)
    for idx, event in enumerate(selected, start=1):
        event.id = f"event-{idx:03d}"
    return selected


def merge_candidate_group(group: list[ExtractionEvent]) -> ExtractionEvent:
    preferred = max(group, key=lambda event: (event.selection_source == "visual-transition", event.score))
    sources = sorted({event.selection_source for event in group})
    trigger_reasons = sorted({reason for event in group for reason in event.trigger_reasons})
    selection_reasons = sorted({reason for event in group for reason in event.selection_reasons}) or trigger_reasons
    segments = sorted({segment for event in group for segment in event.segments})
    excerpts: list[str] = []
    seen_excerpts: set[str] = set()
    for event in sorted(group, key=lambda item: item.representative_seconds):
        excerpt = event.transcript_excerpt.strip()
        if excerpt and excerpt not in seen_excerpts:
            excerpts.append(excerpt)
            seen_excerpts.add(excerpt)
    transcript_excerpt = " ".join(excerpts)
    if len(transcript_excerpt) > 900:
        transcript_excerpt = transcript_excerpt[:897].rstrip() + "..."
    return ExtractionEvent(
        id=preferred.id,
        start_seconds=min(event.start_seconds for event in group),
        end_seconds=max(event.end_seconds for event in group),
        representative_seconds=preferred.representative_seconds,
        transcript_excerpt=transcript_excerpt,
        trigger_reasons=trigger_reasons,
        score=sum(event.score for event in group),
        segments=segments,
        selection_source="+".join(sources),
        selection_reasons=selection_reasons,
    )


def event_rank(event: ExtractionEvent) -> int:
    rank = event.score
    if "visual-transition" in event.selection_source:
        rank += 8
    if "transcript-cue" in event.selection_source and "visual-transition" in event.selection_source:
        rank += 6
    return rank


def cue_counts(segments: list[TranscriptSegment]) -> dict[str, int]:
    counter: Counter[str] = Counter()
    for segment in segments:
        counter.update(segment.cue_matches)
    return dict(counter.most_common())


def low_confidence_candidates(segments: list[TranscriptSegment], *, threshold: int, limit: int = 20) -> list[TranscriptSegment]:
    candidates = [
        segment
        for segment in segments
        if 0 < segment.score < threshold or (segment.score == 0 and any(h in segment.text.lower() for h in ("azure", "foundry", "fabric", "copilot", "diagram", "screen", "portal")))
    ]
    return sorted(candidates, key=lambda segment: (segment.score, -segment.index), reverse=True)[:limit]


def resolve_ffmpeg(explicit_path: str | None = None) -> Path:
    if explicit_path:
        path = Path(explicit_path)
        if path.is_file():
            return path
        raise DependencyError(f"FFmpeg executable not found at: {path}")
    on_path = shutil.which("ffmpeg")
    if on_path:
        return Path(on_path)
    home = Path.home()
    candidates = [
        home / "scoop" / "shims" / "ffmpeg.exe",
        home / "scoop" / "apps" / "ffmpeg" / "current" / "bin" / "ffmpeg.exe",
    ]
    candidates.extend((home / "scoop" / "apps" / "ffmpeg").glob("*/*/bin/ffmpeg.exe"))
    candidates.extend((home / "scoop" / "apps" / "ffmpeg").glob("*/bin/ffmpeg.exe"))
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    raise DependencyError("FFmpeg is required for frame extraction. Install it on PATH or pass --ffmpeg-path.")


def extract_frame(*, ffmpeg_path: Path, video_path: Path, timestamp_seconds: float, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(ffmpeg_path),
        "-hide_banner",
        "-loglevel",
        "error",
        "-ss",
        f"{max(0.0, timestamp_seconds):.3f}",
        "-i",
        str(video_path),
        "-frames:v",
        "1",
        "-q:v",
        "2",
        "-y",
        str(destination),
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=120)
    if result.returncode != 0 or not destination.is_file():
        detail = (result.stderr or result.stdout or "FFmpeg did not create a frame").strip()
        raise FrameExtractionError(detail)


def image_dimensions(path: Path) -> tuple[int | None, int | None]:
    try:
        from PIL import Image
    except ImportError:
        return None, None
    with Image.open(path) as image:
        return image.size


def assess_frame_quality(
    path: Path,
    *,
    min_primary_edge_mean: float,
    min_rich_tile_ratio: float,
) -> FrameQuality:
    try:
        from PIL import Image, ImageFilter, ImageStat
    except ImportError:
        return FrameQuality(status="unknown", notes=["Pillow unavailable; frame quality gate skipped."])

    with Image.open(path) as image:
        width, height = image.size
        primary = image.crop((0, 0, int(width * 0.84), int(height * 0.93))).convert("L").resize((320, 180))
        stats = ImageStat.Stat(primary)
        edge_mean = float(ImageStat.Stat(primary.filter(ImageFilter.FIND_EDGES)).mean[0])
        rich_tiles = 0
        tile_count = 0
        for y in range(0, 180, 30):
            for x in range(0, 320, 40):
                tile = primary.crop((x, y, min(x + 40, 320), min(y + 30, 180)))
                tile_count += 1
                if ImageStat.Stat(tile).stddev[0] >= 8:
                    rich_tiles += 1
        rich_tile_ratio = rich_tiles / tile_count if tile_count else 0.0
        duplicate_hash = primary_dhash(primary)

    quality = FrameQuality(
        status="accepted",
        mean_luma=round(float(stats.mean[0]), 3),
        luma_stddev=round(float(stats.stddev[0]), 3),
        edge_mean=round(edge_mean, 3),
        rich_tile_ratio=round(rich_tile_ratio, 3),
        duplicate_hash=duplicate_hash,
        notes=[
            "Metrics are computed on the primary screen-share region, excluding the participant rail and bottom chrome.",
        ],
    )
    if edge_mean < min_primary_edge_mean and rich_tile_ratio < min_rich_tile_ratio:
        quality.status = "rejected"
        quality.rejection_reason = (
            f"low primary-region visual evidence "
            f"(edge_mean={edge_mean:.2f}, rich_tile_ratio={rich_tile_ratio:.2f})"
        )
    return quality


def primary_dhash(primary_image: Any) -> str:
    small = primary_image.resize((9, 8))
    pixels = small.load()
    bits: list[str] = []
    for y in range(8):
        for x in range(8):
            bits.append("1" if pixels[x, y] > pixels[x + 1, y] else "0")
    value = int("".join(bits), 2)
    return f"{value:016x}"


def hamming_distance_hex(left: str, right: str) -> int:
    return (int(left, 16) ^ int(right, 16)).bit_count()


def find_duplicate(
    duplicate_hash: str | None,
    accepted_hashes: list[tuple[str, str]],
    duplicate_hamming_threshold: int,
) -> str | None:
    if not duplicate_hash:
        return None
    for event_id, accepted_hash in accepted_hashes:
        if hamming_distance_hex(duplicate_hash, accepted_hash) <= duplicate_hamming_threshold:
            return event_id
    return None


def build_pending_agent_analysis(event: ExtractionEvent) -> VisualAnalysis:
    triggers = ", ".join(event.trigger_reasons) or "visual cue"
    return VisualAnalysis(
        status="incomplete",
        method="frame-only",
        summary=f"{event.id} was extracted because the transcript referenced {triggers}; visible screen content still requires agent visual analysis.",
        application_hint=infer_application_hint(event.transcript_excerpt, event),
        information_hierarchy=[
            {"level": "frame", "order": 1, "text": "Frame extracted as a candidate for agent visual inspection.", "confidence": 0},
            {"level": "transcript-context", "order": 2, "text": event.transcript_excerpt, "confidence": None},
        ],
        warnings=["Pending agent-vision analysis; do not treat this event as complete source context."],
    )


def build_rejected_agent_analysis(event: ExtractionEvent) -> VisualAnalysis:
    reason = event.rejection_reason or "frame rejected by quality gate"
    return VisualAnalysis(
        status="rejected",
        method="quality-gate",
        summary=f"{event.id} was rejected before agent-vision analysis because {reason}.",
        application_hint=infer_application_hint(event.transcript_excerpt, event),
        information_hierarchy=[
            {"level": "rejection", "order": 1, "text": reason, "confidence": 1.0},
            {"level": "transcript-context", "order": 2, "text": event.transcript_excerpt, "confidence": None},
        ],
        warnings=["Rejected candidate; do not treat this frame as project evidence."],
    )


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


def delete_directory_inside_output(output_dir: Path, target_dir: Path) -> bool:
    output_root = output_dir.resolve()
    target = target_dir.resolve()
    try:
        target.relative_to(output_root)
    except ValueError:
        return False
    if target.is_dir():
        shutil.rmtree(target)
        return True
    return False


def prune_rejected_events(events: list[ExtractionEvent], output_dir: Path) -> tuple[list[ExtractionEvent], int]:
    retained: list[ExtractionEvent] = []
    removed_count = 0
    for event in events:
        if event.status != "rejected":
            retained.append(event)
            continue
        removed_count += 1
        delete_relative_file(output_dir, event.frame_path)
    compact_event_ids(retained, output_dir)
    return retained, removed_count


def compact_event_ids(events: list[ExtractionEvent], output_dir: Path) -> None:
    for idx, event in enumerate(events, start=1):
        new_id = f"event-{idx:03d}"
        if event.id == new_id:
            continue
        if event.frame_path:
            old_frame = (output_dir / event.frame_path).resolve()
            new_frame = old_frame.with_name(f"{new_id}{old_frame.suffix}")
            try:
                old_frame.relative_to(output_dir.resolve())
                new_frame.relative_to(output_dir.resolve())
            except ValueError:
                event.id = new_id
                event.frame_path = None
            else:
                if old_frame.is_file():
                    old_frame.rename(new_frame)
                    event.frame_path = new_frame.relative_to(output_dir.resolve()).as_posix()
        event.id = new_id
        if event.status == "extracted" and event.visual_analysis.method in INCOMPLETE_METHODS:
            event.visual_analysis = build_pending_agent_analysis(event)


def infer_application_hint(text: str, event: ExtractionEvent) -> str:
    haystack = f"{text} {' '.join(event.trigger_reasons)} {event.transcript_excerpt}".lower()
    if "azure" in haystack or "portal" in haystack or "subscription" in haystack:
        return "Azure portal or Azure architecture screen"
    if "powerpoint" in haystack or "slide" in haystack:
        return "PowerPoint or presentation slide"
    if "pipeline" in haystack or "repo" in haystack or "github" in haystack or "ado" in haystack:
        return "DevOps repository or pipeline screen"
    if "diagram" in haystack:
        return "Architecture diagram"
    return "unknown"


def write_manifest(run: ParserRun) -> Path:
    path = run.output_dir / "manifest.json"
    manifest = {
        "created_at": run.created_at,
        "video_path": str(run.video_path),
        "transcript_path": str(run.transcript_path),
        "output_dir": str(run.output_dir),
        "settings": asdict(run.settings),
        "segment_count": run.segment_count,
        "candidate_segment_count": run.candidate_segment_count,
        "transition_candidate_count": run.transition_candidate_count,
        "contact_sheet_count": run.contact_sheet_count,
        "contact_sheet_frame_count": run.contact_sheet_frame_count,
        "contact_sheet_selection_count": run.contact_sheet_selection_count,
        "event_count": len(run.events),
        "extracted_count": run.extracted_count,
        "rejected_count": run.rejected_count,
        "rejected_removed_count": run.rejected_removed_count,
        "failed_count": run.failed_count,
        "cue_match_counts": run.cue_match_counts,
        "low_confidence_candidates": [segment_to_dict(segment) for segment in run.low_confidence_candidates],
        "events": [event_to_dict(event) for event in run.events],
        "outputs": run.outputs,
    }
    path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    run.outputs["manifest"] = "manifest.json"
    return path


def write_context_markdown(run: ParserRun) -> Path:
    path = run.output_dir / "context.md"
    lines = [
        "# Video Context Package",
        "",
        f"- **Created**: {run.created_at}",
        f"- **Video**: `{run.video_path}`",
        f"- **Transcript**: `{run.transcript_path}`",
        f"- **Transcript segments parsed**: {run.segment_count}",
        f"- **Transcript cue candidates**: {run.candidate_segment_count}",
        f"- **Visual transition candidates**: {run.transition_candidate_count}",
        f"- **Contact sheets**: {run.contact_sheet_count}",
        f"- **Contact-sheet thumbnails**: {run.contact_sheet_frame_count}",
        f"- **Contact-sheet selections**: {run.contact_sheet_selection_count}",
        f"- **Extraction events**: {len(run.events)}",
        f"- **Extracted frames**: {run.extracted_count}",
        f"- **Failed frames**: {run.failed_count}",
        "",
        "## Index",
        "",
    ]
    if run.events:
        lines.extend(["| Event | Timestamp | Status | Source | Score | Summary |", "|-------|-----------|--------|--------|-------|---------|"])
        for event in run.events:
            lines.append(
                f"| {event.id} | {seconds_to_timestamp(event.representative_seconds)} | {event.status} | "
                f"{event.selection_source} | {event.score} | {table_text(event.transcript_excerpt, 140)} |"
            )
        lines.append("")
    else:
        lines.extend(["No extraction events met the configured score threshold.", ""])

    lines.extend(["## Accepted Keyframes", ""])
    accepted_events = [event for event in run.events if event.status == "extracted"]
    if not accepted_events:
        lines.extend(["No accepted keyframes were extracted.", ""])
    for event in accepted_events:
        analysis = event.visual_analysis
        lines.extend(
            [
                f"### {event.id} - {seconds_to_timestamp(event.representative_seconds)}",
                "",
                f"- **Status**: {event.status}",
                f"- **Selection source**: {event.selection_source}",
                f"- **Selection reasons**: {', '.join(event.selection_reasons) or 'None'}",
                f"- **Score**: {event.score}",
                f"- **Trigger reasons**: {', '.join(event.trigger_reasons) or 'None'}",
                f"- **Transcript segments**: {', '.join(str(s) for s in event.segments)}",
                f"- **Visual analysis method**: {analysis.method}",
                f"- **Application hint**: {analysis.application_hint}",
            ]
        )
        if event.image_width and event.image_height:
            lines.append(f"- **Image size**: {event.image_width} x {event.image_height}")
        if event.error:
            lines.append(f"- **Error**: {event.error}")
        lines.extend(["", "**Transcript excerpt**", "", event.transcript_excerpt, "", "**Visible Information Extraction**", ""])
        if analysis.summary:
            lines.extend([analysis.summary, ""])
        if analysis.visible_text:
            lines.extend(["```text", analysis.visible_text, "```", ""])
        if analysis.information_hierarchy:
            lines.extend(["**Information hierarchy**", ""])
            for item in analysis.information_hierarchy:
                text = str(item.get("text", "")).replace("\n", " ").strip()
                confidence = item.get("confidence")
                confidence_text = "" if confidence is None else f" (confidence: {confidence})"
                lines.append(f"- {item.get('level', 'item')} {item.get('order', '')}: {text}{confidence_text}")
            lines.append("")
        if analysis.warnings:
            lines.extend(["**Analysis warnings**", ""])
            for warning in analysis.warnings:
                lines.append(f"- {warning}")
            lines.append("")
        if event.frame_path:
            lines.extend([f"![{event.id}]({event.frame_path})", ""])
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    run.outputs["context"] = "context.md"
    return path


def build_findings(run: ParserRun) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    severity = "medium" if len(run.events) < 5 else "info"
    findings.append(
        {
            "category": "coverage",
            "severity": severity,
            "evidence": f"{len(run.events)} retained extraction events were selected; {run.extracted_count} accepted, {run.failed_count} failed, and {run.rejected_removed_count} rejected candidates were deleted.",
            "recommendation": "Review accepted keyframes for coverage before changing threshold, scene detection, or clustering settings.",
        }
    )
    if run.transition_candidate_count:
        findings.append(
            {
                "category": "transition-coverage",
                "severity": "info",
                "evidence": f"{run.transition_candidate_count} visual transition candidates were detected before merge and quality filtering.",
                "recommendation": "Inspect whether transition-sourced frames cover screen-share changes that transcript cues miss.",
            }
        )
    if run.contact_sheet_frame_count:
        findings.append(
            {
                "category": "contact-sheet-coverage",
                "severity": "info" if run.contact_sheet_selection_count else "medium",
                "evidence": f"{run.contact_sheet_frame_count} thumbnails were sampled into {run.contact_sheet_count} contact sheet(s); {run.contact_sheet_selection_count} were selected for retained extraction.",
                "recommendation": "Use contact-sheet review to choose visually rich screens before extracting full keyframes, especially Foundry models, agents, architecture, IaC, and data configuration screens.",
            }
        )
    if run.rejected_removed_count:
        findings.append(
            {
                "category": "quality-pruning",
                "severity": "info",
                "evidence": f"{run.rejected_removed_count} rejected candidate frame(s) were deleted from the package.",
                "recommendation": "Keep rejected candidates out of project context; rerun with different thresholds only if coverage review shows a missed transition.",
            }
        )
    incomplete = [
        event
        for event in run.events
        if event.status == "extracted"
        and (event.visual_analysis.method in INCOMPLETE_METHODS or event.visual_analysis.status in INCOMPLETE_STATUSES)
    ]
    if incomplete:
        findings.append(
            {
                "category": "visual-analysis",
                "severity": "high",
                "evidence": f"{len(incomplete)} extracted events still need agent visual analysis.",
                "recommendation": "Inspect extracted frames, write agent-vision findings, merge them, and run the context-package validator.",
            }
        )
    if run.failed_count:
        findings.append(
            {
                "category": "extraction",
                "severity": "high",
                "evidence": f"{run.failed_count} events failed during frame extraction.",
                "recommendation": "Inspect failed event errors and verify timestamps, video duration, and FFmpeg path.",
            }
        )
    if run.low_confidence_candidates:
        findings.append(
            {
                "category": "missed-candidates",
                "severity": "medium",
                "evidence": f"{len(run.low_confidence_candidates)} low-confidence visual hints were found.",
                "recommendation": "Review these segments for new cue phrases or rerun with a lower threshold.",
            }
        )
    return findings


def compare_manifest(previous_manifest_path: Path, run: ParserRun) -> dict[str, int | str]:
    previous = json.loads(previous_manifest_path.read_text(encoding="utf-8"))
    return {
        "previous_manifest": str(previous_manifest_path),
        "previous_event_count": int(previous.get("event_count", 0)),
        "current_event_count": len(run.events),
        "event_count_delta": len(run.events) - int(previous.get("event_count", 0)),
        "previous_extracted_count": int(previous.get("extracted_count", 0)),
        "current_extracted_count": run.extracted_count,
        "extracted_count_delta": run.extracted_count - int(previous.get("extracted_count", 0)),
    }


def write_improvement_report(run: ParserRun, *, findings: list[dict[str, str]], comparison: dict[str, int | str] | None = None) -> Path:
    path = run.output_dir / "self-improvement.md"
    lines = [
        "# Self-Improvement Report",
        "",
        "## Run Summary",
        "",
        f"- **Segments parsed**: {run.segment_count}",
        f"- **Candidate segments**: {run.candidate_segment_count}",
        f"- **Visual transition candidates**: {run.transition_candidate_count}",
        f"- **Contact sheets**: {run.contact_sheet_count}",
        f"- **Contact-sheet thumbnails**: {run.contact_sheet_frame_count}",
        f"- **Contact-sheet selections**: {run.contact_sheet_selection_count}",
        f"- **Events retained**: {len(run.events)}",
        f"- **Frames extracted**: {run.extracted_count}",
        f"- **Rejected candidates removed**: {run.rejected_removed_count}",
        f"- **Frame failures**: {run.failed_count}",
        f"- **Threshold**: {run.settings.score_threshold}",
        f"- **Cluster window**: {run.settings.cluster_window_seconds} seconds",
        f"- **Timestamp offset**: {run.settings.timestamp_offset_seconds} seconds",
        "",
    ]
    if comparison:
        lines.extend(
            [
                "## Before / After Comparison",
                "",
                f"- **Previous manifest**: `{comparison['previous_manifest']}`",
                f"- **Event count delta**: {comparison['event_count_delta']} ({comparison['previous_event_count']} -> {comparison['current_event_count']})",
                f"- **Extracted count delta**: {comparison['extracted_count_delta']} ({comparison['previous_extracted_count']} -> {comparison['current_extracted_count']})",
                "",
            ]
        )
    lines.extend(["## Findings", ""])
    for idx, finding in enumerate(findings, start=1):
        lines.extend(
            [
                f"### F{idx:03d}: {finding['category']} ({finding['severity']})",
                "",
                f"**Evidence**: {finding['evidence']}",
                "",
                f"**Recommendation**: {finding['recommendation']}",
                "",
            ]
        )
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    run.outputs["self_improvement"] = "self-improvement.md"
    return path


def event_to_dict(event: ExtractionEvent) -> dict[str, Any]:
    return {
        "id": event.id,
        "start_seconds": event.start_seconds,
        "end_seconds": event.end_seconds,
        "representative_seconds": event.representative_seconds,
        "timestamp": seconds_to_timestamp(event.representative_seconds),
        "transcript_excerpt": event.transcript_excerpt,
        "trigger_reasons": event.trigger_reasons,
        "score": event.score,
        "segments": event.segments,
        "selection_source": event.selection_source,
        "selection_reasons": event.selection_reasons,
        "frame_path": event.frame_path,
        "image_width": event.image_width,
        "image_height": event.image_height,
        "frame_quality": asdict(event.frame_quality),
        "visual_analysis": asdict(event.visual_analysis),
        "status": event.status,
        "rejection_reason": event.rejection_reason,
        "error": event.error,
    }


def segment_to_dict(segment: TranscriptSegment) -> dict[str, Any]:
    return {
        "index": segment.index,
        "start_seconds": segment.start_seconds,
        "end_seconds": segment.end_seconds,
        "timestamp": seconds_to_timestamp(segment.start_seconds),
        "text": segment.text,
        "speaker": segment.speaker,
        "score": segment.score,
        "cue_matches": segment.cue_matches,
    }


def required_file(value: str, label: str) -> Path:
    path = Path(value)
    if not path.is_file():
        raise ValueError(f"{label} file not found: {path}")
    return path


def optional_file(value: str, label: str) -> Path:
    path = Path(value)
    if not path.is_file():
        raise ValueError(f"{label} not found: {path}")
    return path


def validate_settings(args: argparse.Namespace) -> None:
    if args.threshold < 0:
        raise ValueError("--threshold must be non-negative")
    if args.cluster_window < 0:
        raise ValueError("--cluster-window must be non-negative")
    if args.max_frames <= 0:
        raise ValueError("--max-frames must be greater than zero")
    if not 0 < args.scene_threshold < 1:
        raise ValueError("--scene-threshold must be between 0 and 1")
    if args.transition_min_gap < 0:
        raise ValueError("--transition-min-gap must be non-negative")
    if args.max_transition_candidates < 0:
        raise ValueError("--max-transition-candidates must be non-negative")
    if args.event_merge_window < 0:
        raise ValueError("--event-merge-window must be non-negative")
    if args.min_primary_edge_mean < 0:
        raise ValueError("--min-primary-edge-mean must be non-negative")
    if not 0 <= args.min_rich_tile_ratio <= 1:
        raise ValueError("--min-rich-tile-ratio must be between 0 and 1")
    if args.duplicate_hamming_threshold < 0:
        raise ValueError("--duplicate-hamming-threshold must be non-negative")
    if args.contact_sheet_interval <= 0:
        raise ValueError("--contact-sheet-interval must be greater than zero")
    if args.contact_sheet_max_thumbnails <= 0:
        raise ValueError("--contact-sheet-max-thumbnails must be greater than zero")
    if args.contact_sheet_columns <= 0 or args.contact_sheet_rows <= 0:
        raise ValueError("--contact-sheet-columns and --contact-sheet-rows must be greater than zero")
    if args.contact_sheet_thumb_width <= 0:
        raise ValueError("--contact-sheet-thumb-width must be greater than zero")


def prepare_output_dir(output_dir: Path, *, overwrite: bool) -> None:
    if output_dir.exists() and any(output_dir.iterdir()) and not overwrite:
        raise ValueError(f"output directory already contains files; pass --overwrite: {output_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)
    if overwrite:
        cleanup_generated_outputs(output_dir)


def cleanup_generated_outputs(output_dir: Path) -> None:
    for dirname in ("frames", "contact-sheets"):
        delete_directory_inside_output(output_dir, output_dir / dirname)
    for filename in (
        "manifest.json",
        "context.md",
        "self-improvement.md",
        "contact-sheet-manifest.json",
        "contact-sheet-review.md",
        "agent-visual-analysis.json",
    ):
        delete_relative_file(output_dir, filename)


def validate_output_paths(output_dir: Path, paths: list[Path]) -> None:
    for path in paths:
        try:
            path.resolve().relative_to(output_dir.resolve())
        except ValueError as exc:
            raise ValueError(f"generated path is outside output directory: {path}") from exc


def seconds_to_timestamp(seconds: float) -> str:
    bounded = max(0.0, seconds)
    hours = int(bounded // 3600)
    minutes = int((bounded % 3600) // 60)
    secs = int(bounded % 60)
    millis = int(round((bounded - int(bounded)) * 1000))
    if millis == 1000:
        secs += 1
        millis = 0
    return f"{hours:02d}:{minutes:02d}:{secs:02d}.{millis:03d}"


def table_text(value: str, limit: int) -> str:
    text = " ".join(str(value).split())
    if len(text) > limit:
        text = text[: limit - 3].rstrip() + "..."
    return text.replace("|", "\\|")


if __name__ == "__main__":
    raise SystemExit(main())
