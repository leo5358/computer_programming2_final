#!/usr/bin/env python3
"""Extract configured animation frames from recorded horizontal row strips."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from _character_lib import action_by_id, chroma_to_rgba, frame_path, get_canvas, load_request, parse_hex_color, write_json


def remove_chroma(image: Image.Image, key_hex: str, tolerance: int) -> Image.Image:
    rgba = image.convert("RGBA")
    key = parse_hex_color(key_hex)
    pixels = [chroma_to_rgba(pixel, key, tolerance) for pixel in rgba.getdata()]
    rgba.putdata(pixels)
    return rgba


def extract_action(run_dir: Path, request: dict, action: dict, tolerance: int) -> list[str]:
    canvas = get_canvas(request)
    src = run_dir / "decoded" / f"{action['id']}.png"
    if not src.is_file():
        raise SystemExit(f"missing row strip for {action['id']}: {src}")
    frames = int(action["frames"])
    cw, ch = canvas["cell_width"], canvas["cell_height"]
    with Image.open(src) as opened:
        strip = opened.convert("RGBA")
        expected = (frames * cw, ch)
        if strip.size != expected:
            # Resize only the generated strip to the exact configured row geometry.
            # This is deterministic normalization, not visual synthesis.
            strip = strip.resize(expected, Image.Resampling.NEAREST)
        strip = remove_chroma(strip, canvas["chroma_key"], tolerance)
        out_paths = []
        for index in range(frames):
            frame = strip.crop((index * cw, 0, (index + 1) * cw, ch))
            dst = frame_path(run_dir, action["id"], index)
            dst.parent.mkdir(parents=True, exist_ok=True)
            frame.save(dst)
            out_paths.append(str(dst.relative_to(run_dir)))
        return out_paths


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--action-id", default="")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--chroma-tolerance", type=int, default=8)
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    if not args.all and not args.action_id:
        raise SystemExit("pass --all or --action-id")
    actions = request["animations"] if args.all else [action_by_id(request, args.action_id)]
    manifest = {"run_dir": str(run_dir), "frames": {}}
    for action in actions:
        manifest["frames"][action["id"]] = extract_action(run_dir, request, action, args.chroma_tolerance)
    write_json(run_dir / "frames" / "frames-manifest.json", manifest)
    print({"ok": True, "actions": [a["id"] for a in actions]})


if __name__ == "__main__":
    main()
