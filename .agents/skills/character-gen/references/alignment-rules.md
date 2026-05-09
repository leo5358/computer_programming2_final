# Alignment Rules — Preventing 跑版 (Frame Drift)

跑版 is the most common and frustrating spritesheet failure: the character's position, size, or anchor shifts between frames, causing visible jumping or floating during playback.

## Why It Happens

跑版 has two root causes:

1. **Generation drift**: the AI model places the character at different heights or scales across frames in the same strip.
2. **Extraction drift**: post-processing (per-frame bbox crop + recenter) moves the character to a different position in each frame cell.

Character-gen prevents both.

## Generation-Side Rules

Every row-strip prompt enforces these constraints explicitly:

### Anchor Rule
> "The character's feet must land at the same Y position in every frame. The character may not float upward or sink lower between frames."

This pins the vertical anchor. Without this, the model tends to center the character body, which shifts when limbs extend (e.g., a jumping pose is higher than an idle pose if centering by bounding box).

### Scale Rule
> "The character must appear the same height in every frame. Do not grow or shrink the character between frames."

Without this, dynamic poses (sword swings, jumping) may appear larger because the bounding box expands.

### Canvas Rule
> "The output strip must be exactly `{frames × cell_width}` pixels wide and `{cell_height}` pixels tall. Fill the entire canvas with the chroma-key background."

This ensures the model doesn't generate a strip that is slightly narrower or taller than expected, which would cause misaligned slot extraction.

### Slot Rule
> "Treat the canvas as {frames} equal-width invisible slots of {cell_width}×{cell_height} each. Place exactly one complete full-body pose in the center of each slot."

This prevents poses from overlapping slot boundaries.

### Layout Guide
Every row job attaches a layout guide image. The guide shows the exact frame slot grid at the correct cell size. The model must follow slot count, spacing, and centering from the guide. The output must not reproduce guide lines or marks.

## Extraction-Side Rules

Frame extraction uses **fixed slot boundaries** only. The pipeline:

1. Verify the decoded strip dimensions. If slightly off (within tolerance), normalize to exact `frames × cell_width` by `cell_height` before extraction.
2. Extract frames by dividing the strip into `frames` equal-width crops. No component detection.
3. Remove the chroma key by replacing matching pixels with transparency.
4. Write the frame as-is. Do **not** crop by bounding box. Do **not** recenter. Do **not** rescale.

The character stays wherever the AI placed it within the slot. This is intentional — consistent positioning requires consistent generation, not extraction correction.

## When Extraction Does Not Fix Drift

If a generated strip has visual drift (character floats between frames), extraction cannot fix it — it would require rescaling each frame differently, which makes the problem worse. The correct response is:

1. Note the specific frames and the direction of drift in `qa/review.json`.
2. Queue a repair with `queue_character_repairs.py`.
3. Regenerate the row with the anchor and scale rules stated explicitly in the repair note.

## Audit Checklist

After finalization, inspect `qa/contact-sheet.png` for these signs of 跑版:

- Character feet at different Y positions across frames in the same row → anchor drift → repair.
- Character appears smaller or larger in some frames → scale drift → repair.
- Character shifted left or right → horizontal drift → less critical but still worth repair.
- Character clipped at slot edge → canvas too small at generation → repair with explicit canvas size.

Do not accept a spritesheet with visible 跑版. Queue repairs until the animation plays cleanly.
