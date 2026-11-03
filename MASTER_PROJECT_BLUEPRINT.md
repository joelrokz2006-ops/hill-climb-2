# HILL CLIMB 2D — MASTER PROJECT BLUEPRINT
**Version:** 1.0  
**Status:** Planning / Foundation  
**Engine:** Godot 4.x  
**Language:** GDScript by default  
**Team size:** 3 members  
**Project type:** 2D side-view hill-driving game  
**Document owner:** Team Leader  
**Purpose:** This is the single source of truth for the game idea, architecture, team responsibilities, implementation phases, and AI-agent rules.

> **Important:** This project is inspired by the broad hill-driving genre. Do not copy another game's name, branding, exact UI, artwork, level layout, or proprietary assets. Build our own game identity and implementation.

---

# 1. Project Vision

Create a polished, playable 2D side-view hill-driving game in which the player drives a vehicle over rolling and uneven terrain, balances the vehicle in the air, collects rewards, manages fuel, and attempts to travel as far as possible.

## 1.1 Core player experience
- Easy to understand: accelerate and brake/reverse.
- Challenging to master: manage speed, rotation, landing, and terrain.
- Responsive vehicle movement with believable suspension and wheel contact.
- Readable terrain and HUD.
- A replay loop: drive → collect → run out of fuel/crash → receive results → retry and improve.

## 1.2 Initial scope (MVP)
The first playable milestone must contain:
- One playable vehicle.
- One test terrain / hill track.
- Camera that follows the vehicle.
- Acceleration and braking/reverse.
- Vehicle suspension/contact behavior that can handle slopes.
- A basic HUD showing distance and fuel (fuel may be a later MVP sub-step).
- A restart flow.

## 1.3 Planned features (after the MVP)
- Endless or procedurally extended terrain.
- Fuel pickups and fuel depletion.
- Coins or another in-game reward.
- Result screen and saved best distance / currency.
- Main menu and pause menu.
- Sound effects and music.
- Vehicle upgrades / additional vehicles, if time permits.
- Mobile touch controls if Android is selected as a target.

## 1.4 Explicit non-goals unless the team approves a scope change
- Online multiplayer.
- Real-money gambling, betting, or cash-out mechanics.
- User accounts, cloud saves, or backend services.
- Multiple worlds/vehicles before the first vehicle and terrain loop work.
- Rebuilding the entire game from scratch after the foundation is accepted.

---

# 2. Product Decisions and Project Rules

These decisions are the starting baseline. If a decision is not yet confirmed, label it **OPEN** and do not silently assume it is final.

| Decision | Baseline |
|---|---|
| Engine | Godot 4.x |
| Game view | 2D side-view |
| Main gameplay | Hill driving / distance challenge |
| Scripting | GDScript for the first prototype |
| Vehicle physics | `RigidBody2D`-based custom vehicle setup; validate with a test scene |
| Native C++ / GDExtension | Not part of the MVP unless explicitly approved |
| Target platform | OPEN — decide desktop, Android, or both before final input/UI polish |
| Art | Use the supplied project asset collection where appropriate; audit licenses and fit |
| Project style | Small modules, clear ownership, review before merging |

**Do not use Godot's `VehicleBody3D` for this 2D game.** It is a 3D node. A 2D vehicle needs a deliberate 2D setup and tested contact/suspension behavior.

---

# 3. Team of Three — Responsibilities

## Member 1 — Team Leader / Project Foundation / Integration
**Owns:** project setup, architecture, scene flow, shared conventions, integration, GitHub.

### Responsibilities
- Create the Godot project and repository.
- Establish folders, naming conventions, and project settings.
- Create the main scene and game flow.
- Define scene/script interfaces before parallel work begins.
- Integrate Member 2 and Member 3 work.
- Review pull requests and resolve conflicts.
- Keep this master blueprint and progress status current.
- Ensure the project opens and runs from a clean clone.

### Deliverables
- `project.godot` and base folder structure.
- Main scene and scene switching.
- Shared input actions.
- Integration-ready test scene.
- Git workflow and review process.

## Member 2 — Vehicle Gameplay / Physics
**Owns:** vehicle scene, driving controls, wheel/contact behavior, vehicle tuning.

### Responsibilities
- Build a self-contained vehicle scene.
- Implement accelerate, brake/reverse, and optional air rotation.
- Develop and test vehicle suspension/contact behavior.
- Tune mass, traction, torque/force, damping, and rotation.
- Add vehicle animations/sprite placement only after physics is stable.
- Provide a clear interface for the Game Manager and HUD.

