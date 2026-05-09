#!/usr/bin/env python3
"""Prepare a character-gen run folder, prompts, and imagegen job manifest from an asset spec."""

from __future__ import annotations

import argparse
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw

CANONICAL_BASE_PATH = "references/canonical-base.png"
LAYOUT_GUIDE_DIR = "references/layout-guides"
LAYOUT_GUIDE_SAFE_MARGIN = 10


def load_spec(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"spec not found: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid JSON in spec: {exc}") from exc


def validate_spec(spec: dict) -> None:
    required = ["name", "cell", "animations"]
    for field in required:
        if field not in spec:
            raise SystemExit(f"asset_spec.json missing required field: {field}")
    cell = spec["cell"]
    if not isinstance(cell, dict) or "width" not in cell or "height" not in cell:
        raise SystemExit("cell must have width and height")
    if not isinstance(spec["animations"], list) or not spec["animations"]:
        raise SystemExit("animations must be a non-empty list")
    for anim in spec["animations"]:
        for field in ["name", "frames", "fps", "loop", "action"]:
            if field not in anim:
                raise SystemExit(f"animation missing field '{field}': {anim}")


def parse_hex_color(value: str) -> tuple[int, int, int]:
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise SystemExit(f"invalid chroma key: {value}; expected #RRGGBB")
    return tuple(int(value[i: i + 2], 16) for i in (1, 3, 5))


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return f"#{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"


def chroma_key_info(spec: dict) -> dict:
    raw = spec.get("chroma_key", "#FF00FF")
    rgb = parse_hex_color(raw)
    names = {
        (255, 0, 255): "magenta",
        (0, 255, 255): "cyan",
        (0, 255, 0): "green",
        (255, 255, 0): "yellow",
        (0, 0, 255): "blue",
    }
    return {"hex": rgb_to_hex(rgb), "rgb": list(rgb), "name": names.get(rgb, "custom")}


def draw_dashed_line(
    draw: ImageDraw.ImageDraw,
    start: tuple[int, int],
    end: tuple[int, int],
    *,
    fill: str,
    dash: int = 8,
    gap: int = 6,
) -> None:
    x1, y1 = start
    x2, y2 = end
    if x1 == x2:
        step = dash + gap
        for y in range(min(y1, y2), max(y1, y2), step):
            draw.line((x1, y, x2, min(y + dash, max(y1, y2))), fill=fill)
        return
    if y1 == y2:
        step = dash + gap
        for x in range(min(x1, x2), max(x1, x2), step):
            draw.line((x, y1, min(x + dash, max(x1, x2)), y2), fill=fill)
        return


def create_layout_guide(path: Path, anim_name: str, frames: int, cell_w: int, cell_h: int) -> dict:
    width = frames * cell_w
    height = cell_h
    image = Image.new("RGB", (width, height), "#f7f7f7")
    draw = ImageDraw.Draw(image)

    for i in range(frames):
        left = i * cell_w
        right = left + cell_w - 1
        draw.rectangle((left, 0, right, height - 1), outline="#111111", width=2)

        sl = left + LAYOUT_GUIDE_SAFE_MARGIN
        st = LAYOUT_GUIDE_SAFE_MARGIN
        sr = right - LAYOUT_GUIDE_SAFE_MARGIN
        sb = height - 1 - LAYOUT_GUIDE_SAFE_MARGIN
        draw.rectangle((sl, st, sr, sb), outline="#2f80ed", width=1)

        cx = left + cell_w // 2
        cy = height // 2
        draw_dashed_line(draw, (cx, st), (cx, sb), fill="#b8b8b8")
        draw_dashed_line(draw, (sl, cy), (sr, cy), fill="#b8b8b8")

        anchor_y = height - LAYOUT_GUIDE_SAFE_MARGIN - 1
        draw.line((left + LAYOUT_GUIDE_SAFE_MARGIN, anchor_y, right - LAYOUT_GUIDE_SAFE_MARGIN, anchor_y), fill="#e05c00", width=2)

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return {
        "animation": anim_name,
        "path": str(path),
        "width": width,
        "height": height,
        "frames": frames,
        "cell_width": cell_w,
        "cell_height": cell_h,
        "anchor_line": "orange line near bottom marks the target foot/anchor Y position",
        "usage": "layout guide input only; do not reproduce guide lines in the generated sprite strip",
    }


def image_metadata(path: Path) -> dict:
    with Image.open(path) as img:
        return {"width": img.width, "height": img.height, "mode": img.mode}


def rel(path: Path, root: Path) -> str:
    return str(path.resolve().relative_to(root.resolve()))


