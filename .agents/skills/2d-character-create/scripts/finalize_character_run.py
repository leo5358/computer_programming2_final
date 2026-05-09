#!/usr/bin/env python3
"""Run the deterministic finalization steps in order."""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    args = parser.parse_args()
    script_dir = Path(__file__).resolve().parent
    run_dir = Path(args.run_dir).expanduser().resolve()
    py = "python"
    run([py, str(script_dir / "extract_strip_frames.py"), "--run-dir", str(run_dir), "--all"])
    run([py, str(script_dir / "compose_spritesheet.py"), "--run-dir", str(run_dir)])
    run([py, str(script_dir / "make_contact_sheet.py"), "--run-dir", str(run_dir)])
    run([py, str(script_dir / "inspect_frames.py"), "--run-dir", str(run_dir)])
    run([py, str(script_dir / "validate_spritesheet.py"), "--run-dir", str(run_dir)])
    run([py, str(script_dir / "render_animation_videos.py"), "--run-dir", str(run_dir)])
    run([py, str(script_dir / "package_godot_assets.py"), "--run-dir", str(run_dir)])


if __name__ == "__main__":
    main()
