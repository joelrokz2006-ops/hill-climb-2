# Member 2: Vehicle Physics, Upgrades, Stunts & Roster Guide

**Project:** Hill Climb 2D  
**Owner:** Member 2 (Vehicle Gameplay & Physics)  
**Branch:** `feature/member-2-vehicle-upgrades`  
**Engine:** Godot 4.3 (GDScript)  

---

## 1. Overview & Architecture

The vehicle system is a modular, signal-driven 2D physics assembly providing realistic driving, suspension compliance, stunt trick rewards, dynamic audio, and upgrade tiers:
* **Chassis (`RigidBody2D`):** Mass = `8.0` (standard) / `12.0` (monster truck) / `6.0` (buggy), low center of gravity for anti-rollover balance.
* **Dual Wheels (`RigidBody2D`):** Connected via `PinJoint2D` with configurable softness.
* **Dynamic Shock Struts (`Line2D`):** Visually bridges chassis anchors to wheel hubs with dynamic compression and extension.
* **Roof Crash Area (`Area2D`):** Detects driver head/roof impacts with ground terrain (Collision Layer 1).
* **Audio & Effects:**
  * **Dynamic Engine RPM:** Pitch scales smoothly `0.8 - 2.2` based on physical wheel speed and throttle.
  * **Tire Skid Audio:** Fades in during hard braking or high-wheel-spin burnouts.
  * **Low-Fuel Sputter:** Sputters throttle and engine power when tank drops below 15% as physical/audible feedback.
  * **Exhaust Smoke & Tire Dust:** Visual particle emissions when driving.

---

## 2. Stunt & Trick Detection System

VehicleController tracks angular rotation and duration while airborne (`is_grounded == false`):

| Stunt Event | Condition | Signal Emitted | Reward |
|---|---|---|---|
| **Backflip** | 360° clockwise air rotation | `trick_performed("Backflip", 20)` | 20 coins |
| **Frontflip** | 360° counter-clockwise air rotation | `trick_performed("Frontflip", 20)` | 20 coins |
| **Big Air Landing** | Airborne time ≥ 1.2 seconds, followed by clean wheel landing | `airtime_landed(duration, reward)` | 10 coins / second |

*Crash Protection:* If the vehicle crashes on its roof, all pending stunts and airtime rewards are cancelled.

---

## 3. Vehicle Upgrade System (4 Stats, Levels 1–5)

| Stat Name | Config Key | Formula / Effect | Level 1 (Base) | Level 5 (Max) |
|---|---|---|---|---|
| **Engine Power** | `engine_power` | `+20% torque, +12% top speed` per lvl | `18,000 Nm` | `32,400 Nm` |
| **Tire Grip** | `tire_grip` | `+22% friction` on PhysicsMaterial | `1.60 friction` | `3.01 friction` |
| **Suspension** | `suspension` | `-0.08 softness` (firmer damping) | `0.60 softness` | `0.28 softness` |
| **Fuel Tank** | `fuel_tank` | `+25% capacity` per lvl | `100.0 units` | `200.0 units` |

*Methods:*
* `get_stats() -> Dictionary`
* `apply_upgrade(stat_name: String, level: int) -> void`
* `signal upgraded(stat_name: String, level: int)`

---

## 4. Vehicle Catalog (`VehicleRegistry.gd`)

Static decoupled registry providing metadata and instantiators for all playable vehicles:

```gdscript
# Examples:
var all_vehicles: Array[Dictionary] = VehicleRegistry.get_all_vehicles()
var truck_info: Dictionary = VehicleRegistry.get_vehicle("monster_truck")
var vehicle_node: VehicleController = VehicleRegistry.instantiate_vehicle("dune_buggy")
var cost: int = VehicleRegistry.get_upgrade_cost(1) # -> 50 coins
```

### Vehicle Roster:
1. **Classic Hill Climber (`Vehicle.tscn`):** Balanced, agile roadster.
2. **Beast Monster Truck (`MonsterTruck.tscn`):** Heavy duty (`mass = 12.0`), massive 28px tires, high clearance.
3. **Electric Dune Buggy (`DuneBuggy.tscn`):** Ultralight (`mass = 6.0`), high air tilt speed, roll cage design for stunt flips.

---

## 5. Verification Commands

```bash
# Member 2 full suite:
godot --headless -s tests/test_vehicle_physics.gd

# Full project regression check:
godot --headless -s tests/test_game_loop.gd
godot --headless -s tests/test_phase2_core_loop.gd
godot --headless -s tests/test_terrain_and_hud.gd
```
