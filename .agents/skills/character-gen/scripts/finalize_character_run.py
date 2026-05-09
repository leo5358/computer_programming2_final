#!/usr/bin/env python3
"""Finalize a character-gen run: extract frames, compose atlas, export Godot metadata, and QA."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_json(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def default_generated_images_root() -> Path:
    codex_home = Path(os.environ.get("CODEX_HOME") or "~/.codex").expanduser().resolve()
    return codex_home / "generated_images"


def parse_hex_color(value: str) -> tuple[int, int, int]:
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise SystemExit(f"invalid chroma key: {value}")
    return tuple(int(value[i: i + 2], 16) for i in (1, 3, 5))


# ---------------------------------------------------------------------------
# Job validation
# ---------------------------------------------------------------------------

def validate_completed_jobs(manifest: dict, run_dir: Path) -> None:
    jobs = manifest.get("jobs")
    if not isinstance(jobs, list):
        raise SystemExit("invalid imagegen-jobs.json")

    incomplete = [
        str(job.get("id"))
        for job in jobs
        if isinstance(job, dict) and job.get("status", "pending") != "complete"
    ]
    if incomplete:
        raise SystemExit(
            "not all jobs are complete; run character_job_status.py and finish: "
            + ", ".join(incomplete)
        )

    generated_root = default_generated_images_root()
    for job in jobs:
        if not isinstance(job, dict):
            continue
        job_id = str(job.get("id") or "")
        provenance = job.get("source_provenance", "")
        source_raw = job.get("source_path", "")
        output_raw = job.get("output_path", "")

        if not source_raw or not output_raw:
            raise SystemExit(f"job {job_id} is missing source_path or output_path")

        source = Path(source_raw).expanduser().resolve()
        output = run_dir / output_raw if not Path(output_raw).is_absolute() else Path(output_raw)

        if provenance == "synthetic-test":
            pass
        elif provenance == "built-in-imagegen":
            if is_relative_to(source, run_dir):
                raise SystemExit(f"job {job_id} source is inside the run directory")
            if not is_relative_to(source, generated_root) or not source.name.startswith("ig_"):
                raise SystemExit(f"job {job_id} source is not a built-in imagegen output")
        else:
            raise SystemExit(
                f"job {job_id} has unknown provenance '{provenance}'; "
                "record with record_character_result.py"
            )

        expected_sha = job.get("source_sha256", "")
        if not expected_sha:
            raise SystemExit(f"job {job_id} is missing source_sha256")
        if not source.is_file():
            raise SystemExit(f"job {job_id} source image no longer exists: {source}")
        if not output.is_file():
            raise SystemExit(f"job {job_id} decoded output is missing: {output}")
        if file_sha256(source) != expected_sha:
            raise SystemExit(f"job {job_id} source hash mismatch — do not edit source files")
        if file_sha256(output) != expected_sha:
            raise SystemExit(f"job {job_id} decoded output hash mismatch — do not edit decoded files")


# ---------------------------------------------------------------------------
# Frame extraction — slot-based only, no rescaling (anti-跑版)
# ---------------------------------------------------------------------------

def color_distance(r: int, g: int, b: int, key: tuple[int, int, int]) -> float:
    import math
    return math.sqrt((r - key[0]) ** 2 + (g - key[1]) ** 2 + (b - key[2]) ** 2)


def remove_chroma(image: Image.Image, chroma_key: tuple[int, int, int], threshold: float) -> Image.Image:
    rgba = image.convert("RGBA")
    data = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = data[x, y]
            if color_distance(r, g, b, chroma_key) <= threshold:
                data[x, y] = (r, g, b, 0)
    return rgba


def normalize_strip(strip: Image.Image, expected_w: int, expected_h: int, anim_name: str) -> tuple[Image.Image, str | None]:
    """Resize strip to exact expected dimensions if within tolerance (±8px), else error."""
    w, h = strip.size
    if w == expected_w and h == expected_h:
        return strip, None
    tol = 8
    if abs(w - expected_w) <= tol and abs(h - expected_h) <= tol:
        resized = strip.resize((expected_w, expected_h), Image.Resampling.NEAREST)
        note = f"strip normalized from {w}×{h} to {expected_w}×{expected_h}"
        return resized, note
    raise SystemExit(
        f"decoded/{anim_name}.png is {w}×{h} but expected {expected_w}×{expected_h}; "
        "regenerate with the exact canvas size constraint"
    )


def extract_slots(strip: Image.Image, frames: int, cell_w: int, cell_h: int) -> list[Image.Image]:
    """Fixed-width slot extraction. No rescaling, no recentering. Preserves anchor position."""
    results = []
    for i in range(frames):
        left = round(i * cell_w)
        right = round((i + 1) * cell_w)
        crop = strip.crop((left, 0, right, cell_h))
        cell = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        cell.paste(crop.convert("RGBA"), (0, 0))
        results.append(cell)
    return results


def inspect_frame(frame: Image.Image, frame_idx: int, anim_name: str) -> list[str]:
    errors = []
    alpha = frame.getchannel("A")
    data = alpha.tobytes()
    opaque = sum(1 for b in data if b > 16)
    total = len(data)
    if opaque < total * 0.01:
        errors.append(f"frame {frame_idx:02d} appears nearly empty (>99% transparent)")
    if opaque > total * 0.99:
        errors.append(f"frame {frame_idx:02d} chroma key may not have been removed (>99% opaque)")
    return errors


def extract_animation(
    decoded_dir: Path,
    frames_root: Path,
    anim: dict,
    cell_w: int,
    cell_h: int,
    chroma_key: tuple[int, int, int],
    chroma_threshold: float,
) -> dict:
    anim_name = anim["name"]
    frames = anim["frames"]
    strip_path = decoded_dir / f"{anim_name}.png"

    if not strip_path.is_file():
        raise SystemExit(f"decoded/{anim_name}.png not found")

    with Image.open(strip_path) as img:
        strip = img.copy()

    strip, normalize_note = normalize_strip(strip, frames * cell_w, cell_h, anim_name)
    strip = remove_chroma(strip, chroma_key, chroma_threshold)
    frame_images = extract_slots(strip, frames, cell_w, cell_h)

    anim_dir = frames_root / anim_name
    anim_dir.mkdir(parents=True, exist_ok=True)

    errors = []
    frame_paths = []
    for idx, frame_img in enumerate(frame_images):
        frame_errors = inspect_frame(frame_img, idx, anim_name)
        errors.extend(frame_errors)
        out = anim_dir / f"{idx:02d}.png"
        frame_img.save(out, format="PNG")
        frame_paths.append(str(out))

    return {
        "animation": anim_name,
        "frames": frames,
        "cell": {"width": cell_w, "height": cell_h},
        "frame_paths": frame_paths,
        "errors": errors,
        "normalize_note": normalize_note,
        "ok": len(errors) == 0,
    }


# ---------------------------------------------------------------------------
# Atlas composition
# ---------------------------------------------------------------------------

def compose_atlas(
    animations: list[dict],
    frames_root: Path,
    cell_w: int,
    cell_h: int,
    columns: int,
) -> Image.Image:
    rows = len(animations)
    atlas_w = columns * cell_w
    atlas_h = rows * cell_h
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))

    for row_idx, anim in enumerate(animations):
        anim_name = anim["name"]
        frames = anim["frames"]
        anim_dir = frames_root / anim_name
        y_offset = row_idx * cell_h
        for frame_idx in range(frames):
            frame_path = anim_dir / f"{frame_idx:02d}.png"
            if not frame_path.is_file():
                raise SystemExit(f"missing frame: {frame_path}")
            with Image.open(frame_path) as frame_img:
                x_offset = frame_idx * cell_w
                atlas.alpha_composite(frame_img.convert("RGBA"), (x_offset, y_offset))

    return atlas


# ---------------------------------------------------------------------------
# Godot animations.json
# ---------------------------------------------------------------------------

def build_godot_metadata(
    name: str,
    animations: list[dict],
    cell_w: int,
    cell_h: int,
    columns: int,
    spec: dict,
) -> dict:
    anim_meta: dict[str, dict] = {}
    for row_idx, anim in enumerate(animations):
        frames = anim["frames"]
        fps = anim["fps"]
        loop = anim["loop"]
        rects = [
            {"x": f * cell_w, "y": row_idx * cell_h, "w": cell_w, "h": cell_h}
            for f in range(frames)
        ]
        anim_meta[anim["name"]] = {
            "row": row_idx,
            "frames": frames,
            "fps": fps,
            "loop": loop,
            "rects": rects,
        }

    return {
        "image": f"{name}_spritesheet.png",
        "cell_width": cell_w,
        "cell_height": cell_h,
        "columns": columns,
        "rows": len(animations),
        "animations": anim_meta,
    }


# ---------------------------------------------------------------------------
# QA: contact sheet
# ---------------------------------------------------------------------------

def make_contact_sheet(
    atlas: Image.Image,
    animations: list[dict],
    cell_w: int,
    cell_h: int,
    columns: int,
    output_path: Path,
) -> None:
    label_h = 14
    padding = 4
    sheet_w = columns * cell_w + padding * 2
    sheet_h = len(animations) * (cell_h + label_h) + padding * 2
    sheet = Image.new("RGB", (sheet_w, sheet_h), "#1a1a2e")
    draw = ImageDraw.Draw(sheet)

    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Courier New.ttf", 11)
    except Exception:
        font = ImageFont.load_default()

    for row_idx, anim in enumerate(animations):
        y = padding + row_idx * (cell_h + label_h)
        label = f"{anim['name']}  {anim['frames']}fr @ {anim['fps']}fps {'loop' if anim['loop'] else 'once'}"
        draw.text((padding + 2, y), label, fill="#7ecfff", font=font)
        y_atlas = row_idx * cell_h
        for col_idx in range(anim["frames"]):
            x_atlas = col_idx * cell_w
            cell_crop = atlas.crop((x_atlas, y_atlas, x_atlas + cell_w, y_atlas + cell_h))
            bg = Image.new("RGB", (cell_w, cell_h), "#2a2a4a")
            bg.paste(cell_crop.convert("RGB"), (0, 0), cell_crop.convert("RGBA").getchannel("A"))
            sheet.paste(bg, (padding + col_idx * cell_w, y + label_h))
        draw.rectangle(
            [padding, y + label_h, padding + anim["frames"] * cell_w - 1, y + label_h + cell_h - 1],
            outline="#444466",
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(str(output_path))


# ---------------------------------------------------------------------------
# QA: GIF previews
# ---------------------------------------------------------------------------

def make_gif_preview(
    atlas: Image.Image,
    anim: dict,
    row_idx: int,
    cell_w: int,
    cell_h: int,
    output_path: Path,
) -> None:
    frames_count = anim["frames"]
    fps = anim["fps"]
    duration_ms = max(33, round(1000 / fps))
    y_offset = row_idx * cell_h
    frames = []
    for f in range(frames_count):
        x_offset = f * cell_w
        crop = atlas.crop((x_offset, y_offset, x_offset + cell_w, y_offset + cell_h))
        bg = Image.new("RGBA", (cell_w, cell_h), (40, 40, 60, 255))
        bg.alpha_composite(crop.convert("RGBA"))
        frames.append(bg.convert("P", palette=Image.Palette.ADAPTIVE))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    if frames:
        frames[0].save(
            output_path,
            save_all=True,
            append_images=frames[1:],
            duration=duration_ms,
            loop=0,
        )


# ---------------------------------------------------------------------------
# Atlas validation
# ---------------------------------------------------------------------------

def validate_atlas(atlas: Image.Image, animations: list[dict], cell_w: int, cell_h: int, columns: int) -> dict:
    errors = []
    warnings = []

    expected_w = columns * cell_w
    expected_h = len(animations) * cell_h
    if atlas.size != (expected_w, expected_h):
        errors.append(f"atlas is {atlas.size} but expected ({expected_w}, {expected_h})")

    alpha = atlas.getchannel("A")
    for row_idx, anim in enumerate(animations):
        y = row_idx * cell_h
        for f in range(anim["frames"]):
            x = f * cell_w
            cell_alpha = alpha.crop((x, y, x + cell_w, y + cell_h))
            data = cell_alpha.tobytes()
            opaque = sum(1 for b in data if b > 16)
            if opaque < len(data) * 0.005:
                errors.append(f"{anim['name']} frame {f:02d} appears empty in atlas")
        for f in range(anim["frames"], columns):
            x = f * cell_w
            cell_alpha = alpha.crop((x, y, x + cell_w, y + cell_h))
            data = cell_alpha.tobytes()
            opaque = sum(1 for b in data if b > 16)
            if opaque > 0:
                warnings.append(f"{anim['name']} unused slot {f} is not fully transparent")

    return {"ok": len(errors) == 0, "errors": errors, "warnings": warnings}


# ---------------------------------------------------------------------------
# QA: identity check (palette overlap + intra-row size consistency)
# ---------------------------------------------------------------------------

_PALETTE_WARN = 0.55   # overlap below this → warning
_PALETTE_ERROR = 0.40  # overlap below this → error (reported as warning in finalize)
_SIZE_SMALL = 0.30     # frame smaller than 30% of row median → warning
_SIZE_LARGE = 3.0      # frame larger than 300% of row median → warning


def _color_buckets(image: Image.Image, chroma_key: tuple[int, int, int], chroma_threshold: float) -> frozenset:
    """Extract 16-unit quantized color buckets from opaque, non-chroma pixels."""
    rgba = image.convert("RGBA")
    data = rgba.tobytes()
    buckets: set = set()
    for i in range(0, len(data), 4):
        r, g, b, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        if a < 16:
            continue
        if color_distance(r, g, b, chroma_key) < chroma_threshold:
            continue
        buckets.add((r >> 4, g >> 4, b >> 4))
    return frozenset(buckets)


def _palette_overlap(base: frozenset, row: frozenset) -> float:
    if not base:
        return 1.0
    return len(base & row) / len(base)


def _frame_area(cell: Image.Image, chroma_key: tuple[int, int, int], chroma_threshold: float) -> int:
    rgba = cell.convert("RGBA")
    data = rgba.tobytes()
    count = 0
    for i in range(0, len(data), 4):
        r, g, b, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        if a >= 16 and color_distance(r, g, b, chroma_key) >= chroma_threshold:
            count += 1
    return count


def check_row_identity(
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
        return {"animation": anim_name, "palette_overlap": None, "errors": [f"decoded/{anim_name}.png not found"], "warnings": [], "ok": False}

    with Image.open(strip_path) as img:
        strip = img.copy().convert("RGBA")

    row_buckets = _color_buckets(strip, chroma_key, chroma_threshold)
    overlap = _palette_overlap(base_buckets, row_buckets)

    if overlap < _PALETTE_ERROR:
        errors.append(f"palette overlap {overlap:.0%} < {_PALETTE_ERROR:.0%} — likely identity drift; regenerate and compare against canonical-base")
    elif overlap < _PALETTE_WARN:
        warnings.append(f"palette overlap {overlap:.0%} < {_PALETTE_WARN:.0%} — review contact sheet for identity drift")

    expected_w = frames * cell_w
    areas: list[int] = []
    if abs(strip.width - expected_w) <= 8 and abs(strip.height - cell_h) <= 8:
        normalized = strip if (strip.width == expected_w and strip.height == cell_h) else strip.resize((expected_w, cell_h), Image.Resampling.NEAREST)
        for i in range(frames):
            cell = normalized.crop((i * cell_w, 0, (i + 1) * cell_w, cell_h))
            areas.append(_frame_area(cell, chroma_key, chroma_threshold))
        if areas:
            median_area = sorted(areas)[len(areas) // 2]
            for i, area in enumerate(areas):
                if median_area > 0 and area < median_area * _SIZE_SMALL:
                    warnings.append(f"frame {i:02d} area {area} << row median {median_area} — possible missing pose or scale drift")
                if median_area > 0 and area > median_area * _SIZE_LARGE:
                    warnings.append(f"frame {i:02d} area {area} >> row median {median_area} — possible scale drift")

    return {
        "animation": anim_name,
        "palette_overlap": round(overlap, 3),
        "frame_areas": areas,
        "errors": errors,
        "warnings": warnings,
        "ok": len(errors) == 0,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--key-threshold", type=float, default=96.0, help="Chroma key distance threshold")
    parser.add_argument("--skip-previews", action="store_true")
    parser.add_argument("--allow-synthetic-test-sources", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    spec_path = run_dir / "asset_spec.json"
    request_path = run_dir / "character_request.json"
    manifest_path = run_dir / "imagegen-jobs.json"

    if not spec_path.is_file():
        raise SystemExit(f"asset_spec.json not found in {run_dir}")

    spec = load_json(spec_path)
    request = load_json(request_path) if request_path.exists() else {}
    manifest = load_json(manifest_path)

    name = spec["name"]
    cell_w = spec["cell"]["width"]
    cell_h = spec["cell"]["height"]
    animations = spec["animations"]
    columns = spec.get("columns", max(a["frames"] for a in animations))

    chroma_info = request.get("chroma_key") or {}
    chroma_hex = chroma_info.get("hex") if isinstance(chroma_info, dict) else None
    if not chroma_hex:
        chroma_hex = spec.get("chroma_key", "#FF00FF")
    chroma_key = parse_hex_color(chroma_hex)

    if not args.allow_synthetic_test_sources:
        validate_completed_jobs(manifest, run_dir)

    decoded_dir = run_dir / "decoded"
    frames_root = run_dir / "frames"
    final_dir = run_dir / "final"
    qa_dir = run_dir / "qa"
    for d in [frames_root, final_dir, qa_dir]:
        d.mkdir(parents=True, exist_ok=True)

    print("Extracting frames...")
    extraction_results = []
    review_rows = []
    normalization_log = []
    for anim in animations:
        result = extract_animation(decoded_dir, frames_root, anim, cell_w, cell_h, chroma_key, args.key_threshold)
        extraction_results.append(result)
        if result.get("normalize_note"):
            normalization_log.append({"animation": anim["name"], "note": result["normalize_note"]})
        review_rows.append({
            "animation": anim["name"],
            "frames": anim["frames"],
            "errors": result["errors"],
            "warnings": [],
            "ok": result["ok"],
        })

    frames_manifest = {
        "ok": True,
        "chroma_key": {"hex": chroma_hex, "rgb": list(chroma_key), "threshold": args.key_threshold},
        "animations": [
            {"animation": r["animation"], "frames": r["frames"], "method": "slots"} for r in extraction_results
        ],
    }
    (frames_root / "frames-manifest.json").write_text(
        json.dumps(frames_manifest, indent=2) + "\n", encoding="utf-8"
    )

    print("Checking identity consistency...")
    identity_rows: list[dict] = []
    base_path = run_dir / "references" / "canonical-base.png"
    if base_path.is_file():
        with Image.open(base_path) as img:
            base_buckets = _color_buckets(img.copy(), chroma_key, args.key_threshold)
        for anim in animations:
            strip_path = decoded_dir / f"{anim['name']}.png"
            id_result = check_row_identity(strip_path, base_buckets, anim, cell_w, cell_h, chroma_key, args.key_threshold)
            identity_rows.append(id_result)
            for row in review_rows:
                if row["animation"] == anim["name"]:
                    row["warnings"].extend(id_result["warnings"])
                    if id_result["errors"]:
                        row["warnings"].extend([f"[identity] {e}" for e in id_result["errors"]])
                    break
        identity_check = {
            "ok": all(r["ok"] for r in identity_rows),
            "canonical_base": "references/canonical-base.png",
            "palette_thresholds": {"warn": _PALETTE_WARN, "error": _PALETTE_ERROR},
            "rows": identity_rows,
        }
        (qa_dir / "identity-check.json").write_text(json.dumps(identity_check, indent=2) + "\n", encoding="utf-8")
    else:
        print("  canonical-base.png not found; skipping identity check")

    review = {
        "ok": all(r["ok"] for r in extraction_results),
        "rows": review_rows,
        "normalization": normalization_log,
    }
    review_path = qa_dir / "review.json"
    review_path.write_text(json.dumps(review, indent=2) + "\n", encoding="utf-8")

    if not review["ok"]:
        failures = [
            f"{row['animation']}: {'; '.join(row['errors'])}"
            for row in review_rows
            if row["errors"]
        ]
        print(json.dumps({
            "ok": False,
            "review": str(review_path),
            "repair_hint": "Run queue_character_repairs.py, regenerate failing rows with $imagegen, then finalize again.",
            "failures": failures,
        }, indent=2))
        raise SystemExit(1)

    print("Composing atlas...")
    atlas = compose_atlas(animations, frames_root, cell_w, cell_h, columns)
    atlas_path = final_dir / f"{name}_spritesheet.png"
    atlas.save(str(atlas_path), format="PNG")

    godot_meta = build_godot_metadata(name, animations, cell_w, cell_h, columns, spec)
    meta_path = final_dir / f"{name}_animations.json"
    meta_path.write_text(json.dumps(godot_meta, indent=2) + "\n", encoding="utf-8")

    validation = validate_atlas(atlas, animations, cell_w, cell_h, columns)
    validation_path = final_dir / "validation.json"
    validation_path.write_text(json.dumps(validation, indent=2) + "\n", encoding="utf-8")

    if not validation["ok"]:
        print(json.dumps({
            "ok": False,
            "validation": str(validation_path),
            "errors": validation["errors"],
            "repair_hint": "Fix the listed errors and finalize again.",
        }, indent=2))
        raise SystemExit(1)

    print("Generating QA contact sheet...")
    contact_sheet_path = qa_dir / "contact-sheet.png"
    make_contact_sheet(atlas, animations, cell_w, cell_h, columns, contact_sheet_path)

    if not args.skip_previews:
        print("Generating GIF previews...")
        previews_dir = qa_dir / "previews"
        previews_dir.mkdir(exist_ok=True)
        for row_idx, anim in enumerate(animations):
            gif_path = previews_dir / f"{anim['name']}.gif"
            make_gif_preview(atlas, anim, row_idx, cell_w, cell_h, gif_path)

    summary = {
        "ok": True,
        "run_dir": str(run_dir),
        "name": name,
        "cell": {"width": cell_w, "height": cell_h},
        "atlas": str(atlas_path),
        "animations_json": str(meta_path),
        "validation": str(validation_path),
        "contact_sheet": str(contact_sheet_path),
        "previews": None if args.skip_previews else str(qa_dir / "previews"),
        "animation_count": len(animations),
        "validation_warnings": validation.get("warnings", []),
        "identity_check": str(qa_dir / "identity-check.json") if identity_rows else None,
        "identity_ok": all(r["ok"] for r in identity_rows) if identity_rows else None,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    summary_path = qa_dir / "run-summary.json"
    summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
