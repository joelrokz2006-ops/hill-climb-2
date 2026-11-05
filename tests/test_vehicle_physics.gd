extends SceneTree

const VehicleRegistry = preload("res://scripts/vehicle/VehicleRegistry.gd")

func _init() -> void:
	print("========================================")
	print("--- BEGIN MEMBER 2 VEHICLE FULL TEST ---")
	print("========================================")
	
	# 1. Test VehicleRegistry
	print("-> Testing VehicleRegistry catalog...")
	var all_vehicles: Array[Dictionary] = VehicleRegistry.get_all_vehicles()
	assert(all_vehicles.size() == 4, "Registry must contain 4 vehicles (got %d)" % all_vehicles.size())
	print("✓ VehicleRegistry verified: %d vehicles available" % all_vehicles.size())
	
	for v in all_vehicles:
		print("  • [%s]: %s (Cost: %d coins)" % [v["id"], v["display_name"], v["unlock_cost"]])
		assert(ResourceLoader.exists(v["scene_path"]), "Vehicle scene path must exist: %s" % v["scene_path"])
		assert(ResourceLoader.exists(v["preview_path"]), "Vehicle preview path must exist: %s" % v["preview_path"])
	
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
	
	# 3. Test Removed Vehicles are Not in Registry
	print("-> Testing that removed vehicles (classic_car, monster_truck, one_wheel_scooter) are absent...")
	assert(not VehicleRegistry.has_vehicle("classic_car"), "classic_car must not be in VehicleRegistry")
	assert(not VehicleRegistry.has_vehicle("monster_truck"), "monster_truck must not be in VehicleRegistry")
	assert(not VehicleRegistry.has_vehicle("one_wheel_scooter"), "one_wheel_scooter must not be in VehicleRegistry")
	print("✓ Removed vehicles correctly excluded from registry")

	# 3c. Test BlueFlameTruck instantiation
	print("-> Testing BlueFlameTruck.tscn instantiation via Registry...")
	var b_truck: VehicleController = VehicleRegistry.instantiate_vehicle("blue_flame_truck")
	assert(b_truck != null, "BlueFlameTruck must instantiate cleanly")
	root.add_child(b_truck)
	b_truck.position = Vector2(400, 320)
	for i in range(5):
		await physics_frame
	assert(b_truck.mass == 10.0, "BlueFlameTruck should have mass 10.0")
	b_truck.queue_free()
	print("✓ BlueFlameTruck variation verified")

	# 3d. Test OrcRacer instantiation
	print("-> Testing OrcRacer.tscn instantiation via Registry...")
	var orc: VehicleController = VehicleRegistry.instantiate_vehicle("orc_racer")
	assert(orc != null, "OrcRacer must instantiate cleanly")
	root.add_child(orc)
	orc.position = Vector2(500, 320)
	for i in range(5):
		await physics_frame
	assert(orc.mass == 7.5, "OrcRacer should have mass 7.5")
	orc.queue_free()
	print("✓ OrcRacer variation verified")

	# 3e. Test TrophyTruck instantiation
	print("-> Testing TrophyTruck.tscn instantiation via Registry...")
	var trophy: VehicleController = VehicleRegistry.instantiate_vehicle("trophy_truck")
	assert(trophy != null, "TrophyTruck must instantiate cleanly")
	root.add_child(trophy)
	trophy.position = Vector2(600, 320)
	for i in range(5):
		await physics_frame
	assert(trophy.mass == 9.0, "TrophyTruck should have mass 9.0")
	trophy.queue_free()
	print("✓ TrophyTruck variation verified")
	
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
