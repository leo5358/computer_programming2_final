# Hatch Pet Delta

This skill intentionally keeps the stable parts of the hatch-pet workflow:

- one canonical base image;
- one grounded image-generation job per animation row;
- job manifest tracking;
- deterministic frame extraction;
- deterministic atlas composition;
- QA contact sheet and validation report;
- targeted repair workflow.

Main changes:

- The output is for 2D game characters, not Codex pets.
- Atlas geometry is configurable by JSON.
- Actions are not fixed to pet states.
- Godot-friendly metadata is packaged.
- Character roles include protagonist, small enemy, boss, NPC, and custom.
