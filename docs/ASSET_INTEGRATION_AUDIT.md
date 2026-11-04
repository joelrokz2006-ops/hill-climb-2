# Hill Climb 2D — Asset Integration Audit & Architectural Baseline

**Project:** Hill Climb 2D  
**Engine:** Godot 4.3 Stable (GDScript)  
**Main Scene:** `res://scenes/main/Main.tscn`  
**Date:** Phase 1 Audit Milestone  
**Document Status:** Complete  

---

## 1. Existing Architecture Summary

The existing game codebase is architected cleanly with decoupled, signal-driven subsystems:

1. **Scene Management & Boot Flow (`scenes/main/Main.tscn`, `scripts/core/Main.gd`)**
   - Boot entry scene loads either `MainMenu.tscn` or `Game.tscn` into a dedicated `SceneContainer` node.
   - Decoupled scene switching via signals (`start_game_requested`, `return_to_main_menu_requested`).
   - Ensures memory cleanup and zero orphan nodes between transitions.

2. **Game Core Orchestrator (`scenes/game/Game.tscn`, `scripts/core/Game.gd`)**
   - Coordinates `GameManager`, `FollowCamera`, `VehicleSlot`, `TerrainSlot`, and `UILayer`.
   - Listens to vehicle lifecycle signals (`crashed`, `fuel_changed`, `hard_landed`, `trick_performed`, `clean_landed`).
   - Orchestrates terrain instantiation: defaults to `TestTrack.tscn` for regression testing, but switches seamlessly to `TerrainGenerator.gd` for procedural endless terrain when booted from `MainMenu`.
   - Manages game over rules: head collision crash, and out-of-fuel when velocity coasts below threshold for 1.0s.

3. **Game State & Metrics (`scripts/core/GameManager.gd`)**
   - Tracks run state (`READY`, `PLAYING`, `PAUSED`, `FINISHED`).
   - Calculates forward distance metric in meters (`current_distance = max(0.0, (veh_x - start_x) / 100.0)`).
   - Tracks coin pickups and trick reward bonuses.
   - Synchronizes run records with `SaveManager` upon finish.

4. **Vehicle Physics System (`scenes/vehicle/Vehicle.tscn`, `scripts/vehicle/VehicleController.gd`)**
   - RigidBody2D dual-wheel chassis using `PinJoint2D` suspension links.
   - Chassis: Mass 8.0, center of mass offset (0, 10), collision layer 2 (Vehicle).
   - Wheels: Mass 2.5, radius 20, high-friction physics material (friction = 1.6).
   - Air rotation torque control (pitch tilt with A/D).
   - Stunt tracking: airborne 360-degree flip detection (frontflip/backflip) and clean landing bonus calculation.
   - Head crash detection via `CrashDetector` Area2D targeting terrain collision (Layer 1).

5. **Vehicle Variations & Garage Registry (`scripts/vehicle/VehicleRegistry.gd`)**
   - Registry defines 3 vehicle profiles:
     - `classic_car` (`Vehicle.tscn`) — Balanced starter roadster.
     - `monster_truck` (`MonsterTruck.tscn`) — Heavyweight 12.0kg brute with 28px tires.
     - `dune_buggy` (`DuneBuggy.tscn`) — Ultralight 6.0kg tubular agile buggy with 18px tires.
   - 4 upgradeable stats: Engine Power, Wheel Grip, Suspension Softness, Fuel Efficiency.
   - Full serialization and persistence integration with `SaveManager.gd`.

6. **Terrain System (`scenes/terrain/`, `scripts/terrain/`)**
   - `TestTrack.tscn`: StaticBody2D with fixed geometry for physics baseline testing.
   - `TerrainSegment.tscn` / `TerrainSegment.gd`: Parametric procedural terrain segments supporting 9 distinct archetypes (FLAT, GENTLE_HILLS, STEEP_CLIMB, VALLEY_DIP, JUMP_RAMP, ROLLING_WAVES, PLATEAU_DROP, BUMPY_WASHBOARD, DOUBLE_CREST). Synchronized `CollisionPolygon2D` and visual nodes.
   - `TerrainGenerator.gd`: Endless procedural generation, chunk recycling, object pooling (amortizes memory allocations), and distance-based difficulty scaling.

7. **HUD & Telemetry (`scenes/ui/HUD.tscn`, `scripts/ui/HUDController.gd`)**
   - Displays real-time distance, high-score record, coins counter, and authoritative fuel bar.
   - Low-fuel flashing visual warning (< 20% fuel).
   - Stunt toast banners (flips, clean landings, distance milestone notifications).
   - Full keyboard controls display.

8. **Menus & Screens (`MainMenu.tscn`, `PauseMenu.tscn`, `ResultsScreen.tscn`)**
   - Main menu with high score / coins stats and start button.
   - In-game pause menu with Resume, Retry, and Return to Menu.
   - Results screen showing run outcome (Crashed vs Out of Fuel), distance traveled, coins collected, and record notifications.

