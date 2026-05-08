# Character Spec Schema

This skill expects a JSON file. The schema is intentionally simple so it can be hand-written.

## Minimal shape

```json
{
  "character": {
    "id": "protagonist",
    "display_name": "Unnamed Swordsman",
    "role": "protagonist",
    "description": "A young wandering swordsman with a short blade and worn cloak.",
    "style_notes": "Dark fantasy side-scrolling pixel art, readable silhouette, limited palette."
  },
  "canvas": {
    "cell_width": 96,
    "cell_height": 96,
    "columns": "auto",
    "background": "transparent",
    "chroma_key": "#FF00FF"
  },
  "animations": [
    {"id": "idle", "frames": 4, "fps": 6, "prompt": "calm breathing stance"},
    {"id": "walk-right", "frames": 6, "fps": 10, "prompt": "side-view walking right"},
    {"id": "attack-light", "frames": 6, "fps": 12, "prompt": "quick katana slash"}
  ]
}
```

## Top-level fields

### `character`

Required.

- `id`: stable kebab-case id used for folders and metadata.
- `display_name`: readable label.
- `role`: `protagonist`, `enemy`, `boss`, `npc`, `prop-character`, or custom.
- `description`: identity and design description.
- `style_notes`: visual style constraints.
- `palette`: optional list of important color words or hex colors.
- `must_keep`: optional list of identity features that must never change.
- `must_avoid`: optional list of forbidden features.
- `references`: optional list of image paths.

### `canvas`

Required.

- `cell_width`: frame width in pixels.
- `cell_height`: frame height in pixels.
- `columns`: integer or `"auto"`.
- `background`: normally `"transparent"`.
- `chroma_key`: default `"#FF00FF"`; used during generation cleanup.
- `padding`: optional safe padding inside each frame.

### `animations`

Required list.

Each animation:

- `id`: stable action id.
- `frames`: number of frames in the row.
- `fps`: playback speed metadata.
- `prompt`: action-specific prompt.
- `row`: optional explicit row index.
- `mirror_from`: optional source action id.
- `allow_mirror`: optional boolean. Mirroring still requires visual approval.
- `loop`: optional boolean.
- `combat_tags`: optional list such as `parry`, `guard`, `posture`, `telegraph`, `attack`.

## Output dimensions

The atlas dimensions are:

```text
width  = columns * cell_width
height = row_count * cell_height
```

If `columns` is `"auto"`, it becomes the maximum `frames` value among animations.
