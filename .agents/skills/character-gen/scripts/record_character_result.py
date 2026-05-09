#!/usr/bin/env python3
"""Record a selected $imagegen output for a character-gen animation job."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

CANONICAL_BASE_PATH = "references/canonical-base.png"


def load_manifest(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"job manifest not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def all_jobs(manifest: dict) -> list[dict]:
    jobs = manifest.get("jobs")
    if not isinstance(jobs, list):
        raise SystemExit("invalid imagegen-jobs.json: jobs must be a list")
    return [job for job in jobs if isinstance(job, dict)]


def find_job(manifest: dict, job_id: str) -> dict:
    for job in all_jobs(manifest):
        if job.get("id") == job_id:
            return job
    raise SystemExit(f"unknown job id: {job_id}")


def completed_ids(manifest: dict) -> set[str]:
    return {
        str(job["id"])
        for job in all_jobs(manifest)
        if job.get("status") == "complete" and isinstance(job.get("id"), str)
    }


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def image_metadata(path: Path) -> dict:
    with Image.open(path) as img:
        img.verify()
    with Image.open(path) as img:
        return {"width": img.width, "height": img.height, "mode": img.mode, "format": img.format}


def manifest_relative(path: Path, run_dir: Path) -> str:
    return str(path.resolve().relative_to(run_dir.resolve()))


def is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def default_generated_images_root() -> Path:
    codex_home = Path(os.environ.get("CODEX_HOME") or "~/.codex").expanduser().resolve()
    return codex_home / "generated_images"


def validate_source(source: Path, run_dir: Path, allow_synthetic: bool) -> str:
    if allow_synthetic:
        return "synthetic-test"
    if is_relative_to(source, run_dir):
        raise SystemExit(
            "source is inside the run directory; record the original $imagegen output "
            "from $CODEX_HOME/generated_images/.../ig_*.png instead"
        )
    generated_root = default_generated_images_root()
    if not is_relative_to(source, generated_root) or not source.name.startswith("ig_"):
        raise SystemExit(
            f"source does not look like a built-in $imagegen output; expected "
            f"{generated_root}/.../ig_*.png"
        )
    return "built-in-imagegen"


def update_canonical_base(run_dir: Path, output: Path, manifest: dict, job: dict, metadata: dict) -> None:
    if job.get("id") != "base":
        return
    canonical = run_dir / CANONICAL_BASE_PATH
    canonical.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(output, canonical)
    sha = file_sha256(canonical)
    reference = {
        "path": manifest_relative(canonical, run_dir),
        "source_job": "base",
        "sha256": sha,
        "metadata": metadata,
    }
    job["canonical_reference_path"] = reference["path"]
    manifest["canonical_identity_reference"] = reference

    request_path = run_dir / "character_request.json"
    if request_path.exists():
        request = json.loads(request_path.read_text(encoding="utf-8"))
        request["canonical_identity_reference"] = reference
        request_path.write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--job-id", required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--allow-synthetic-test-source", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    source = Path(args.source).expanduser().resolve()

    if not source.is_file():
        raise SystemExit(f"source image not found: {source}")

    provenance = validate_source(source, run_dir, args.allow_synthetic_test_source)

    manifest_path = run_dir / "imagegen-jobs.json"
    manifest = load_manifest(manifest_path)
    job = find_job(manifest, args.job_id)

    missing = [
        dep for dep in job.get("depends_on", [])
        if isinstance(dep, str) and dep not in completed_ids(manifest)
    ]
    if missing:
        raise SystemExit(f"job {args.job_id} is not ready; missing: {', '.join(missing)}")

    output_raw = job.get("output_path")
    if not isinstance(output_raw, str):
        raise SystemExit(f"job {args.job_id} has no output_path")
    output = run_dir / output_raw
    if output.exists() and not args.force:
        raise SystemExit(f"{output} already exists; pass --force to replace it")

    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, output)
    metadata = image_metadata(output)

    job["status"] = "complete"
    job["source_path"] = str(source)
    job["source_provenance"] = provenance
    job["source_sha256"] = file_sha256(source)
    job["output_sha256"] = file_sha256(output)
    if provenance == "synthetic-test":
        job["synthetic_test_source"] = True
    else:
        job.pop("synthetic_test_source", None)
    job["completed_at"] = datetime.now(timezone.utc).isoformat()
    job["metadata"] = metadata
    for key in ["last_error", "repair_reason", "queued_at"]:
        job.pop(key, None)

    update_canonical_base(run_dir, output, manifest, job, metadata)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    print(json.dumps({
        "ok": True,
        "job_id": args.job_id,
        "output": str(output),
        "metadata": metadata,
    }, indent=2))


if __name__ == "__main__":
    main()
