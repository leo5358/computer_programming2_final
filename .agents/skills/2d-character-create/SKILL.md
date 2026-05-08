---
name: 2d-character-create
description: Create, repair, validate, preview, and package reusable 2D pixel-art game character spritesheets from a JSON character spec, reference images, or both. Use when a user wants protagonist, enemy, NPC, monster, or boss game sprites with configurable cell sizes such as 32x32, 64x64, 96x96, or larger; configurable animation rows and frame counts; transparent backgrounds; grounded row-by-row image generation; consistency QA contact sheets; Godot-friendly atlas metadata; and packaged output assets.
---

# 2D Character Create

## Overview

Create reusable 2D pixel-art game character assets from a JSON spec. This skill is adapted from the `hatch-pet` workflow style, but the output target is game production sprites, not Codex desktop pets.

The normal run creates:

- a canonical base character reference;
- one generated row strip per configured animation action;
- extracted frame PNGs;
- a transparent spritesheet atlas;
- QA contact sheets and validation reports;
- Godot-friendly metadata and packaged assets.

The user-facing input should be a JSON file whenever possible. The JSON controls character identity, role, cell size, animation actions, frame counts, FPS, output names, and optional reference images.

## Generation Delegation

Use `$imagegen` for all normal visual generation.

Before generating base art, animation row strips, or repair rows, load and follow the installed image generation skill:

```text
${CODEX_HOME:-$HOME/.codex}/skills/.system/imagegen/SKILL.md
```

Do not call the Image API directly for the normal path. Let `$imagegen` choose its built-in-first path and fallback rules. If `$imagegen` says a fallback requires confirmation, ask before continuing.

When invoking `$imagegen`, pass the generated character prompt as the authoritative visual spec. Do not wrap it in a generic illustration prompt. Do not add cinematic polish, splash-art language, anime-key-art treatment, 3D render language, or marketing-card composition unless the JSON explicitly asks for that and it still fits pixel-game sprite output.

Use this skill's scripts only for deterministic work: preparing prompts and manifests, copying selected `$imagegen` outputs, extracting frames, validating rows, composing the atlas, creating QA media, and packaging game assets.

Hard boundary: do not create, draw, tile, warp, mirror, or synthesize character visuals with local Python/Pillow/SVG/canvas/HTML/CSS as a substitute for `$imagegen`. Local scripts may create layout guides, contact sheets, masks, metadata, and previews from already-generated visuals.

## Input Contract

Prefer a JSON spec file:

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/2D-character-create"
python "$SKILL_DIR/scripts/prepare_character_run.py" \
  --spec /absolute/path/to/character.json \
  --output-dir /absolute/path/to/run
```

See `references/character-spec-schema.md` and the files under `examples/`.

If the user gives a concept instead of JSON, create a temporary JSON spec first, then run the same workflow. Do not hide the inferred values; save them into `character_request.json`.

## Pixel Character Style

Default style is readable 2D game pixel art:

- clear silhouette;
- consistent proportions across every frame;
- limited palette;
- hard-edged forms;
- no painterly gradients;
- no photographic texture;
- no UI labels or frame numbers inside the generated strips;
- transparent final output.

For the user's current project, bias toward side-scrolling action-game sprites: readable weapon arcs through pose, not through soft motion blur; grounded attack anticipation; clear guard/parry stance; and a body language suitable for posture/軀幹條 combat.

## Configurable Atlas

Unlike `hatch-pet`, this skill must not hardcode an 8x9, 192x208 pet atlas. The JSON may define:

```json
"canvas": {
  "cell_width": 96,
  "cell_height": 96,
  "columns": "auto",
  "background": "transparent",
  "chroma_key": "#FF00FF"
}
```

Rules:

- `cell_width` and `cell_height` are authoritative.
- `columns: "auto"` means the maximum frame count among actions.
- Rows are assigned from the animation list order unless an action sets an explicit `row`.
- Unused cells must be fully transparent.
- For bosses or large enemies, use larger cells such as `128x128`, `160x160`, or `192x192` rather than scaling small sprites upward.

## Animation Rows

Each configured animation action becomes one row-strip job. Common action ids:

- `idle`
- `walk-right`
- `walk-left`
- `run-right`
- `run-left`
- `attack-light`
- `attack-heavy`
- `guard`
- `parry`
- `hurt`
- `posture-break`
- `death`
- `special`

Use `references/animation-actions.md` for default guidance, but obey the JSON first.

Every row-strip job must use grounding images:

1. the canonical base reference created or selected during the base step;
2. any user reference images copied into the run folder;
3. the layout guide for that row.

Only the base job may be prompt-only. Treat any generated animation row without the canonical base image as invalid.

## Mirroring Policy

Mirroring is allowed only when the JSON permits it and visual inspection says it is safe.

Examples where mirroring is usually safe:

- simple walking left/right with symmetrical clothing;
- small enemies without asymmetrical weapons.

Examples where mirroring is usually unsafe:

- one-handed weapon on a specific side;
- character has a scar, emblem, prosthetic, shield, sheath, or asymmetric armor;
- attack timing depends on blade hand or readable combat telegraph.

If unsure, generate the opposite direction as a normal grounded `$imagegen` row.

## Visible Progress Plan

For a normal run, keep a visible checklist:

1. Reading the character spec.
2. Creating the base character reference.
3. Creating animation rows.
4. Extracting frames and composing the spritesheet.
5. Running QA and packaging Godot-ready assets.

Only mark a step complete when the corresponding file, image, or decision exists.

## Default Workflow

### 1. Prepare the run

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/2D-character-create"
python "$SKILL_DIR/scripts/prepare_character_run.py" \
  --spec /absolute/path/to/character.json \
  --output-dir /absolute/path/to/run
```

