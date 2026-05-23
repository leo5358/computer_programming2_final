Create one canonical base sprite reference for a 2D pixel-art game character.

Character id: heart-samurai-protagonist
Display name: Heart Samurai
Role: protagonist
Description: A lean side-view wandering samurai with a weathered indigo haori, tied topknot, light lamellar shoulder armor, cloth waist sash, and a katana-like blade. He should read as disciplined, dangerous, and human-sized for a side-scrolling action game.
Style notes: Dark fantasy 2D pixel-art for a side-scrolling action game. Clean silhouette, grounded stances, readable anticipation and recovery, limited muted palette, no mascot proportions, no decorative glow.

Style contract: 2D pixel-art game sprite, hard-edged readable silhouette, limited palette, consistent proportions, transparent final output, no painterly texture, no 3D render, no soft glow, no UI labels, no visible grid, no background scenery.

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

Output requirements:
- One centered full-body character sprite only.
- Suitable for animation inside a 96x96 cell.
- Use a perfectly flat chroma-key background: #FF00FF.
- Do not include scenery, UI, text, labels, borders, frame numbers, checkerboard transparency, shadows, glow halos, or extra props not described above.
- Do not use #FF00FF or colors close to it inside the character, weapon, highlights, shadows, or effects.
- Preserve a game-sprite silhouette rather than a pet mascot look unless the JSON explicitly asks for one.