### Deliverables
- `scenes/vehicle/Vehicle.tscn`
- Vehicle scripts and input integration.
- A test scene or documented steps proving the vehicle drives on a basic slope.
- A list of exported tuning properties and their meaning.

### Boundaries
- Do not edit the main scene or global game flow without coordination.
- Do not change the agreed input action names without notifying Member 1.
- Do not add a new physics plugin or native extension without approval.

## Member 3 — Terrain / Environment / HUD
**Owns:** terrain scene and generation, backgrounds, pickup visuals, HUD components.

### Responsibilities
- Create a simple fixed test track first.
- Implement terrain collision that matches visible terrain.
- Prepare reusable terrain segments or a controlled terrain generator.
- Organize background/parallax layers.
- Create HUD elements for distance, fuel, and rewards.
- Ensure HUD scales/readable on the selected target platform.
- Audit supplied art for correct dimensions, transparency, and licensing.

### Deliverables
- Terrain scene and terrain scripts.
- Environment/background setup.
- HUD scene(s).
- Asset register and any missing-asset list.

### Boundaries
- Do not alter vehicle physics implementation.
- Do not create a new game loop or separate scene architecture without approval.
- Do not make the terrain generator the critical path before the fixed test track works.

## Shared responsibilities
All members must:
- Work in their assigned branch and folders.
- Keep scenes small and reusable.
- Test their own work before requesting review.
- Explain new dependencies and design changes.
- Avoid committing generated caches, editor temporary files, or secrets.
- Update the progress checklist when a deliverable is completed.

---

# 4. Folder and Scene Structure

Use this structure as the initial baseline. Add folders only when a real feature needs them.

```text
HillClimb2D/
├── project.godot
├── README.md
├── MASTER_PROJECT_BLUEPRINT.md
├── DEVELOPMENT_PROGRESS.md
├── TEAM_ROLES.md
├── .gitignore
│
├── assets/
│   ├── vehicles/
│   │   ├── player/
│   │   └── effects/
│   ├── terrain/
│   ├── environment/
│   │   ├── backgrounds/
│   │   └── parallax/
│   ├── pickups/
│   ├── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
│
├── scenes/
│   ├── main/
│   │   └── Main.tscn
│   ├── game/
│   │   └── Game.tscn
│   ├── vehicle/
│   │   └── Vehicle.tscn
│   ├── terrain/
│   │   ├── TestTrack.tscn
│   │   └── TerrainSegment.tscn
│   ├── pickups/
│   │   ├── Coin.tscn
│   │   └── FuelPickup.tscn
│   └── ui/
│       ├── HUD.tscn
│       ├── MainMenu.tscn
│       ├── PauseMenu.tscn
│       └── ResultsScreen.tscn
│
├── scripts/
│   ├── core/
│   │   ├── GameManager.gd
│   │   └── SaveManager.gd
│   ├── vehicle/
│   │   └── VehicleController.gd
│   ├── terrain/
│   │   └── TerrainGenerator.gd
│   ├── pickups/
│   │   ├── Coin.gd
│   │   └── FuelPickup.gd
│   └── ui/
│       └── HUDController.gd
│
├── docs/
│   ├── TEAM_ROLES.md
│   ├── DEVELOPMENT_PROGRESS.md
│   ├── ASSET_REGISTER.md
│   ├── TECHNICAL_DECISIONS.md
│   └── testing/
│
└── tests/
    └── README.md
```

## 4.1 Structure notes
- Godot scenes (`.tscn`) belong in `scenes/`.
- Scripts (`.gd`) belong in `scripts/`.
- Imported source art/audio belongs in `assets/`; do not manually edit Godot's generated `.godot/` cache.
- Keep `Main.tscn` as the entry point. It should control high-level scene flow, not contain all gameplay logic.
- `Game.tscn` assembles the vehicle, terrain, camera, and HUD.
- `Vehicle.tscn` must be reusable and should not depend on hard-coded paths into `Main.tscn`.
- `GameManager.gd` owns run state (playing, paused, finished), not the vehicle's low-level physics.
- `SaveManager.gd` owns local persistence only after the basic run loop works.

---

# 5. Architecture and Interfaces

## 5.1 Main scene flow
```text
Main
 ├── MainMenu (planned)
 └── Game
      ├── Terrain / TerrainGenerator
      ├── Vehicle
      ├── Camera2D
      └── HUD
```

The MVP can launch directly into `Game.tscn` while the menu is unfinished. Keep the future menu flow possible without redesigning the game scene.

