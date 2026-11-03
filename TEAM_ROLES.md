# Team Roles & Responsibilities

**Project:** Hill Climb 2D  
**Team Size:** 3 Members  
**Framework:** Godot 4.3 (GDScript)  

---

## Member 1 — Team Leader / Foundation & Integration
- **Ownership:** Architecture, Game Flow, Scene Integration, Git & CI conventions.
- **Assigned Directories:**
  - `scenes/main/`
  - `scenes/game/`
  - `scripts/core/`
  - `project.godot`, `.gitignore`, `README.md`, `MASTER_PROJECT_BLUEPRINT.md`
- **Interfaces Owned:**
  - `GameManager` (run state machine, telemetry signals)
  - `GameScene` (assembly slot integration, camera binding)
  - `FollowCamera` (target tracking)

---

## Member 2 — Vehicle Gameplay & Physics
- **Ownership:** Vehicle mechanics, suspension tuning, controls, fuel depletion.
- **Assigned Directories:**
  - `scenes/vehicle/`
  - `scripts/vehicle/`
  - `assets/vehicles/`
- **Interfaces to adhere to:**
  - Expose signals: `crashed`, `fuel_changed(current, max_fuel)`
  - Provide `reset_vehicle(at_position: Vector2)`
  - Respond to input actions: `accelerate`, `brake_reverse`, `tilt_left`, `tilt_right`

---

## Member 3 — Terrain, Environment & HUD
- **Ownership:** Terrain geometry, collision consistency, background parallax, HUD rendering.
- **Assigned Directories:**
  - `scenes/terrain/`
  - `scenes/ui/`
  - `scripts/terrain/`
  - `scripts/ui/`
  - `assets/terrain/`, `assets/environment/`, `assets/ui/`
- **Interfaces to adhere to:**
  - Terrain must expose static collision on Collision Layer 1 (Mask 2 for vehicles).
  - HUD connects to `GameManager` and `Vehicle` signals without altering vehicle physics directly.
