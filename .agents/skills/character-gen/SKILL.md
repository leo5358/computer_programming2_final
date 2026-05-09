---
name: character-gen
description: Use when creating, repairing, validating, or packaging Godot-ready 2D pixel-art combat spritesheets for characters, bosses, and enemies. Input is a JSON spec controlling cell size, animation names, frame counts, FPS, and style. Use when the user wants hero, enemy, or boss sprite assets for a 2D side-scrolling action game.
---

# Character Gen

## Overview

Generate Godot-ready 2D combat spritesheets from a JSON spec. The spec is the source of truth for cell size, animation names, frame counts, FPS, loop flags, chroma key, style, and Godot metadata. All visual generation delegates to `$imagegen`.

Adapted from the hatch-pet workflow: canonical base reference, one row-strip prompt per animation, deterministic slot-based frame extraction, atlas composition, QA contact sheet, GIF previews, and Godot `animations.json` metadata.

## Core Rules

- One cell size per asset. A 96×96 hero and a 128×128 boss must be separate specs and separate atlases. Never mix cell sizes in one atlas.
- Read all animations from `asset_spec.json`. Never hardcode animation names.
- Use `$imagegen` for every visual generation job — base art and every animation row strip.
- Record every selected visual output with `record_character_result.py`. Never manually edit `imagegen-jobs.json` to mark jobs complete.
- Extract frames using fixed slot boundaries. Never rescale or recenter individual frames after extraction — this is the primary cause of 跑版 (position drift).
- Preserve canonical base identity across all rows. Treat identity drift as a blocker even when validation passes.
- Run `record_character_result.py`, repair queuing, and finalization in the parent only. Never run these in parallel.

## Anti-跑版 Alignment Protocol

跑版 (frame misalignment) is when the character's position, size, or anchor drifts across frames, causing the sprite to visually jump or float when played back. Prevent it at every stage.

### During prompt generation

Every row prompt must include these explicit constraints:

- **Anchor rule**: "The character's feet must land at the same Y position in every frame. Do not let the character float upward or drift lower between frames."
- **Scale rule**: "The character must be the same apparent height in every frame. Do not grow or shrink the character between frames."
- **Canvas rule**: "The output must be exactly `{frames} × {cell_width}` pixels wide by `{cell_height}` pixels tall. Fill the entire canvas."
- **Slot rule**: "Treat the canvas as {frames} equal-width invisible slots of {cell_width}×{cell_height} each. Place one complete pose in the center of each slot."

### During frame extraction

- Use fixed slot-based extraction (equal-width crops). Do not use connected-component detection.
- Do NOT rescale frames. Do NOT bbox-crop and recenter. Each slot is taken at face value.
- Only remove the chroma key; preserve every pixel exactly as generated.
- If a row has bad alignment after extraction, queue a repair — never fix it with local transforms.

## Asset Spec

Use `references/godot-sprite-spec.md` for the full field reference. Minimal required spec:

```json
{
  "schema_version": 1,
  "engine": "godot",
  "asset_type": "character",
  "name": "hero",
  "cell": { "width": 96, "height": 96 },
  "chroma_key": "#FF00FF",
  "style_notes": "Side-view 2D pixel art combat sprite, readable silhouette, limited palette.",
  "animations": [
    { "name": "idle",     "frames": 6, "fps": 8,  "loop": true,  "action": "calm battle-ready idle stance" },
    { "name": "run",      "frames": 8, "fps": 12, "loop": true,  "action": "right-facing run loop" },
    { "name": "attack_1", "frames": 6, "fps": 14, "loop": false, "action": "horizontal sword slash" }
  ]
}
```

See `example/hero_96x96_spec.json` and `example/boss_128x128_spec.json` for full templates.

## Workflow

### Step 1 — Write or confirm `asset_spec.json`

Write `asset_spec.json` based on the user's character description and target animations. Use `references/animation-presets.md` for recommended animation names, frame counts, and FPS for combat characters.

### Step 2 — Prepare the run

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/character-gen"
python "$SKILL_DIR/scripts/prepare_character_run.py" \
  --spec /absolute/path/to/asset_spec.json \
  --reference /absolute/path/to/reference.png \
  --output-dir /absolute/path/to/run \
  --force
```

`--reference` and `--output-dir` are optional. Without `--reference`, the base job is prompt-only. Without `--output-dir`, a timestamped folder is created under `~/output/character-gen/<name>/`.

### Step 3 — Check job status

```bash
python "$SKILL_DIR/scripts/character_job_status.py" --run-dir /absolute/path/to/run
```

### Step 4 — Generate and record the base job

Use `$imagegen` with the base prompt (`prompts/base-character.md`) and any listed reference images. After selecting the output:

```bash
python "$SKILL_DIR/scripts/record_character_result.py" \
  --run-dir /absolute/path/to/run \
  --job-id base \
  --source /absolute/path/to/generated/ig_*.png
