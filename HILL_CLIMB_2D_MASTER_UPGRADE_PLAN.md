# HILL CLIMB 2D — MASTER GAMEPLAY UPGRADE & FINAL INTEGRATION PLAN

**Project:** Hill Climb 2D  
**Engine:** Godot 4.3 (GDScript)  
**Project style:** 2D physics-based endless driving game inspired by classic hill-climb games  
**Current responsibility:** Member 1 — Team Leader, Gameplay Integration & Final Polish  
**Document purpose:** Single execution plan for AGY to audit, integrate, improve, and verify the existing project without destroying completed team work.

---

# 1. PROJECT GOAL

Upgrade the current playable prototype into a polished, replayable hill-climb game with:

- Responsive and believable vehicle physics.
- A satisfying acceleration, braking, suspension, landing, and air-control feel.
- Endless procedural terrain that continuously extends in front of the vehicle.
- Interesting hills, valleys, bumps, ramps, and difficulty progression.
- Fuel and coin collection during a run.
- Clear run feedback, readable HUD, results, restart, and saved progress.
- Small, useful gameplay features that improve replayability without expanding the project into an unmanageable scope.

The desired experience is inspired by the *feel and gameplay principles* of classic hill-climb games. Do not copy copyrighted artwork, logos, characters, UI assets, or proprietary game content. Use the project's own assets and visual identity.

**Main quality target:** The player should feel that they are driving a vehicle over a changing landscape—not merely holding accelerate while a car slides forward.

---

# 2. IMPORTANT PROJECT STATUS AND PRESERVATION RULES

The supplied project progress documents report that the following work has been completed by the team:

## Member 2 — Vehicle work reported complete

- Vehicle assembly and physics.
- Acceleration and brake/reverse.
- Air rotation.
- Wheel contact and suspension tuning.
- Vehicle effects and audio hooks.
- Vehicle tuning guide.
- Vehicle test scene and physics tests.
- Engine audio, landing sound, skid audio, dust and exhaust effects.
- Vehicle upgrade properties and vehicle variants are also reported in the progress tracker.

## Member 3 — Terrain, environment and HUD work reported complete

- Fixed test track.
- Terrain collision and visual alignment.
- Parallax environment.
- HUD for distance, fuel, and coins.
- Procedural terrain generator.
- Nine terrain segment archetypes.
- Segment pooling.
- Difficulty progression.
- Terrain surface query API.
- Procedural coin and fuel placement.
- Pickup visual effects.
- Responsive/glass-style HUD and fuel feedback.

## Member 1 — Core game systems reported complete

- Main/Game scene integration.
- Game state management.
- Distance tracking.
- Crash and out-of-fuel run endings.
- Results and pause screens.
- Fuel and coin pickup integration.
- Restart flow.
- Save persistence and main menu.

**These are status claims from the supplied `DEVELOPMENT_PROGRESS.md` and `HILL_CLIMB_MASTER_TODO.md`. AGY must inspect the actual current files and run the project before treating every claim as verified.**

## Non-negotiable preservation rules

1. Do not recreate the project.
2. Do not replace completed Member 2 or Member 3 systems with new implementations.
3. Do not delete or rename existing scenes, scripts, assets, signals, input actions, or public methods unless a real conflict requires it and the change is documented.
4. Do not rewrite `VehicleController.gd`, `TerrainGenerator.gd`, `HUDController.gd`, or their scenes from scratch.
5. Prefer small, isolated edits and new helper scripts/scenes where practical.
6. Preserve existing scene interfaces and signals.
7. Preserve the fixed test track and vehicle test scene for regression testing.
8. Preserve vehicle variants and upgrade support.
9. Do not add unrelated features, online multiplayer, ads, shops, accounts, or backend services.
10. Do not mark an item complete because code was generated. Completion requires an actual test or an explicitly documented manual verification.
11. Before editing, inspect Git status and create a feature branch or a recoverable commit.
12. After each small group of changes, run relevant tests and inspect the diff.

If a completed system is defective, first explain the defect and propose the smallest safe correction. Do not silently replace the system.

---

# 3. FIRST TASK — AUDIT THE REAL PROJECT

Before changing code, inspect the current repository and report:

- Godot version and project entry scene.
- Actual scene tree of `Main.tscn` and `Game.tscn`.
- Whether `Game.tscn` uses the procedural terrain generator or only the fixed test track.
- How the terrain generator creates, extends, recycles, and pools segments.
- How the vehicle is spawned and how the camera follows it.
- How vehicle acceleration, torque, wheel speed, friction, suspension, and air rotation work.
- Which object owns the authoritative fuel value.
- How fuel pickups update fuel.
- How distance and best distance are calculated.
- How crash, out-of-fuel, pause, results, and restart are connected.
- How coins, upgrades, vehicle variants, and save data are preserved.
- Existing tests and their actual results.
- Missing assets, broken references, runtime errors, and warnings.

