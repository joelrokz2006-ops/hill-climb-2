# Development Progress Tracker

**Project:** Hill Climb 2D  
**Engine:** Godot 4.3 (GDScript)  
**Status:** Phase 2 Complete (Core Run Loop Verified)  
**Last Updated:** Phase 2 Core Run Loop Implemented & Verified  

---

## Phase Status Summary

| Phase | Description | Owner | Status | Notes |
|---|---|---|---|---|
| **Phase 0** | Project & Team Setup | Member 1 | **COMPLETED** | Repo, structure, project.godot, input map, Godot 4.3 verified |
| **Phase 1** | Vehicle on Test Hill (First Playable) | Member 1 (Lead), 2, 3 | **COMPLETED** | Main & Game skeletons, tuned vehicle physics, test hill, particle effects, parallax environment, HUD |
| **Phase 2** | Core Run Loop | Member 1 (Lead) | **COMPLETED** | Run states, game-over triggers, results overlay, pickups, full restart cycle |
| **Phase 3** | Terrain Progression | Member 3 | PLANNED | Procedural or segmented endless terrain generation |
| **Phase 4** | Pickups and Rewards | Member 2 & 3 | PLANNED | Fuel cans, coins, score persistence |
| **Phase 5** | UI & Menus | Member 1 & 3 | PLANNED | Main menu, settings, pause menu, results overlay |
| **Phase 6** | Art, Audio & Polish | Team | **IN PROGRESS (Member 2 Vehicle Polish Complete)** | Dynamic RPM engine audio, landing thuds, tire skid audio, exhaust/dust particles, suspension struts |
| **Phase 7** | QA & Release Preparation | Team | PLANNED | Cross-platform export testing, release packaging |
| **Phase 8** | Optional Enhancements | Member 2 | **IN PROGRESS (Vehicle Systems Complete)** | 4-stat 5-tier upgrade system, Monster Truck & Dune Buggy variations, VehicleRegistry catalog |

---

## Detailed Task Checklist

### Phase 0 — Project and Team Setup
- [x] Confirm Godot 4.x version used by all members (Verified: Godot 4.3 stable).
- [x] Confirm target platform: Desktop / Mobile ready.
- [x] Create Git repository and add blueprint.
- [x] Create initial folder structure (`assets/`, `scenes/`, `scripts/`, `docs/`, `tests/`).
- [x] Add `.gitignore` for Godot-generated files and editor caches.
- [x] Establish branch naming and pull-request conventions.
- [x] Confirm input action names (`accelerate`, `brake_reverse`, `tilt_left`, `tilt_right`, `restart`, `pause`).
- [x] Create a minimal project that opens and runs cleanly.

### Phase 1 — Vehicle Prototype on a Fixed Test Hill (First Playable)
- [x] **Member 1**: Create `Main.tscn` and `Game.tscn` skeleton with scene switching.
- [x] **Member 1 / 3**: Create a fixed test hill with matching collision (`scenes/terrain/TestTrack.tscn`).
- [x] **Member 1 / 2**: Create first vehicle physics prototype (`scenes/vehicle/Vehicle.tscn`, `scripts/vehicle/VehicleController.gd`).
- [x] **Member 1**: Add smooth camera follow (`scripts/core/FollowCamera.gd`).
- [x] **Member 1 / 2**: Add accelerate, brake/reverse, and air tilt controls.
- [x] **Member 2**: Implement particle feedback (exhaust smoke on acceleration, wheel dust kickup on terrain contact).
- [x] **Member 2**: Implement engine audio pitch scaling and landing thud audio triggers.
- [x] **Member 2**: Create standalone isolated test bench with varied slopes (`scenes/vehicle/VehicleTest.tscn`).
- [x] **Member 2**: Document exported tuning properties (`docs/VEHICLE_TUNING_GUIDE.md`).
- [x] Test driving up and down the hill (Verified via automated physics test).
- [x] Test vehicle landing and rotation behavior.
- [x] Tune physics to prevent constant flipping or jitter.
- [x] Integrate all parts into one playable scene (`scenes/game/Game.tscn`).
- [x] Run a clean test from the project entry scene (`tests/test_game_loop.gd` passed 100%).
- [x] Run dedicated vehicle physics test suite (`tests/test_vehicle_physics.gd` passed 100%).

### Phase 2 — Core Run Loop
- [x] **Member 1**: Run state machine (`READY`, `PLAYING`, `PAUSED`, `FINISHED`) in `GameManager.gd`.
- [x] **Member 1**: Distance tracking and live telemetry.
- [x] **Member 1**: Game over triggers for vehicle crash and out-of-fuel coasting stop.
- [x] **Member 1**: Results screen overlay (`scenes/ui/ResultsScreen.tscn`) displaying distance, record, coins, and retry button.
- [x] **Member 1**: Pause menu overlay (`scenes/ui/PauseMenu.tscn`) with resume and restart options.
- [x] **Member 1**: Reusable fuel pickup (`scenes/pickups/FuelPickup.tscn`) and coin pickup (`scenes/pickups/Coin.tscn`).
- [x] **Member 1**: Safe restart flow resetting vehicle, metrics, UI, and test track pickups.
- [x] **Member 1**: Automated Phase 2 test suite (`tests/test_phase2_core_loop.gd` passed 100%).

### Phase 6 & Phase 8 — Member 2 Vehicle Polish, Upgrades & Roster
- [x] **Member 2**: Implement 4-stat 5-tier upgrade system (`engine_power`, `tire_grip`, `suspension`, `fuel_tank`).
- [x] **Member 2**: Expose `get_stats() -> Dictionary`, `apply_upgrade(stat_name, level)`, and `signal upgraded`.
- [x] **Member 2**: Dynamic engine RPM pitch audio modulation (`engine_audio.pitch_scale = lerpf(0.8, 2.2, speed_ratio)`).
- [x] **Member 2**: Tire screech audio (`SkidAudio`) triggering dynamically on hard braking and wheel burnouts.
- [x] **Member 2**: Dynamic suspension shock struts (`Line2D`) visually connecting chassis to wheel hubs with real-time compression.
- [x] **Member 2**: Stunt detection: 360° Frontflips and Backflips (`signal trick_performed(name, coins)`).
- [x] **Member 2**: Big airtime detection (`signal airtime_landed(duration, coins)`).
- [x] **Member 2**: Physical low-fuel throttle sputtering warning (< 15% fuel).
- [x] **Member 2**: Additional vehicle variations: `scenes/vehicle/MonsterTruck.tscn` and `scenes/vehicle/DuneBuggy.tscn`.
- [x] **Member 2**: Static vehicle registry contract: `scripts/vehicle/VehicleRegistry.gd`.
- [x] **Member 2**: Full automated verification suite (`tests/test_vehicle_physics.gd` passed 100%).

---

## Verification Logs

- Headless Godot Editor check: `godot --headless --editor --quit` -> **0 errors**
- Entry Scene execution: `godot --headless scenes/main/Main.tscn --quit-after 60` -> **Exit code 0**
- Full automated integration suite: `godot --headless -s tests/test_game_loop.gd` -> **Exit code 0**
- Member 2 vehicle standalone suite: `godot --headless -s tests/test_vehicle_physics.gd` -> **Exit code 0**
- Member 3 terrain & HUD suite: `godot --headless -s tests/test_terrain_and_hud.gd` -> **Exit code 0**
- Phase 2 core run loop suite: `godot --headless -s tests/test_phase2_core_loop.gd` -> **Exit code 0**
