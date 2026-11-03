extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN PHASE 1 INTEGRATION TEST ---")
	print("========================================")
	
	var main_packed = load("res://scenes/main/Main.tscn")
	assert(main_packed != null, "Main.tscn must load successfully")
	var main_scene = main_packed.instantiate()
	root.add_child(main_scene)
	
	# Wait for ready and scene initialization
	for i in range(10):
		await process_frame
	
	# Transition into Game scene if starting in menu
	if main_scene.has_method("load_game") and not main_scene.get_node_or_null("SceneContainer/Game"):
		main_scene.load_game()
		for i in range(5):
			await process_frame
	
	var game = main_scene.get_node_or_null("SceneContainer/Game")
	assert(game != null, "Game node must be instantiated inside SceneContainer")
	print("✓ Main.tscn loaded and instantiated Game into SceneContainer")
	
	var gm = game.get_node_or_null("GameManager")
	assert(gm != null, "GameManager node must exist in Game scene")
	assert(gm.current_state == 1, "GameManager should be in PLAYING state")
	print("✓ GameManager active in PLAYING state")
	
	var vehicle = game.vehicle
	assert(vehicle != null, "Vehicle reference must be valid in Game scene")
	var initial_x: float = vehicle.global_position.x
	print("✓ Vehicle resolved: initial position x = %f, y = %f" % [initial_x, vehicle.global_position.y])
	
	var camera = game.follow_camera
	assert(camera != null, "FollowCamera must exist")
	assert(camera.get("target") == vehicle, "FollowCamera target must be Vehicle")
	print("✓ FollowCamera targeting Vehicle")
	
	var hud = game.hud
	assert(hud != null, "HUD node must exist in Game scene")
	print("✓ HUD wired and listening to game events")
	
	# Simulate acceleration input over 60 physics frames (1 full second)
	print("-> Simulating player holding 'accelerate' input...")
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	Input.action_release("accelerate")
	
	var moved_x: float = vehicle.global_position.x
	var distance_traveled: float = moved_x - initial_x
	print("✓ Vehicle after 60 frames: x = %f (moved forward by %f px)" % [moved_x, distance_traveled])
	assert(distance_traveled > 10.0, "Vehicle must move forward significantly under acceleration")
	
	var tracked_distance: float = gm.current_distance
	print("✓ GameManager tracked distance = %f m" % tracked_distance)
	assert(tracked_distance > 0.0, "GameManager distance metric must be greater than 0")
	
	# Test restart
	print("-> Simulating player pressing 'restart'...")
	Input.action_press("restart")
	await process_frame
	await physics_frame
	Input.action_release("restart")
	for i in range(5):
		await physics_frame
	
	print("✓ Vehicle reset to spawn position: x = %f" % vehicle.global_position.x)
	assert(absf(vehicle.global_position.x - game.spawn_position.x) < 5.0, "Vehicle should return to spawn position upon restart")
	
	print("========================================")
	print("✓ ALL PHASE 1 INTEGRATION TESTS PASSED SUCCESSFULLY!")
	print("========================================")
	quit(0)
