# Godot Sprite Spec

The `asset_spec.json` file is the source of truth for all character generation. Scripts read this file directly — do not pass cell size, animation count, or animation names as separate arguments.

## Required Fields

```json
{
  "schema_version": 1,
  "engine": "godot",
  "asset_type": "character",
  "name": "hero",
  "cell": { "width": 96, "height": 96 },
  "chroma_key": "#FF00FF",
  "animations": [
    { "name": "idle", "frames": 6, "fps": 8, "loop": true, "action": "calm battle-ready idle" }
  ]
}
```

- `schema_version`: always `1`.
- `engine`: must be `"godot"`.
- `asset_type`: `"character"`, `"enemy"`, `"boss"`, or `"npc"`. Affects atlas naming only.
- `name`: lowercase identifier. Used as the base name for output files (`hero_spritesheet.png`, `hero_animations.json`).
- `cell.width` / `cell.height`: frame size in pixels. Keep one size per atlas. Typical values: 96×96 for characters and enemies, 128×128 or 160×160 for bosses.
- `chroma_key`: flat background color for generated strips. Avoid colors present in your character's palette. Defaults to `#FF00FF` (magenta).
- `animations`: ordered list. Row order in the atlas matches this list unless `row` is overridden.

## Animation Fields

Each animation object:

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Godot animation name. Used as the job ID and output filename. |
| `frames` | Yes | Number of frames in this animation. |
| `fps` | Yes | Playback speed in Godot. |
| `loop` | Yes | Whether the animation loops. |
| `action` | Yes | One-sentence description of the movement for the image-gen prompt. |
| `row` | No | Fixed row index in the atlas. Omit to use list order. |
| `prompt_notes` | No | Extra constraints appended to the row-strip prompt. |

## Optional Spec Fields

| Field | Description |
|---|---|
| `description` | One-sentence stable character identity description. Used in prompts. |
| `columns` | Atlas columns. Defaults to the maximum frame count across all animations. |
| `style_notes` | Art direction notes injected into every prompt. |
| `direction` | Default facing direction. Use `"right"` (standard for side-view games). |

## Atlas Layout

- Atlas width: `columns × cell.width`
- Atlas height: `animation_count × cell.height`
- Each animation occupies exactly one row.
- Frames go left to right within each row.
- Unused cells at the end of a row are fully transparent.
- Each slot is exactly `cell.width × cell.height` pixels.

## Output Files

After finalization:

- `final/<name>_spritesheet.png`: lossless RGBA atlas.
- `final/<name>_animations.json`: Godot metadata.

The `animations.json` schema:

```json
{
  "image": "<name>_spritesheet.png",
  "cell_width": 96,
  "cell_height": 96,
  "columns": 8,
  "rows": 4,
  "animations": {
    "idle": {
      "row": 0,
      "frames": 6,
      "fps": 8,
      "loop": true,
      "rects": [
        { "x": 0, "y": 0, "w": 96, "h": 96 },
        ...
      ]
    }
  }
}
```

## Recommended Cell Sizes

| Asset type | Recommended cell |
|---|---|
| Hero / protagonist | 96×96 |
| Standard enemy | 96×96 or 64×64 |
| Mini-boss | 128×128 |
| Full boss | 128×128 or 160×160 |
| VFX / effects | Separate spec, size as needed |

Keep one cell size per atlas. If a boss has a large body and small attack effects, they get separate specs.
