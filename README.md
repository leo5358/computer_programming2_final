# 心音之忍 Heartbeat of Shinobi

*Heartbeat of Shinobi* is a 2D side-scrolling action game vertical slice prototype. It features a high-stakes combat system inspired by the "clashing swords" mechanics of *Sekiro*, enhanced by a unique **Heartbeat BPM System**.

Built with **Godot 4.6.2** and **GDExtension (C/C++)**, this project demonstrates a performant and precise combat engine where the player's biological rhythm directly impacts gameplay mechanics.

---

## Core Mechanics

### 1. Precise Parry System
Timing is everything. Successfully parrying incoming attacks prevents damage and builds the opponent's **Posture**.
- **Perfect Parry:** Negates all damage and significantly increases enemy Posture.
- **Normal Block:** Reduces damage but increases your own Posture and BPM.

### 2. Heartbeat BPM System
A simulated heart rate that tracks combat intensity.
- **Dynamic Feedback:** As BPM rises, the screen pulses, heartbeats intensify, and the background music shifts.
- **Risk vs. Reward:** Higher BPM slows down your Posture recovery, increasing the risk of being broken. However, it reflects the adrenaline of a offensive state.

### 3. Posture System
Both the player and the boss have a Posture bar.
- When Posture reaches 100%, the entity is **Stunned**.
- Breaking the boss's Posture allows for a powerful **Execution** move.

### 4. Boss Phase Transition
The encounter features a multi-phase boss fight. Reducing the boss to 50% HP triggers a dramatic transition into Phase 2, with increased aggression and new visual/audio intensity.

---

## Tech Stack

- **Engine:** Godot 4.6.2 (Standard)
- **Core Logic:** C / C++ via GDExtension for high-performance combat calculations, AI, and state management.
- **View Layer:** GDScript for UI, Animations, VFX, and SFX orchestration.
- **Build System:** SCons.
- **OS Support:** Optimized for Ubuntu 24.04 (also compatible with macOS/Windows).

---

## Getting Started

### Prerequisites (Ubuntu 24.04)

Install the necessary build dependencies:

```bash
sudo apt update && sudo apt install -y build-essential scons \
pkg-config libx11-dev libxcursor-dev libxinerama-dev \
libxrandr-dev libxi-dev libgl-dev libasound2-dev libpulse-dev
```

### Building the Project

1.  Clone the repository with submodules (for `godot-cpp`):
    ```bash
    git clone https://github.com/godotengine/godot-cpp.git
    cd godot-cpp
    git submodule update --init
    cd ..
    ```
2.  Build the GDExtension library using SCons:
    ```bash
    mkdir -p project/bin
    scons platform=linux target=template_debug arch=x86_64 api_version=4.6
    ```
3.  Open the project in Godot:
    ```bash
    godot --editor project/
    ```

---

## Controls & Hotkeys

### Combat & Movement
| Action | Key / Input | Description |
| :--- | :---: | :--- |
| **Move Left / Right** | `A` / `D` or `←` / `→` | Character movement |
| **Run** | `Shift` (Hold) | Increase movement speed |
| **Jump / Wall Climb** | `Space` | Jump; hold while pushing into a wall to climb |
| **Attack** | `J` or `LMB` | Basic offensive strike (Mouse Left Click) |
| **Parry / Block** | `K` or `RMB` | Press for Parry, Hold for Block (Mouse Right Click) |
| **Dash / Dodge** | `L` | Short invulnerability window; can trigger Perfect Dodge |
| **Perfect Dodge** | `Shift` (Tap) | Trigger a precise dodge when an attack is incoming |

### Items & Tools
| Action | Key | Description |
| :--- | :---: | :--- |
| **Select Item** | `1` - `5` | Switch between Kunai, Ash Ball, Gourd, etc. |
| **Use Attack Item** | `E` | Throw Kunai or use offensive items |
| **Use Heal Item** | `R` | Use Gourd (recover 30% HP) or other healing items |

### System & Debug
| Action | Key | Description |
| :--- | :---: | :--- |
| **Toggle Debug** | `F1` | Show/Hide internal combat data |
| **Force BPM** | `F2` | Set BPM to 200 (Adrenaline test) |
| **Reset Combat** | `F5` | Instantly reset the encounter |
| **Toggle Mute** | `M` | Mute/Unmute Background Music |
| **Hurtbox Debug** | `B` | Toggle visualization of collision boxes |
| **Autopilot** | `P` | Toggle AI-assisted combat verification |

---

## Project Structure

- `src/`: C/C++ source code for the `CombatServer` and `AIBrain`.
- `project/`: The Godot project files.
  - `scenes/`: Game levels and entity scenes (Player, Boss).
  - `scripts/`: GDScript files for visual and interactive components.
  - `assets/`: Sprites, SFX, and other media.
- `docs/`: Design documents and development plans.

---

## Debugging

The project includes a comprehensive **Debug Overlay** (toggle with `F1`). It displays real-time data from the C module, including:
- Exact Parry timing (Delta T)
- Player/Boss State machine status
- BPM influence on Posture recovery
- Input Buffer status
- Attack ID tracking

---

## Credits

Developed as a Final Project for Computer Programming II.
