#!/usr/bin/env python3
"""Inspect extracted frames and write basic geometry/alpha metrics."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from _character_lib import frame_path, get_canvas, load_request, write_json


def bbox_alpha(image: Image.Image):
    alpha = image.convert("RGBA").getchannel("A")
    return alpha.getbbox()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    args = parser.parse_args()
    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    canvas = get_canvas(request)
    metrics = []
    for action in request["animations"]:
        for index in range(int(action["frames"])):
            path = frame_path(run_dir, action["id"], index)
            entry = {"action": action["id"], "index": index, "path": str(path.relative_to(run_dir)), "exists": path.is_file()}
            if path.is_file():
                with Image.open(path) as im:
                    rgba = im.convert("RGBA")
                    entry["size"] = list(rgba.size)
                    entry["bbox"] = list(bbox_alpha(rgba) or [])
                    entry["wrong_size"] = rgba.size != (canvas["cell_width"], canvas["cell_height"])
            metrics.append(entry)
    write_json(run_dir / "qa" / "frame-metrics.json", {"frames": metrics})
    print({"ok": True, "metrics": str(run_dir / 'qa' / 'frame-metrics.json')})


if __name__ == "__main__":
    main()