def base_prompt(spec: dict, chroma: dict) -> str:
    name = spec["name"]
    description = spec.get("description", f"the {name} character")
    style = spec.get("style_notes", "Side-view 2D pixel art combat sprite, readable combat silhouette, limited palette, crisp hard-edged shapes, continuous 1-2 px dark outline.")
    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    chroma_hex = chroma["hex"]
    chroma_name = chroma["name"]
    direction = spec.get("direction", "right")

    return f"""Create a single clean full-body reference sprite for a 2D action game character named "{name}".

Character: {description}

Style: {style}

Output one complete centered full-body character pose on a perfectly flat pure {chroma_name} {chroma_hex} chroma-key background. The character must face {direction}. The character must be fully visible and readable at {cell_w}×{cell_h} pixels — no cropping, no clipping.

Alignment requirement: center the character horizontally. Place the character's feet near the bottom of the canvas with a small margin. This anchored position will be the reference for all animation rows.

Do not include scenery, text, labels, borders, UI panels, shadows, glows, floor marks, speed lines, or decorative effects. Do not use {chroma_hex} or colors close to {chroma_name} in the character's palette, outline, or highlights."""


def row_prompt(spec: dict, anim: dict, chroma: dict) -> str:
    name = spec["name"]
    description = spec.get("description", f"the {name} character")
    style = spec.get("style_notes", "Side-view 2D pixel art combat sprite, readable combat silhouette, limited palette, crisp hard-edged shapes, continuous 1-2 px dark outline.")
    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    anim_name = anim["name"]
    frames = anim["frames"]
    action = anim["action"]
    strip_w = frames * cell_w
    chroma_hex = chroma["hex"]
    chroma_name = chroma["name"]
    extra_notes = anim.get("prompt_notes", "")

    extra_block = f"\nAdditional notes: {extra_notes}" if extra_notes else ""

    return f"""Create a {frames}-frame horizontal sprite strip for the animation `{anim_name}` of the character "{name}".

Use the attached canonical base image for character identity. Use the attached layout guide for slot count, spacing, and anchor position — follow the orange anchor line at the bottom of each slot as the target foot position.

Character: {description}
Style: {style}

Identity lock — preserve exactly from the canonical base:
- Same body shape, head shape, limb proportions, and overall silhouette.
- Same face design: eye shape, expression language, and any facial markings or features.
- Same exact color palette — do not introduce new colors or alter existing ones.
- Same outline weight and line style. Do not change the art style between frames.
- Same equipment, weapons, and accessories: same size, design, placement side, and attachment style. Do not change or remove them.
- Do not redesign the character. Only the pose changes for this animation.
- A row that looks like a related but different character is a failure even if geometry QA passes.
- Prefer a subtler animation over any pose change that alters the character's identity.

Anti-跑版 alignment rules — critical, must be followed:
- ANCHOR: The character's feet must be at the same Y position in every frame, aligned with the orange anchor line in the layout guide. The character must not float upward or sink lower between frames.
- SCALE: The character must be the same apparent height in every frame. Do not grow or shrink the character between frames.
- CANVAS: The output strip must be exactly {strip_w} pixels wide and {cell_h} pixels tall. Fill the entire canvas with the {chroma_name} background.
- SLOTS: Treat the canvas as {frames} equal-width invisible slots of {cell_w}×{cell_h} each. Place exactly one complete full-body pose centered horizontally in each slot.
- FILL: Every slot must contain a complete visible pose. Do not leave any slot empty or only partially filled.
- SEPARATION: No pose may cross into a neighboring slot. Keep each pose self-contained within its slot.

Animation action: {action}{extra_block}

Background and artifacts:
- Flat pure {chroma_name} {chroma_hex} background only. No scenery, no floor, no environment.
- No shadows, drop shadows, floor shadows, contact shadows, glows, halos, or auras.
- No speed lines, motion blur, motion trails, afterimages, or dust.
- No text, labels, frame numbers, watermarks, UI, guide lines, or grid marks.
- Do not use {chroma_hex} or colors close to {chroma_name} in the character, outline, or effects.
- No stray pixels, disconnected fragments, or partial poses outside the character silhouette.
- Do not reproduce layout guide lines, borders, color marks, or the guide background.

Output format:
- One single horizontal image strip, exactly {strip_w}×{cell_h} pixels.
- {frames} complete poses arranged left to right.
- Lossless or high-quality output preferred."""


def make_jobs(spec: dict, run_dir: Path, copied_refs: list[dict]) -> list[dict]:
    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    reference_inputs = [
        {"path": rel(Path(str(ref["copied_path"])), run_dir), "role": "character reference"}
        for ref in copied_refs
    ]
    identity_refs = [CANONICAL_BASE_PATH, "decoded/base.png"]

    jobs: list[dict] = [
        {
            "id": "base",
            "kind": "base-character",
            "status": "pending",
            "prompt_file": "prompts/base-character.md",
            "input_images": reference_inputs,
            "output_path": "decoded/base.png",
            "depends_on": [],
            "generation_skill": "$imagegen",
            "requires_grounded_generation": bool(reference_inputs),
            "allow_prompt_only_generation": not reference_inputs,
            "recording_owner": "parent",
            "cell": {"width": cell_w, "height": cell_h},
        }
    ]

    for anim in spec["animations"]:
        anim_name = anim["name"]
        frames = anim["frames"]
        jobs.append({
            "id": anim_name,
            "kind": "row-strip",
            "status": "pending",
            "prompt_file": f"prompts/rows/{anim_name}.md",
            "input_images": [
                *reference_inputs,
                {
                    "path": f"{LAYOUT_GUIDE_DIR}/{anim_name}.png",
                    "role": f"layout guide for {frames} frame slots — follow slot grid and orange anchor line; do not reproduce guide marks",
                },
                {"path": CANONICAL_BASE_PATH, "role": "canonical identity reference"},
                {"path": "decoded/base.png", "role": "approved base character"},
            ],
            "output_path": f"decoded/{anim_name}.png",
            "depends_on": ["base"],
            "generation_skill": "$imagegen",
            "requires_grounded_generation": True,
            "allow_prompt_only_generation": False,
            "identity_reference_paths": identity_refs,
            "parallelizable_after": ["base"],
            "recording_owner": "parent",
            "cell": {"width": cell_w, "height": cell_h},
            "frames": frames,
            "fps": anim["fps"],
            "loop": anim["loop"],
        })

    return jobs


