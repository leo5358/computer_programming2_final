#!/usr/bin/env python3
"""Prepare a JSON-configured 2D character spritesheet run."""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

from _character_lib import copy_image, ensure_file, now_iso, rel, slugify, write_json, read_json

STYLE_CONTRACT = (
    "2D pixel-art game sprite, hard-edged readable silhouette, limited palette, "
    "consistent proportions, transparent final output, no painterly texture, no 3D render, "
    "no soft glow, no UI labels, no visible grid, no background scenery."
)


def normalize_spec(spec: dict[str, Any]) -> dict[str, Any]:
    character = dict(spec.get("character") or {})
    if not character.get("id"):
        character["id"] = slugify(character.get("display_name", "character"))
    character["id"] = slugify(character["id"])
    character.setdefault("display_name", character["id"].replace("-", " ").title())
    character.setdefault("role", "character")
    character.setdefault("description", "A reusable 2D pixel-art game character.")
    character.setdefault("style_notes", "")
    character.setdefault("must_keep", [])
    character.setdefault("must_avoid", [])
    character.setdefault("references", [])

    canvas = dict(spec.get("canvas") or {})
    canvas["cell_width"] = int(canvas.get("cell_width", 96))
    canvas["cell_height"] = int(canvas.get("cell_height", 96))
    canvas.setdefault("background", "transparent")
    canvas.setdefault("chroma_key", "#FF00FF")
    canvas["padding"] = int(canvas.get("padding", max(4, min(canvas["cell_width"], canvas["cell_height"]) // 16)))

    animations = list(spec.get("animations") or [])
    if not animations:
        animations = [
            {"id": "idle", "frames": 4, "fps": 6, "loop": True, "prompt": "subtle breathing idle"},
            {"id": "walk-right", "frames": 6, "fps": 10, "loop": True, "prompt": "side-view walking right"},
            {"id": "attack-light", "frames": 6, "fps": 12, "loop": False, "prompt": "quick readable attack"},
        ]
    used_rows: set[int] = set()
    next_row = 0
    normalized_actions: list[dict[str, Any]] = []
    for raw in animations:
        action = dict(raw)
        action["id"] = slugify(action.get("id", f"action-{len(normalized_actions)}"), default=f"action-{len(normalized_actions)}")
        action["frames"] = int(action.get("frames", 4))
        action["fps"] = int(action.get("fps", 8))
        action.setdefault("loop", True)
        action.setdefault("prompt", action["id"].replace("-", " "))
        if "row" in action:
            row = int(action["row"])
        else:
            while next_row in used_rows:
                next_row += 1
            row = next_row
        action["row"] = row
        used_rows.add(row)
        next_row = max(next_row, row + 1)
        normalized_actions.append(action)

    if canvas.get("columns") == "auto" or canvas.get("columns") is None:
        canvas["columns"] = max(action["frames"] for action in normalized_actions)
    canvas["columns"] = int(canvas["columns"])
    canvas["rows"] = max(action["row"] for action in normalized_actions) + 1
    return {"character": character, "canvas": canvas, "animations": normalized_actions}


def line(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], fill: str) -> None:
    draw.line((*start, *end), fill=fill, width=1)


def create_layout_guide(path: Path, action: dict[str, Any], canvas: dict[str, Any]) -> dict[str, Any]:
    frames = int(action["frames"])
    cw, ch = int(canvas["cell_width"]), int(canvas["cell_height"])
    padding = int(canvas.get("padding", 0))
    image = Image.new("RGB", (frames * cw, ch), "#f5f5f5")
    draw = ImageDraw.Draw(image)
    for i in range(frames):
        left = i * cw
        right = left + cw - 1
        draw.rectangle((left, 0, right, ch - 1), outline="#111111", width=2)
        safe = (left + padding, padding, right - padding, ch - 1 - padding)
        draw.rectangle(safe, outline="#2f80ed", width=1)
        cx = left + cw // 2
        cy = ch // 2
        line(draw, (cx, padding), (cx, ch - 1 - padding), "#bbbbbb")
        line(draw, (left + padding, cy), (right - padding, cy), "#bbbbbb")
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return {
        "action_id": action["id"],
        "path": str(path),
        "width": image.width,
        "height": image.height,
        "frames": frames,
        "cell_width": cw,
        "cell_height": ch,
        "usage": "layout guide only; do not copy visible guide lines into output",
    }


def list_text(items: list[str]) -> str:
    return "\n".join(f"- {item}" for item in items) if items else "- none"


def base_prompt(request: dict[str, Any]) -> str:
    c = request["character"]
    canvas = request["canvas"]
    return f"""
Create one canonical base sprite reference for a 2D pixel-art game character.

Character id: {c['id']}
Display name: {c['display_name']}
Role: {c['role']}
Description: {c['description']}
Style notes: {c.get('style_notes') or 'Use the default style contract.'}

Style contract: {STYLE_CONTRACT}

Must keep:
{list_text(c.get('must_keep', []))}

Must avoid:
{list_text(c.get('must_avoid', []))}

Output requirements:
- One centered full-body character sprite only.
- Suitable for animation inside a {canvas['cell_width']}x{canvas['cell_height']} cell.
- Use a perfectly flat chroma-key background: {canvas['chroma_key']}.
- Do not include scenery, UI, text, labels, borders, frame numbers, checkerboard transparency, shadows, glow halos, or extra props not described above.
- Do not use {canvas['chroma_key']} or colors close to it inside the character, weapon, highlights, shadows, or effects.
- Preserve a game-sprite silhouette rather than a pet mascot look unless the JSON explicitly asks for one.
""".strip()


def row_prompt(request: dict[str, Any], action: dict[str, Any]) -> str:
    c = request["character"]
    canvas = request["canvas"]
    return f"""
Create one horizontal animation row strip for the same 2D pixel-art game character.

Character id: {c['id']}
Display name: {c['display_name']}
Role: {c['role']}
Canonical identity: {c['description']}
Style notes: {c.get('style_notes') or 'Use the default style contract.'}
Animation id: {action['id']}
Animation prompt: {action.get('prompt', action['id'])}
Frame count: {action['frames']}
Target cell size: {canvas['cell_width']}x{canvas['cell_height']}
Chroma key background: {canvas['chroma_key']}

Identity lock:
- Use the attached canonical base image as the source of truth.
- Do not redesign the character.
- Preserve head shape, body proportions, face/mask, hair/horns/tail, weapon, armor, palette, outline weight, and silhouette.
- Keep every frame recognizably the same individual character.
- If a weapon or accessory exists, preserve its size, side, material, and attachment unless the action requires pose-only movement.

Must keep:
{list_text(c.get('must_keep', []))}

Must avoid:
{list_text(c.get('must_avoid', []))}

Layout requirements:
- Output exactly {action['frames']} complete full-body frames in a single horizontal row.
- Treat the image as {action['frames']} equal-width invisible frame slots.
- Center one complete pose in each slot.
- No pose may cross into a neighboring slot.
- Do not reproduce the layout guide: no visible boxes, guide lines, center marks, labels, or guide colors.
- Use a perfectly flat {canvas['chroma_key']} background across the whole row.
- Do not include scenery, UI, text, frame numbers, visible grids, checkerboard transparency, or watermarks.
- Avoid detached motion arcs, speed lines, soft glows, blurred smears, and shadows unless explicitly required by the JSON and still readable as pixel art.
- Prefer readable pose changes over decorative effects.

Style contract: {STYLE_CONTRACT}
""".strip()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, help="Path to character JSON spec")
    parser.add_argument("--output-dir", default="", help="Run directory. Defaults to ./output/2d-character-create/<id>-timestamp")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    spec_path = ensure_file(Path(args.spec), "spec")
    request = normalize_spec(read_json(spec_path))
    character_id = request["character"]["id"]
    timestamp = now_iso().replace(":", "").replace("+00:00", "Z")
    run_dir = Path(args.output_dir).expanduser().resolve() if args.output_dir else (Path.cwd() / "output" / "2d-character-create" / f"{character_id}-{timestamp}").resolve()
    if run_dir.exists() and any(run_dir.iterdir()) and not args.force:
        raise SystemExit(f"{run_dir} already exists and is not empty; pass --force to reuse it")

    for directory in ["references", "references/layout-guides", "prompts/rows", "decoded", "frames", "qa", "output", "package"]:
        (run_dir / directory).mkdir(parents=True, exist_ok=True)

    copied_refs = []
    for index, raw in enumerate(request["character"].get("references", []), start=1):
        src = ensure_file(Path(raw), f"reference {index}")
        dst = run_dir / "references" / f"reference-{index:02d}{src.suffix.lower()}"
        copy_image(src, dst)
        copied_refs.append({"source_path": str(src), "path": rel(dst, run_dir), "role": "character reference"})

    guides = []
    for action in request["animations"]:
        guide = create_layout_guide(run_dir / "references" / "layout-guides" / f"{action['id']}.png", action, request["canvas"])
        guide["path"] = rel(Path(guide["path"]), run_dir)
        guides.append(guide)

    request["schema_version"] = 1
    request["created_at"] = now_iso()
    request["source_spec"] = str(spec_path)
    request["references"] = copied_refs
    request["layout_guides"] = guides
    request["primary_generation_skill"] = "$imagegen"
    write_json(run_dir / "character_request.json", request)

    (run_dir / "prompts" / "base-character.md").write_text(base_prompt(request) + "\n", encoding="utf-8")
    for action in request["animations"]:
        (run_dir / "prompts" / "rows" / f"{action['id']}.md").write_text(row_prompt(request, action) + "\n", encoding="utf-8")

    reference_inputs = [{"path": item["path"], "role": item["role"]} for item in copied_refs]
    jobs = [{
        "id": "base",
        "kind": "base-character",
        "status": "pending",
        "prompt_file": "prompts/base-character.md",
        "input_images": reference_inputs,
        "output_path": "decoded/base.png",
        "depends_on": [],
        "generation_skill": "$imagegen",
        "requires_grounded_generation": bool(reference_inputs),
        "allow_prompt_only_generation": not bool(reference_inputs),
        "recording_owner": "parent"
    }]
    for action in request["animations"]:
        extra_inputs = []
        mirror_policy = {}
        if action.get("mirror_from"):
            extra_inputs.append({"path": f"decoded/{action['mirror_from']}.png", "role": f"source row for mirror decision: {action['mirror_from']}"})
            mirror_policy = {
                "may_derive_from": action["mirror_from"],
                "requires_explicit_approval": True,
                "fallback_generation_skill": "$imagegen"
            }
        jobs.append({
            "id": action["id"],
            "kind": "row-strip",
            "status": "pending",
            "prompt_file": f"prompts/rows/{action['id']}.md",
            "input_images": [
                *reference_inputs,
                {"path": "references/canonical-base.png", "role": "canonical identity reference"},
                {"path": "decoded/base.png", "role": "approved base character"},
                {"path": f"references/layout-guides/{action['id']}.png", "role": f"layout guide for {action['frames']} frame slots; do not copy lines"},
                *extra_inputs,
            ],
            "output_path": f"decoded/{action['id']}.png",
            "depends_on": ["base", *([action["mirror_from"]] if action.get("mirror_from") else [])],
            "generation_skill": "$imagegen",
            "requires_grounded_generation": True,
            "allow_prompt_only_generation": False,
            "mirror_policy": mirror_policy,
            "recording_owner": "parent"
        })
    write_json(run_dir / "imagegen-jobs.json", {"schema_version": 1, "created_at": now_iso(), "run_dir": str(run_dir), "primary_generation_skill": "$imagegen", "jobs": jobs})
    print({"ok": True, "run_dir": str(run_dir), "ready_jobs": ["base"]})


if __name__ == "__main__":
    main()
