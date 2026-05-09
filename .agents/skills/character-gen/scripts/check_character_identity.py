#!/usr/bin/env python3
"""Check character identity consistency: palette overlap and frame-size stability per animation row.

Palette overlap measures what fraction of the canonical base's color buckets also appear
in each decoded animation row. Low overlap indicates identity drift (different character design).
Frame-size consistency checks whether individual frames within a row have similar opaque pixel
counts — large outliers suggest scale drift or a missing pose.

Exits 0 if all rows pass, 1 if any row has errors.
"""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path

from PIL import Image


PALETTE_WARN_THRESHOLD = 0.55   # overlap below this → warning
PALETTE_ERROR_THRESHOLD = 0.40  # overlap below this → error
SIZE_OUTLIER_SMALL = 0.30       # frame < 30% of row median → warning
SIZE_OUTLIER_LARGE = 3.0        # frame > 300% of row median → warning


def load_json(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def parse_hex_color(value: str) -> tuple[int, int, int]:
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise SystemExit(f"invalid color: {value}")
    return (int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16))


def _chroma_dist(r: int, g: int, b: int, key: tuple[int, int, int]) -> float:
    return math.sqrt((r - key[0]) ** 2 + (g - key[1]) ** 2 + (b - key[2]) ** 2)


def color_buckets(image: Image.Image, chroma_key: tuple[int, int, int], chroma_threshold: float) -> frozenset:
    """Extract 16-unit quantized color buckets from opaque, non-chroma pixels."""
    rgba = image.convert("RGBA")
    data = rgba.tobytes()
    buckets: set = set()
    for i in range(0, len(data), 4):
        r, g, b, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        if a < 16:
            continue
        if _chroma_dist(r, g, b, chroma_key) < chroma_threshold:
            continue
        buckets.add((r >> 4, g >> 4, b >> 4))
    return frozenset(buckets)


def palette_overlap(base: frozenset, row: frozenset) -> float:
    """Fraction of base color buckets that also appear in the row."""
    if not base:
        return 1.0
    return len(base & row) / len(base)


def frame_area(cell: Image.Image, chroma_key: tuple[int, int, int], chroma_threshold: float) -> int:
    """Count opaque, non-chroma pixels."""
    rgba = cell.convert("RGBA")
    data = rgba.tobytes()
    count = 0
    for i in range(0, len(data), 4):
        r, g, b, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        if a >= 16 and _chroma_dist(r, g, b, chroma_key) >= chroma_threshold:
            count += 1
    return count


def check_row(
    strip_path: Path,
    base_buckets: frozenset,
    anim: dict,
    cell_w: int,
    cell_h: int,
    chroma_key: tuple[int, int, int],
    chroma_threshold: float,
) -> dict:
    anim_name = anim["name"]
    frames = anim["frames"]
    errors: list[str] = []
    warnings: list[str] = []

    if not strip_path.is_file():
        return {
            "animation": anim_name,
            "palette_overlap": None,
            "frame_areas": [],
            "errors": [f"decoded/{anim_name}.png not found"],
            "warnings": [],
            "ok": False,
        }

    with Image.open(strip_path) as img:
        strip = img.copy().convert("RGBA")

    # Palette overlap
    row_buckets = color_buckets(strip, chroma_key, chroma_threshold)
    overlap = palette_overlap(base_buckets, row_buckets)

    if overlap < PALETTE_ERROR_THRESHOLD:
        errors.append(
            f"palette overlap {overlap:.0%} < {PALETTE_ERROR_THRESHOLD:.0%} — "
            "likely identity drift; regenerate and compare against canonical-base"
        )
    elif overlap < PALETTE_WARN_THRESHOLD:
        warnings.append(
            f"palette overlap {overlap:.0%} < {PALETTE_WARN_THRESHOLD:.0%} — "
            "review contact sheet for identity drift"
        )

    # Intra-row frame-size consistency
    expected_w = frames * cell_w
    areas: list[int] = []
    if abs(strip.width - expected_w) <= 8 and abs(strip.height - cell_h) <= 8:
        if strip.width != expected_w or strip.height != cell_h:
            strip = strip.resize((expected_w, cell_h), Image.Resampling.NEAREST)
        for i in range(frames):
            cell = strip.crop((i * cell_w, 0, (i + 1) * cell_w, cell_h))
            areas.append(frame_area(cell, chroma_key, chroma_threshold))
        if areas:
            median_area = sorted(areas)[len(areas) // 2]
            for i, area in enumerate(areas):
                if median_area > 0 and area < median_area * SIZE_OUTLIER_SMALL:
                    warnings.append(
                        f"frame {i:02d} area {area} << row median {median_area} — "
                        "possible missing pose or scale drift"
                    )
                if median_area > 0 and area > median_area * SIZE_OUTLIER_LARGE:
                    warnings.append(
                        f"frame {i:02d} area {area} >> row median {median_area} — "
                        "possible scale drift"
                    )
    else:
        warnings.append(
            f"strip dimensions {strip.width}×{strip.height} differ too much from "
            f"expected {expected_w}×{cell_h}; size consistency check skipped"
        )

    return {
        "animation": anim_name,
        "palette_overlap": round(overlap, 3),
        "frame_areas": areas,
        "errors": errors,
        "warnings": warnings,
        "ok": len(errors) == 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--json-out", default="", help="Override output path (default: qa/identity-check.json)")
    parser.add_argument("--chroma-threshold", type=float, default=80.0)
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    spec = load_json(run_dir / "asset_spec.json")

    request_path = run_dir / "character_request.json"
    request = load_json(request_path) if request_path.exists() else {}

    chroma_info = request.get("chroma_key") or {}
    chroma_hex = chroma_info.get("hex") if isinstance(chroma_info, dict) else None
    if not chroma_hex:
        chroma_hex = spec.get("chroma_key", "#FF00FF")
    chroma_key = parse_hex_color(chroma_hex)

    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    animations = spec["animations"]

    base_path = run_dir / "references" / "canonical-base.png"
    if not base_path.is_file():
        raise SystemExit(
            f"canonical-base.png not found: {base_path}\n"
            "Record the base job first with record_character_result.py."
        )

    with Image.open(base_path) as img:
        base_buckets = color_buckets(img.copy(), chroma_key, args.chroma_threshold)

    rows = []
    for anim in animations:
        strip_path = run_dir / "decoded" / f"{anim['name']}.png"
        rows.append(check_row(strip_path, base_buckets, anim, cell_w, cell_h, chroma_key, args.chroma_threshold))

    all_ok = all(r["ok"] for r in rows)
    result = {
        "ok": all_ok,
        "canonical_base": "references/canonical-base.png",
        "chroma_key": chroma_hex,
        "palette_thresholds": {"warn": PALETTE_WARN_THRESHOLD, "error": PALETTE_ERROR_THRESHOLD},
        "rows": rows,
    }

    out_path = (
        Path(args.json_out).expanduser().resolve()
        if args.json_out
        else run_dir / "qa" / "identity-check.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
