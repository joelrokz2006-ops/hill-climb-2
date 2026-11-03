# Hill Climb 2D

A polished 2D physics-based side-view hill driving game built with **Godot 4.3** and GDScript.

Inspired by classic hill-climbing games, players navigate challenging rolling terrain, manage vehicle balance and throttle, collect rewards, manage fuel, and aim for maximum distance without crashing.

---

## Quick Start

### Prerequisites
- **Godot Engine 4.3+** (Standard edition)

### Running the Project
1. Open Godot Engine and import this project folder (`project.godot`).
2. Press **F5** (or click **Play**) to launch the main scene (`res://scenes/main/Main.tscn`).

### Controls
| Action | Key / Input | Notes |
|---|---|---|
| **Accelerate** | `D` / `Right Arrow` | Drives vehicle forward via rear/front wheels |
| **Brake / Reverse** | `A` / `Left Arrow` | Applies wheel braking or reverse torque |
| **Air Tilt (Pitch)** | `A` (tilt back) / `D` (tilt forward) | Rotates vehicle while airborne |
| **Restart** | `R` | Resets current run immediately to spawn |
| **Pause** | `Esc` / `P` | Pauses/resumes gameplay |

---

## Project Architecture

The project is structured according to `MASTER_PROJECT_BLUEPRINT.md`:

```text
HillClimb2D/
├── project.godot
├── MASTER_PROJECT_BLUEPRINT.md
├── DEVELOPMENT_PROGRESS.md
├── TEAM_ROLES.md
├── assets/          # Sprites, audio, environment, fonts
├── scenes/          # Godot .tscn scene files
│   ├── main/        # Root scene switcher (Main.tscn)
│   ├── game/        # Assembly integration hub (Game.tscn)
│   ├── vehicle/     # Self-contained vehicle physics (Vehicle.tscn)
│   ├── terrain/     # Terrain & test tracks (TestTrack.tscn)
│   ├── pickups/     # Coins and fuel cans
│   └── ui/          # HUD, menus, results screens
├── scripts/         # GDScript source code
│   ├── core/        # Game.gd, GameManager.gd, FollowCamera.gd
│   ├── vehicle/     # VehicleController.gd
│   ├── terrain/     # Terrain generation & collision
│   └── ui/          # HUDController.gd
├── docs/            # Documentation & architectural decisions
└── tests/           # Headless automated integration test scripts
```

## Running Automated Tests

Run the headless integration test suite:

```bash
godot --headless -s tests/test_game_loop.gd
```
