extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN PHASE 2 CORE RUN LOOP TEST ---")
	print("========================================")
	
	var main_packed = load("res://scenes/main/Main.tscn")
	assert(main_packed != null, "Main.tscn must load successfully")
	var main_scene = main_packed.instantiate()
	root.add_child(main_scene)
	
	# Wait for ready and scene setup
	for i in range(15):
		await process_frame
		await physics_frame
	
	# Transition into Game scene if starting in menu
	if main_scene.has_method("load_game") and not main_scene.get_node_or_null("SceneContainer/Game"):
		main_scene.load_game()
		for i in range(5):
			await process_frame
			await physics_frame
	
	var game: GameScene = main_scene.get_node_or_null("SceneContainer/Game")
	assert(game != null, "Game node must exist in SceneContainer")
	print("✓ Game scene loaded inside Main")
	
	var gm = game.game_manager
	assert(gm != null, "GameManager must exist in Game scene")
	assert(gm.current_state == 1, "GameManager must be in PLAYING state (1)")
	print("✓ GameManager active and in PLAYING state")
	
	var vehicle: VehicleController = game.vehicle
	assert(vehicle != null, "Vehicle reference must be valid")
	var start_x = vehicle.global_position.x
	print("✓ Vehicle resolved at x = %f" % start_x)
	
	var results_screen = game.results_screen
	var pause_menu = game.pause_menu
	assert(results_screen != null, "ResultsScreen must exist in Game scene")
	assert(pause_menu != null, "PauseMenu must exist in Game scene")
	assert(results_screen.visible == false, "ResultsScreen must be hidden during play")
	assert(pause_menu.visible == false, "PauseMenu must be hidden during play")
	print("✓ UI Overlays (ResultsScreen & PauseMenu) initialized in hidden state")
	
	# 1. Test Acceleration & Fuel Depletion
	print("-> Testing acceleration, forward motion, and fuel depletion...")
	var initial_fuel: float = vehicle.current_fuel
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	Input.action_release("accelerate")
	
	var moved_dist = vehicle.global_position.x - start_x
	print("✓ Forward motion: +%f px" % moved_dist)
	assert(moved_dist > 15.0, "Vehicle must advance under acceleration")
	assert(vehicle.current_fuel < initial_fuel, "Fuel must deplete during acceleration")
	print("✓ Fuel consumed: %f -> %f" % [initial_fuel, vehicle.current_fuel])
	assert(gm.current_distance > 0.0, "GameManager distance metric must increase")
	print("✓ Distance tracked: %f m" % gm.current_distance)
	
	# 2. Test Pause & Resume
	print("-> Testing pause and resume cycle...")
	gm.pause_run(true)
	await process_frame
	assert(gm.current_state == 2, "GameManager must be in PAUSED state (2)")
	assert(paused == true, "SceneTree must be paused")
	assert(pause_menu.visible == true, "PauseMenu must become visible when paused")
	print("✓ Pause state verified (PauseMenu visible)")
	
	gm.pause_run(false)
	await process_frame
	assert(gm.current_state == 1, "GameManager must return to PLAYING state (1)")
	assert(paused == false, "SceneTree must be unpaused")
	assert(pause_menu.visible == false, "PauseMenu must hide on resume")
	print("✓ Resume state verified (PauseMenu hidden)")
	
	# 3. Test Pickups (Coin and Fuel)
	print("-> Testing Pickup collection...")
	var initial_coins: int = gm.coins_collected
	var coin_node: Area2D = game.find_child("Coin1", true, false)
	if coin_node:
		# Simulate vehicle entering coin area
		coin_node._on_body_entered(vehicle)
		await process_frame
		assert(gm.coins_collected > initial_coins, "Coins must increase on pickup")
		assert(coin_node.get("is_collected") == true, "Coin must be marked collected")
		print("✓ Coin collected: count = %d" % gm.coins_collected)
	
	var fuel_pickup: Area2D = game.find_child("Fuel1", true, false)
	if fuel_pickup:
		var fuel_before: float = vehicle.current_fuel
		fuel_pickup._on_body_entered(vehicle)
		await process_frame
		assert(vehicle.current_fuel > fuel_before, "Fuel must increase on FuelPickup collection")
		assert(fuel_pickup.get("is_collected") == true, "FuelPickup must be marked collected")
		print("✓ FuelPickup collected: fuel = %f" % vehicle.current_fuel)
		
	# 4. Test Game-Over on Crash & ResultsScreen
	print("-> Testing Game-Over crash condition and ResultsScreen...")
	vehicle.crashed.emit()
	await process_frame
	
	assert(gm.current_state == 3, "GameManager must enter FINISHED state (3) on crash")
	assert(gm.finish_reason == "crashed", "Finish reason must be 'crashed'")
	assert(results_screen.visible == true, "ResultsScreen must become visible on run finish")
	assert(results_screen.title_label.text == "DRIVER CRASHED!", "Results title must show 'DRIVER CRASHED!'")
	print("✓ Crash game-over verified with ResultsScreen active")
	
	# 5. Test Run Restart
	print("-> Testing run restart via ResultsScreen...")
	results_screen._on_retry_pressed()
	for i in range(10):
		await process_frame
		await physics_frame
		
	assert(gm.current_state == 1, "GameManager must reset to PLAYING state (1)")
	assert(results_screen.visible == false, "ResultsScreen must hide upon restart")
	assert(absf(vehicle.global_position.x - game.spawn_position.x) < 5.0, "Vehicle must reset to spawn position")
	assert(vehicle.current_fuel == vehicle.max_fuel, "Vehicle fuel must reset to maximum (100)")
	assert(gm.current_distance < 0.1, "Run distance must reset near 0")
	
	if coin_node:
		assert(coin_node.get("is_collected") == false, "Coin must reset for new run")
	if fuel_pickup:
		assert(fuel_pickup.get("is_collected") == false, "FuelPickup must reset for new run")
		
	print("✓ Full restart cycle verified: vehicle, metrics, and pickups reset")
	print("========================================")
	print("✓ ALL PHASE 2 CORE RUN LOOP TESTS PASSED!")
	print("========================================")
	quit(0)
