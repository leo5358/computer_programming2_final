#!/usr/bin/env python3
"""Validate atlas geometry and extracted frame completeness."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from _character_lib import frame_path, get_canvas, load_request, write_json


def frame_has_alpha_content(path: Path) -> bool:
    with Image.open(path) as im:
        return im.convert("RGBA").getchannel("A").getbbox() is not None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--spritesheet", default="output/spritesheet.png")
    args = parser.parse_args()
    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    canvas = get_canvas(request)
    errors, warnings = [], []
    expected_size = (canvas["columns"] * canvas["cell_width"], canvas["rows"] * canvas["cell_height"])
    sheet = run_dir / args.spritesheet
    if not sheet.is_file():
        errors.append(f"missing spritesheet: {sheet}")
    else:
        with Image.open(sheet) as im:
            if im.size != expected_size:
                errors.append(f"spritesheet size {im.size} != expected {expected_size}")
    for action in request["animations"]:
        for index in range(int(action["frames"])):
            path = frame_path(run_dir, action["id"], index)
            if not path.is_file():
                errors.append(f"missing frame: {path.relative_to(run_dir)}")
                continue
            with Image.open(path) as im:
                if im.size != (canvas["cell_width"], canvas["cell_height"]):
                    errors.append(f"wrong frame size: {path.relative_to(run_dir)} {im.size}")
            if not frame_has_alpha_content(path):
                warnings.append(f"blank frame: {path.relative_to(run_dir)}")
    review = {"ok": not errors, "errors": errors, "warnings": warnings, "expected_size": expected_size}
    write_json(run_dir / "qa" / "review.json", review)
    print(review)
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
