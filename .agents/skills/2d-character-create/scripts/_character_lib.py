from __future__ import annotations

import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

IMAGE_SUFFIXES = {".png", ".webp", ".jpg", ".jpeg"}
DEFAULT_CHROMA_KEY = "#FF00FF"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def slugify(value: str, default: str = "character") -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-{2,}", "-", value).strip("-")
    return value or default


def ensure_file(path: Path, label: str = "file") -> Path:
    path = path.expanduser().resolve()
    if not path.is_file():
        raise SystemExit(f"{label} not found: {path}")
    return path


def ensure_dir(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def load_request(run_dir: Path) -> dict[str, Any]:
    request_path = run_dir / "character_request.json"
    if not request_path.is_file():
        raise SystemExit(f"missing request: {request_path}")
    return read_json(request_path)


def load_jobs(run_dir: Path) -> dict[str, Any]:
    jobs_path = run_dir / "imagegen-jobs.json"
    if not jobs_path.is_file():
        raise SystemExit(f"missing jobs manifest: {jobs_path}")
    return read_json(jobs_path)


def save_jobs(run_dir: Path, jobs: dict[str, Any]) -> None:
    write_json(run_dir / "imagegen-jobs.json", jobs)


def find_job(jobs: dict[str, Any], job_id: str) -> dict[str, Any]:
    for job in jobs.get("jobs", []):
        if job.get("id") == job_id:
            return job
    raise SystemExit(f"job not found: {job_id}")


def get_canvas(request: dict[str, Any]) -> dict[str, Any]:
    canvas = request.get("canvas", {})
    return {
        "cell_width": int(canvas.get("cell_width", 96)),
        "cell_height": int(canvas.get("cell_height", 96)),
        "columns": int(canvas.get("columns", 1)),
        "rows": int(canvas.get("rows", len(request.get("animations", [])))),
        "background": canvas.get("background", "transparent"),
        "chroma_key": canvas.get("chroma_key", DEFAULT_CHROMA_KEY),
        "padding": int(canvas.get("padding", 0)),
    }


def rel(path: Path, root: Path) -> str:
    return str(path.resolve().relative_to(root.resolve()))


def copy_image(src: Path, dst: Path) -> Path:
    if src.suffix.lower() not in IMAGE_SUFFIXES:
        raise SystemExit(f"unsupported image suffix for {src}; expected one of {sorted(IMAGE_SUFFIXES)}")
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return dst


def action_by_id(request: dict[str, Any], action_id: str) -> dict[str, Any]:
    for action in request.get("animations", []):
        if action.get("id") == action_id:
            return action
    raise SystemExit(f"animation not found in request: {action_id}")


def frame_path(run_dir: Path, action_id: str, index: int) -> Path:
    return run_dir / "frames" / action_id / f"{action_id}_{index:03d}.png"


def chroma_to_rgba(pixel: tuple[int, int, int, int], key: tuple[int, int, int], tolerance: int) -> tuple[int, int, int, int]:
    r, g, b, a = pixel
    if a == 0:
        return pixel
    if abs(r - key[0]) <= tolerance and abs(g - key[1]) <= tolerance and abs(b - key[2]) <= tolerance:
        return (r, g, b, 0)
    return pixel


def parse_hex_color(value: str) -> tuple[int, int, int]:
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value or ""):
        raise SystemExit(f"invalid hex color: {value}; expected #RRGGBB")
    return tuple(int(value[i:i+2], 16) for i in (1, 3, 5))
