Create one horizontal animation row strip for the same 2D pixel-art game character.

Character id: heart-samurai-protagonist
Display name: Heart Samurai
Role: protagonist
Canonical identity: A lean side-view wandering samurai with a weathered indigo haori, tied topknot, light lamellar shoulder armor, cloth waist sash, and a katana-like blade. He should read as disciplined, dangerous, and human-sized for a side-scrolling action game.
Style notes: Dark fantasy 2D pixel-art for a side-scrolling action game. Clean silhouette, grounded stances, readable anticipation and recovery, limited muted palette, no mascot proportions, no decorative glow.
Animation id: dash
Animation prompt: quick low evasive dash to the right, body compressed, strong forward commitment
Frame count: 6
Target cell size: 96x96
Chroma key background: #FF00FF

Identity lock:
- Use the attached canonical base image as the source of truth.
- Do not redesign the character.
- Preserve head shape, body proportions, face/mask, hair/horns/tail, weapon, armor, palette, outline weight, and silhouette.
- Keep every frame recognizably the same individual character.
- If a weapon or accessory exists, preserve its size, side, material, and attachment unless the action requires pose-only movement.

Must keep:
- topknot silhouette
- weathered indigo haori
- katana-like blade
- light shoulder armor
- cloth waist sash
- human adult samurai proportions
- side-view readability

Must avoid:
- chibi proportions
- cute mascot face
- oversized anime hair
- extra weapons
- 3D render look
- soft bloom
- background scenery

Layout requirements:
- Output exactly 6 complete full-body frames in a single horizontal row.
- Treat the image as 6 equal-width invisible frame slots.
- Center one complete pose in each slot.
- No pose may cross into a neighboring slot.
- Do not reproduce the layout guide: no visible boxes, guide lines, center marks, labels, or guide colors.
- Use a perfectly flat #FF00FF background across the whole row.
- Do not include scenery, UI, text, frame numbers, visible grids, checkerboard transparency, or watermarks.
- Avoid detached motion arcs, speed lines, soft glows, blurred smears, and shadows unless explicitly required by the JSON and still readable as pixel art.
- Prefer readable pose changes over decorative effects.

Style contract: 2D pixel-art game sprite, hard-edged readable silhouette, limited palette, consistent proportions, transparent final output, no painterly texture, no 3D render, no soft glow, no UI labels, no visible grid, no background scenery.