Create a report with three labels:

- **Verified:** directly inspected and successfully tested.
- **Present, not runtime-verified:** files/code exist, but behavior has not been demonstrated.
- **Missing or defective:** implementation is absent or a reproducible problem exists.

Do not assume the progress tracker is proof of runtime behavior.

---

# 4. PRIORITY 1 — MAKE THE DRIVING FEEL GOOD

## 4.1 Target driving experience

The vehicle should have:

- Immediate but controllable throttle response.
- A noticeable difference between flat-ground driving and uphill climbing.
- Natural loss of speed on steep slopes.
- Enough power to climb reasonable hills without feeling stuck.
- Visible wheel rotation and believable wheel-to-ground contact.
- Suspension compression and rebound over bumps.
- A controlled landing after jumps.
- Air rotation that responds predictably to player input.
- Braking and reverse that feel different from forward acceleration.
- No constant flipping, jittering, sinking, or uncontrollable wheel spin.

The goal is **arcade-realistic**, not a fully accurate vehicle simulator. It should be easy to understand and fun to control.

## 4.2 Diagnose before tuning

Inspect the existing vehicle and test scene. Check:

- Motor torque and engine power upgrade multiplier.
- Maximum wheel angular speed and how the limit is applied.
- Torque direction for both wheels.
- Whether torque is applied to the intended wheels.
- Wheel angular velocity and chassis forward velocity.
- Wheel friction and actual contact with the terrain.
- Chassis mass, wheel mass, center of mass, and inertia.
- PinJoint2D setup, joint softness, and suspension behavior.
- Collision layers/masks and terrain collision geometry.
- Fuel-related engine power reduction.
- Whether acceleration is incorrectly applied while paused or finished.

Do not assume that weak climbing is caused by torque alone.

## 4.3 Wheel speed and traction

Review the current angular-speed condition. A one-sided comparison such as:

`angular_velocity < max_wheel_speed`

may not correctly handle reverse rotation. Evaluate whether an absolute-speed check, signed motor target, or another controller approach is appropriate.

Do not merely clamp wheel speed in a way that causes abrupt loss of power. Use a smooth, predictable motor response.

Determine whether the wheels are:
- Not rotating enough — possible insufficient torque or input issue.
- Spinning rapidly while the chassis barely moves — possible traction/contact issue.
- Moving slowly with the chassis — possible power, mass, slope, or collision issue.
- Lifting the front of the car — possible torque, center-of-mass, or slope interaction.

## 4.4 Controlled tuning procedure

1. Record the current values before changing anything.
2. Use the same fixed test hill and same vehicle for baseline testing.
3. Test flat-ground acceleration.
4. Test a moderate uphill slope.
5. Test the steepest intended normal slope.
6. Observe wheel spin, chassis speed, body angle, and suspension.
7. Change one related group of parameters at a time.
8. Retest after every change.
9. Keep a before/after tuning table in `docs/VEHICLE_TUNING_CHANGELOG.md`.

Do not:
- Make vehicle mass extremely low just to climb.
- Disable gravity or collisions.
- Apply an unrealistic constant force directly to the chassis.
- Make every slope easy.
- Remove air control or upgrades.
- Set huge torque values without testing rollover and wheel spin.

**Acceptance criteria**
- Responsive acceleration on flat terrain.
- Can climb the intended moderate slopes.
- Steep slopes remain challenging but not arbitrarily impossible.
- No persistent uncontrolled wheel spin.
- No repeated backward flipping under normal throttle.
- Stable landings and repeatable behavior.
- Existing vehicle physics tests still pass.

---

# 5. PRIORITY 2 — ENDLESS TERRAIN: VERIFY, CONNECT, AND IMPROVE

The supplied progress tracker already reports an endless procedural terrain system with nine segment types, pooling, adaptive difficulty, and continuous joins. Therefore, **do not build a second terrain generator**.

First verify whether the current game scene actually uses it. The fixed `TestTrack.tscn` should remain available for testing.

## 5.1 Required runtime behavior

