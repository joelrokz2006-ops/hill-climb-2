extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN MEMBER 2 VEHICLE FULL TEST ---")
	print("========================================")
	
	# 1. Test VehicleRegistry
	print("-> Testing VehicleRegistry catalog...")
	var all_vehicles: Array[Dictionary] = VehicleRegistry.get_all_vehicles()
	assert(all_vehicles.size() == 3, "Registry must contain 3 vehicles")
	print("✓ VehicleRegistry verified: %d vehicles available" % all_vehicles.size())
	
	for v in all_vehicles:
		print("  • [%s]: %s (Cost: %d coins)" % [v["id"], v["display_name"], v["unlock_cost"]])
		assert(ResourceLoader.exists(v["scene_path"]), "Vehicle scene path must exist: %s" % v["scene_path"])
	
	var cost_lvl1 = VehicleRegistry.get_upgrade_cost(1)
	assert(cost_lvl1 == 50, "Level 1 upgrade cost should be 50")
	print("✓ Upgrade pricing verified")
	
	# 2. Test DuneBuggy instantiation
	print("-> Testing DuneBuggy.tscn instantiation via Registry...")
	var buggy: VehicleController = VehicleRegistry.instantiate_vehicle("dune_buggy")
	assert(buggy != null, "DuneBuggy must instantiate cleanly")
	root.add_child(buggy)
	buggy.position = Vector2(100, 320)
	
	for i in range(5):
		await physics_frame
	
	assert(buggy.mass == 6.0, "DuneBuggy should have lightweight 6.0 mass")
	assert(buggy.max_wheel_speed >= 90.0, "DuneBuggy should have high top speed")
	buggy.queue_free()
	print("✓ DuneBuggy variation verified")
	
	# 3. Test MonsterTruck instantiation
	print("-> Testing MonsterTruck.tscn instantiation via Registry...")
	var truck: VehicleController = VehicleRegistry.instantiate_vehicle("monster_truck")
	assert(truck != null, "MonsterTruck must instantiate cleanly")
	root.add_child(truck)
	truck.position = Vector2(200, 320)
	
	for i in range(5):
		await physics_frame
	
	assert(truck.mass == 12.0, "MonsterTruck should have heavyweight 12.0 mass")
	truck.queue_free()
	print("✓ MonsterTruck variation verified")
	
	# 4. Test VehicleTest.tscn & Stunt Signals
	print("-> Loading VehicleTest.tscn...")
	var test_packed = load("res://scenes/vehicle/VehicleTest.tscn")
	assert(test_packed != null, "VehicleTest.tscn must load successfully")
	var test_scene = test_packed.instantiate()
	root.add_child(test_scene)
	
	for i in range(15):
		await process_frame
		await physics_frame
	
	var vehicle: VehicleController = test_scene.vehicle
	assert(vehicle != null, "Vehicle must exist in VehicleTest")
	
	# Connect stunt signals
	var tricks_detected: Array[String] = []
	var airtime_recorded: Array[float] = []
	vehicle.trick_performed.connect(func(trick_name: String, _reward: int):
		tricks_detected.append(trick_name)
		print("  ★ Stunt Detected: %s!" % trick_name)
	)
	vehicle.airtime_landed.connect(func(dur: float, reward: int):
		airtime_recorded.append(dur)
		print("  ★ Airtime Landed: %.2fs (Reward: %d coins)" % [dur, reward])
	)
	
	# Test Upgrade System
	print("-> Testing Upgrades API...")
	vehicle.apply_upgrade("engine_power", 4)
	assert(vehicle.engine_level == 4, "Engine level should be 4")
	vehicle.apply_upgrade("suspension", 3)
	assert(vehicle.suspension_level == 3, "Suspension level should be 3")
	vehicle.apply_upgrade("fuel_tank", 2)
	assert(vehicle.fuel_tank_level == 2, "Fuel tank level should be 2")
	vehicle.apply_upgrade("tire_grip", 5)
	assert(vehicle.grip_level == 5, "Tire grip level should be 5")
	print("✓ Upgrades successfully applied across all 4 stats")
	
	# Test Upgrade Serialization
	print("-> Testing upgrade serialization for SaveManager...")
	var serialized = vehicle.serialize_upgrades()
	assert(serialized["engine_level"] == 4 and serialized["grip_level"] == 5, "Serialized dictionary must match levels")
	vehicle.deserialize_upgrades({"engine_level": 2, "grip_level": 3, "suspension_level": 4, "fuel_tank_level": 5})
	assert(vehicle.engine_level == 2 and vehicle.fuel_tank_level == 5, "Deserialized levels must match")
	vehicle.deserialize_upgrades(serialized) # restore
	print("✓ Upgrade serialization and deserialization verified")
	
	# Test Stunt Flip Detection (Simulate airborne full rotation)
	print("-> Simulating airborne 360° flip...")
	vehicle.is_grounded = false
	vehicle.was_grounded = false
	vehicle.rotation = 0.0
	vehicle._last_air_rotation = 0.0
	
	# Step through full rotation in increments
	var steps: int = 12
	for s in range(steps + 1):
		vehicle.rotation = (float(s) / float(steps)) * TAU
		vehicle._track_stunts(0.1)
	
	assert(tricks_detected.size() > 0, "Flip detection must trigger trick_performed signal")
	print("✓ Trick signal verified: detected %s" % tricks_detected[0])
	
	# Test Airtime Landed Signal
	print("-> Simulating clean landing after big air...")
	vehicle.air_time = 1.5
	vehicle.is_grounded = true
	vehicle._track_stunts(0.016)
	assert(airtime_recorded.size() > 0 and airtime_recorded[0] >= 1.2, "Clean landing after > 1.2s air should trigger airtime_landed")
	print("✓ Airtime landing signal verified")
	
	# Test Dynamic Audio Pitch
	print("-> Testing dynamic RPM audio pitch under throttle...")
	Input.action_press("accelerate")
	for i in range(30):
		await physics_frame
	Input.action_release("accelerate")
	
	if vehicle.engine_audio:
		assert(vehicle.engine_audio.pitch_scale > 0.85, "RPM pitch should increase with throttle")
		print("✓ RPM Audio pitch verified: %f" % vehicle.engine_audio.pitch_scale)
	
	# Test Vehicle Reset
	print("-> Testing vehicle reset...")
	vehicle.reset_vehicle(test_scene.spawn_position)
	assert(vehicle.air_time == 0.0, "Air time should reset to 0 immediately upon reset")
	assert(vehicle.current_fuel == vehicle.max_fuel, "Fuel should reset to max")
	for i in range(5):
		await physics_frame
	print("✓ Vehicle reset verified")
	
	print("========================================")
	print("✓ ALL MEMBER 2 TO-DO ITEMS VERIFIED & PASSED!")
	print("========================================")
	quit(0)
