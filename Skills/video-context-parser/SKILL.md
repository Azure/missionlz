---
name: video-context-parser
description: Use when an AI coding agent needs to extract project-context-ready visual evidence from video recordings, screen-share captures, or meeting recordings with paired VTT transcripts; create keyframes, inspect what was visible on screen with agent or multimodal vision, merge agent-vision findings, and produce validated context packages under .project-context/generated/video-context for AIS clarify, design, or recommendation workflows.
compatibility: Requires Python 3.11+, FFmpeg on PATH or --ffmpeg-path, and Pillow for contact-sheet generation.
---

# Video Context Parser

Extract screen-share context from video recordings with paired transcripts, including meeting recordings, and turn it into source-backed generated context that AIS workflows can read. The default output is `.project-context/generated/video-context/<run-id>/`. The preferred discovery loop is contact-sheet-first: sample many labeled thumbnails, inspect the tile sheets with the coding agent or an approved multimodal model, select visually rich frames, then extract and analyze only those retained keyframes.

This is a portable Agent Skill. `SKILL.md`, `scripts/`, and `references/` are the source of truth for compatible coding agents. Files under `agents/`, such as `agents/openai.yaml`, are optional interface metadata and are not required to run the workflow.

## Dependencies

- Python 3.11+ to run the bundled scripts.
- FFmpeg for scene detection, thumbnail sampling, and frame extraction. The parser checks an explicit `--ffmpeg-path`, then PATH, then common Windows Scoop locations, and exits with a clear error if FFmpeg is unavailable.
- Pillow for the preferred contact-sheet discovery workflow. Install it in the active Python environment with `python -m pip install Pillow`; without Pillow, contact-sheet generation cannot run. Frame quality scoring falls back to `unknown` if Pillow is missing after contact sheets are disabled.

The bundled scripts do not upload media or call hosted vision services. Hosted model analysis is an optional agent workflow step and requires explicit approval for the recording.

## Workflow

1. Confirm inputs:
   - Video recording path, usually MP4.
   - Transcript path, usually WebVTT.
   - Run ID for the project-context output folder.
   - Local FFmpeg path when it is not on PATH.
   - Pillow is installed in the Python environment when using the default contact-sheet workflow.
2. Run discovery extraction. Omit `--output` unless the user explicitly asks for a non-project-context location. By default the parser samples contact-sheet thumbnails and also supports transcript/scene fallback selection:
   ```powershell
   python Skills/video-context-parser/scripts/run_parser.py `
     --video "<recording.mp4>" `
     --transcript "<transcript.vtt>" `
     --ffmpeg-path "<ffmpeg.exe>" `
     --run-id "<stable-run-id>" `
     --contact-sheet-interval 15 `
     --contact-sheet-max-thumbnails 280 `
     --self-improve `
     --overwrite
   ```
   The wrapper writes contact sheets and preliminary context to `.project-context/generated/video-context/<stable-run-id>/`.
3. Inspect `contact-sheet-review.md` and each `contact-sheets/sheet-*.jpg` with the coding agent's image perception.
   - Select only useful project-context frames by thumbnail id, then write `.project-context/generated/video-context/<stable-run-id>/contact-sheet-selection.json`.
   - Check that important screen-share transitions are covered, especially platform screens, architecture diagrams, Azure AI Foundry models, Azure AI Foundry agents, repository/IaC screens, and data/source configuration screens.
   - Skip meeting gallery, webcam-only, blank, loading, repeated, and purely transitional frames at this thumbnail stage.
   - Do not rely on transcript text alone for visible screen content.