- Terrain is generated ahead of the vehicle before the player reaches the end of the current segment.
- Terrain behind the camera/player is safely recycled or returned to the pool.
- The player never sees the world end during a normal run.
- Visual ground and collision geometry remain aligned.
- Segment joins do not create gaps, sharp collision steps, or sudden physics impulses.
- Terrain generation does not cause noticeable frame drops.
- The generator does not create unbounded numbers of nodes.
- Restart returns the run to a known initial terrain state.
- The generator can continue producing terrain for a long run.

## 5.2 Use existing terrain archetypes

Inspect and reuse the existing archetypes reported in the project:

1. Flat
2. Gentle Hills
3. Steep Climb
4. Valley Dip
5. Jump Ramp
6. Rolling Waves
7. Plateau Drop
8. Bumpy Washboard
9. Double Crest

Do not duplicate these if they already exist. Improve their selection, transitions, and pacing only where testing identifies a problem.

## 5.3 Difficulty progression

Build a fair progression curve using existing adaptive difficulty support:

- Early run: broad, gentle hills to teach controls.
- Early-middle: moderate climbs, valleys, and small bumps.
- Middle: combinations of climbs, dips, and jumps.
- Later: more frequent challenging combinations, while preserving recovery opportunities.
- Very long runs: varied terrain, not simply maximum steepness everywhere.

Difficulty should increase gradually and should not make the game impossible because of random segment selection.

Add a safe recovery rhythm: challenging sections should sometimes be followed by a flatter or more manageable section.

## 5.4 Terrain verification

Test at least:
- Initial spawn and first several segments.
- Multiple transitions between all available archetypes.
- 5,000+ pixels of travel.
- 25,000+ pixels of travel if practical.
- Segment recycling and reuse.
- Restart after traveling far into the generated world.
- Pickups near segment boundaries.
- Vehicle collision at segment joins.

Record actual distance or test duration, node/pool counts if available, and any observed gaps or frame spikes.

**Acceptance criteria:** A sustained run continues generating terrain with no visible end, no collision gaps, no unbounded node growth, and no major performance stalls.

---

# 6. PRIORITY 3 — MAKE THE CAMERA AND WORLD FEEL ALIVE

Reuse the existing `FollowCamera.gd` and parallax environment. Do not replace the environment artwork.

Improve only where needed:

- Smooth horizontal camera follow with a small forward look-ahead.
- Camera vertical movement should follow hills and jumps without excessive bouncing.
- Use mild camera smoothing; do not make the camera lag so much that the player loses visibility.
- Keep the vehicle and upcoming terrain visible.
- Avoid abrupt camera snapping on restart.
- Use existing parallax layers to create a sense of depth and speed.
- Check that parallax loops seamlessly during long runs.
- Optional subtle camera shake on hard landing or crash, with a small amplitude and short duration.
- Optional subtle zoom or framing adjustment for large jumps only if it does not disorient the player.

**Acceptance criteria:** The player can always judge the upcoming ground and vehicle position; camera motion feels smooth rather than distracting.

---

# 7. PRIORITY 4 — GAMEPLAY FEEDBACK AND SMALL FEATURES

Add only small features that fit the existing systems and do not delay the main driving/terrain experience.

## 7.1 Fuel and coin placement

Reuse existing procedural pickup placement.

- Fuel cans should be reachable with normal driving skill.
- Do not place fuel inside terrain or beyond an impossible jump.
- Avoid placing fuel so frequently that fuel management becomes meaningless.
- Coins can form simple lines or arcs that encourage controlled jumps.
- Do not force the player into an unavoidable crash to collect rewards.
- Preserve the existing anti-double-collection behavior.
- Ensure pickups reset/reappear correctly for a new run according to current design.

## 7.2 Distance milestones

Add small distance feedback at reasonable milestones, for example:
- 100 m
- 250 m
- 500 m
- 1,000 m

Use a short HUD banner or subtle animation. Avoid blocking gameplay or pausing the game.

## 7.3 Landing feedback

When the vehicle lands:
- Reuse the existing landing detection and landing sound.
- Add a subtle visual response if appropriate.
- Avoid playing the effect repeatedly while wheels remain in contact.
- Do not award duplicate airtime/stunt rewards.

## 7.4 Stunt feedback

If the existing stunt detection is already implemented:
- Verify frontflip/backflip detection.
- Verify airtime rewards.
- Show a brief readable reward notification.
- Ensure a crash cancels unearned stunt rewards.
- Do not create a second stunt detector.

## 7.5 Fuel warning

Reuse the existing low-fuel HUD indicator:
- Warning should be clear but not cover the road.
- Do not flash constantly at normal fuel levels.
- Ensure it resets on restart.

## 7.6 Optional small gameplay addition: near-miss / clean landing bonus

