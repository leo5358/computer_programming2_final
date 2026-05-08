# QA Rubric

Do not accept the spritesheet until all relevant checks pass.

## Geometry

- Atlas size equals `columns * cell_width` by `rows * cell_height`.
- Every configured frame exists.
- Unused cells are transparent.
- No frame is clipped by its cell.
- Each row contains the exact configured number of frames.

## Character Consistency

- Same silhouette, proportions, palette, material, and outline style across rows.
- Face, mask, hair, horns, tail, weapon, armor, scars, and accessories do not mutate unintentionally.
- No row introduces a new character, extra weapon, or unrelated object.
- Boss scale stays boss scale; small enemy scale stays small enemy scale.

## Pixel Sprite Style

- Reads as a 2D pixel-game sprite, not painterly art, anime key art, 3D render, or app icon.
- Hard edges and limited palette remain intact.
- No soft shadows, glow halos, blurred smears, background scenery, text, labels, frame numbers, or visible grids.

## Animation Completeness

- The action is recognizable at the final cell size.
- First and last frames loop acceptably when `loop` is true.
- Attack, guard, parry, hurt, posture-break, and death states are distinguishable.
- Frames are not just duplicated still images with tiny geometric transforms.

## Repair Policy

Repair the smallest failing scope first:

1. One bad frame.
2. One bad row.
3. The canonical base only if the identity is wrong.
4. Full atlas regeneration only if layout or identity is broadly broken.