## 5.2 Responsibility boundaries
- **Vehicle:** movement, physics, contact state, vehicle-specific signals.
- **Terrain:** ground shape, collision, terrain extension.
- **GameManager:** current run state, restart/end run, distance and run-level coordination.
- **HUD:** displays data and sends button requests; it should not calculate physics or own the run state.
- **Pickups:** detect collection and emit a signal / notify the run manager.
- **SaveManager:** local best distance and currency persistence; do not introduce a server.

## 5.3 Suggested signals / interfaces
Use these as a starting contract. Confirm names in a team discussion before implementation; do not create duplicate signal systems.

Vehicle may expose:
- `crashed` or `vehicle_disabled`
- `fuel_changed(current, maximum)` once fuel is implemented
- `distance_updated(distance)` only if the vehicle is the chosen distance source

Pickup may expose:
- `collected(value)` or a typed signal for coin/fuel pickup

GameManager may expose:
- `run_started`
- `run_paused`
- `run_finished(distance, reward)`

Prefer signals over hard-coded references between unrelated scenes. Avoid excessive global singletons.

---

# 6. AI Agent Rules — MUST FOLLOW

This section is mandatory for every AI coding assistant, agent, or code-generation tool used in the project. Copy it into the agent's project instructions if the tool supports that.

## 6.1 Protect the project's idea
1. **This blueprint is the source of truth.** Read it before proposing or editing project code.
2. Do not replace the hill-driving concept with another game genre, theme, or core loop.
3. Do not silently change the agreed feature list, controls, physics approach, folder structure, scene ownership, or team assignments.
4. Do not introduce multiplayer, accounts, online leaderboards, monetization, gambling, or backend services unless the human team explicitly approves.
5. Do not remove an existing feature or asset because a different design seems better.
6. Do not reinterpret “inspired by hill-driving games” as permission to copy copyrighted art, branding, exact UI, or levels.

## 6.2 Ask before making significant changes
Before a change that affects architecture, scene tree, dependencies, input names, save format, physics method, project settings, or another member's files:
- Explain the proposed change and why it is needed.
- List affected files and risks.
- Wait for explicit human approval.
- If no approval is given, keep the existing design.

Minor bug fixes within the assigned module may proceed, provided they do not change public interfaces.

## 6.3 File-editing safeguards
- Inspect the existing project before editing. Do not assume files are empty or use a template blindly.
- Make the smallest focused change that solves the task.
- Never overwrite the whole project, a whole scene, or a whole script when a targeted edit is enough.
- Preserve working code, comments, scene node names, signals, exported properties, and asset references unless the task explicitly requires changing them.
- Do not delete, rename, or move files without approval.
- Do not create duplicate scripts/scenes to avoid understanding the existing implementation.
- Do not change `.tscn` node paths casually; they may be referenced by scripts.
- Do not modify `project.godot`, `.gitignore`, shared core scripts, or another member's owned files without informing Member 1.
- Never modify or delete the blueprint or progress file without a human request. You may suggest updates separately.

## 6.4 Implementation quality
- Use Godot 4.x syntax and APIs. Do not provide Godot 3 syntax.
- Use GDScript by default. Do not add C++, GDExtension, plugins, or external libraries without approval.
- Follow the existing code style and naming conventions.
- Keep physics logic out of HUD scripts and UI logic out of vehicle physics scripts.
- Avoid unnecessary global variables and autoload singletons.
- Use typed variables where they improve clarity, and use exported properties for tunable values.
- Explain any non-obvious physics values or calculations.
- Do not claim a feature is implemented unless the relevant files were actually changed and tested.

## 6.5 Testing and reporting
After each task, report:
1. What changed.
2. Exact files changed/created.
3. What was tested and how.
4. Test result (pass / fail / not run).
5. Known limitations or follow-up work.
6. Any blueprint conflict or decision needing human approval.

If the agent cannot run Godot or verify a scene, it must say **“Not tested in Godot”** instead of claiming success.

## 6.6 Work in small phases
- Implement only the phase/task requested.
- Do not jump ahead to menus, upgrades, procedural generation, or polish while the vehicle-on-test-track milestone is broken.
- Keep the first implementation simple and replace it only after the team approves a specific improvement.
- When unsure, ask one concise question rather than inventing a project decision.

