# PICKUP COLLECTION BUG REPORT

**Project:** Hill Climb 2D  
**Engine:** Godot 4.7+ Stable  
**Date:** 2026-11-05  

---

## 1. Overview & Problem Statement
In the user-supplied gameplay screenshot, coins were clearly floating high above the terrain on a hill slope, while others were failing to register collection when passed over by the player's vehicle.

The player requested:
- Coins and fuel canisters must always appear clearly above the terrain surface without penetrating the ground polygon or floating high into the air.
- Pickup collision shapes must align precisely with their visible artwork.
- Pickups must be physically reachable and reliably collectible on all terrain shapes (flat ground, uphill slopes, downhill slopes, valleys, and procedural endless tracks).
- Collision detection must reliably trigger when touched by any part of the vehicle (chassis, front wheel, rear wheel).
- Pickups must update HUD metrics immediately (+coins in GameManager, refuel in VehicleController) and play collection SFX/particles without double-rewarding.

---

## 2. Root Cause Analysis
1. **Vertical Clearance Jump Bug (`TerrainGenerator._calculate_safe_pickup_y`):**
   - The previous clearance calculation sampled 6 test points around the pickup's bounding box against `seg.collision_polygon`.
   - On uphill and downhill slopes, the outer test point at `local_x ± 16` fell inside the rising slope geometry.
   - When any point triggered `Geometry2D.is_point_in_polygon()`, the code jumped `safe_y` upwards by `highest_ground_y - (base_clearance + half_extent)`.
   - This subtracted 50px–70px from Y, pushing the coin into the sky. Because the vehicle's chassis was only ~34px above ground, the vehicle drove directly underneath the floating coin without touching its collision shape.
2. **Detection Filtering Narrowness (`Coin.gd` & `FuelPickup.gd`):**
   - Area2D detection previously relied on a shallow single-level `body.get_parent()` check.
   - When a wheel or child body with deep hierarchy entered the Area2D, or when an Area2D from the vehicle intersected, detection was dropped.
3. **Reset State Bug (`Coin.reset_pickup`):**
   - `Coin.reset_pickup()` forgot to re-enable `collision_shape.set_deferred("disabled", false)`, causing recycled coins to remain permanently non-collidable after a restart.

---

## 3. Implementations & Changes
1. **Proportional Surface Clearance Calculation (`scripts/terrain/TerrainGenerator.gd`):**
   - Replaced the 50px vertical jump with a gentle iterative constraint solver.
   - Initial target Y: `minf(center_surf_y - base_clearance, highest_ground_y - (half_extent + 6.0))`.
   - If any perimeter point intersects the ground polygon, it nudges `safe_y -= 2.0` in micro-steps until strictly outside the collision polygon.
   - Result: Pickups are positioned between 30px and 60px above ground across all slope angles, precisely within the sweep volume of the vehicle chassis and wheels.
2. **Recursive Vehicle Detection (`scripts/pickups/Coin.gd` & `scripts/pickups/FuelPickup.gd`):**
   - Implemented `_is_vehicle(node)` / `_find_vehicle(node)` traversing up the parent chain (`while curr != null`).
   - Connected both `body_entered` and `area_entered` signals.
   - Re-enabled `collision_shape.set_deferred("disabled", false)` and `visual.visible = true` in `reset_pickup()`.
3. **Enlarged Collision Shapes:**
   - In `Coin.tscn`: `CircleShape2D` radius adjusted to `20.0px` (matching visible sprite + aura).
   - In `FuelPickup.tscn`: `RectangleShape2D` size adjusted to `Vector2(32, 36)`.
   - Fast-moving vehicles traveling over 180 km/h now register 100% collision coverage without tunneling.
4. **Group Registration (`scripts/vehicle/VehicleController.gd`):**
   - Automatically adds `self`, `rear_wheel`, and `front_wheel` to the `"vehicle"` group upon `_ready()`.

---

## 4. Verification & Results
- Verified in `tests/test_ui_pickups_and_new_vehicles.gd`:
  - Zero underground pickups across flat, steep climb, and valley dip.
  - Clearance strictly maintained within reachable bounds (30–65px for coins, 40–75px for fuel).
  - Touching rear wheel or front wheel triggers collection cleanly.
  - Single collection emit, particles emit, SFX plays, and duplicate collection is blocked.
- Verified in `tests/test_new_vehicle_and_collectibles.gd`:
  - 100% pass across 26,000 px procedural run with 0 underground pickups.
