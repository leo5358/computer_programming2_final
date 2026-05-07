# Native Combat Formulas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move combat formulas into pure C and expose them to Godot through a C++ GDExtension wrapper.

**Architecture:** `src/combat_math.c` owns numeric formula behavior in C. `src/native_combat_math.cpp` wraps those C functions as a Godot `RefCounted` class named `NativeCombatMath`. `project/scripts/combat_math.gd` becomes a thin compatibility layer that uses native formulas when the extension is loaded, and falls back to GDScript formulas while the Windows DLL is not built.

**Tech Stack:** Godot 4.6.2, GDScript test harness, GDExtension C++, pure C formula module, SCons build config.

---

### Task 1: Native Formula Contract

**Files:**
- Create: `project/tests/test_native_combat_math.gd`
- Create: `src/combat_math.h`
- Create: `src/combat_math.c`

- [x] **Step 1: Write a failing native availability test**

Check that Godot can see `NativeCombatMath` and that its numeric results match the current GDScript formula contract.

- [x] **Step 2: Run the test and verify it fails**

Run Godot headless with `res://tests/test_native_combat_math.gd`. It should fail because the GDExtension DLL is not built and `NativeCombatMath` is unavailable.

- [x] **Step 3: Add pure C formulas**

Implement C functions for damage, posture clamp, heartbeat clamp, block duration, and adrenaline damage.

### Task 2: GDExtension Wrapper

**Files:**
- Create: `src/native_combat_math.h`
- Create: `src/native_combat_math.cpp`
- Modify: `src/register_types.cpp`
- Modify: `SConstruct`
- Modify: `project/example.gdextension`

- [x] **Step 1: Register `NativeCombatMath`**

Expose the C formulas as a `RefCounted` Godot class with callable methods.

- [x] **Step 2: Include C sources in the build**

Update SCons so `src/*.c` compiles with `src/*.cpp`, and emit Windows DLL names matching `example.gdextension`.

### Task 3: Godot Fallback Bridge

**Files:**
- Modify: `project/scripts/combat_math.gd`
- Modify: `project/tests/test_combat_math.gd`

- [x] **Step 1: Prefer native formulas when available**

Make the existing `CombatMath` script instantiate `NativeCombatMath` if the extension has loaded. Keep the existing GDScript implementation as fallback.

- [x] **Step 2: Verify fallback tests still pass**

Run `test_combat_math.gd` so gameplay remains testable before the native DLL exists.