Only if the core game is stable:
- A clean landing after a jump may award a small bonus.
- A near-miss bonus may reward narrowly avoiding a crash only if reliable detection is possible.
- Do not add these if they require fragile physics heuristics or create confusing rewards.

---

# 8. PRIORITY 5 — UI AND PLAYER FLOW

Reuse the current Main Menu, HUD, Pause Menu, Results Screen, and SaveManager.

Improve:
- Clear Start/Resume/Restart navigation.
- Clear display of distance, best distance, fuel, and coins.
- Results screen should explain why the run ended (crash or out of fuel).
- Results should show current distance, best distance, and run coins.
- Retry should start a clean run.
- Main menu should show persistent best distance and total coins if already supported.
- Button focus and keyboard navigation should be usable.
- Avoid text overlapping the vehicle or important terrain.
- Keep a consistent visual style.
- If mobile is selected, add touch controls only after confirming target platform and mapping.

Do not create a second HUD or results system.

---

# 9. PRIORITY 6 — AUDIO AND VISUAL POLISH

Reuse existing assets and audio hooks. First inspect the asset register and licenses.

Improve only what is missing or clearly defective:
- Engine audio should respond smoothly to throttle and wheel speed.
- Avoid sudden pitch jumps or audio continuing after game over.
- Tire skid sound should reflect actual wheel slip/braking, not play continuously.
- Landing audio should trigger once per landing.
- Existing dust and exhaust particles should be visible but not overwhelm the scene.
- Pickup sounds and visual feedback should be distinct.
- Background/parallax should support the terrain rather than distract.
- Ensure all audio levels are balanced.

Do not download or add assets without recording their source and license in `docs/ASSET_REGISTER.md`.

---

# 10. PRIORITY 7 — FIX AND VERIFY CROSS-SYSTEM CONSISTENCY

Review these known risk areas from the current source review.

## 10.1 One authoritative fuel value

The current code review identified that `VehicleController` and `GameManager` may both store fuel. `FuelPickup.gd` appears to call both `vehicle.refuel()` and `GameManager.add_fuel()`.

Inspect the actual current implementation. Choose one authoritative fuel owner and make the HUD, game-over logic, and pickups read/update that same value. Avoid two independent values that can drift.

Preserve fuel tank upgrades and fuel signals.

## 10.2 Distance semantics

Review whether current distance is:
- Current forward progress in this run.
- Best distance reached in this run.
- Persistent best distance across runs.

Do not mix these concepts. Backward movement should not increase progress. Restart should reset current run distance but preserve persistent records.

## 10.3 Restart completeness

Test reset of:
- Chassis and both wheels.
- Linear and angular velocity.
- Vehicle crash flags and temporary states.
- Fuel and run timer.
- Distance and run rewards.
- Pickup collection state.
- Terrain generator state and segment pool.
- Camera framing.
- HUD, pause, and results UI.
- Temporary particles, popups, and tweens where necessary.

Do not assume setting only the chassis position is sufficient. Verify the joints and wheel assembly after reset.

## 10.4 Game state and input

Ensure:
- Gameplay input is ignored while paused or finished.
- Crash/out-of-fuel only finishes a run once.
- Pause cannot be activated after finish.
- Restart works from the results screen.
- No duplicate input handling exists.
- Physics does not continue as normal gameplay while paused.
- Signals are connected once and disconnected safely when nodes are removed.

---

# 11. IMPLEMENTATION ORDER — DO NOT DO EVERYTHING AT ONCE

AGY must follow this order and report after each stage.

## Stage A — Audit and backup

- Inspect Git status and current branch.
- Create a safe feature branch.
- Inspect all current files.
- Run existing tests before editing.
- Record baseline vehicle tuning values.
- Report findings and proposed minimal edits.

**Do not edit until the audit report is produced.**

## Stage B — Fix driving feel

- Diagnose weak uphill acceleration.
- Tune torque, speed limit, traction, mass, and suspension only as evidence requires.
- Preserve existing vehicle variants and upgrades.
- Test flat, moderate slope, steep slope, jump, and landing.
- Record before/after values.

## Stage C — Verify endless terrain integration

- Confirm `Game.tscn` uses the existing procedural generator for the endless mode.
- Keep `TestTrack.tscn` for controlled tests.
- Fix integration issues without replacing `TerrainGenerator.gd`.
- Test long runs, joins, pooling, restart, and pickup placement.

## Stage D — Fix cross-system consistency

- Fuel ownership and pickup update path.
- Distance semantics.
- Restart reset completeness.
- Game-over, results, pause, and input consistency.

