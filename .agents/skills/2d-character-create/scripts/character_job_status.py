#!/usr/bin/env python3
"""Print pending/ready/done imagegen jobs for a run."""
from __future__ import annotations

import argparse
from pathlib import Path

from _character_lib import load_jobs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    args = parser.parse_args()
    jobs = load_jobs(Path(args.run_dir).expanduser().resolve())
    done = {job["id"] for job in jobs.get("jobs", []) if job.get("status") in {"recorded", "complete"}}
    for job in jobs.get("jobs", []):
        deps = set(job.get("depends_on", []))
        ready = deps.issubset(done) and job.get("status") == "pending"
        print(f"{job['id']}: status={job.get('status')} ready={ready} deps={','.join(job.get('depends_on', [])) or '-'} prompt={job.get('prompt_file')}")


if __name__ == "__main__":
    main()