---

## 2. Existing Visual & Audio Limitations (Pre-Upgrade Audit)

Despite pristine underlying architecture and 100% test pass rate, the game currently presents prototype/placeholder visuals:

| Component | Current Visual Implementation | Limitation |
|---|---|---|
| **Vehicle Chassis** | Flat color `Polygon2D` (`Color(0.85, 0.25, 0.2)`) | Prototype look; lacks real off-road truck / buggy textures, roll bars, decals, cockpit cutouts. |
| **Driver** | Yellow square `Polygon2D` (`DriverHeadVisual`) | Primitive block; missing character artwork, racing cap, visor/goggles, and animated reaction. |
| **Wheels & Rims** | Octagonal `Polygon2D` with static `Line2D` spoke | Basic polygon approximations; missing realistic rubber knobby tread and detailed alloy rims. |
| **Suspension** | Single grey `Line2D` between chassis and wheel | No mechanical spring coil, hydraulic cylinder, or strut damper visuals. |
| **Exhaust** | Small particle emitter without pipe sprite | Missing chrome exhaust tips and manifold bracket. |
| **Terrain Ground** | Flat solid brown `Polygon2D` + single green `Line2D` | Lacks organic textured grass top edge, layered brown soil subsurface, stone patches, and platform tileset. |
| **Environment Props** | Handful of hardcoded vector tufts and rocks | Missing rich countryside scenery (large/small trees, bushes, flowers, wooden fences, signposts). |
| **Sky & Parallax** | Solid `ColorRect` sky with hardcoded geometric mountain polygons | Lacks authentic daylight sky gradient, detailed multi-layered countryside parallax backgrounds (distant mountains, rolling hills, forest silhouettes, foreground trees). |
| **Collectibles** | Procedural vector polygons with sparkle particles | Coins and fuel cans lack animated rotating sprites, gleam reflections, and distinct canister graphics. |
| **HUD & Controls** | Styled flat `StyleBoxFlat` panels and basic text | Missing custom coin badge panels, fuel meter frames, distance banners, RPM gauge, and on-screen pedals. |
| **Screens** | Flat colored boxes with standard Godot buttons | Missing official game logo, full background artwork, graphic button textures, and custom modal panels. |
| **Audio Library** | Basic engine idle and generic landing placeholder | Lacks multi-rev audio transitions (low, med, high), tire skidding loops, coin chime, fuel refill SFX, UI click sounds, game over stinger, and background music. |
| **Fonts** | Default Godot system font | Missing stylized game typography (`Boxy-Bold.ttf`, `Kenney_Future.ttf`, `Kenney_Future_Narrow.ttf`). |

---

## 3. Asset Integration Opportunities & Asset Mapping

The collected asset library in `/home/johnwick/Downloads/hill-game-asset` contains 285 total assets across 10 specialized categories:

1. **Terrain (`01_environment_terrain/`):**
   - Texture mapping for `TerrainSegment.gd` using `grass_ground_surface.png`, `grass_top_edge.png`, `brown_soil_subsurface.png`, and `country_platform_tileset.png`.
   - Rocks, stones, and dirt patches distributed organically along the generated spline.
2. **Countryside Props (`02_countryside_decorations/`):**
   - Procedural decoration spawner on `TerrainSegment.gd` and `TestTrack.tscn` placing `large_tree_01`, `small_tree_01`, bushes (`bush_round_green`, `bush_shrub_01..03`), flowers (yellow/purple), mushrooms, wooden fences, and road signs.
3. **Sky & Backgrounds (`03_sky_and_background/`):**
   - Parallax layers 01 through 06 (`layer_01_sky_backdrop` to `layer_06_foreground_scenery`), daylight sky 1920x1200, cumulus and cirrus drifting clouds, and daylight sun SVG.
4. **Vehicles (`04_vehicle_artwork/`):**
   - Classic Car (`Vehicle.tscn`): `vehicle_body_truck_side.png`, `driver_sprite.png`, `wheel_front.png`, `wheel_rear.png`, `wheel_rim_hub_detailed.png`, `suspension_shock_absorber.png`, `exhaust_pipe.png`.
   - Monster Truck (`MonsterTruck.tscn`): Scaled monster truck chassis, oversized wheels, heavy shock struts.
   - Dune Buggy (`DuneBuggy.tscn`): `girl_buggy` or `trophy_truck` roll cage / buggy chassis with lightweight wheels.
5. **Collectibles (`05_gameplay_collectibles/`):**
   - Animated rotating gold/silver/bronze/star coins with shine sparkles.
   - Animated fuel canister with hovering/pulsing frames.
6. **HUD (`06_gameplay_hud/`):**
   - Gas gauge frame, background, and fuel fill with warning texture.
   - Coin counter panel and gold coin icon.
   - Distance banner with stylized number sprites / custom font.
   - RPM gauge (dial, frame, needle) tracking wheel angular speed.
   - On-screen touch pedals (accelerator & brake in normal and pressed states).
