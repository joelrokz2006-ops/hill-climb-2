# HILL CLIMB 2D — MASTER DEVELOPMENT TO-DO LIST

**Source:** `MASTER_PROJECT_BLUEPRINT.md` (Version 1.0) & `HILL_CLIMB_2D_MASTER_UPGRADE_PLAN.md`  
**Engine:** Godot 4.3 | **Language:** GDScript | **Team:** 3 members  
**Current status:** Master Gameplay Upgrade (Stages A–F) Complete & Fully Verified  

## How to use
- Mark an item complete only after implementation and verification.
- `Done` below means confirmed by actual test runs in Godot or verified files.
- `Verify` means a file/activity exists but behavior is not confirmed.
- Keep this list and `DEVELOPMENT_PROGRESS.md` updated.

## Confirmed progress so far
- [x] AGY created the project folder structure.
- [x] Scene files exist: `Main.tscn`, `Game.tscn`, `TestTrack.tscn`, `ProceduralTrack.tscn`, `Vehicle.tscn`, `MonsterTruck.tscn`, `DuneBuggy.tscn`, `HUD.tscn`, `PauseMenu.tscn`, `ResultsScreen.tscn`, `MainMenu.tscn`.
- [x] Project pushed to GitHub.
- [x] Verify all scenes are valid and connected (Tested in Godot 4.3).
- [x] Verify project starts from `Main.tscn` (Tested in Godot 4.3).
- [x] Verify scripts are attached correctly (Tested in Godot 4.3).
- [x] Verify Input Map actions (`accelerate`, `brake_reverse`, `tilt_left`, `tilt_right`, `restart`, `pause`).
- [x] Verify `.gitignore` and clean launch without errors.
- [x] Master gameplay audit and bug fix completed (23/23 points verified).
- [x] Stage B & C gameplay upgrade completed (Camera trauma, stunts & milestones, endless terrain integration).

---

# PHASE 0 — PROJECT AND TEAM SETUP
**Owner: Member 1 / Team Leader**

- [x] Confirm all members use the same Godot 4.x version (Engine verified: 4.3-stable).
- [x] Decide target platform: desktop / mobile architecture ready.
- [x] Create initial folder structure.
- [x] Push project and blueprint to GitHub.
- [x] Verify repository includes `project.godot`, blueprint, progress file, scenes, scripts, and assets.
- [x] Verify `.gitignore` excludes generated Godot cache/editor files, exported builds, and secrets.
- [x] Establish branch names and pull-request/review process.
- [x] Confirm shared Input Map action names with the team.
- [x] Verify `Main.tscn` is configured as the startup scene.
- [x] Verify `Main.tscn` launches or loads `Game.tscn`.
- [x] Verify project opens and runs without errors (`godot --headless --quit-after 60` exit code 0).

**Exit criteria:** All members can clone/open the project; main scene runs without errors. (COMPLETED)

# PHASE 1 — VEHICLE PROTOTYPE ON A FIXED TEST HILL
**First playable milestone | Members 1, 2, 3**

## Member 1 — Foundation and integration
- [x] Create/verify `Main.tscn` skeleton.
- [x] Create/verify `Game.tscn` skeleton.
- [x] Agree on scene/script interfaces before parallel implementation (`TEAM_ROLES.md` & `TECHNICAL_DECISIONS.md`).
- [x] Integrate vehicle scene into the game.
- [x] Integrate fixed test terrain into the game.
- [x] Add/verify camera follow (`FollowCamera.gd` tracks vehicle with velocity lookahead).
- [x] Integrate and verify basic HUD placeholder (`HUD.tscn` wired to `GameManager` and `Vehicle`).
- [x] Run a clean test from the project entry scene (`tests/test_game_loop.gd` passed with exit code 0).

## Member 2 — Vehicle physics
- [x] Build a self-contained `scenes/vehicle/Vehicle.tscn`.
- [x] Implement accelerate with 75,000 Nm base torque and smooth saturation.
- [x] Implement brake/reverse.
- [x] Implement optional air rotation and stabilization.
- [x] Develop and test wheel/contact/suspension behavior.
- [x] Tune mass, traction, force/torque, damping, and rotation.
- [x] Add vehicle particle effects (exhaust smoke and wheel kickup dust).
- [x] Provide a clear interface for Game Manager and HUD (`crashed`, `fuel_changed`, `refuel`).
- [x] Document exported tuning properties and changelog (`docs/VEHICLE_TUNING_CHANGELOG.md`).
- [x] Provide a test scene proving the vehicle drives on slopes (`scenes/vehicle/VehicleTest.tscn` & `tests/test_vehicle_physics.gd`).

## Member 3 — Terrain, environment, and HUD
- [x] Create a simple fixed test track (`TestTrack.tscn` with rock strata and collision).
- [x] Ensure terrain collision matches visible terrain.
- [x] Prepare a multi-layer parallax background (`ParallaxEnvironment.tscn` mountains, hills, clouds, sun).
- [x] Create HUD elements for distance, fuel, and rewards (`HUD.tscn`).
- [x] Check HUD readability and responsive scaling.
- [x] Prepare asset register (`docs/ASSET_REGISTER.md`).

**Exit criteria:** Vehicle drives reliably across the fixed test hill; no critical physics or scene errors. (COMPLETED)

