#!/usr/bin/env python3
"""Create a QA contact sheet showing all extracted frames in their atlas rows."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from _character_lib import frame_path, get_canvas, load_request


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--output", default="qa/contact-sheet.png")
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    canvas = get_canvas(request)
    cw, ch, cols = canvas["cell_width"], canvas["cell_height"], canvas["columns"]
    label_w = 180
    header_h = 24
    width = label_w + cols * cw
    height = header_h + canvas["rows"] * ch
    sheet = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.load_default()
    except Exception:
        font = None
    draw.text((8, 4), request["character"]["id"], fill=(0,0,0,255), font=font)
    for action in request["animations"]:
        row = int(action["row"])
        y = header_h + row * ch
        draw.text((8, y + 8), f"{action['id']} ({action['frames']}f)", fill=(0,0,0,255), font=font)
        for col in range(cols):
            x = label_w + col * cw
            draw.rectangle((x, y, x+cw-1, y+ch-1), outline=(160,160,160,255), width=1)
        for index in range(int(action["frames"])):
            src = frame_path(run_dir, action["id"], index)
            if src.is_file():
                with Image.open(src) as opened:
                    sheet.alpha_composite(opened.convert("RGBA"), (label_w + index*cw, y))
            draw.text((label_w + index*cw + 3, y + 3), str(index), fill=(0,0,0,180), font=font)
    out = run_dir / args.output
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print({"ok": True, "contact_sheet": str(out)})


if __name__ == "__main__":
    main()