4. Rerun with the selection file so retained keyframes come from the contact-sheet pass:
   ```powershell
   python Skills/video-context-parser/scripts/run_parser.py `
     --video "<recording.mp4>" `
     --transcript "<transcript.vtt>" `
     --ffmpeg-path "<ffmpeg.exe>" `
     --run-id "<stable-run-id>" `
     --contact-sheet-selection ".project-context\generated\video-context\<stable-run-id>\contact-sheet-selection.json" `
     --contact-sheet-interval 15 `
     --contact-sheet-max-thumbnails 280 `
     --self-improve `
     --overwrite
   ```
5. Inspect the retained full-size frames and write visual findings as JSON using `references/visual-analysis-schema.md`.
6. Merge findings into the context package:
   ```powershell
   python Skills/video-context-parser/scripts/apply_agent_visual_analysis.py `
     --manifest ".project-context\generated\video-context\<stable-run-id>\manifest.json" `
     --analysis ".project-context\generated\video-context\<stable-run-id>\agent-visual-analysis.json"
   ```
7. Validate the package:
   ```powershell
   python Skills/video-context-parser/scripts/validate_context_package.py `
     --manifest ".project-context\generated\video-context\<stable-run-id>\manifest.json"
   ```
8. Feed the generated project-context package into downstream AIS spec, clarify, design, or recommendation work.

Do not use `artifacts/video-context/` as the default output. Use an explicit `--output` only for scratch experiments or when the user asks for a different location.

## Analyzer Choice

- **agent-vision**: Required default. The active coding agent inspects frames and records visible UI, diagrams, text, relationships, tables, and uncertainty.
- **openai-vision / azure-openai-vision**: Optional automation path when credentials and policy allow uploading frames. Use only after confirming the recording may be sent to the selected provider.
- **frame-only**: Incomplete fallback. Accept only for extraction smoke tests; do not treat it as satisfying visual information extraction.
- **contact-sheet-selection**: Preferred selection source. The coding agent or approved multimodal model inspects large thumbnail galleries and chooses only visually interesting frames before full extraction.
- **quality-gate / rejected**: Backup non-evidence outcome for blank, loading, gallery-only, or duplicate frames that slip past selection. Rejected frame files and event details are pruned from the package; only aggregate removal counts remain in the self-improvement evidence.

## Agent Visual Analysis Requirements

For each extracted frame, capture:

- application or screen type
- visible text, labels, headings, tabs, table/list values, and configuration values
- information hierarchy in top-to-bottom or semantic order
- screen summary in 1-3 sentences
- why the frame matters for the project context
- uncertainty, unreadable regions, and source gaps
- sensitive-screen warnings without overexposing secrets, keys, or personal emails

Never claim a frame contains text or configuration that is not visible. If the image is too blurry or cropped, record the limitation.

Avoid selecting a frame when the thumbnail is only a meeting gallery, webcam tile, loading screen, blank screen, or duplicate of an already accepted frame. If a non-evidence frame slips into the retained set, use `status: "rejected"` and provide `rejection_reason` in the merge input; the merge step deletes the frame, removes the event from `manifest.json` and `context.md`, and removes the rejected entry from `agent-visual-analysis.json`.

## Output Authority

Treat `context.md` and `manifest.json` as generated, source-backed project context. They may support recommendations, but they do not override SOW-confirmed scope or raw client-provided source files. Source media stays in its original location; the skill stores frame extracts and generated analysis only.

## Resources

- `scripts/run_parser.py`: run transcript-guided and scene-transition keyframe extraction with quality and duplicate rejection.
- `contact-sheet-review.md`: generated review guide linking the sampled thumbnail sheets.
- `contact-sheet-manifest.json`: generated thumbnail id to timestamp map used by contact-sheet selection.
- `scripts/apply_agent_visual_analysis.py`: merge agent-written visual analysis into `manifest.json`, prune rejected events and frame files, and regenerate `context.md`.
- `scripts/validate_context_package.py`: fail when extracted events still have incomplete or frame-only analysis, when rejected events remain in the manifest, when `agent-visual-analysis.json` still holds rejected entries, or when `frames/` contains orphaned files not referenced by a retained event.
- `references/visual-analysis-schema.md`: JSON shape and inspection prompt for agent-vision findings.
