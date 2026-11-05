# Technical Decisions Log

**Project:** Hill Climb 2D  
**Engine:** Godot 4.7+ Stable (GDScript)  

---

## Architecture Decisions

### 1. Decoupled Signal-Driven Flow vs Global Autoloads
- **Decision:** Use localized composition inside `Game.tscn` where `Game.gd` orchestrates `GameManager`, `Vehicle`, `Camera2D`, `SnowfallManager`, and `HUD` via signals rather than relying on bloated global autoloads.
- **Rationale:** Section 5.3 & 6.4 of the Blueprint mandates avoiding excessive global singletons and keeping vehicle physics decoupled from UI. This enables `Vehicle.tscn` to be tested in isolation and prevents cross-scene state pollution.

### 2. Vehicle Physics Model: RigidBody2D Dual & Single-Wheel Assemblies
- **Dual-Wheel Vehicles (Classic Car, Monster Truck, Dune Buggy):** Central chassis `RigidBody2D` connected to front and rear `RigidBody2D` wheels via `PinJoint2D` nodes with softness damping.
- **Single-Wheel Vehicle (One-Wheel Scooter):** Single central `RigidBody2D` wheel pinned directly under the chassis center-of-mass via `PinJoint2D`. Stabilized through an active Gyroscopic Balance Assistance PID loop (`balance_kp = 3200`, `balance_kd = 320`) applying restorative torque to the chassis while allowing responsive player lean input (`tilt_left` / `tilt_right`).
- **Rationale:** Godot's `VehicleBody3D` cannot be used in 2D. Custom 2D physics using dual or single wheels with high friction (`1.60` to `2.20`) provides realistic suspension compliance, climbing grip on steep inclines, and air rotational control when airborne.

### 3. Authoritative Centralized Continuous Fuel Consumption
- **Decision:** Relocated fuel consumption out of `VehicleController._handle_input()` into `GameManager._process(delta)`.
- **Implementation:**
  - Drain rate is an exported float (`fuel_drain_rate: float = 4.0`) representing fuel drained per second.
  - Active strictly during `RunState.PLAYING` (stationary, accelerating, or coasting).
  - Ceases instantly when paused (`RunState.PAUSED`), finished (`RunState.FINISHED`), or before run start.
  - Non-negative clamping and single-trigger out-of-fuel depletion signals prevent redundant game-over events.

### 4. Geometry-Aware Pickup Clearance & Ground Detection
- **Decision:** Replace naive Y-offset clearance with bounding-box terrain sampling (`_calculate_safe_pickup_y()`).
- **Implementation:**
  - Evaluates local surface height `y` across the pickup visual width: $x - \frac{w}{2}$, $x$, and $x + \frac{w}{2}$.
  - Takes the minimum $y$ (highest peak underneath the pickup).
  - Tests bounding box bottom points against `collision_polygon` points via `Geometry2D.is_point_in_polygon()`.
  - Applies a guaranteed safety margin of $\ge 34\text{ px}$ for coins and $\ge 46\text{ px}$ for fuel canisters, ensuring pickups never clip into or spawn beneath terrain surfaces regardless of steep slopes, cliffs, or valleys.

### 5. Milestone-Triggered Snowfall System (`SnowfallManager`)
- **Decision:** Implement dedicated autonomous `SnowfallManager` listening to `GameManager.distance_updated`.
- **Implementation:**
  - Fires at integer multiples of 200m (200m, 400m, 600m, etc.).
  - Tracks `_last_milestone_index` to prevent re-triggering within the same milestone bracket.
  - Handles distance teleporting/jumps gracefully by advancing the index without triggering duplicate storms.
  - Smoothly tweens blizzard and fog overlay opacities and activates particle emission for 10-second weather bursts.
  - Resets cleanly when `run_started` is signaled.

### 6. Dynamic Vehicle Instantiation and Selection Persistence
- **Decision:** Store `selected_vehicle_id` in `SaveManager` disk file (`user://save_data.json`) with fallback to `"classic_car"`.
- **Implementation:**
  - Main menu provides visual vehicle selection modal displaying all 4 registered vehicles with live statistics, cost, and selection status.
  - `Game.gd` queries `SaveManager.get_selected_vehicle_id()` during `_setup_vehicle()`.
  - Safely disconnects and removes existing vehicle node from the tree prior to freeing to avoid name-mangling in Godot's SceneTree, and dynamically spawns the chosen vehicle.

### 7. Collision Layers & Masks
- **Layer 1:** Terrain / Solid Ground (Static bodies)
- **Layer 2:** Vehicles & Wheels (Rigid bodies)
- **Layer 3:** Pickups / Triggers (Area2D)
- **Layer 4:** Hazards / Crash boundaries

### 8. Input Mapping Standard
- `accelerate`: `KEY_D`, `KEY_RIGHT`
- `brake_reverse`: `KEY_A`, `KEY_LEFT`
- `tilt_left`: `KEY_A`, `KEY_LEFT`
- `tilt_right`: `KEY_D`, `KEY_RIGHT`
- `nitro`: `KEY_SHIFT`, `KEY_SPACE`, `KEY_N`
- `restart`: `KEY_R`
- `pause`: `KEY_ESCAPE`, `KEY_P`
- Programmatic fallback included in `GameManager._ensure_input_actions()` ensures tests and headless runners never fail due to uninitialized input maps.