### AI agent instruction block (copy/paste)
```text
You are a coding assistant working on our Godot 4.x 2D hill-driving game.
Read MASTER_PROJECT_BLUEPRINT.md, DEVELOPMENT_PROGRESS.md, and TEAM_ROLES.md first.
The blueprint is the source of truth. Preserve the hill-driving concept and existing architecture.
Do not change the core idea, feature scope, folder structure, scene interfaces, physics approach,
dependencies, or another member's files without explaining the change and receiving explicit approval.
Inspect existing files before editing. Make small, targeted changes. Never overwrite or delete
working code/scenes/assets unnecessarily. Use Godot 4.x GDScript by default; no C++, plugins,
backend, multiplayer, or new major features unless approved.
Implement only the requested task. At the end, list changed files, explain changes, state exactly
what was tested, report limitations, and flag any decision that needs human approval.
Never claim testing or completion if it was not actually verified in Godot.
```

---

# 7. Development Phases — Master To-Do List

**Rule:** Do not mark a checkbox complete until the feature is implemented and verified. “Planned” is not “done.”

## Phase 0 — Project and team setup
- [ ] Confirm Godot 4.x version used by all members.
- [ ] Confirm target platform: desktop, Android, or both.
- [ ] Create Git repository and add this blueprint.
- [ ] Create initial folder structure.
- [ ] Add `.gitignore` for Godot-generated files and editor caches.
- [ ] Establish branch naming and pull-request process.
- [ ] Confirm input action names.
- [ ] Create a minimal project that opens and runs.

**Exit criteria:** All three members can clone/open the project; main scene runs without errors.

## Phase 1 — Vehicle prototype on a fixed test hill (FIRST PLAYABLE)
- [ ] Member 1 creates `Main.tscn` and `Game.tscn` skeleton.
- [ ] Member 3 creates a fixed test hill with matching collision.
- [ ] Member 2 creates the first vehicle physics prototype.
- [ ] Add camera follow.
- [ ] Add accelerate and brake/reverse controls.
- [ ] Test driving up and down the hill.
- [ ] Test vehicle landing and rotation behavior.
- [ ] Tune physics to prevent constant flipping, sinking, or jitter.
- [ ] Integrate all parts into one playable scene.
- [ ] Run a clean test from the project entry scene.

**Exit criteria:** Player can repeatedly drive across the test hill; no critical physics or scene errors.

## Phase 2 — Core run loop
- [ ] Create run states: playing, paused, finished.
- [ ] Add distance tracking.
- [ ] Add a restart action/button.
- [ ] Add basic results display.
- [ ] Add fuel value and depletion.
- [ ] Add fuel pickup.
- [ ] Add game-over condition.
- [ ] Verify restarting resets the run correctly.

**Exit criteria:** A complete run can start, progress, end, and restart.

## Phase 3 — Terrain progression
- [ ] Choose fixed segments or procedural terrain after prototype testing.
- [ ] Create reusable terrain segments.
- [ ] Extend terrain ahead of the vehicle.
- [ ] Remove/recycle terrain behind the vehicle safely.
- [ ] Ensure collision joins do not have gaps or sharp unintended edges.
- [ ] Add basic variation while preserving fair driving.
- [ ] Test long runs for performance and stability.

**Exit criteria:** Terrain continues as the player moves; no visible/collision gaps in a sustained test.

## Phase 4 — Pickups and rewards
- [ ] Add coin/reward pickup.
- [ ] Add pickup collision and collection feedback.
- [ ] Update reward counter.
- [ ] Prevent double collection.
- [ ] Add local save for currency and best distance.
- [ ] Test save/load across game restarts.

**Exit criteria:** Pickups work once each and saved values persist correctly.

## Phase 5 — UI and game flow
- [ ] Main menu.
- [ ] Start game button.
- [ ] Pause/resume.
- [ ] Restart.
- [ ] Results screen.
- [ ] HUD for distance, fuel, and currency.
- [ ] Consistent UI styling.
- [ ] Test UI at the chosen resolution/aspect ratio.
- [ ] If Android is a target, add and test touch controls.

**Exit criteria:** Player can navigate the game without editor controls and UI remains readable.

## Phase 6 — Art, audio, and polish
- [ ] Audit and assign final sprites.
- [ ] Confirm sprite scale and transparent margins.
- [ ] Align vehicle body and wheel visuals with physics.
- [ ] Add background/parallax.
- [ ] Add engine, pickup, crash, and UI sounds as appropriate.
- [ ] Add subtle effects/animations.
- [ ] Tune camera smoothing and visual feedback.
- [ ] Check performance and remove unused assets.

**Exit criteria:** Game looks and sounds cohesive; visuals do not interfere with gameplay.

