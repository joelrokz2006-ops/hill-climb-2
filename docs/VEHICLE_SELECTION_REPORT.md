# VEHICLE SELECTION REPORT

**Project:** Hill Climb 2D  
**Engine:** Godot 4.7+ Stable  
**Date:** 2026-11-05  

---

## 1. Overview & Problem Statement
In the reference screenshot of the vehicle select interface (`MainMenu.tscn`):
1. **Missing Preview:** The Beast Monster Truck card displayed no sprite preview (blank card).
2. **Duplicate Preview:** The Electric Dune Buggy card displayed the exact same red roadster sprite as the Classic Hill Climber.
3. **No Navigation Controls:** The interface lacked previous/next vehicle arrows and could not accommodate more than 4 vehicles without clipping.
4. **New Fleet Scale:** With 3 newly added vehicles (`Blue Flame Truck`, `Orc Racer`, and `Trophy Truck`), a total of 7 vehicles needed to be displayed seamlessly.

The player requested:
- A properly visible vehicle selection interface featuring:
  - Vehicle preview texture (unclipped, aspect-ratio preserved).
  - Vehicle name.
  - Previous vehicle arrow ("◀").
  - Next vehicle arrow ("▶").
  - Select button with clear visual highlight for the chosen car.
  - Selected vehicle indicator ("★ SELECTED").
  - Back button returning to the main menu.
- A horizontal carousel layout accessible via arrow buttons, touch gestures, mouse scrolling, and drag.
- Persistent saving of the selected vehicle in `SaveManager.gd`.
- Dynamic spawning of the selected vehicle at race start in `Game.gd`.

---

## 2. Root Cause Analysis
1. **Invalid Preview Path:** In `scripts/vehicle/VehicleRegistry.gd`, `monster_truck` had `preview_path` set to `"res://assets/vehicles/monster_truck/body.png"` which did not exist on disk.
2. **Hardcoded Vehicle IDs in SaveManager:** `SaveManager.gd` had a hardcoded array `["classic_car", "monster_truck", "dune_buggy", "one_wheel_scooter"]`. Any selection outside those 4 was discarded and defaulted back to `"classic_car"`.
3. **Static Grid vs Carousel:** The menu had a plain `HBoxContainer` without left/right carousel arrow navigation buttons, preventing smooth paging through larger fleet counts.

---

## 3. Implementations & Changes
1. **Fixed Asset Previews (`scripts/vehicle/VehicleRegistry.gd`):**
   - Corrected `monster_truck` preview to `res://assets/vehicles/player/body/vehicle_body_truck_side.png`.
   - Set `blue_flame_truck` preview to `res://assets/vehicles/blue_flame_truck/vehicle_assembled_preview.png`.
   - Set `orc_racer` preview to `res://assets/vehicles/orc_racer/body.png`.
   - Set `trophy_truck` preview to `res://assets/vehicles/trophy_truck/assembled.png`.
2. **Dynamic Persistence (`scripts/core/SaveManager.gd`):**
   - Replaced hardcoded arrays in `get_selected_vehicle_id()` and `set_selected_vehicle_id()` with dynamic queries to `VehicleRegistry.get_vehicle_ids()`.
   - Selection persists across reloads to `user://save_data.json`.
3. **Carousel Navigation UI (`scenes/main/MainMenu.tscn`):**
   - Added `CarouselRow` containing:
     - `PrevVehicleButton` ("◀", size 40x160)
     - `ScrollContainer` (horizontal scroll auto, vertical disabled) with `VehicleCardsContainer`
     - `NextVehicleButton` ("▶", size 40x160)
   - Enlarged `VehicleSelectPanel` to `860x490` with rounded card styling.
4. **Card Construction & Animation (`scripts/core/MainMenuController.gd`):**
   - Each card is an individual `PanelContainer` (165x290 px) with glowing green borders for the selected vehicle (`Color(0.3, 0.9, 0.5)`).
   - `TextureRect` previews use `STRETCH_KEEP_ASPECT_CENTERED` to prevent any image clipping.
   - Status label displays `"★ SELECTED"` (green) or `"READY"` (soft blue).
   - Action button displays `"ACTIVE"` (disabled) or `"SELECT"` (clickable).
   - Smooth tween scrolling on `PrevVehicleButton` / `NextVehicleButton` press.
   - Automatic deferred scroll to the active vehicle on menu open.
5. **Dynamic Spawner (`scripts/core/Game.gd`):**
   - Instantiates `SaveManager.get_selected_vehicle_id()` cleanly into `VehicleSlot` at race start.

---

## 4. Verification & Results
- Verified in `tests/test_ui_pickups_and_new_vehicles.gd`:
  - 4 cards rendered for the active roster.
  - Zero blank cards; all 4 textures load valid image resources.
  - Navigation arrows exist and respond to click events.
  - Switching selection persists to disk and updates card highlights.
- Verified in `tests/test_complete_bug_fixes_and_features.gd`:
  - 100% pass across UI, save persistence, and in-game vehicle instantiation.

---

## 5. Active Fleet Revision (Pruned Catalog)
Per player instruction, the vehicle roster was streamlined:
- **Removed Vehicles:**
  - `classic_car` ("Classic Hill Climber")
  - `monster_truck` ("Beast Monster Truck")
  - `one_wheel_scooter` ("One-Wheel Scooter")
- **Active Fleet (4 Registered Vehicles):**
  1. `blue_flame_truck` ("Blue Flame Truck") — **Starting Free Starter Vehicle** (`unlock_cost = 0`).
  2. `orc_racer` ("Orc Racer") — 350 coins.
  3. `trophy_truck` ("Trophy Truck") — 500 coins.
  4. `dune_buggy` ("Electric Dune Buggy") — 450 coins.
- **SaveManager & Fallback:**
  - Default and fallback starter vehicle updated from `"classic_car"` to `"blue_flame_truck"`.
  - All tests updated and verified.
