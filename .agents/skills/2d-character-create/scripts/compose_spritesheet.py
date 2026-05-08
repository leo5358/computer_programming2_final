#!/usr/bin/env python3
"""Compose a transparent spritesheet atlas from extracted frames."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from _character_lib import frame_path, get_canvas, load_request, write_json


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--output", default="output/spritesheet.png")
    parser.add_argument("--webp-output", default="output/spritesheet.webp")
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    canvas = get_canvas(request)
    cw, ch, cols, rows = canvas["cell_width"], canvas["cell_height"], canvas["columns"], canvas["rows"]
    atlas = Image.new("RGBA", (cols * cw, rows * ch), (0, 0, 0, 0))
    for action in request["animations"]:
        row = int(action["row"])
        for index in range(int(action["frames"])):
            src = frame_path(run_dir, action["id"], index)
            if not src.is_file():
                raise SystemExit(f"missing frame: {src}")
            with Image.open(src) as opened:
                frame = opened.convert("RGBA")
                if frame.size != (cw, ch):
                    frame = frame.resize((cw, ch), Image.Resampling.NEAREST)
                atlas.alpha_composite(frame, (index * cw, row * ch))
    output = run_dir / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)
    webp_path = None
    if args.webp_output:
        try:
            webp_path = run_dir / args.webp_output
            atlas.save(webp_path, format="WEBP", lossless=True, quality=100, method=6)
        except Exception as exc:
            webp_path = None
            print(f"warning: could not write webp: {exc}")
    write_json(run_dir / "output" / "atlas.json", {
        "image": str(output.relative_to(run_dir)),
        "webp_image": str(webp_path.relative_to(run_dir)) if webp_path else None,
        "cell_width": cw,
        "cell_height": ch,
        "columns": cols,
        "rows": rows,
        "width": atlas.width,
        "height": atlas.height,
        "animations": [{"id": a["id"], "row": a["row"], "frames": a["frames"], "fps": a.get("fps", 8), "loop": a.get("loop", True)} for a in request["animations"]]
    })
    print({"ok": True, "spritesheet": str(output)})


if __name__ == "__main__":
    main()
