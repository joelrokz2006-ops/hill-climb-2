extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN MEMBER 2 VEHICLE UPGRADES TEST ---")
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
	
	# 1. Test Initial Stats & Upgrade System Interface
	print("-> Testing get_stats()...")
	var stats: Dictionary = vehicle.get_stats()
	assert(stats.has("engine_power"), "Stats must contain 'engine_power'")
	assert(stats.has("tire_grip"), "Stats must contain 'tire_grip'")
	assert(stats.has("suspension"), "Stats must contain 'suspension'")
	assert(stats.has("fuel_tank"), "Stats must contain 'fuel_tank'")
	print("✓ get_stats() returned valid 4-stat dictionary")
	
	var initial_torque: float = vehicle.motor_torque
	var initial_fuel_cap: float = vehicle.max_fuel
	
	print("-> Testing apply_upgrade('engine_power', 3)...")
	vehicle.apply_upgrade("engine_power", 3)
	assert(vehicle.engine_level == 3, "Engine level should be 3")
	assert(vehicle.motor_torque > initial_torque, "Motor torque must increase with upgrade")
	print("✓ Upgraded engine: torque %f -> %f" % [initial_torque, vehicle.motor_torque])
	
	print("-> Testing apply_upgrade('fuel_tank', 4)...")
	vehicle.apply_upgrade("fuel_tank", 4)
	assert(vehicle.fuel_tank_level == 4, "Fuel tank level should be 4")
	assert(vehicle.max_fuel > initial_fuel_cap, "Max fuel capacity must increase with upgrade")
	print("✓ Upgraded fuel tank: max_fuel %f -> %f" % [initial_fuel_cap, vehicle.max_fuel])
	
	print("-> Testing apply_upgrade('tire_grip', 5)...")
	vehicle.apply_upgrade("tire_grip", 5)
	assert(vehicle.grip_level == 5, "Grip level should be 5")
	var grip_stats = vehicle.get_stats()
	assert(grip_stats["tire_grip"]["friction"] > 1.6, "Effective wheel friction must increase")
	print("✓ Upgraded tire grip: friction = %f" % grip_stats["tire_grip"]["friction"])
	
	# 2. Test Acceleration & Dynamic RPM Pitch
	print("-> Simulating acceleration with dynamic RPM modulation...")
	Input.action_press("accelerate")
	for i in range(45):
		await physics_frame
	
	if vehicle.engine_audio:
		print("✓ Dynamic engine audio pitch scale: %f" % vehicle.engine_audio.pitch_scale)
		assert(vehicle.engine_audio.pitch_scale > 0.85, "Pitch scale should dynamically rise with acceleration and wheel RPM")
	
	Input.action_release("accelerate")
	
	# 3. Test Air Tilt Control
	print("-> Testing mid-air flip and tilt control...")
	Input.action_press("tilt_right")
	for i in range(20):
		await physics_frame
	Input.action_release("tilt_right")
	print("✓ Tilt input executed without exceeding angular velocity cap (%f)" % vehicle.angular_velocity)
	assert(absf(vehicle.angular_velocity) <= vehicle.max_air_angular_velocity + 0.5, "Angular velocity must be clamped to prevent wild spinning")
	
	# 4. Test MonsterTruck Scene
	print("-> Testing MonsterTruck.tscn instantiation...")
	var monster_packed = load("res://scenes/vehicle/MonsterTruck.tscn")
	assert(monster_packed != null, "MonsterTruck.tscn must load successfully")
	var monster_truck: VehicleController = monster_packed.instantiate()
	root.add_child(monster_truck)
	monster_truck.position = Vector2(500, 320)
	
	for i in range(5):
		await physics_frame
	
	assert(monster_truck.motor_torque >= 28000.0, "MonsterTruck should have high base torque")
	var monster_stats: Dictionary = monster_truck.get_stats()
	assert(monster_stats.has("engine_power"), "MonsterTruck must implement get_stats()")
	monster_truck.queue_free()
	print("✓ MonsterTruck variation validated successfully")
	
	print("========================================")
	print("✓ ALL MEMBER 2 UPGRADE & PHYSICS TESTS PASSED!")
	print("========================================")
	quit(0)