```

This writes `decoded/base.png` and `references/canonical-base.png`. All row jobs use the canonical base as their identity reference.

### Step 5 — Generate and record each animation row

For each row job listed in `imagegen-jobs.json`:

1. Use `$imagegen` with the row prompt, canonical base, layout guide, and any user references listed in the job's `input_images`.
2. Record the selected output:

```bash
python "$SKILL_DIR/scripts/record_character_result.py" \
  --run-dir /absolute/path/to/run \
  --job-id <animation-name> \
  --source /absolute/path/to/generated/ig_*.png
```

### Step 6 — Finalize

```bash
python "$SKILL_DIR/scripts/finalize_character_run.py" --run-dir /absolute/path/to/run
```

Expected output structure:

```text
run/
  asset_spec.json
  character_request.json
  imagegen-jobs.json
  prompts/
    base-character.md
    rows/<animation>.md
  references/
    canonical-base.png
    layout-guides/<animation>.png
  decoded/
    base.png
    <animation>.png
  frames/
    <animation>/00.png ... N.png
    frames-manifest.json
  final/
    <name>_spritesheet.png
    <name>_animations.json
    validation.json
  qa/
    contact-sheet.png
    review.json
    previews/<animation>.gif
    run-summary.json
```

## Row Generation With Subagents

After `base` is recorded and `references/canonical-base.png` exists, row-strip visual generation **must** use subagents. Before spawning any row subagent, state which rows are being delegated. If subagents cannot be spawned because the environment or tool policy blocks them, stop before row-strip generation, explain the blocker, and ask for explicit user direction. Do not silently fall back to sequential row generation.

**Delegation order — mandatory:**

1. Parent generates and records `base`.
2. Parent spawns a subagent for `idle` first. Record the result and visually confirm the character identity matches the canonical base before proceeding.
3. Only after `idle` passes identity review, spawn subagents for all remaining animation rows in parallel.
4. Parent records every returned result with `record_character_result.py`. Do not let subagents record results themselves.

**Parent responsibilities**: own `asset_spec.json`, `imagegen-jobs.json`, `record_character_result.py`, finalization, repair queuing, and all QA output.

**Subagent responsibilities**: handle one animation row. Use `$imagegen` only. Do not edit manifests, decoded files, frames, or final outputs. Return the selected source path and a one-sentence QA note.

Subagent prompt template:

```text
Generate the `<animation>` row strip for this character-gen run.

Run dir: <absolute run dir>
Prompt file: <absolute prompt file>
Input images:
- <absolute path> — <role>

Read and follow the row prompt exactly. Use `$imagegen` only.

Before returning, verify all of these:
- Exactly <frames> complete poses arranged left-to-right
- Same character identity as the canonical base (same body, head, palette, proportions)
- Flat chroma-key background — no scenery, no UI, no guide lines
- No clipping, no empty slots, no slot-crossing
- Consistent character scale across all frames
- Character foot position at the same Y level in every frame (anti-跑版)

Do not edit manifests, copy files into decoded/, or run any scripts.

Return only:
selected_source=/absolute/path/to/$CODEX_HOME/generated_images/.../ig_*.png
qa_note=<one sentence>
```

No silent sequential fallback: only an explicit user instruction such as "do not use subagents" authorizes sequential row generation. The final answer must report which rows were delegated to subagents.

## Repair Workflow

When finalization fails due to QA errors, queue repairs:

```bash
python "$SKILL_DIR/scripts/queue_character_repairs.py" --run-dir /absolute/path/to/run
```

This reopens failed animation jobs and appends failure notes to their prompts. Regenerate each reopened job with `$imagegen`, record with `record_character_result.py --force`, and finalize again.

For alignment repairs: include the specific frame number and drift description in the repair note. Require the model to fix the anchor position explicitly.

For identity drift repairs: include the canonical base, the contact sheet, and the failure note as grounding context.

## Godot Import

The exported `<name>_animations.json` contains per-animation row index, frame count, FPS, loop flag, cell size, and frame rectangles. Use this to build a `SpriteFrames` resource for `AnimatedSprite2D`.

Hitboxes, hurtboxes, collision shapes, and pivot conventions belong in the Godot project. This skill exports visual frames and metadata only.

## Common Failures

- **跑版 (position drift)**: regenerate the row with explicit anchor and scale constraints in the prompt.
- **Character scale changes within a row**: regenerate using the canonical base as a scale reference with same-height requirement.
- **Wrong frame count**: regenerate with explicit canvas size requirement (`frames × cell_width` wide by `cell_height` tall).
- **Character clipped at slot edge**: regenerate with layout guide attached and safe-margin wording.
- **Identity drift across rows**: use the canonical base and contact sheet as grounding; regenerate the drifted row only.
- **Chroma key appears in palette**: choose a different `chroma_key` in `asset_spec.json` before any generation.
- **Unused cells not transparent**: check chroma key threshold; adjust `--key-threshold` in finalize if needed.
