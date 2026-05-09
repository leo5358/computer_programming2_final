# 2D-character-create

A reusable Codex skill for JSON-configured 2D pixel game character spritesheets.

Install by copying this folder into:

```text
${CODEX_HOME:-$HOME/.codex}/skills/2D-character-create
```

Start with one of:

```bash
python scripts/prepare_character_run.py --spec examples/protagonist.json --output-dir /tmp/swordsman-run
python scripts/prepare_character_run.py --spec examples/small-enemy.json --output-dir /tmp/enemy-run
python scripts/prepare_character_run.py --spec examples/boss.json --output-dir /tmp/boss-run
```

Then use `$imagegen` for the jobs in `imagegen-jobs.json`, record selected outputs, and finalize.
