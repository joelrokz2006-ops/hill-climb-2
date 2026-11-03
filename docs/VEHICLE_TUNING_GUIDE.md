# Member 2: Vehicle Physics, Upgrades & Tuning Guide

**Project:** Hill Climb 2D  
**Owner:** Member 2 (Vehicle Gameplay & Physics)  
**Branch:** `feature/member-2-vehicle-upgrades`  
**Engine:** Godot 4.3 (GDScript)  

---

## 1. Overview & Architecture

The vehicle is modeled as a 2D composite physics assembly with customizable upgrade tiers, dynamic RPM engine pitch modulation, and fine-tuned airborne flip control:
* **Chassis (`RigidBody2D`):** Mass = `8.0`, Center of Mass offset = `Vector2(0, 10)` (low center of gravity for anti-rollover stability).
* **Rear & Front Wheels (`RigidBody2D`):** Mass = `2.5` each, dynamically scalable friction (`PhysicsMaterial`).
* **Suspension (`PinJoint2D`):** Dual joints anchoring wheels to chassis with dynamic softness and dampening.
* **Roof Crash Area (`Area2D`):** Detects driver head/roof impact against ground collision (Layer 1).
* **Dynamic Feedback:**
  * **Dynamic RPM Engine Audio:** Pitch scales smoothly via `lerpf(0.8, 2.2, speed_ratio)` driven by wheel angular velocity and throttle input.
  * **Exhaust Smoke:** Particle bursts emit when accelerating.
  * **Tire Dust:** Kicks up when grounded wheels rotate against terrain.
  * **Landing Sound:** Triggers on heavy impact.

---

## 2. Vehicle Upgrade System (4 Stats, Levels 1–5)

VehicleController exposes 4 distinct upgradeable stats:

| Stat Name | Config Key | Multiplier / Formula | Level 1 (Base) | Level 5 (Max) | Description |
|---|---|---|---|---|---|
| **Engine Power** | `engine_power` | `+20% torque, +12% top speed` per lvl | `18,000 Nm` | `32,400 Nm` | Significantly boosts climbing power and uphill acceleration. |
| **Tire Grip** | `tire_grip` | `+22% friction` per lvl | `1.60 friction` | `3.01 friction` | Prevents tire slip on steep 30°–45° hills. |
| **Suspension** | `suspension` | `-0.08 softness` per lvl | `0.60 softness` | `0.28 softness` | Stiffens suspension, absorbing big drops and preventing bottoming out. |
| **Fuel Tank** | `fuel_tank` | `+25% capacity` per lvl | `100.0 units` | `200.0 units` | Doubles fuel capacity for extended runs. |

### Public Contract Functions & Signals:
* `get_stats() -> Dictionary`: Returns a dictionary of all 4 stats with current level, effective values, and multipliers.
* `apply_upgrade(stat_name: String, level: int) -> void`: Sets the specified stat tier (1–5) and recalculates all live physics properties immediately.
* `signal upgraded(stat_name: String, level: int)`: Emitted when any stat is upgraded.

---

## 3. Dynamic RPM Audio

In `_update_audio(delta: float)`:
* Calculates `wheel_speed_ratio = max(rear_w_rpm, front_w_rpm) / max_wheel_speed`.
* Blends with `throttle_ratio = Input.get_action_strength("accelerate")`.
* `speed_ratio = clamp((wheel_speed_ratio * 0.65) + (throttle_ratio * 0.35), 0.0, 1.0)`.
* `engine_audio.pitch_scale = lerpf(0.8, 2.2, speed_ratio)`.

---

## 4. Air Control & Flips

* `air_tilt_torque = 24000.0`: Agile response to `tilt_left` and `tilt_right` allowing smooth front-flips and back-flips.
* `max_air_angular_velocity = 6.5 rad/s`: Clamps maximum airborne rotational velocity to prevent uncontrollable death spins.
* `airborne_angular_damping = 2.0`: Automatically stabilizes and levels the car when the player releases tilt keys in mid-air.

---

## 5. Vehicle Variations

* **Standard Vehicle:** `scenes/vehicle/Vehicle.tscn` — Agile, balanced classic hill climber.
* **Monster Truck:** `scenes/vehicle/MonsterTruck.tscn` — Heavy chassis (`mass = 12.0`), massive knobby wheels (`radius = 28px`), higher ground clearance, and higher base motor torque (`28,000 Nm`). Fully interchangeable in any game scene.
