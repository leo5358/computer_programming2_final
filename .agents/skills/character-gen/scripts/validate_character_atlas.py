#!/usr/bin/env python3
"""Validate a finalized character atlas against the asset spec."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def load_json(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("atlas", help="Path to the atlas PNG")
    parser.add_argument("--spec", default="", help="Path to asset_spec.json")
    parser.add_argument("--json-out", default="", help="Write validation JSON to this path")
    args = parser.parse_args()

    atlas_path = Path(args.atlas).expanduser().resolve()
    if not atlas_path.is_file():
        raise SystemExit(f"atlas not found: {atlas_path}")

    spec_path = (
        Path(args.spec).expanduser().resolve()
        if args.spec
        else atlas_path.parent.parent / "asset_spec.json"
    )
    spec = load_json(spec_path)

    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    animations = spec["animations"]
    columns = spec.get("columns", max(a["frames"] for a in animations))

    expected_w = columns * cell_w
    expected_h = len(animations) * cell_h

    errors = []
    warnings = []

    with Image.open(atlas_path) as atlas:
        actual_w, actual_h = atlas.size
        mode = atlas.mode

        if (actual_w, actual_h) != (expected_w, expected_h):
            errors.append(f"atlas size {actual_w}×{actual_h} does not match expected {expected_w}×{expected_h}")

        if "A" not in mode:
            warnings.append("atlas has no alpha channel — transparency may be missing")

        if "A" in mode:
            alpha = atlas.getchannel("A")
            for row_idx, anim in enumerate(animations):
                y = row_idx * cell_h
                for f in range(anim["frames"]):
                    x = f * cell_w
                    cell_alpha = alpha.crop((x, y, x + cell_w, y + cell_h))
                    data = cell_alpha.tobytes()
                    opaque = sum(1 for b in data if b > 16)
                    if opaque < len(data) * 0.005:
                        errors.append(f"{anim['name']} frame {f:02d} is nearly empty (possible missing generation or chroma key failure)")
                for f in range(anim["frames"], columns):
                    x = f * cell_w
                    cell_alpha = alpha.crop((x, y, x + cell_w, y + cell_h))
                    data = cell_alpha.tobytes()
                    opaque = sum(1 for b in data if b > 16)
                    if opaque > 0:
                        warnings.append(f"{anim['name']} unused slot {f} is not fully transparent")

    result = {
        "ok": len(errors) == 0,
        "atlas": str(atlas_path),
        "spec": str(spec_path),
        "dimensions": {"width": actual_w, "height": actual_h},
        "expected": {"width": expected_w, "height": expected_h},
        "cell": {"width": cell_w, "height": cell_h},
        "columns": columns,
        "animations": len(animations),
        "errors": errors,
        "warnings": warnings,
    }

    if args.json_out:
        out_path = Path(args.json_out).expanduser().resolve()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(result, indent=2))
    if not result["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
