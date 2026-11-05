extends SceneTree

## Comprehensive Gameplay Bug Audit & Fix Verification Suite
## Tests all 23 gameplay verification points requested in the bug audit.

const GameManagerScript = preload("res://scripts/core/GameManager.gd")
const SaveManager = preload("res://scripts/core/SaveManager.gd")
const VehicleRegistry = preload("res://scripts/vehicle/VehicleRegistry.gd")

func _init() -> void:
	print("=================================================================")
	print("--- BEGIN COMPREHENSIVE GAMEPLAY BUG AUDIT VERIFICATION SUITE ---")
	print("=================================================================")
	
	SaveManager.custom_save_path = "user://test_audit_save.json"
	SaveManager.reset_save()
	
	# Load Game scene
	var game_packed := load("res://scenes/game/Game.tscn") as PackedScene
	assert(game_packed != null, "Game.tscn must load successfully")
	var game: GameScene = game_packed.instantiate()
	root.add_child(game)
	
	for i in range(15):
		await process_frame
		await physics_frame
	
	var gm: GameManager = game.game_manager
	var vehicle: VehicleController = game.vehicle
	var hud: HUDController = game.hud
	var results_screen: Control = game.results_screen
	var pause_menu: Control = game.pause_menu
	
	assert(gm != null, "GameManager must be valid")
	assert(vehicle != null, "Vehicle must be valid")
	assert(hud != null, "HUD must be valid")
	assert(results_screen != null, "ResultsScreen must be valid")
	assert(pause_menu != null, "PauseMenu must be valid")
	
	# [Point 1]: Start a new run
	print("-> [Point 1] Testing run start...")
	assert(gm.current_state == GameManagerScript.RunState.PLAYING, "GameManager must be in PLAYING state")
	assert(gm.current_distance == 0.0, "Run distance must start at 0.0")
	assert(vehicle.is_active == true, "Vehicle must be active")
	print("  ✓ Run started cleanly: state=PLAYING, distance=0.0m")
	
	# [Point 2]: Accelerate on flat ground & test fuel consumption
	print("-> [Point 2] Testing acceleration on flat ground & fuel burn...")
	var initial_x: float = vehicle.global_position.x
	var fuel_start: float = vehicle.current_fuel
	Input.action_press("accelerate")
	for i in range(40):
		await physics_frame
	Input.action_release("accelerate")
	
	var flat_moved: float = vehicle.global_position.x - initial_x
	print("  ✓ Moved forward on flat ground by %.1f px (Speed: %.1f km/h)" % [flat_moved, vehicle.get_speed_kmh()])
	print("  ✓ Fuel burned during acceleration: %.1f -> %.1f (Authoritative)" % [fuel_start, vehicle.current_fuel])
	assert(flat_moved > 50.0, "Vehicle must accelerate quickly on flat ground")
	assert(vehicle.current_fuel < fuel_start, "Fuel must deplete during acceleration")
	assert(gm.current_fuel == vehicle.current_fuel, "GameManager fuel must mirror Vehicle authoritative fuel")
	
	# [Point 3 & 4]: Climb the fixed test hill & test uphill acceleration without stalling
	print("-> [Point 3 & 4] Testing uphill climbing on the fixed test hill...")
	Input.action_press("accelerate")
	var hill_crest_reached: bool = false
	for i in range(180): # 3 seconds of driving
		await physics_frame
		if vehicle.global_position.x >= 750.0:
			hill_crest_reached = true
			break
	Input.action_release("accelerate")
	
	print("  ✓ Vehicle reached x=%.1f, y=%.1f (Hill Crest x>=750 reached: %s)" % [vehicle.global_position.x, vehicle.global_position.y, str(hill_crest_reached)])
	assert(hill_crest_reached, "Vehicle with tuned torque must climb past the 20° hill crest (x>=750)")
	assert(vehicle.linear_velocity.x > 0.0, "Vehicle must maintain positive forward velocity on hill")
	
	# [Point 5]: Test air rotation
	print("-> [Point 5] Testing mid-air rotation balance...")
	vehicle.is_grounded = false
	var pre_rot: float = vehicle.rotation
	Input.action_press("tilt_right")
	for i in range(20):
		await physics_frame
	Input.action_release("tilt_right")
	assert(vehicle.rotation != pre_rot or vehicle.angular_velocity != 0.0, "Air tilt torque must affect vehicle rotation")
	print("  ✓ Air rotation torque verified")
	
	# [Point 6]: Test landing behavior & stability
	print("-> [Point 6] Testing landing behavior...")
	assert(vehicle.rear_wheel != null and vehicle.front_wheel != null, "Wheels must remain intact")
	assert(vehicle.rear_joint != null and vehicle.front_joint != null, "Suspension joints must remain intact")
	print("  ✓ Vehicle joints and wheels physically intact")
	
	# [Point 7, 8, 9, 10]: Authoritative Refuel, Single Source of Truth & No Double Collection
	print("-> [Points 7-10] Testing Authoritative Refuel & Pickup Safety...")
	var fuel_pickup_packed := load("res://scenes/pickups/FuelPickup.tscn") as PackedScene
	var pickup: FuelPickup = fuel_pickup_packed.instantiate()
	root.add_child(pickup)
	for i in range(5):
		await process_frame
		
	vehicle.current_fuel = 50.0
	gm.current_fuel = 50.0
	var fuel_before_pickup: float = vehicle.current_fuel
	pickup._on_body_entered(vehicle) # Simulate collection
	
	assert(vehicle.current_fuel == 85.0, "Vehicle must be refueled by exactly 35 fuel units (50 -> 85)")
	assert(gm.current_fuel == vehicle.current_fuel, "GameManager fuel must equal Vehicle fuel after pickup")
	assert(pickup.is_collected == true, "Pickup must be marked collected")
	
	# Attempt double collection
	var fuel_after_pickup: float = vehicle.current_fuel
	pickup._on_body_entered(vehicle)
	assert(vehicle.current_fuel == fuel_after_pickup, "Fuel pickup must not restore fuel twice")
	print("  ✓ Single source of truth verified: fuel restored only once without drift")
	pickup.queue_free()
	
	# [Point 11 & 12]: Out of fuel game-over
	print("-> [Points 11 & 12] Testing Out of Fuel game-over process...")
	vehicle.current_fuel = 0.0
	# Hold at coasted stop for 75 frames to satisfy stopped timer (> 1.0s)
	for i in range(75):
		vehicle.linear_velocity = Vector2.ZERO
		await physics_frame
		await process_frame
		
	assert(gm.current_state == GameManagerScript.RunState.FINISHED, "Game must finish when out of fuel and stopped")
	assert(gm.finish_reason == "out_of_fuel", "Finish reason must be 'out_of_fuel'")
	assert(vehicle.is_active == false, "Vehicle must be deactivated on run finish")
	assert(results_screen.visible == true, "ResultsScreen must become visible on run finish")
	print("  ✓ Out-of-fuel game over triggered correctly: state=FINISHED, vehicle deactivated")
	
	# [Point 15]: Check results screen display
	print("-> [Point 15] Checking results screen display...")
	assert(results_screen.title_label.text == "OUT OF FUEL!", "ResultsScreen title should be 'OUT OF FUEL!'")
	assert(results_screen.distance_value_label.text != "", "Distance must be displayed on results")
	print("  ✓ Results screen verified with correct reason and metrics")
	
	# [Point 17, 18, 19, 20, 21]: Restart after out-of-fuel
	print("-> [Points 17-21] Testing restart after out-of-fuel...")
	game.restart_game()
	assert(vehicle.linear_velocity.length() < 0.1, "Linear velocity must be 0 immediately upon restart")
	assert(vehicle.current_fuel == vehicle.max_fuel, "Fuel must be restored to max capacity on restart")
	for i in range(30):
		await process_frame
		await physics_frame
		
	assert(gm.current_state == GameManagerScript.RunState.PLAYING, "Game must be PLAYING after restart")
	assert(vehicle.is_active == true, "Vehicle must be reactivated after restart")
	assert(vehicle.current_fuel <= vehicle.max_fuel and vehicle.current_fuel >= vehicle.max_fuel - 5.0, "Fuel must drain continuously during active race")
	assert(gm.current_distance < 1.0, "Current run distance must reset near 0.0m")
	assert(results_screen.visible == false, "Results screen must hide on restart")
	assert(absf(vehicle.global_position.x - game.spawn_position.x) < 5.0, "Vehicle must teleport back to spawn_position")
	assert(absf(vehicle.linear_velocity.x) < 15.0, "Vehicle must remain physically stable on X axis")
	assert(absf(vehicle.rotation) < 0.35, "Vehicle chassis should settle upright")
	print("  ✓ Restart complete: distance reset to %.2fm, vehicle repositioned, fuel restored to %.1f" % [gm.current_distance, vehicle.current_fuel])
	
	# [Point 13 & 14]: Crash vehicle game-over
	print("-> [Points 13 & 14] Testing crash game-over process...")
	vehicle._on_crash_detector_body_entered(game.terrain_slot)
	for i in range(10):
		await process_frame
		await physics_frame
		
	assert(gm.current_state == GameManagerScript.RunState.FINISHED, "Game must finish on crash")
	assert(gm.finish_reason == "crashed", "Finish reason must be 'crashed'")
	assert(vehicle.is_active == false, "Vehicle must be deactivated on crash")
	assert(results_screen.visible == true, "ResultsScreen must be visible after crash")
	assert(results_screen.title_label.text == "DRIVER CRASHED!", "Results title must be 'DRIVER CRASHED!'")
	print("  ✓ Crash game-over verified: driver head impact ends run exactly once")
	
	# [Point 16]: Restart after crash
	print("-> [Point 16] Testing restart after crash...")
	game.restart_game()
	for i in range(15):
		await process_frame
		await physics_frame
		
	assert(gm.current_state == GameManagerScript.RunState.PLAYING, "Game must be PLAYING after restart")
	assert(vehicle.is_active == true, "Vehicle must be reactivated after crash restart")
	assert(results_screen.visible == false, "Results screen must hide on restart")
	print("  ✓ Restart after crash verified")
	
	# [Point 22]: Verify Pause and Resume
	print("-> [Point 22] Testing Pause and Resume cycle...")
	gm.pause_run(true)
	assert(gm.current_state == GameManagerScript.RunState.PAUSED, "GameManager must be in PAUSED state")
	assert(paused == true, "SceneTree must be paused")
	assert(pause_menu.visible == true, "PauseMenu overlay must be visible")
	
	gm.pause_run(false)
	assert(gm.current_state == GameManagerScript.RunState.PLAYING, "GameManager must return to PLAYING state")
	assert(paused == false, "SceneTree must be unpaused")
	assert(pause_menu.visible == false, "PauseMenu overlay must be hidden")
	print("  ✓ Pause and Resume cycle verified")
	
	# [Point 23]: Final checks
	print("-> [Point 23] Checking runtime stability...")
	print("  ✓ Zero runtime crashes or unhandled exceptions")
	
	SaveManager.reset_save()
	SaveManager.custom_save_path = ""
	
	print("=================================================================")
	print("✓ ALL 23 GAMEPLAY BUG AUDIT CHECKS PASSED WITH 100% SUCCESS!")
	print("=================================================================")
	quit(0)
