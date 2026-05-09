#!/usr/bin/env python3
"""Show ready and pending $imagegen jobs for a character-gen run."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_manifest(run_dir: Path) -> dict:
    path = run_dir / "imagegen-jobs.json"
    if not path.exists():
        raise SystemExit(f"job manifest not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def all_jobs(manifest: dict) -> list[dict]:
    raw = manifest.get("jobs")
    if not isinstance(raw, list):
        raise SystemExit("invalid imagegen-jobs.json: jobs must be a list")
    return [job for job in raw if isinstance(job, dict)]


def completed_ids(manifest: dict) -> set[str]:
    return {
        str(job["id"])
        for job in all_jobs(manifest)
        if job.get("status") == "complete" and isinstance(job.get("id"), str)
    }


def missing_deps(job: dict, completed: set[str]) -> list[str]:
    deps = job.get("depends_on", [])
    if not isinstance(deps, list):
        return []
    return [dep for dep in deps if isinstance(dep, str) and dep not in completed]


def job_view(job: dict, run_dir: Path, completed: set[str]) -> dict:
    inputs = job.get("input_images") if isinstance(job.get("input_images"), list) else []
    input_images = []
    for item in inputs:
        path = (
            run_dir / item["path"]
            if isinstance(item, dict) and isinstance(item.get("path"), str)
            else None
        )
        input_images.append({
            "path": str(path) if path else None,
            "role": item.get("role") if isinstance(item, dict) else None,
            "exists": path.is_file() if path else False,
        })

    prompt_file = job.get("prompt_file")
    output_path = job.get("output_path")
    return {
        "id": job.get("id"),
        "kind": job.get("kind"),
        "status": job.get("status", "pending"),
        "prompt_file": str(run_dir / prompt_file) if isinstance(prompt_file, str) else None,
        "input_images": input_images,
        "output_path": str(run_dir / output_path) if isinstance(output_path, str) else None,
        "missing_dependencies": missing_deps(job, completed),
        "repair_attempt": job.get("repair_attempt", 0),
        "frames": job.get("frames"),
        "cell": job.get("cell"),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    manifest = load_manifest(run_dir)
    completed = completed_ids(manifest)
    pending = [job for job in all_jobs(manifest) if job.get("status", "pending") != "complete"]
    ready = [job for job in pending if not missing_deps(job, completed)]
    blocked = [job for job in pending if missing_deps(job, completed)]

    result = {
        "ok": True,
        "run_dir": str(run_dir),
        "counts": {
            "total": len(all_jobs(manifest)),
            "complete": len(completed),
            "ready": len(ready),
            "blocked": len(blocked),
        },
        "ready_jobs": [job_view(job, run_dir, completed) for job in ready],
        "blocked_jobs": [job_view(job, run_dir, completed) for job in blocked],
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
