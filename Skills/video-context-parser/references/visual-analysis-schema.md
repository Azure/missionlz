# Visual Analysis Schema

Use this JSON shape after inspecting extracted frames with compatible agent image perception or an approved multimodal model. Store the file as `agent-visual-analysis.json` beside the package manifest under `.project-context/generated/video-context/<run-id>/`.

Before full-frame analysis, inspect the generated contact sheets and store selected thumbnail ids as `contact-sheet-selection.json`:

```json
{
  "selected_frames": [
    {
      "id": "thumb-0127",
      "reason": "Azure AI Foundry Models page showing deployed model names and configuration columns."
    },
    {
      "id": "thumb-0134",
      "reason": "Azure AI Foundry Agents screen showing agent list and orchestration context."
    }
  ]
}
```

Select from the contact sheets first so gallery, blank, loading, and duplicate frames are skipped before full keyframe extraction.

```json
{
  "events": [
    {
      "id": "event-001",
      "status": "complete",
      "method": "agent-vision",
      "application_hint": "Azure portal or architecture diagram",
      "screen_summary": "The frame shows ...",
      "visible_text": "Exact readable text, line separated when possible.",
      "information_hierarchy": [
        {
          "level": "screen",
          "order": 1,
          "text": "Top-level screen title or main visual subject",
          "confidence": 0.9
        },
        {
          "level": "section",
          "order": 2,
          "text": "Visible subsection, tree node, table row, or configuration value",
          "confidence": 0.8
        }
      ],
      "key_observations": [
        "Important visible fact tied to the project context."
      ],
      "warnings": [
        "Small text is unreadable in the lower-right panel.",
        "Screen includes a visible secret or personal identifier; value intentionally not transcribed."
      ],
      "confidence": 0.82
    }
  ]
}
```

For a non-evidence frame, use a rejected event in the merge input instead of forcing a weak analysis. The merge script treats `status: "rejected"` as a prune instruction: it deletes the frame file, removes the event from `manifest.json` and `context.md`, and removes the rejected item from `agent-visual-analysis.json`.

```json
{
  "events": [
    {
      "id": "event-002",
      "status": "rejected",
      "method": "agent-vision",
      "rejection_reason": "Meeting gallery only; no shared technical screen is visible.",
      "screen_summary": "The frame shows participant video tiles, not project evidence.",
      "visible_text": "",
      "information_hierarchy": [
        {
          "level": "source-gap",
          "order": 1,
          "text": "No readable project screen, diagram, portal, document, or code is visible.",
          "confidence": 0.95
        }
      ],
      "warnings": [
        "Rejected as non-evidence; do not use for project recommendations."
      ],
      "confidence": 0.95
    }
  ]
}
```

## Inspection Prompt

For each frame, inspect only what is visible. Return concise, source-backed JSON:

- Identify the application or artifact type.
- Extract all readable screen text, including headings, navigation labels, node names, tabs, table labels, and configuration values.
- Build an information hierarchy that reflects the visible layout or semantic structure.
- Summarize what the screen shows and why it matters.
- Record unreadable/cropped/blurry regions as warnings.
- Record sensitive values as warnings without copying secrets, full API keys, or personal email addresses unless the user explicitly asks and policy allows it.
- Do not infer values that are not visible.
- Reject meeting-gallery, webcam-only, blank, loading, or duplicate frames instead of stretching them into evidence.

## Method Guidance

- Use `method: "agent-vision"` for normal agent frame inspection.
- Use a hosted model method only when provider use is approved for the recording.
- Do not mark an event `complete` if it only has transcript context and no visual inspection.
- Use `status: "rejected"` when visual inspection confirms the frame is not useful project evidence; after merge, rejected details must not remain in generated project context.

## Confidence Guidance

- `0.9-1.0`: Clearly readable and visually unambiguous.
- `0.7-0.89`: Mostly clear, minor unreadable text or uncertain labels.
- `0.4-0.69`: Useful but incomplete due to blur, crop, or dense small text.
- Below `0.4`: Preserve as warning/source gap rather than firm evidence.