# PHASE 2 — CORE RUN LOOP
**Owned by Member 1 (Lead) — COMPLETED & VERIFIED**

- [x] Create run states: ready, playing, paused, finished (`GameManager.gd` state machine).
- [x] Add distance tracking (Meters tracked and real-time HUD updates).
- [x] Add restart action/button (`R` key and UI Retry buttons).
- [x] Add basic results display (`scenes/ui/ResultsScreen.tscn` with distance, records, coins, and retry button).
- [x] Add fuel value and depletion (Authoritative vehicle fuel ownership).
- [x] Add fuel pickup (`scenes/pickups/FuelPickup.tscn` refuels vehicle once safely).
- [x] Add game-over condition (Fatal crash impact & out-of-fuel vehicle stop).
- [x] Verify restarting resets the run correctly (`PhysicsServer2D` transform, fuel, distance, pickups reset).
- [x] Verify a run can start, progress, end, and restart (`tests/test_phase2_core_loop.gd` passed 100%).

**Exit criteria:** Complete run loop works. (COMPLETED)

# PHASE 3 — TERRAIN PROGRESSION
**Primary owner: Member 3; integration/review: Member 1 — COMPLETED & VERIFIED**

- [x] Implement reusable terrain segments (9 segment archetypes with synchronized visuals and collision).
- [x] Extend terrain ahead of the vehicle (Continuous procedural generation ahead of moving target).
- [x] Remove/recycle terrain behind the vehicle safely (High-performance segment object pooling).
- [x] Ensure collision joins have no gaps or unintended sharp edges (Continuous zero-derivative boundary tangents).
- [x] Add fair terrain variation (Dynamic difficulty progression and restoring center bias).
- [x] Test long runs for performance and stability (Tested over 26,000+ pixels without degradation).
- [x] Connect `TerrainGenerator` into `Game.tscn` as the primary endless driving mode.

**Exit criteria:** Terrain continues during play with no visible/collision gaps in a sustained test. (COMPLETED)

# PHASE 4 — PICKUPS AND REWARDS
**Pickups visual & procedural placement: Member 3; Currency mechanics & Save Persistence: Member 1 & 2 — COMPLETED & VERIFIED**

- [x] Add coin/reward pickup (`scenes/pickups/Coin.tscn` with gold aura and sparkle burst particles).
- [x] Add pickup collision and collection feedback.
- [x] Procedural pickup placement on generated terrain (air arcs, contour trails, safe surface offset).
- [x] Balanced fuel spacing (~85 meters) ensuring reachable fuel canisters.
- [x] Update reward counter (HUD coins display and GameManager coins tracking).
- [x] Prevent double collection (`is_collected` guard flag).
- [x] Add local save for currency and best distance (`scripts/core/SaveManager.gd`).
- [x] Test save/load across game restarts (`tests/test_main_menu_and_save.gd` passed 100%).

**Exit criteria:** Pickups collect once and saved values persist. (COMPLETED)

# PHASE 5 — UI AND GAME FLOW
**Game flow, Save & Main Menu: Member 1; In-game HUD: Member 3 — COMPLETED & VERIFIED**

- [x] Create main menu (`scenes/main/MainMenu.tscn`, `scripts/core/MainMenuController.gd`).
- [x] Add Start Game button (Launches `Game.tscn` in endless procedural mode).
- [x] Add pause/resume (`scenes/ui/PauseMenu.tscn` & HUD pause banner).
- [x] Add restart (`scenes/ui/ResultsScreen.tscn` & R key restart).
- [x] Add results screen showing finish reason ("DRIVER CRASHED!" vs "OUT OF FUEL!"), distance, coins, and best record.
- [x] Add HUD with distance odometer, fuel gauge, coins badge, and non-blocking toast notifications.
- [x] Distance milestone banners (100m, 250m, 500m, 1,000m).
- [x] Stunt reward popups (Backflip +20, Frontflip +20, Wheelie +10, Big Air +15, Clean Landing +5).

**Exit criteria:** Player can navigate the game without editor controls and UI remains readable. (COMPLETED)

# PHASE 6 — ART, AUDIO, AND POLISH
**Team — COMPLETED & VERIFIED**

- [x] Dynamic RPM engine pitch audio modulation.
- [x] Tire skid screech audio on hard braking or burnout.
- [x] Landing thuds and camera trauma screen shake.
- [x] Dynamic suspension shock struts (`Line2D`) visually compressing with wheel motion.
- [x] Multi-layer parallax background looping seamlessly with zero vertical gaps.
- [x] Atmospheric haze and glowing sun corona.

**Exit criteria:** Cohesive visuals/audio that do not interfere with gameplay. (COMPLETED)

# PHASE 7 — QA AND RELEASE PREPARATION
**Team — COMPLETED & VERIFIED**

- [x] 23-point comprehensive gameplay bug audit passed 100% (`tests/test_gameplay_bug_audit.gd`).
- [x] Stage B & C integration verification passed 100% (`tests/test_stage_b_c_integration.gd`).
- [x] Zero script runtime exceptions or crashes.
- [x] All 7 test suites passing in Godot 4.3 headless mode.

---

# DEFINITION OF DONE
All tasks and requirements from `MASTER_PROJECT_BLUEPRINT.md` and `HILL_CLIMB_2D_MASTER_UPGRADE_PLAN.md` have been satisfied and verified.
