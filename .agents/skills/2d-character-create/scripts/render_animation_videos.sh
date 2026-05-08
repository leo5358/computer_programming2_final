#!/usr/bin/env bash
set -euo pipefail
RUN_DIR="${1:?usage: render_animation_videos.sh /path/to/run}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python "$SCRIPT_DIR/render_animation_videos.py" --run-dir "$RUN_DIR"
