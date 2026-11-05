# UI CORRECTION REPORT

**Project:** Hill Climb 2D  
**Engine:** Godot 4.7+ Stable  
**Date:** 2026-11-05  

---

## 1. Overview & Problem Statement
In the user-supplied gameplay screenshot, the in-game mobile HUD featured an obsolete square Nitro button above the right-hand acceleration pedal. It was enclosed in a dark square rounded card, possessed redundant borders, and had an overlapping text label `"⚡ NITRO"` on top of the bottle icon.

The player requested:
- Displaying only the clean Nitro artwork (`nitro_bottle.png`) with a transparent background.
- Eliminating the old dark card/box background and border.
- Eliminating duplicate Nitro icons and removing the second text label.
- Preserving the exact screen position above the right-side gas pedal without overlapping it.
- Preserving full interactivity (touch, mouse, keyboard input actions).
- Providing responsive visual feedback (press animation, modulation on boost, and dimming when depleted).
- Preserving the top-left HUD Nitro energy percentage bar and digital readouts.

---

## 2. Root Cause Analysis
- **Scene Hierarchy (`scenes/ui/HUD.tscn`):** `NitroButton` was configured as a `TextureButton` with `nitro_boost.png` (a 256x256 icon with a dark navy rounded square background) and had a child node `NitroButtonLabel` displaying `"⚡ NITRO"`.
- **Layout & Hitbox:** The dark card made the button look like a desktop window widget rather than a sleek mobile racing game touch control.

---

## 3. Implementations & Changes
1. **Visual Texture Update (`scenes/ui/HUD.tscn`):**
   - Switched `texture_normal` and `texture_pressed` to `res://assets/effects/nitro/nitro_bottle.png`.
   - Removed the child `NitroButtonLabel` node.
   - Removed all opaque card backgrounds and borders.
   - Preserved `ignore_texture_size = true` and `stretch_mode = 5` (STRETCH_KEEP_ASPECT_CENTERED).
   - Position: `offset_left = -122.0`, `offset_top = -214.0`, `offset_right = -42.0`, `offset_bottom = -130.0` (hitbox 80x84 px), positioned cleanly above `GasPedal` (`offset_top = -122.0`, `offset_bottom = -26.0`) with 8px vertical spacing and zero overlap.
2. **Controller Logic (`scripts/ui/HUDController.gd`):**
   - Cleaned up button signal binding using dedicated non-redundant methods (`_on_nitro_button_down`, `_on_nitro_button_up`).
   - Depletion state: Modulates to `Color(0.5, 0.5, 0.5, 0.6)` when `current_nitro <= 0.0`.
   - Boosting state: Modulates with high-energy glow `Color(1.3, 1.3, 1.5, 1.0)`.
   - Normal state: Restores clean `Color.WHITE` when replenished.
   - Preserved top-left HUD `NitroBar`, `NitroPercentageLabel`, and `NitroBottleIcon`.

---

## 4. Verification & Results
- Verified in `tests/test_ui_pickups_and_new_vehicles.gd`:
  - `NitroButton` texture ends with `nitro_bottle.png`.
  - Child label node removed.
  - Position strictly above `GasPedal` (`nitro_btn.offset_bottom <= gas_pedal.offset_top`).
  - Pressing triggers `"nitro"` action; releasing releases it.
  - Modulates correctly on depletion and replenishment.

---

## 4. Pause Menu Navigation Enhancement: "MAIN MENU" Button
- **Requirement:** Add a third button ("MAIN MENU") in the pause menu matching the exact style of "RESUME" and "RETRY", which smoothly returns to the startup main menu.
- **Changes in `scenes/ui/PauseMenu.tscn`:**
  - Expanded `PanelContainer` minimum size to `Vector2(340, 330)`.
  - Added `MainMenuButton` (`type="Button"`, `unique_name_in_owner = true`, `custom_minimum_size = Vector2(0, 48)`).
  - Styled with Kenney Future font (15pt), white font color, and `StyleBoxTexture_retry` button skin.
- **Changes in `scripts/ui/PauseMenuController.gd` & `scripts/core/Game.gd`:**
  - Added `signal menu_requested` to `PauseMenuController`.
  - Wired `MainMenuButton.pressed` to unpause the engine (`game_manager.pause_run(false)`), hide the pause menu, and emit `menu_requested`.
  - In `Game.gd`, connected `pause_menu.menu_requested` to `exit_to_main_menu()`.
  - In `Main.gd`, `load_menu()` smoothly unloads the active race and transitions back to `MainMenu.tscn`.

---

## 5. Old Analog Meter Removal & Speedometer Realignment
- **Requirement:** Remove the old analog meter (`RPMGauge`) that displayed side-by-side with the new speedometer dial at the bottom right.
- **Changes in `scenes/ui/HUD.tscn`:**
  - Removed `RPMGauge` control node and its child components (`DialBack`, `NeedlePivot`, `RPMNeedle`, `DialFrame`).
  - Repositioned the high-resolution racing `SpeedometerGauge` to `offset_left = -260.0, offset_right = -140.0` (top: `-125.0`, bottom: `-5.0`), placing it neatly adjacent to the acceleration controls with a clean 12px margin.
- **Verification:**
  - Verified no orphaned references; tests passed with 100% success.

---

## 6. Mobile Button Scaling & Left-Side Nitro Placement
- **Requirement:**
  - Increase the size of the acceleration (`GasPedal`) and brake (`BrakePedal`) buttons to full mobile touch dimensions.
  - Move the `NitroButton` from the right side over to the left side, stacked above the brake pedal.
  - Ensure all three primary touch controls (`GasPedal`, `BrakePedal`, and `NitroButton`) have the exact same size.
- **Changes in `scenes/ui/HUD.tscn`:**
  - **Button Sizing:** Scaled `GasPedal`, `BrakePedal`, and `NitroButton` from `92x96 px` to `140x140 px`, matching the 1:1 square aspect ratio of their native textures and providing comfortable touch hitboxes for mobile devices.
  - **Left Side Layout (`TouchControls`):**
    - `BrakePedal`: Bottom left (`offset_left = 32.0, offset_right = 172.0`, `offset_top = -164.0, offset_bottom = -24.0`).
    - `NitroButton`: Positioned above the brake pedal on the left (`offset_left = 32.0, offset_right = 172.0`, `offset_top = -324.0, offset_bottom = -184.0`). Maintains a clean 20px vertical gap with `BrakePedal` and a generous 168px clearance below `TopStatsPanel`.
  - **Right Side Layout (`TouchControls`):**
    - `GasPedal`: Bottom right (`offset_left = -172.0, offset_right = -32.0`, `offset_top = -164.0, offset_bottom = -24.0`).
    - `SpeedometerGauge`: Realigned to `offset_left = -312.0, offset_right = -192.0`, `offset_top = -144.0, offset_bottom = -24.0`, providing a clean 20px gap to `GasPedal` with aligned bottom baseline.
- **Verification:**
  - `test_ui_pickups_and_new_vehicles.gd`: Verified `BrakePedal` size (140x140), `GasPedal` size (140x140), `NitroButton` size (140x140), left-side anchor placement, and clearance above brake pedal with 100% test pass.
