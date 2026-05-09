#!/usr/bin/env python3
"""Create targeted repair prompts from QA review errors/warnings."""
from __future__ import annotations

import argparse
from pathlib import Path

from _character_lib import load_request, read_json, write_json


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True)
    args = parser.parse_args()
    run_dir = Path(args.run_dir).expanduser().resolve()
    request = load_request(run_dir)
    review_path = run_dir / "qa" / "review.json"
    if not review_path.is_file():
        raise SystemExit("run validate_spritesheet.py first")
    review = read_json(review_path)
    repairs = []
    for action in request["animations"]:
        action_id = action["id"]
        related = [msg for msg in review.get("errors", []) + review.get("warnings", []) if action_id in msg]
        if related:
            prompt = run_dir / "prompts" / "repairs" / f"{action_id}.md"
            prompt.parent.mkdir(parents=True, exist_ok=True)
            prompt.write_text(
                f"Regenerate only animation row `{action_id}` for the same character.\n"
                f"Use the canonical base and original row prompt. Fix these QA issues:\n"
                + "\n".join(f"- {item}" for item in related)
                + "\nPreserve identity and layout exactly.\n",
                encoding="utf-8"
            )
            repairs.append({"action_id": action_id, "prompt_file": str(prompt.relative_to(run_dir)), "issues": related})
    write_json(run_dir / "qa" / "repairs.json", {"repairs": repairs})
    print({"ok": True, "repair_count": len(repairs)})


if __name__ == "__main__":
    main()
