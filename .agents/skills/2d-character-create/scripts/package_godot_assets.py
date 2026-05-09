#!/usr/bin/env python3
"""Package spritesheet outputs and metadata into a Godot-friendly folder."""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from _character_lib import frame_path, get_canvas, load_request, write_json


def copy_if_exists(src: Path, dst: Path) -> None:
    if src.is_file():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    args = parser.parse_args()
    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    c = request["character"]
    canvas = get_canvas(request)
    package = run_dir / "package" / "godot" / c["id"]
    package.mkdir(parents=True, exist_ok=True)
    copy_if_exists(run_dir / "output" / "spritesheet.png", package / "spritesheet.png")
    copy_if_exists(run_dir / "output" / "spritesheet.webp", package / "spritesheet.webp")
    animations = []
    for action in request["animations"]:
        paths = []
        for index in range(int(action["frames"])):
            src = frame_path(run_dir, action["id"], index)
            dst = package / "frames" / action["id"] / src.name
            copy_if_exists(src, dst)
            paths.append(str(dst.relative_to(package)))
        animations.append({
            "id": action["id"],
            "row": action["row"],
            "frames": action["frames"],
            "fps": action.get("fps", 8),
            "loop": action.get("loop", True),
            "frame_paths": paths
        })
    write_json(package / "character.json", c)
    write_json(package / "animations.json", {"animations": animations})
    write_json(package / "atlas.json", {
        "image": "spritesheet.png",
        "cell_width": canvas["cell_width"],
        "cell_height": canvas["cell_height"],
        "columns": canvas["columns"],
        "rows": canvas["rows"],
        "width": canvas["columns"] * canvas["cell_width"],
        "height": canvas["rows"] * canvas["cell_height"]
    })
    print({"ok": True, "package": str(package)})


if __name__ == "__main__":
    main()
