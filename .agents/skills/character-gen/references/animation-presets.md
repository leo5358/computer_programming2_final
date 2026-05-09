# Animation Presets — Sekiro-Style 2D Combat

Recommended animation names, frame counts, and FPS for a side-scrolling 2D combat game inspired by Sekiro: Shadows Die Twice.

Use these as starting points. You do not need all of them — start with the animations your gameplay actually uses and add more as needed.

## Hero / Protagonist — 96×96 cells

### Core Movement

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `idle` | 6 | 8 | true | Battle-ready idle stance, subtle breathing |
| `run` | 8 | 12 | true | Right-facing sprint with weapon held ready |
| `jump` | 4 | 10 | false | Takeoff → rise → peak → begin descent |
| `fall` | 3 | 10 | true | Controlled freefall pose |
| `land` | 3 | 12 | false | Landing impact, brief crouch |

### Sword Combat

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `attack_1` | 6 | 14 | false | Quick horizontal slash — anticipation, swing, follow-through, recovery |
| `attack_2` | 6 | 14 | false | Upward diagonal slash — different arc from attack_1 |
| `attack_3` | 5 | 16 | false | Thrust — short forward lunge |

### Defense & Parry

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `guard` | 2 | 8 | true | Raised blade guard stance, minimal motion |
| `parry` | 4 | 16 | false | Active parry — quick blade intercept, sharp timing window |
| `deflect` | 5 | 16 | false | Perfect deflect — sharp clash pose, brief spark implied by stance |

### Reactions

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `hurt` | 3 | 10 | false | Hit reaction — torso recoil, readable silhouette |
| `death` | 8 | 10 | false | Defeated collapse to a downed pose |

### Sekiro-Specific (optional, add when gameplay needs them)

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `dash` | 5 | 16 | false | Quick forward burst step |
| `stealth_kill` | 8 | 12 | false | Crouched approach into swift stab |

---

## Boss — 128×128 cells

Bosses use larger cells and fewer, more deliberate animations. Frame counts are higher to show dramatic windup and recovery.

### Core

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `idle` | 6 | 6 | true | Imposing idle stance, slow threatening sway |
| `walk` | 8 | 8 | true | Slow deliberate advance |
| `turn` | 4 | 8 | false | 180° facing flip |

### Attacks

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `tell` | 4 | 8 | false | Visual telegraph before a big attack — wind-up pose |
| `heavy_attack` | 8 | 12 | false | Slow powerful slash with long windup and recovery |
| `special_attack` | 10 | 12 | false | Signature move unique to this boss |

### Reactions

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `stagger` | 5 | 10 | false | Posture-broken stagger, brief vulnerability window |
| `enrage` | 6 | 10 | false | Phase transition — rage/power-up animation |
| `death` | 10 | 8 | false | Dramatic death collapse |

---

## Enemy / Small Foe — 64×64 or 96×96 cells

Enemies have simpler animation sets. Three or four animations are usually enough.

| Name | Frames | FPS | Loop | Action description |
|---|---|---|---|---|
| `idle` | 4 | 8 | true | Alert patrol stance |
| `run` | 6 | 12 | true | Chase or approach |
| `attack` | 5 | 12 | false | Single strike |
| `death` | 6 | 10 | false | Collapse |

---

## Tips

- Start with `idle`, `run`, and one `attack` — get these looking right before adding more.
- The `tell` animation for bosses is important for game feel: players need visual cues before attacks land.
- `parry` and `deflect` are separate if your game distinguishes between blocking and perfect-timing parry.
- Use `prompt_notes` in the spec to give the AI extra guidance for unusual animations (e.g., `"prompt_notes": "Blade must be clearly raised in frames 0-1, then clash position in frame 2"`).
