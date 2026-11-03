# Technical Decisions Log

**Project:** Hill Climb 2D  
**Engine:** Godot 4.3 Stable (GDScript)  

---

## Architecture Decisions

### 1. Decoupled Signal-Driven Flow vs Global Autoloads
- **Decision:** Use localized composition inside `Game.tscn` where `Game.gd` orchestrates `GameManager`, `Vehicle`, `Camera2D`, and `HUD` via signals rather than relying on bloated global autoloads.
- **Rationale:** Section 5.3 & 6.4 of the Blueprint mandates avoiding excessive global singletons and keeping vehicle physics decoupled from UI. This enables `Vehicle.tscn` to be tested in isolation and prevents cross-scene state pollution.

### 2. Vehicle Physics Model: RigidBody2D Dual-Wheel Assembly
- **Decision:** The vehicle uses a central `RigidBody2D` chassis connected to two `RigidBody2D` wheels via `PinJoint2D` nodes with softness damping.
- **Rationale:** Godot's `VehicleBody3D` cannot be used in 2D. Custom 2D physics using dual wheels with high friction (`1.6`) provides realistic suspension compliance, climbing grip on steep inclines, and air rotational control when airborne.

### 3. Collision Layers & Masks
- **Layer 1:** Terrain / Solid Ground (Static bodies)
- **Layer 2:** Vehicles & Wheels (Rigid bodies)
- **Layer 3:** Pickups / Triggers (Area2D)
- **Layer 4:** Hazards / Crash boundaries

### 4. Input Mapping Standard
- `accelerate`: `KEY_D`, `KEY_RIGHT`
- `brake_reverse`: `KEY_A`, `KEY_LEFT`
- `tilt_left`: `KEY_A`, `KEY_LEFT`
- `tilt_right`: `KEY_D`, `KEY_RIGHT`
- `restart`: `KEY_R`
- `pause`: `KEY_ESCAPE`, `KEY_P`
- Programmatic fallback included in `GameManager._ensure_input_actions()` ensures tests and headless runners never fail due to uninitialized input maps.

### 5. Automated Headless Verification
- Automated integration test `tests/test_game_loop.gd` executes headless SceneTree frames to guarantee physics stability, scene instantiation, camera targeting, and vehicle reset functionality without requiring a desktop display server.