def default_output_dir(name: str) -> Path:
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return Path.home() / "output" / "character-gen" / f"{name}-{ts}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, help="Path to asset_spec.json")
    parser.add_argument("--reference", action="append", default=[], help="Optional reference image(s)")
    parser.add_argument("--output-dir", default="", help="Run output directory")
    parser.add_argument("--force", action="store_true", help="Overwrite existing run dir")
    args = parser.parse_args()

    spec_path = Path(args.spec).expanduser().resolve()
    spec = load_spec(spec_path)
    validate_spec(spec)

    chroma = chroma_key_info(spec)
    name = spec["name"]
    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    animations = spec["animations"]
    columns = spec.get("columns", max(a["frames"] for a in animations))

    run_dir = (
        Path(args.output_dir).expanduser().resolve()
        if args.output_dir
        else default_output_dir(name).resolve()
    )
    if run_dir.exists() and any(run_dir.iterdir()) and not args.force:
        raise SystemExit(f"{run_dir} already exists; pass --force to reuse")
    run_dir.mkdir(parents=True, exist_ok=True)

    for subdir in ["references", "prompts/rows", "decoded", "qa", "frames", "final"]:
        (run_dir / subdir).mkdir(parents=True, exist_ok=True)

    shutil.copy2(spec_path, run_dir / "asset_spec.json")

    raw_refs = [Path(p).expanduser().resolve() for p in args.reference]
    copied_refs: list[dict] = []
    for idx, src in enumerate(raw_refs, 1):
        if not src.is_file():
            raise SystemExit(f"reference not found: {src}")
        dest = run_dir / "references" / f"reference-{idx:02d}{src.suffix.lower() or '.png'}"
        shutil.copy2(src, dest)
        meta = image_metadata(dest)
        meta["source_path"] = str(src)
        meta["copied_path"] = str(dest)
        copied_refs.append(meta)

    layout_guides = []
    for anim in animations:
        guide_path = run_dir / LAYOUT_GUIDE_DIR / f"{anim['name']}.png"
        guide = create_layout_guide(guide_path, anim["name"], anim["frames"], cell_w, cell_h)
        guide["path"] = rel(guide_path, run_dir)
        layout_guides.append(guide)

    (run_dir / "prompts" / "base-character.md").write_text(
        base_prompt(spec, chroma).rstrip() + "\n", encoding="utf-8"
    )
    for anim in animations:
        (run_dir / "prompts" / "rows" / f"{anim['name']}.md").write_text(
            row_prompt(spec, anim, chroma).rstrip() + "\n", encoding="utf-8"
        )

    request = {
        "name": name,
        "description": spec.get("description", ""),
        "asset_type": spec.get("asset_type", "character"),
        "cell": {"width": cell_w, "height": cell_h},
        "columns": columns,
        "chroma_key": chroma,
        "animations": [
            {"name": a["name"], "frames": a["frames"], "fps": a["fps"], "loop": a["loop"]}
            for a in animations
        ],
        "layout_guides": layout_guides,
        "references": copied_refs,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "primary_generation_skill": "$imagegen",
    }
    (run_dir / "character_request.json").write_text(
        json.dumps(request, indent=2) + "\n", encoding="utf-8"
    )

    jobs_manifest = {
        "schema_version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "run_dir": str(run_dir),
        "primary_generation_skill": "$imagegen",
        "jobs": make_jobs(spec, run_dir, copied_refs),
    }
    (run_dir / "imagegen-jobs.json").write_text(
        json.dumps(jobs_manifest, indent=2) + "\n", encoding="utf-8"
    )

    print(json.dumps({
        "ok": True,
        "run_dir": str(run_dir),
        "name": name,
        "cell": {"width": cell_w, "height": cell_h},
        "animations": [a["name"] for a in animations],
        "request": str(run_dir / "character_request.json"),
        "jobs": str(run_dir / "imagegen-jobs.json"),
        "ready_jobs": ["base"],
    }, indent=2))


if __name__ == "__main__":
    main()
