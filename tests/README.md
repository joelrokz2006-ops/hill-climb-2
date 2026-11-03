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

## How to Run Headless Tests

Run directly using Godot's headless CLI:

```bash
godot --headless -s tests/test_game_loop.gd
```
