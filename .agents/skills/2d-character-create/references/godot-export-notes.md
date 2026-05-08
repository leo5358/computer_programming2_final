# Godot Export Notes

This skill packages ordinary spritesheet data. In Godot 4, you can use the output with `AnimatedSprite2D`, `Sprite2D` plus manual frame logic, or a custom importer.

The generated files are:

```text
package/godot/<character_id>/
  character.json
  atlas.json
  animations.json
  spritesheet.png
  frames/
```

`atlas.json` records:

- `cell_width`
- `cell_height`
- `columns`
- `rows`
- `image`

`animations.json` records one entry per animation:

- `id`
- `row`
- `frames`
- `fps`
- `loop`
- `frame_paths`

Recommended Godot import settings:

- Filter: off / nearest.
- Mipmaps: off for crisp pixel art.
- Use integer camera scaling when possible.
- Keep atlas dimensions stable once gameplay code depends on frame coordinates.
