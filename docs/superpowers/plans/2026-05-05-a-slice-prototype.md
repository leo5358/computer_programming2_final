# A Slice Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a small playable 2D action slice with movement, attack, block, heartbeat pressure, health/posture UI, one minor enemy, and one simple boss.

**Architecture:** Keep gameplay scripts in GDScript for fast iteration. Put numeric combat formulas in a small pure script so they can later be moved behind GDExtension/C without changing scene code. Use simple ColorRect visuals and Area2D hitboxes for a stable classroom prototype.

**Tech Stack:** Godot 4.6.2, GDScript, 2D physics nodes, future GDExtension/C formula port.

---

### Task 1: Combat Formula Test Harness

**Files:**
- Create: `project/tests/test_combat_math.gd`
- Create: `project/scripts/combat_math.gd`

- [x] **Step 1: Write failing test**

Create a Godot script test that loads `res://scripts/combat_math.gd` and verifies health damage, posture clamping, heartbeat clamping, block duration scaling, and adrenaline damage scaling.

- [x] **Step 2: Run test and verify it fails**

Run: `Godot --headless --path project --script res://tests/test_combat_math.gd`
Expected: failure because `combat_math.gd` does not exist yet.

- [x] **Step 3: Implement minimal combat formulas**

Create `CombatMath` with static methods for damage, posture, heartbeat, block duration, and adrenaline damage.

- [x] **Step 4: Run test and verify it passes**

Run the same Godot command and expect exit code 0.

### Task 2: Playable Combat Slice

**Files:**
- Modify: `project/scripts/player.gd`
- Create: `project/scripts/enemy.gd`
- Create: `project/scripts/boss.gd`
- Create: `project/scripts/combat_ui.gd`
- Modify: `project/scenes/Player.tscn`
- Create: `project/scenes/Enemy.tscn`
- Create: `project/scenes/Boss.tscn`
- Modify: `project/scenes/Main.tscn`
- Modify: `project/project.godot`

- [x] **Step 1: Add player combat controls**

Add attack, block, health, posture, heartbeat, and signal output to the player.

- [x] **Step 2: Add enemy and boss scenes**

Create simple `CharacterBody2D` enemies with hurtboxes, attack areas, and posture/health behavior.

- [x] **Step 3: Add UI**

Create a CanvasLayer with progress bars for player health, player posture, heartbeat, enemy posture, and boss posture.

- [x] **Step 4: Verify project load**

Run Godot headless and report any extension-only warnings separately from gameplay errors.
