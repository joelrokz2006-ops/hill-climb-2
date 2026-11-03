# HILL CLIMB 2D — MASTER DEVELOPMENT TO-DO LIST

**Source:** `MASTER_PROJECT_BLUEPRINT.md` (Version 1.0)  
**Engine:** Godot 4.x | **Language:** GDScript | **Team:** 3 members  
**Current status:** Phase 0 Completed / Member 1 Phase 1 Integration Completed

## How to use
- Mark an item complete only after implementation and verification.
- `Done` below means confirmed by actual test runs in Godot or verified files.
- `Verify` means a file/activity exists but behavior is not confirmed.
- Keep this list and `DEVELOPMENT_PROGRESS.md` updated.

## Confirmed progress so far
- [x] AGY created the project folder structure (confirmed by screenshots).
- [x] These scene files exist: `Main.tscn`, `Game.tscn`, `TestTrack.tscn`, `Vehicle.tscn`, `HUD.tscn` (screenshot).
- [x] Project pushed to GitHub (you confirmed).
- [x] Verify all scenes are valid and connected (Tested in Godot 4.3).
- [x] Verify project starts from `Main.tscn` (Tested in Godot 4.3).
- [x] Verify scripts are attached correctly (Tested in Godot 4.3).
- [x] Verify Input Map actions (`project.godot` restored and verified).
- [x] Verify `.gitignore` and clean launch without errors.

---

# PHASE 0 — PROJECT AND TEAM SETUP
**Owner: Member 1 / Team Leader**

- [ ] Confirm all members use the same Godot 4.x version (Engine verified: 4.3-stable; team confirmation pending).
- [ ] Decide target platform: desktop, Android, or both (OPEN in blueprint).
- [x] Create initial folder structure.
- [x] Push project and blueprint to GitHub.
- [x] Verify repository includes `project.godot`, blueprint, progress file, scenes, scripts, and assets.
- [x] Verify `.gitignore` excludes generated Godot cache/editor files, exported builds, and secrets.
- [x] Establish branch names and pull-request/review process (Documented in blueprint & team roles).
- [x] Confirm shared Input Map action names with the team (`accelerate`, `brake_reverse`, `tilt_left`, `tilt_right`, `restart`, `pause`).
- [x] Verify `Main.tscn` is configured as the startup scene.
- [x] Verify `Main.tscn` launches or loads `Game.tscn`.
- [x] Verify project opens and runs without errors (`godot --headless --quit-after 60` exit code 0).
- [ ] Ensure all three members can clone/open the project.