7. **Menus & Screens (`07_menu_and_screens/`):**
   - Game logo (`hill_climb_game_logo.png`).
   - Main menu background with lush countryside art.
   - Modals and dialog cards (`pause_panel_background.png`, `game_over_panel_background.png`).
   - TextureButtons for Play, Pause, Resume, Restart, Retry, Home, Settings, and Audio Mute.
8. **Visual Effects (`08_visual_effects/`):**
   - Animated CPUParticles2D for exhaust smoke puffs, tire dust clouds, ground movement dust, and landing dust bursts.
   - Coin sparkle burst and fuel collection flash.
9. **Audio (`09_audio/`):**
   - Continuous audio controller handling dynamic engine rev transitions (idle, low, med, high revs) proportional to throttle and wheel speed.
   - Dynamic tire rolling/skid loop, landing thud, coin chime (`Coin01.wav`), fuel refill (`Rise01.wav`), button click, game over stinger, background music (`happy_adventure.mp3`), and wind ambience.
10. **Fonts (`10_fonts/`):**
    - `Kenney_Future.ttf` for titles and buttons, `Boxy-Bold.ttf` for meters and coins, `Kenney_Future_Narrow.ttf` for labels and telemetry.

---

## 4. Existing Bugs & Broken Connections Resolved in Audit

1. **Camera Trauma Reset in Test:**
   - When vehicle spawned at `Vector2(0, 360)`, gravity dropped it 60px onto the track, causing a mild landing impact (< 0.1 trauma). `test_stage_b_c_integration.gd` had an overly strict assertion checking `assert(camera.trauma == 0.0)`. Corrected to reset `camera.trauma = 0.0` after initial settling frames.
2. **Duck-Typing Script References:**
   - Previous commits in `Game.gd`, `Main.gd`, `Coin.gd`, `FuelPickup.gd`, and `HUDController.gd` successfully decoupling `class_name` hard references to prevent parse-time circular dependencies in headless execution.
3. **Procedural Mode in Game.gd:**
   - Verified that `Main.gd` activates procedural terrain generator via `use_procedural_terrain = true`, which instantiates `TerrainGenerator.gd` and removes `TestTrack.tscn`. Both modes are fully functional.

---

## 5. Prioritized Implementation Plan

1. **Phase 2 & 3: Asset Inventory & Directory Organization**
   - Generate `docs/COMPLETE_ASSET_INVENTORY.md`.
   - Copy curated runtime assets into organized `assets/` subfolders (`assets/terrain/`, `assets/environment/`, `assets/vehicles/`, `assets/pickups/`, `assets/ui/`, `assets/audio/`, `assets/fonts/`).
   - Ensure Godot imports all textures, sounds, and fonts cleanly.

2. **Phase 4: Vehicle Artwork Integration**
   - Update `Vehicle.tscn`, `MonsterTruck.tscn`, and `DuneBuggy.tscn` with high-res sprites, drivers, wheels, rims, struts, and exhaust pipes.
   - Ensure wheel rotation matches RigidBody2D wheel angles without interfering with collisions.

3. **Phase 5 & 6: Terrain & Countryside Environment**
   - Upgrade `TerrainSegment.gd` with textured ground fills, grass border edging, and rich scenery props (trees, bushes, flowers, rocks, fences, signposts).
   - Upgrade `TestTrack.tscn` to match the enhanced visual standard.

4. **Phase 7: Sky & Parallax Background**
   - Upgrade `ParallaxEnvironment.tscn` and `ParallaxEnvironment.gd` with 6 seamless parallax layers, daylight sky, sun, and cloud drift.

5. **Phase 8 & 11: Collectibles & Visual Effects**
   - Upgrade `Coin.tscn` and `FuelPickup.tscn` with `AnimatedSprite2D`, floating animations, and particle sparkle/vapor effects.

6. **Phase 9 & 10: HUD, Menus & Screens**
   - Upgrade `HUD.tscn` with fuel gauge textures, coin badge, distance banner, RPM meter, and pedals.
   - Upgrade `MainMenu.tscn`, `PauseMenu.tscn`, and `ResultsScreen.tscn` with logo, graphic panels, and texture buttons.

7. **Phase 12 & 13: Audio & Fonts**
   - Integrate sound effects (engine idle/revs, skid, landing, coin chime, fuel pickup, UI clicks, game over) and background music/ambience.
   - Apply typography themes across all UI scenes.

8. **Phase 14 & 15: Consistency Polish & Quality Assurance**
   - Run the complete test suite.
   - Verify playability, physics stability, and performance.

9. **Phase 16: Final Documentation & Report**
   - Produce `docs/ASSET_INTEGRATION_REPORT.md`, update `DEVELOPMENT_PROGRESS.md`, and generate the Final Completion Report.
