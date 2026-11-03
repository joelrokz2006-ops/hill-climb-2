extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN MEMBER 2 VEHICLE TEST ---")
	print("========================================")
	
	var test_packed = load("res://scenes/vehicle/VehicleTest.tscn")
	assert(test_packed != null, "VehicleTest.tscn must load successfully")
	var test_scene = test_packed.instantiate()
	root.add_child(test_scene)
	
	# Wait for scene ready
	for i in range(15):
		await process_frame
		await physics_frame
	
	var vehicle: VehicleController = test_scene.vehicle
	assert(vehicle != null, "Vehicle must be instantiated inside VehicleTest")
	print("✓ Vehicle resolved: initial position x = %f, y = %f" % [vehicle.global_position.x, vehicle.global_position.y])
	
	assert(vehicle.rear_wheel != null, "RearWheel must exist")
	assert(vehicle.front_wheel != null, "FrontWheel must exist")
	assert(vehicle.crash_detector != null, "CrashDetector must exist")
	print("✓ Vehicle components verified (Dual wheels, crash detector, physics joints)")
	
	# Initial state checks
	var initial_x: float = vehicle.global_position.x
	var initial_fuel: float = vehicle.current_fuel
	assert(initial_fuel == vehicle.max_fuel, "Fuel must start at maximum")
	print("✓ Initial fuel verified: %f / %f" % [initial_fuel, vehicle.max_fuel])
	
	# Test Acceleration
	print("-> Simulating forward acceleration for 60 frames...")
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	Input.action_release("accelerate")
	
	var moved_x: float = vehicle.global_position.x - initial_x
	print("✓ Forward movement after 60 frames: %f px" % moved_x)
	assert(moved_x > 15.0, "Vehicle must drive forward under acceleration")
	
	# Test Fuel Depletion
	var fuel_after_accel: float = vehicle.current_fuel
	print("✓ Fuel after acceleration: %f" % fuel_after_accel)
	assert(fuel_after_accel < initial_fuel, "Fuel must decrease during acceleration")
	
	# Test Refuel Hook
	print("-> Testing refuel(10.0)...")
	vehicle.refuel(10.0)
	assert(vehicle.current_fuel > fuel_after_accel, "Refuel must restore fuel")
	print("✓ Fuel after refuel: %f" % vehicle.current_fuel)
	
	# Test Brake / Reverse
	print("-> Simulating brake_reverse for 30 frames...")
	Input.action_press("brake_reverse")
	for i in range(30):
		await physics_frame
	Input.action_release("brake_reverse")
	print("✓ Brake input executed successfully")
	
	# Test Reset Vehicle
	print("-> Testing reset_vehicle back to spawn...")
	vehicle.reset_vehicle(test_scene.spawn_position)
	for i in range(5):
		await physics_frame
	
	print("✓ Position after reset: x = %f, y = %f" % [vehicle.global_position.x, vehicle.global_position.y])
	assert(absf(vehicle.global_position.x - test_scene.spawn_position.x) < 5.0, "Chassis must return to spawn position")
	assert(vehicle.current_fuel == vehicle.max_fuel, "Fuel must be restored to max upon reset")
	assert(vehicle.is_active == true, "Vehicle must be active after reset")
	
	print("========================================")
	print("✓ ALL MEMBER 2 VEHICLE TESTS PASSED!")
	print("========================================")
	quit(0)