## Stage E — Add small gameplay improvements

- Distance milestone notifications.
- Better landing/pickup feedback.
- Fair pickup distribution.
- Small camera and audio polish.
- Optional bonuses only if stable.

## Stage F — Regression and final verification

- Run all existing test scripts.
- Add targeted tests for any changed behavior.
- Perform manual gameplay tests.
- Inspect Godot output for errors and warnings.
- Update documentation and progress tracker.
- Review Git diff for accidental changes.

---

# 12. REQUIRED TEST PLAN

Run the actual project using the agreed Godot 4.3 version.

## Vehicle tests
- Accelerate on flat terrain.
- Brake and reverse.
- Climb a moderate hill.
- Climb a steep hill.
- Observe wheel spin and traction.
- Test air rotation.
- Test landing and suspension.
- Test crash detection.
- Test each vehicle variant if supported.

## Endless terrain tests
- Confirm procedural mode starts.
- Confirm new terrain appears before the player reaches the end.
- Confirm old terrain is recycled.
- Confirm joins have no visual/collision gaps.
- Confirm all archetypes can appear.
- Confirm difficulty progression is gradual.
- Run a sustained test (target 25,000+ pixels if practical).
- Restart after a long run.

## Run loop and pickups
- Start, pause, resume, finish, and restart.
- Collect one coin and verify exactly one reward.
- Collect one fuel can and verify exactly one fuel restoration.
- Confirm fuel never exceeds maximum or falls below zero.
- Run out of fuel and confirm correct results.
- Crash and confirm correct results.
- Verify current distance resets and best distance persists.
- Verify pickups and terrain reset correctly.

## UI/audio
- Check HUD readability.
- Check low-fuel warning.
- Check results reason and values.
- Check menu and pause controls.
- Check engine, skid, landing, pickup, and crash audio.
- Confirm no audio or effects remain stuck after restart.

## Test reporting rules

For each test, report one of:
- PASS — actually executed and passed.
- FAIL — executed and failed.
- NOT RUN — not executed.
- MANUAL REQUIRED — cannot be reliably verified by the automated test.

Never fabricate test results or claim a full gameplay test based only on code inspection.

---

# 13. DEFINITION OF DONE

The upgrade is complete only when:

- [ ] Existing Member 2 vehicle systems are preserved and still work.
- [ ] Existing Member 3 terrain, environment, and HUD systems are preserved and still work.
- [ ] The vehicle feels responsive and can climb intended hills.
- [ ] Vehicle remains controllable and stable.
- [ ] Endless terrain is connected to the actual game mode.
- [ ] Terrain extends continuously and recycles safely.
- [ ] Difficulty progression is fair.
- [ ] Fuel, coins, distance, and best distance are consistent.
- [ ] Crash and out-of-fuel endings work.
- [ ] Restart resets transient gameplay state completely.
- [ ] HUD, results, and pause flow remain correct.
- [ ] Existing tests pass or any failures are explained.
- [ ] Manual gameplay tests are recorded.
- [ ] No new blocking runtime errors or warnings are present.
- [ ] Asset sources/licenses are documented.
- [ ] `DEVELOPMENT_PROGRESS.md`, `HILL_CLIMB_MASTER_TODO.md`, and relevant technical docs are updated.
- [ ] Changes are committed on the feature branch and reviewed before merging.

---

# 14. REQUIRED AGY FINAL REPORT

When finished, provide:

1. **Audit summary:** What was already implemented and what was missing.
2. **Root causes:** Actual causes of weak acceleration or any other defects.
3. **Files changed:** Exact list, with reason for each change.
4. **Files deliberately preserved:** Especially Member 2 and Member 3 completed modules.
5. **Vehicle tuning table:** Before/after values and reason.
6. **Endless terrain verification:** Which generator is used, how recycling works, and how long it was tested.
7. **Gameplay features added:** Only features actually implemented.
8. **Test report:** PASS / FAIL / NOT RUN / MANUAL REQUIRED.
9. **Known limitations:** Honest list of anything unfinished.
10. **How to play:** Controls and how to test the finished game.

Do not say “everything is complete” unless the definition of done is genuinely satisfied.

---

# 15. FINAL DIRECTION

Work as a careful senior Godot gameplay engineer and integration lead.

The objective is not to generate the maximum amount of code. The objective is to make the existing project feel like a coherent, polished, classic hill-climb driving game while protecting the work already completed by the other two team members.

**Inspect first. Preserve working systems. Make small changes. Test continuously. Explain clearly.**
