# NEW VEHICLES IMPLEMENTATION REPORT

**Project:** Hill Climb 2D  
**Engine:** Godot 4.7+ Stable  
**Date:** 2026-11-05  

---

## 1. Overview & Problem Statement
The user provided a new vehicle asset archive `zip- asset.zip` containing 7 nested zip files for three new vehicle designs:
1. **Blue Flame Truck**
2. **Orc Racer**
3. **Trophy Truck**

The player requested:
- Extracting and properly organising assets into dedicated directories under `res://assets/vehicles/`.
- Building separate vehicle scenes using existing vehicle architecture and shared controller capabilities.
- Providing individual rotating wheels, suspension struts, driver sprites, exhaust pipes, particle emitters, and crash detectors.
- Tailoring distinct physical properties (mass, motor torque, brake torque, suspension softness, tire friction, air tilt torque) for each vehicle.
- Registering all 3 vehicles in `VehicleRegistry.gd` alongside existing vehicles (`classic_car`, `monster_truck`, `dune_buggy`, and `one_wheel_scooter`).
- Ensuring full compatibility with Nitro boost visuals, fuel consumption, refuel mechanics, camera targeting, HUD speedometer, and save persistence.

---

## 2. Asset Organisation
All nested zip archives were extracted and mapped into clean project paths:

### 2.1 Blue Flame Truck (`res://assets/vehicles/blue_flame_truck/`)
- `vehicle_body_truck_side.png` (Chassis side body artwork with flame design)
- `driver_sprite.png` (Driver cockpit artwork)
- `wheel_front.png` & `wheel_rear.png` (Heavy-tread off-road tires)
- `wheel_rim_hub_detailed.png` (Chrome detailed hubcap rims)
- `vehicle_assembled_preview.png` (High-resolution assembled preview for selection card)
- `vehicle_layer_breakdown_preview.png`, `wheel_rim_hub_aligned.png`, `wheel_rim_hub.png`, `wheel_tire_tread.png`

### 2.2 Orc Racer (`res://assets/vehicles/orc_racer/`)
- `body.png` (Wasteland roll-cage racer chassis)
- `driver.png` (Orc driver with helmet)
- `wheel_front.png` & `wheel_rear.png` (Lightweight alloy sprint wheels)

### 2.3 Trophy Truck (`res://assets/vehicles/trophy_truck/`)
- `body.png` (Long-wheelbase desert baja truck chassis)
- `wheel.png` (All-terrain off-road desert tire)
- `assembled.png` (Composite assembly preview for selection card)

---

## 3. Vehicle Scenes & Physics Specifications

### 3.1 Blue Flame Truck (`scenes/vehicle/BlueFlameTruck.tscn`)
- **Chassis Body:** `vehicle_body_truck_side.png` (Scale: 0.18)
- **Driver:** `driver_sprite.png` (Scale: 0.14, Pos: -6, -18)
- **Wheels:** Front & Rear wheels with detailed chrome rims (`radius = 22.0px`)
- **Mounts & Joints:** Rear `(-42, 18)`, Front `(45, 18)`, `softness = 0.65`
- **Mass:** 10.0 kg
- **Base Motor Torque:** 110,000.0 Nm
- **Base Brake Torque:** 65,000.0 Nm
- **Tire Friction:** 1.80
- **Air Tilt Torque:** 30,000.0 Nm
- **Gameplay Feel:** Heavyweight muscle truck with strong low-end hill-climbing torque and solid suspension compliance.

### 3.2 Orc Racer (`scenes/vehicle/OrcRacer.tscn`)
- **Chassis Body:** `body.png` (Scale: 0.18)
- **Driver:** `driver.png` (Scale: 0.15, Pos: -6, -18)
- **Wheels:** Front & Rear alloy wheels (`radius = 17.0px`)
- **Mounts & Joints:** Rear `(-38, 16)`, Front `(40, 16)`, `softness = 0.58`
- **Mass:** 7.5 kg
- **Base Motor Torque:** 85,000.0 Nm
- **Base Brake Torque:** 45,000.0 Nm
- **Tire Friction:** 1.75
- **Air Tilt Torque:** 30,000.0 Nm
- **Gameplay Feel:** Agile sprint buggy with quick acceleration, responsive mid-air rotation, and rapid recovery from steep launches.

### 3.3 Trophy Truck (`scenes/vehicle/TrophyTruck.tscn`)
- **Chassis Body:** `body.png` (Scale: 0.18)
- **Driver:** `driver_sprite.png` (Scale: 0.14, Pos: -4, -18)
- **Wheels:** Front & Rear desert tires (`radius = 19.0px`, Scale: 0.32)
- **Mounts & Joints:** Rear `(-42, 18)`, Front `(44, 18)`, `softness = 0.70`
- **Mass:** 9.0 kg
- **Base Motor Torque:** 95,000.0 Nm
- **Base Brake Torque:** 55,000.0 Nm
- **Tire Friction:** 1.80
- **Air Tilt Torque:** 29,000.0 Nm
- **Gameplay Feel:** Long-travel desert racer absorbing hard landings effortlessly while maintaining steady high-speed stability over rough bumps.

---

## 4. Vehicle Catalog Registration (`scripts/vehicle/VehicleRegistry.gd`)
All 7 vehicles are registered in `ORDERED_IDS`:
1. `classic_car` (Cost: 0, Free starter)
2. `monster_truck` (Cost: 250)
3. `dune_buggy` (Cost: 450)
4. `one_wheel_scooter` (Cost: 0, Starter monowheel)
5. `blue_flame_truck` (Cost: 300)
6. `orc_racer` (Cost: 350)
7. `trophy_truck` (Cost: 500)

---

## 5. Verification & Results
- Verified in `tests/test_ui_pickups_and_new_vehicles.gd`:
  - All 3 new vehicles instantiate cleanly from `VehicleRegistry`.
  - Wheels, mounts, suspension pin joints, and crash detectors verified.
  - `_ensure_nitro_visuals()` attaches Nitro flame, burst, and trailing sparks.
  - Boost activation and refuel mechanics function reliably.
- Verified in `tests/test_vehicle_physics.gd`:
  - 100% pass across all 7 fleet vehicles.
