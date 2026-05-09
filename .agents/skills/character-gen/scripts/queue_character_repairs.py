#!/usr/bin/env python3
"""Reopen failed animation row jobs after frame QA for a character-gen run."""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


def load_json(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def all_jobs(manifest: dict) -> list[dict]:
    jobs = manifest.get("jobs")
    if not isinstance(jobs, list):
        raise SystemExit("invalid imagegen-jobs.json")
    return [job for job in jobs if isinstance(job, dict)]


def rows_to_repair(review: dict, repair_on_warnings: bool) -> list[dict]:
    rows = review.get("rows")
    if not isinstance(rows, list):
        raise SystemExit("review does not contain row-level results")
    repairs = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        errors = row.get("errors") if isinstance(row.get("errors"), list) else []
        warnings = row.get("warnings") if isinstance(row.get("warnings"), list) else []
        if errors or (repair_on_warnings and warnings):
            repairs.append({
                "animation": row.get("animation") or row.get("state", ""),
                "reason": "; ".join(str(item) for item in [*errors, *warnings]) or "failed QA",
            })
    return repairs


def archive_decoded(run_dir: Path, job: dict, anim_name: str, attempt: int) -> str | None:
    output_raw = job.get("output_path")
    output = (
        run_dir / output_raw
        if isinstance(output_raw, str)
        else run_dir / "decoded" / f"{anim_name}.png"
    )
    if not output.exists():
        return None
    archive_dir = run_dir / "decoded" / "repair-archive"
    archive_dir.mkdir(parents=True, exist_ok=True)
    dest = archive_dir / f"{anim_name}-attempt-{attempt}-previous{output.suffix or '.png'}"
    counter = 2
    while dest.exists():
        dest = archive_dir / f"{anim_name}-attempt-{attempt}-previous-{counter}{output.suffix or '.png'}"
        counter += 1
    shutil.move(str(output), dest)
    return str(dest.relative_to(run_dir))


def queue_repair(manifest: dict, run_dir: Path, anim_name: str, reason: str) -> dict:
    for job in all_jobs(manifest):
        if job.get("id") != anim_name:
            continue
        attempt = int(job.get("repair_attempt", 0)) + 1
        archived = archive_decoded(run_dir, job, anim_name, attempt)

        job["status"] = "pending"
        job["repair_attempt"] = attempt
        job["repair_reason"] = reason
        job["queued_at"] = datetime.now(timezone.utc).isoformat()

        if archived:
            prev = job.setdefault("previous_outputs", [])
            if not isinstance(prev, list):
                prev = []
                job["previous_outputs"] = prev
            prev.append({"attempt": attempt, "path": archived, "archived_at": job["queued_at"]})

        for key in ["source_path", "source_provenance", "source_sha256", "output_sha256", "completed_at", "metadata", "synthetic_test_source"]:
            job.pop(key, None)

        return {"attempt": attempt, "archived_output": archived}

    raise SystemExit(f"unknown animation job id: {anim_name}")


def append_repair_note(run_dir: Path, anim_name: str, attempt: int, reason: str) -> None:
    prompt_path = run_dir / "prompts" / "rows" / f"{anim_name}.md"
    if not prompt_path.exists():
        raise SystemExit(f"row prompt not found: {prompt_path}")
    existing = prompt_path.read_text(encoding="utf-8")
    note = f"""

Repair attempt {attempt} — reason: {reason}

REPAIR REQUIREMENTS — these are mandatory additions to the original prompt above:
- The previous `{anim_name}` strip failed QA. Regenerate the entire row.
- Fill every requested frame slot with one complete full-body character pose.
- Anti-跑版 enforcement: the character's feet MUST be at the same Y position in every frame. Check each frame individually before returning.
- Same-scale enforcement: the character must appear the same height in all frames. Do not allow any frame to be larger or smaller.
- Use the canonical base image and original references listed in imagegen-jobs.json as grounding inputs.
- Preserve the exact character identity from the canonical base — same body, head, palette, outline, proportions. Do not redesign.
"""
    prompt_path.write_text(existing.rstrip() + note.rstrip() + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--review", default="", help="Path to review.json (default: qa/review.json)")
    parser.add_argument("--repair-on-warnings", action="store_true")
    args = parser.parse_args()

    run_dir = Path(args.run_dir).expanduser().resolve()
    review_path = (
        Path(args.review).expanduser().resolve() if args.review
        else run_dir / "qa" / "review.json"
    )
    manifest_path = run_dir / "imagegen-jobs.json"

    review = load_json(review_path)
    manifest = load_json(manifest_path)

    repairs = rows_to_repair(review, args.repair_on_warnings)
    if not repairs:
        print(json.dumps({"ok": True, "queued": [], "message": "No repairs needed."}))
        return

    queued = []
    for repair in repairs:
        anim_name = str(repair["animation"])
        reason = str(repair["reason"])
        result = queue_repair(manifest, run_dir, anim_name, reason)
        attempt = result["attempt"]
        append_repair_note(run_dir, anim_name, attempt, reason)
        queued.append({"animation": anim_name, "reason": reason, **result})

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "queued": queued}, indent=2))


if __name__ == "__main__":
    main()
