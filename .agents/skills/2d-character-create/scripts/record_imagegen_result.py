#!/usr/bin/env python3
"""Record a selected $imagegen output into a character run."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from _character_lib import copy_image, find_job, load_jobs, now_iso, rel, save_jobs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--job-id", required=True)
    parser.add_argument("--image", required=True)
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    src = Path(args.image).expanduser().resolve()
    if not src.is_file():
        raise SystemExit(f"image not found: {src}")
    jobs = load_jobs(run_dir)
    job = find_job(jobs, args.job_id)
    dst = run_dir / job["output_path"]
    copy_image(src, dst)
    # Normalize to PNG for deterministic downstream scripts.
    if dst.suffix.lower() != ".png":
        with Image.open(dst) as im:
            png_dst = dst.with_suffix(".png")
            im.convert("RGBA").save(png_dst)
        dst.unlink()
        dst = png_dst
        job["output_path"] = rel(dst, run_dir)
    if args.job_id == "base":
        canonical = run_dir / "references" / "canonical-base.png"
        with Image.open(dst) as im:
            im.convert("RGBA").save(canonical)
    job["status"] = "recorded"
    job["recorded_at"] = now_iso()
    job["recorded_source"] = str(src)
    job["output_path"] = rel(dst, run_dir)
    save_jobs(run_dir, jobs)
    print({"ok": True, "job_id": args.job_id, "output": str(dst)})


if __name__ == "__main__":
    main()