This creates:

```text
character_request.json
imagegen-jobs.json
prompts/base-character.md
prompts/rows/<action>.md
references/layout-guides/<action>.png
decoded/
frames/
qa/
package/
```

### 2. Generate the base character

Open `imagegen-jobs.json`, find the `base` job, and call `$imagegen` using `prompts/base-character.md` and the listed input images.

After the user or operator selects the generated base image:

```bash
python "$SKILL_DIR/scripts/record_imagegen_result.py" \
  --run-dir /absolute/path/to/run \
  --job-id base \
  --image /absolute/path/to/selected-base.png
```

This records `decoded/base.png` and `references/canonical-base.png`.

### 3. Generate animation row strips

For each pending row job, call `$imagegen` with that job's prompt and input images. The base/canonical reference must be attached.

Record each selected row output:

```bash
python "$SKILL_DIR/scripts/record_imagegen_result.py" \
  --run-dir /absolute/path/to/run \
  --job-id attack-light \
  --image /absolute/path/to/selected-attack-light.png
```

### 4. Extract frames

```bash
python "$SKILL_DIR/scripts/extract_strip_frames.py" \
  --run-dir /absolute/path/to/run \
  --all
```

### 5. Compose atlas

```bash
python "$SKILL_DIR/scripts/compose_spritesheet.py" \
  --run-dir /absolute/path/to/run
```

### 6. QA

```bash
python "$SKILL_DIR/scripts/make_contact_sheet.py" \
  --run-dir /absolute/path/to/run

python "$SKILL_DIR/scripts/validate_spritesheet.py" \
  --run-dir /absolute/path/to/run
```

Inspect `qa/contact-sheet.png` and `qa/review.json`. Repair the smallest failing scope first: one frame, then one row, then base regeneration only when the identity is broken.

### 7. Package for Godot

```bash
python "$SKILL_DIR/scripts/package_godot_assets.py" \
  --run-dir /absolute/path/to/run
```

The package folder contains `spritesheet.png`, `spritesheet.webp` when supported, `atlas.json`, `frames/`, `animations.json`, and `character.json`.

## QA Standard

Do not accept an asset until these pass:

- exact atlas dimensions match `columns * cell_width` by `rows * cell_height`;
- unused cells are transparent;
- every configured frame exists;
- no generated row contains visible grid lines, labels, checkerboard transparency, or background scenery;
- the same character identity is preserved across all rows;
- weapons, armor, horns, tails, scars, masks, and palettes do not mutate across frames;
- attack/guard/parry poses are readable at the configured cell size;
- no row is just geometric transforms of the same still image;
- contact sheet shows complete poses, not cropped fragments.

## Output Naming

Use stable game-facing names:

```text
<character_id>/
  character.json
  atlas.json
  animations.json
  spritesheet.png
  spritesheet.webp
  frames/
    idle/idle_000.png
    idle/idle_001.png
    attack-light/attack-light_000.png
```

For Godot, prefer lowercase kebab-case action ids. Avoid spaces and punctuation.

## Notes for This User's Project

The intended use case includes a 2D side-scrolling Sekiro-like final project with protagonist, small enemies, and one boss. It should support posture/軀幹條, heartbeat pressure, guard/parry states, and readable difficulty telegraphs. Therefore, the default example specs include protagonist, enemy, and boss variants with guard/parry/posture-break actions.