## Phase 7 — QA and release preparation
- [ ] Test all core controls.
- [ ] Test run start/end/restart.
- [ ] Test fuel and pickups.
- [ ] Test save/load.
- [ ] Test terrain over a long run.
- [ ] Check output/debug console for errors and warnings.
- [ ] Test on each selected target platform.
- [ ] Verify asset licenses and attribution.
- [ ] Prepare README and build instructions.
- [ ] Create a release build and test it outside the editor.

**Exit criteria:** A reproducible build is playable, documented, and has no known blocking issue.

## Phase 8 — Optional approved enhancements
- [ ] Vehicle upgrades.
- [ ] Additional vehicles.
- [ ] Additional terrain themes.
- [ ] Achievements or missions.
- [ ] Mobile-specific polish.
- [ ] Other enhancements only after the MVP is stable.

---

# 8. Git and Collaboration Workflow

## 8.1 Branches
Recommended:
- `main` — stable, tested project.
- `feature/foundation` — Member 1.
- `feature/vehicle-physics` — Member 2.
- `feature/terrain-hud` — Member 3.

For individual tasks, branches may be created from the relevant feature branch:
- `feature/camera-follow`
- `feature/fuel-system`
- `fix/terrain-collision`

## 8.2 Rules
1. Do not commit directly to `main`.
2. Pull the latest base branch before starting.
3. Commit focused changes with clear messages.
4. Open a pull request for integration.
5. Member 1 reviews integration and scene conflicts.
6. Test the merged project before marking the phase complete.
7. Do not commit `.godot/` generated cache, local editor state, exported builds, or secrets unless there is a specific reason.

## 8.3 Suggested commit messages
- `feat: add vehicle prototype controls`
- `feat: create fixed test hill`
- `fix: improve vehicle slope stability`
- `feat: add distance HUD`
- `docs: update development progress`

---

# 9. Asset Audit and Licensing

- [ ] Create `docs/ASSET_REGISTER.md`.
- [ ] Record asset name, source, author, license, attribution requirement, and usage.
- [ ] Confirm the asset archive is extracted and organized.
- [ ] Confirm vehicle body and wheel sprites exist and fit the planned physics setup.
- [ ] Confirm terrain images have usable collision geometry.
- [ ] Check image dimensions, transparency, and pixel/art style consistency.
- [ ] Check audio formats and volume.
- [ ] Replace or create missing assets only after identifying what is missing.
- [ ] Do not assume an asset is free for commercial use merely because it is downloadable.

---

# 10. Definition of Done

A task is complete only when:
- [ ] The task matches this blueprint or has an approved decision update.
- [ ] The implementation is in the correct owned module.
- [ ] No unrelated feature or file was changed.
- [ ] The project opens in the agreed Godot version.
- [ ] The relevant behavior was tested, or testing limitations are stated.
- [ ] No new blocking errors are present.
- [ ] The owner updates `DEVELOPMENT_PROGRESS.md`.
- [ ] The change is committed and reviewed before merging to `main`.

---

# 11. Risk Register

| Risk | Mitigation |
|---|---|
| Vehicle feels unstable | Start with a fixed test hill; tune physics before endless terrain |
| Visual wheels do not match collision | Separate physics/contact nodes from wheel sprites; tune offsets |
| Team merge conflicts | Assign ownership; agree on interfaces; use pull requests |
| AI changes architecture unexpectedly | Enforce the AI rules and require approval for significant changes |
| Scope grows too early | Complete the MVP phases before optional features |
| Assets have unclear licenses | Track source/license and replace uncertain assets |
| Game works only in editor | Test a clean clone and exported build |

---

# 12. Immediate Start Order

## First work session
1. **Member 1:** Create/open the Godot project, add the blueprint, set up folders and Git, and make the main scene launch.
2. **Member 2:** Build the vehicle prototype in its own scene and test it independently on a simple slope.
3. **Member 3:** Build a fixed test hill with collision and prepare a basic background/HUD placeholder.
4. **Member 1:** Integrate the vehicle and terrain into `Game.tscn`; test the first playable loop.
5. Team: Review the result and update the progress file together.

Do not start with the main menu, upgrade system, full procedural terrain, or advanced effects. The first success is simple: **the car drives reliably over a test hill.**

---

# 13. Progress Log

| Date | Phase | Update | Owner |
|---|---|---|---|
| TBD | Phase 0 | Blueprint prepared; project setup and implementation still need confirmation | Team |
| TBD | Phase 1 | First vehicle-on-test-hill prototype | Members 1, 2, 3 |

**Current status:** Blueprint prepared. Do not report implementation milestones as complete until the team confirms they have been built and tested.
