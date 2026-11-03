# Automated Tests Directory

This directory contains automated integration and unit test scripts for **Hill Climb 2D**.

## Available Tests

- `test_game_loop.gd`:
  - Instantiates `Main.tscn`
  - Validates `GameScene` mounting and `GameManager` state transitions
  - Verifies vehicle spawn, camera target binding, and HUD listeners
  - Simulates 60 physics frames of acceleration input and checks forward displacement
  - Verifies `GameManager` distance metric updates
  - Simulates run restart and asserts physics state reset to spawn position

- `test_vehicle_physics.gd`:
  - Standalone validation for Member 2 (Vehicle Gameplay & Physics)
  - Tests dual wheels, mass compliance, torque application, and refueling

- `test_phase2_core_loop.gd`:
  - Standalone validation for Phase 2 Core Run Loop
  - Tests vehicle acceleration, fuel depletion, results screen, pause overlay, pickup collection, and restart cycle

- `test_terrain_and_hud.gd`:
  - Complete standalone validation for Member 3 (Terrain, Pickups, Environment & HUD)
  - Tests `TerrainSegment` collision & visual synchronization across all 9 segment archetypes
  - Tests `TerrainGenerator` procedural spawning, seamless joins (0 gap), segment object pooling, and memory recycling
  - Tests dynamic difficulty progression and amplitude scaling across long distances
  - Tests procedural Coin and Fuel canister distribution, air arcs, contour trails, and 100% above-ground surface safety
  - Tests `ParallaxEnvironment` 5-layer depth scaling, cloud drift, and 0-gap seamless looping at mirror boundaries
  - Tests `HUDController` distance, low-fuel flashing warning beacon, refuel recovery, coin counter, pause, crash, and finish notifications
  - Tests responsive UI layout and full rect anchor presets
  - Tests standalone `Coin` and `FuelPickup` collection, particle bursts, and run reset
  - Tests `Vehicle` driving across procedural terrain scene (`ProceduralTrack.tscn`)

## How to Run Headless Tests

Run directly using Godot's headless CLI:

```bash
# Member 3 complete suite:
godot --headless -s tests/test_terrain_and_hud.gd

# Full integration suite:
godot --headless -s tests/test_game_loop.gd
godot --headless -s tests/test_phase2_core_loop.gd
godot --headless -s tests/test_vehicle_physics.gd
```
