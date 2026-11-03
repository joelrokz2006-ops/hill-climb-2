# Member 2: Vehicle Physics & Tuning Guide

**Project:** Hill Climb 2D  
**Owner:** Member 2 (Vehicle Gameplay & Physics)  
**Branch:** `feature/vehicle-physics`  
**Engine:** Godot 4.3 (GDScript)  

---

## 1. Overview & Architecture

The vehicle is modeled as a 2D composite physics assembly:
* **Chassis (`RigidBody2D`):** Mass = `8.0`, Center of Mass offset = `Vector2(0, 10)` (low center of gravity for anti-rollover stability).
* **Rear & Front Wheels (`RigidBody2D`):** Mass = `2.5` each, high-friction physics material (`1.6` friction, `0.15` bounce).
* **Suspension (`PinJoint2D`):** Dual joints anchoring wheels to chassis with soft compliance (`softness = 0.6`).
* **Roof Crash Area (`Area2D`):** Detects driver head/roof impact against ground collision (Layer 1).
* **Dynamic Feedback:**
  * Exhaust smoke (`CPUParticles2D`) emits when accelerating.
  * Ground dust (`CPUParticles2D`) kicks up when wheels have ground contact and spin.
  * Dynamic engine pitch scale responds to driving speed and throttle.
  * Landing thud audio triggers on firm ground impact.

---

## 2. Exported Tuning Parameters Reference

These parameters are exposed on `VehicleController` for real-time editor tuning:

| Group | Parameter | Type | Default | Description |
|---|---|---|---|---|
| **Motor & Drive** | `motor_torque` | `float` | `18000.0` | Forward drive torque applied to wheels during acceleration. |
| | `brake_torque` | `float` | `12000.0` | Reverse / braking torque applied when pressing brake/reverse. |
| | `max_wheel_speed` | `float` | `80.0` | Maximum rotational velocity of wheels in radians/sec. |
| | `air_tilt_torque` | `float` | `12000.0` | Rotational torque applied for mid-air balancing and tilting. |
| | `airborne_angular_damping` | `float` | `1.5` | Rotational damping applied while airborne to stabilize landings. |
| **Fuel** | `consumes_fuel` | `bool` | `true` | Enables or disables fuel depletion during acceleration. |
| | `max_fuel` | `float` | `100.0` | Fuel tank capacity. |
| | `fuel_burn_rate` | `float` | `4.0` | Units of fuel consumed per second under full acceleration. |

---

## 3. Public Interface & Contract

Member 2 strictly adheres to the team interface contract:

### Signals
* `signal crashed`: Emitted when the driver head/roof strikes terrain.
* `signal fuel_changed(current: float, max_fuel: float)`: Emitted when fuel burns or refuels.

### Public Methods
* `reset_vehicle(at_position: Vector2) -> void`: Full physics reset via `PhysicsServer2D` restoring transform and clearing velocities.
* `refuel(amount: float) -> void`: Replenishes vehicle fuel tank (up to `max_fuel`).
* `get_speed_kmh() -> float`: Telemetry helper returning vehicle speed in km/h.

---

## 4. Isolated Test Bench (`VehicleTest.tscn`)

Located at: `scenes/vehicle/VehicleTest.tscn`

Includes:
1. Flat start platform (`0m - 20m`)
2. `15°` Gentle Incline
3. `30°` Steep Hill Climb
4. Crest & Downhill ski-ramp
5. Jump Lip & Airborne landing gap
6. Suspension ripple bumps

### How to Run:
* In editor: Open and press **F6** on `scenes/vehicle/VehicleTest.tscn`.
* Automated test:
  ```bash
  godot --headless -s tests/test_vehicle_physics.gd
  ```
