#!/usr/bin/env python3
"""Mirror a directional row only after explicit visual approval."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps

from _character_lib import action_by_id, get_canvas, load_request


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--source-action", required=True)
    parser.add_argument("--target-action", required=True)
    parser.add_argument("--approved", action="store_true", help="Required. Confirms visual inspection approved mirroring.")
    args = parser.parse_args()
    if not args.approved:
        raise SystemExit("mirroring requires --approved after visual inspection")
    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    src_action = action_by_id(request, args.source_action)
    target_action = action_by_id(request, args.target_action)
    if int(src_action["frames"]) != int(target_action["frames"]):
        raise SystemExit("source and target frame counts must match for mirroring")
    canvas = get_canvas(request)
    src = run_dir / "decoded" / f"{args.source_action}.png"
    dst = run_dir / "decoded" / f"{args.target_action}.png"
    if not src.is_file():
        raise SystemExit(f"missing source strip: {src}")
    with Image.open(src) as im:
        mirrored = ImageOps.mirror(im.convert("RGBA"))
        expected = (target_action["frames"] * canvas["cell_width"], canvas["cell_height"])
        if mirrored.size != expected:
            mirrored = mirrored.resize(expected, Image.Resampling.NEAREST)
        mirrored.save(dst)
    print({"ok": True, "output": str(dst)})


if __name__ == "__main__":
    main()
