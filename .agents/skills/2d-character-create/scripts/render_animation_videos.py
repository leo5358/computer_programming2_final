#!/usr/bin/env python3
"""Render simple GIF previews for extracted animation frames."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from _character_lib import frame_path, load_request


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--action-id", default="")
    args = parser.parse_args()
    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    actions = [a for a in request["animations"] if not args.action_id or a["id"] == args.action_id]
    out_dir = run_dir / "qa" / "previews"
    out_dir.mkdir(parents=True, exist_ok=True)
    outputs = []
    for action in actions:
        images = []
        for index in range(int(action["frames"])):
            path = frame_path(run_dir, action["id"], index)
            if path.is_file():
                images.append(Image.open(path).convert("RGBA"))
        if not images:
            continue
        out = out_dir / f"{action['id']}.gif"
        duration = max(20, int(1000 / int(action.get("fps", 8))))
        images[0].save(out, save_all=True, append_images=images[1:], duration=duration, loop=0 if action.get("loop", True) else 1, disposal=2)
        for im in images:
            im.close()
        outputs.append(str(out))
    print({"ok": True, "outputs": outputs})


if __name__ == "__main__":
    main()