**Exit criteria:** All members can clone/open the project; main scene runs without errors.

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
- [x] Review member branches/PRs and resolve scene conflicts (PR #1 from `member2contract` integrated into `main`).

## Member 2 — Vehicle physics
- [x] Build a self-contained `scenes/vehicle/Vehicle.tscn` (Enhanced physics, particle anchors, and audio hooks).
- [x] Implement accelerate.
- [x] Implement brake/reverse.
- [x] Implement optional air rotation.
- [x] Develop and test wheel/contact/suspension behavior.
- [x] Tune mass, traction, force/torque, damping, and rotation.
- [x] Add vehicle animations/sprite placement (Exhaust smoke particles & tire dust kickup).
- [x] Provide a clear interface for Game Manager and HUD (`crashed`, `fuel_changed`, `refuel`).
- [x] Document exported tuning properties and their meaning (`docs/VEHICLE_TUNING_GUIDE.md`).
- [x] Provide a test scene or steps proving the vehicle drives on a basic slope (`scenes/vehicle/VehicleTest.tscn` & `tests/test_vehicle_physics.gd`).

## Member 3 — Terrain, environment, and HUD
- [x] Create a simple fixed test track first (`TestTrack.tscn` updated with rock strata and collision).
- [x] Ensure terrain collision matches visible terrain.
- [x] Prepare a basic background/environment (`ParallaxEnvironment.tscn` multi-layer parallax with mountains, clouds, sun).
- [x] Create HUD elements for distance and fuel/rewards as agreed (`HUD.tscn` with distance, fuel gauge, low fuel flash, coins).
- [x] Check HUD readability for selected platform.
- [x] Audit supplied assets for dimensions, transparency, style, and licensing.
- [x] Prepare asset register and missing-asset list (`docs/ASSET_REGISTER.md`).

## First playable verification
- [x] Test driving up and down the hill (Verified in `VehicleTest.tscn` and `Game.tscn`).
- [x] Test vehicle landing and rotation behavior.
- [x] Tune physics to avoid constant flipping, sinking, or jitter.
- [x] Confirm player can repeatedly drive across the test hill.
- [x] Confirm no critical physics or scene errors remain.

**Exit criteria:** Vehicle drives reliably across the fixed test hill; no critical physics or scene errors. (ALL MEMBERS COMPLETE)

# PHASE 2 — CORE RUN LOOP
**Current Active Phase — Owned by Member 1 (Lead)**

- [ ] Create run states: playing, paused, finished.
- [ ] Add distance tracking.
- [ ] Add restart action/button.
- [ ] Add basic results display.
- [ ] Add fuel value and depletion.
- [ ] Add fuel pickup.
- [ ] Add game-over condition.
- [ ] Verify restarting resets the run correctly.
- [ ] Verify a run can start, progress, end, and restart.

**Exit criteria:** Complete run loop works.

# PHASE 3 — TERRAIN PROGRESSION
**Primary owner: Member 3; integration/review: Member 1**

- [ ] Decide fixed segments or procedural terrain after prototype testing.
- [ ] Create reusable terrain segments.
- [ ] Extend terrain ahead of the vehicle.
- [ ] Remove/recycle terrain behind the vehicle safely.
- [ ] Ensure collision joins have no gaps or unintended sharp edges.
- [ ] Add fair terrain variation.
- [ ] Test long runs for performance and stability.

**Exit criteria:** Terrain continues during play with no visible/collision gaps in a sustained test.

# PHASE 4 — PICKUPS AND REWARDS

- [ ] Add coin/reward pickup.
- [ ] Add pickup collision and collection feedback.
- [ ] Update reward counter.
- [ ] Prevent double collection.
- [ ] Add local save for currency and best distance.
- [ ] Test save/load across game restarts.

**Exit criteria:** Pickups collect once and saved values persist.

# PHASE 5 — UI AND GAME FLOW

- [ ] Create main menu.
- [ ] Add Start Game button.
- [ ] Add pause/resume.
- [ ] Add restart.
- [ ] Add results screen.
- [ ] Add HUD for distance, fuel, and currency.
- [ ] Apply consistent UI styling.
- [ ] Test UI at chosen resolution/aspect ratio.
- [ ] If Android is selected, add and test touch controls.

**Exit criteria:** Player can navigate the game without editor controls and UI remains readable.

# PHASE 6 — ART, AUDIO, AND POLISH

- [ ] Audit and assign final sprites.
- [ ] Confirm sprite scale and transparent margins.
- [ ] Align vehicle body and wheel visuals with physics.
- [ ] Add background/parallax.
- [ ] Add engine, pickup, crash, and UI sounds as appropriate.
- [ ] Add subtle effects/animations.
- [ ] Tune camera smoothing and visual feedback.
- [ ] Check performance and remove unused assets.

**Exit criteria:** Cohesive visuals/audio that do not interfere with gameplay.

# PHASE 7 — QA AND RELEASE PREPARATION

- [ ] Test all core controls.
- [ ] Test run start/end/restart.
- [ ] Test fuel and pickups.
- [ ] Test save/load.
- [ ] Test terrain over a long run.
- [ ] Check Godot output/debug console for errors and warnings.
- [ ] Test on each selected target platform.
- [ ] Verify asset licenses and attribution.
- [ ] Prepare README and build instructions.
- [ ] Create a release build.
- [ ] Test release build outside the editor.

**Exit criteria:** Reproducible, documented, playable build with no known blocking issue.

# PHASE 8 — OPTIONAL APPROVED ENHANCEMENTS
**Only after MVP is stable**

- [ ] Vehicle upgrades.
- [ ] Additional vehicles.
- [ ] Additional terrain themes.
- [ ] Achievements or missions.
- [ ] Mobile-specific polish.
- [ ] Other team-approved enhancements.

# TEAM / GIT / DOCUMENTATION CHECKLIST

- [ ] Each member works in assigned branch and folders.
- [ ] Members test their own work before review.
- [ ] New dependencies and design changes are explained.
- [x] No generated caches, editor temporary files, or secrets are committed.
- [ ] Do not commit directly to `main`.
- [ ] Pull latest base branch before starting a task.
- [ ] Use focused commits with clear messages.
- [ ] Open pull requests for integration.
- [ ] Member 1 reviews integration and scene conflicts.
- [ ] Test merged project before marking phase complete.
- [x] Update `DEVELOPMENT_PROGRESS.md` for verified completed work.
- [x] Keep this master checklist current.

# ASSET AUDIT

- [x] Create/verify `docs/ASSET_REGISTER.md`.
- [ ] Record asset name, source, author, license, attribution requirement, and usage.
- [ ] Confirm asset archive is extracted and organized.
- [ ] Confirm vehicle body and wheel sprites exist and fit physics setup.
- [ ] Confirm terrain images have usable collision geometry.
- [ ] Check image dimensions, transparency, and art-style consistency.
- [ ] Check audio formats and volume.
- [ ] Identify missing assets before creating/replacing them.
- [ ] Do not assume downloadable assets are free for commercial use.

# DEFINITION OF DONE — APPLY TO EVERY TASK

- [x] Task matches blueprint or has approved decision update.
- [x] Implementation is in the correct owned module.
- [x] No unrelated feature/file was changed.
- [x] Project opens in the agreed Godot version.
- [x] Relevant behavior was tested, or limitations are stated.
- [x] No new blocking errors are present.
- [x] `DEVELOPMENT_PROGRESS.md` is updated.
- [x] Change is committed and reviewed before merging to `main`.

## Current next action
**Member 1 (Team Leader):** Phase 1 is fully completed and verified across all 3 members. Member 1 now begins **Phase 2 — Core Run Loop**: implementing run state coordination (`READY` -> `PLAYING` -> `PAUSED` -> `FINISHED`), end-of-run results screen, game-over handlers (crashed & out of fuel), and restart reset flows.
