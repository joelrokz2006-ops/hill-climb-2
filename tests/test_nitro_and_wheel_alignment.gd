extends SceneTree

# Comprehensive test suite for Vehicle Wheel Alignment & Nitro Boost Implementation

func _init() -> void:
	print("\n=================================================================")
	print("--- BEGIN VEHICLE WHEEL ALIGNMENT & NITRO BOOST TEST SUITE ---")
	print("=================================================================")
	
	test_wheel_alignment_all_vehicles()
	test_nitro_boost_physics_and_energy()
	test_pothole_assist_detection()
	test_hud_nitro_integration()
	
	print("\n=================================================================")
	print("✓ ALL WHEEL ALIGNMENT & NITRO BOOST TESTS PASSED SUCCESSFULLY!")
	print("=================================================================\n")
	quit(0)

func test_wheel_alignment_all_vehicles() -> void:
	print("-> [1/4] Verifying Wheel Alignment and Marker2D Anchors across all vehicles...")
	
	var vehicle_scenes := [
		{"path": "res://scenes/vehicle/Vehicle.tscn", "name": "ClassicCar"},
		{"path": "res://scenes/vehicle/MonsterTruck.tscn", "name": "MonsterTruck"},
		{"path": "res://scenes/vehicle/DuneBuggy.tscn", "name": "DuneBuggy"}
	]
	
	for entry in vehicle_scenes:
		var scene_res = load(entry["path"])
		assert(scene_res != null, "Vehicle scene %s must load" % entry["path"])
		var vehicle = scene_res.instantiate()
		root.add_child(vehicle)
		
		# Verify Marker2D anchors exist
		var rear_mount: Marker2D = vehicle.get_node_or_null("RearWheelMount")
		var front_mount: Marker2D = vehicle.get_node_or_null("FrontWheelMount")
		var rear_strut_mount: Marker2D = vehicle.get_node_or_null("RearStrutMount")
		var front_strut_mount: Marker2D = vehicle.get_node_or_null("FrontStrutMount")
		
		assert(rear_mount != null, "%s must have RearWheelMount" % entry["name"])
		assert(front_mount != null, "%s must have FrontWheelMount" % entry["name"])
		assert(rear_strut_mount != null, "%s must have RearStrutMount" % entry["name"])
		assert(front_strut_mount != null, "%s must have FrontStrutMount" % entry["name"])
		
		var rear_wheel: RigidBody2D = vehicle.get_node_or_null("RearWheel")
		var front_wheel: RigidBody2D = vehicle.get_node_or_null("FrontWheel")
		assert(rear_wheel != null, "%s must have RearWheel" % entry["name"])
		assert(front_wheel != null, "%s must have FrontWheel" % entry["name"])
		
		# Verify wheels match marker positions
		assert(rear_wheel.position.is_equal_approx(rear_mount.position), 
			"%s RearWheel position %v must match RearWheelMount %v" % [entry["name"], rear_wheel.position, rear_mount.position])
		assert(front_wheel.position.is_equal_approx(front_mount.position), 
			"%s FrontWheel position %v must match FrontWheelMount %v" % [entry["name"], front_wheel.position, front_mount.position])
		
		# Verify Wheel Collision and Sprites share center (position Vector2.ZERO inside wheel)
		var r_col = rear_wheel.get_node_or_null("WheelCollision")
		var r_spr = rear_wheel.get_node_or_null("WheelSprite")
		assert(r_col != null and r_col.position == Vector2.ZERO, "%s Rear WheelCollision must be centered" % entry["name"])
		assert(r_spr != null and r_spr.position == Vector2.ZERO, "%s Rear WheelSprite must be centered" % entry["name"])
		
		var f_col = front_wheel.get_node_or_null("WheelCollision")
		var f_spr = front_wheel.get_node_or_null("WheelSprite")
		assert(f_col != null and f_col.position == Vector2.ZERO, "%s Front WheelCollision must be centered" % entry["name"])
		assert(f_spr != null and f_spr.position == Vector2.ZERO, "%s Front WheelSprite must be centered" % entry["name"])
		
		# Verify PinJoint2D connects chassis and wheels at marker positions
		var rear_joint: PinJoint2D = vehicle.get_node_or_null("RearJoint")
		var front_joint: PinJoint2D = vehicle.get_node_or_null("FrontJoint")
		assert(rear_joint != null and rear_joint.position.is_equal_approx(rear_mount.position), "%s RearJoint must match RearWheelMount" % entry["name"])
		assert(front_joint != null and front_joint.position.is_equal_approx(front_mount.position), "%s FrontJoint must match FrontWheelMount" % entry["name"])
		
		# Verify reset_vehicle restores wheels to exact marker offsets
		var test_spawn := Vector2(250, 400)
		vehicle.reset_vehicle(test_spawn)
		assert(rear_wheel.position.is_equal_approx(rear_mount.position), "%s reset_vehicle must restore RearWheel to marker offset" % entry["name"])
		assert(front_wheel.position.is_equal_approx(front_mount.position), "%s reset_vehicle must restore FrontWheel to marker offset" % entry["name"])
		
		# Verify BoostParticles and NitroAudio exist on vehicle
		assert(vehicle.get_node_or_null("BoostParticles") != null, "%s must have BoostParticles" % entry["name"])
		assert(vehicle.get_node_or_null("NitroAudio") != null, "%s must have NitroAudio" % entry["name"])
		
		root.remove_child(vehicle)
		vehicle.free()
		print("  ✓ %s: Marker anchors, joint mounts, collision centering, and reset verified" % entry["name"])
	
	print("✓ All vehicle scenes verified with precise wheel positioning!")

func test_nitro_boost_physics_and_energy() -> void:
	print("-> [2/4] Testing Nitro Boost Energy System and Physics Mechanics...")
	
	var vehicle_scene = load("res://scenes/vehicle/Vehicle.tscn")
	var vehicle = vehicle_scene.instantiate()
	root.add_child(vehicle)
	vehicle._ready()
	
	# Initial energy check
	assert(vehicle.current_nitro == 100.0, "Initial nitro must be 100.0")
	assert(not vehicle.is_nitro_active, "Nitro must be initially inactive")
	
	var nitro_tracker := {
		"changed_count": 0,
		"state_changed_count": 0,
		"last_state": false
	}
	
	vehicle.nitro_changed.connect(func(_c, _m): nitro_tracker["changed_count"] += 1)
	vehicle.nitro_state_changed.connect(func(active): 
		nitro_tracker["state_changed_count"] += 1
		nitro_tracker["last_state"] = active
	)
	
	# Request nitro activation
	vehicle.set_nitro_active(true)
	vehicle._physics_process(0.1)
	
	assert(vehicle.is_nitro_active == true, "Nitro must become active after requested")
	assert(nitro_tracker["last_state"] == true, "nitro_state_changed must emit true")
	assert(vehicle.current_nitro < 100.0, "Nitro must consume energy while active")
	assert(vehicle.boost_particles.emitting == true, "BoostParticles must be emitting while nitro active")
	
	# Verify continuous consumption
	var pre_nitro: float = vehicle.current_nitro
	vehicle._physics_process(0.5)
	assert(vehicle.current_nitro < pre_nitro, "Nitro must continuously decrease")
	
	# Simulate full depletion
	vehicle.current_nitro = 1.0
	vehicle._physics_process(0.2) # burn 5 units, goes <= 0
	assert(vehicle.current_nitro == 0.0, "Nitro must clamp at 0.0")
	assert(vehicle.is_nitro_active == false, "Nitro must auto-deactivate on empty")
	assert(vehicle.boost_particles.emitting == false, "BoostParticles must stop on empty")
	
	# Cannot reactivate when empty or below minimum energy (8.0)
	vehicle.set_nitro_active(true)
	vehicle._physics_process(0.1)
	assert(vehicle.is_nitro_active == false, "Cannot reactivate nitro when below min energy")
	
	# Passive recharge when deactivated
	vehicle.set_nitro_active(false)
	vehicle._physics_process(1.0)
	assert(vehicle.current_nitro > 0.0, "Nitro must passively recharge when inactive: got %f" % vehicle.current_nitro)
	
	# Verify reset_vehicle restores nitro to 100%
	vehicle.reset_vehicle(Vector2(0, 0))
	assert(vehicle.current_nitro == vehicle.max_nitro, "reset_vehicle must restore full nitro")
	assert(not vehicle.is_nitro_active, "reset_vehicle must ensure nitro is deactivated")
	
	root.remove_child(vehicle)
	vehicle.free()
	print("  ✓ Nitro energy consumption, cutoff at 0%, recharge, and reset verified")

func test_pothole_assist_detection() -> void:
	print("-> [3/4] Testing Pothole Dip Assistance Detection...")
	
	var vehicle_scene = load("res://scenes/vehicle/Vehicle.tscn")
	var vehicle = vehicle_scene.instantiate()
	root.add_child(vehicle)
	vehicle._ready()
	
	var pothole_tracker := {
		"hint_emitted": false,
		"hint_state": false
	}
	vehicle.pothole_assist_hint.connect(func(active):
		pothole_tracker["hint_emitted"] = true
		pothole_tracker["hint_state"] = active
	)
	
	# Simulate vehicle stuck in steep dip: grounded, attempting gas, slow speed, tilted uphill
	vehicle.is_grounded = true
	vehicle.linear_velocity = Vector2(10, 0)
	vehicle.rotation = -0.3 # tilted up
	
	# Simulate 0.6s of struggling while gas is requested
	Input.action_press("accelerate")
	for i in range(15):
		vehicle._check_pothole_assist(0.04)
	Input.action_release("accelerate")
	
	assert(pothole_tracker["hint_emitted"], "pothole_assist_hint signal must emit when vehicle struggles in steep dip")
	assert(pothole_tracker["hint_state"] == true, "pothole_assist_hint must be true when struggling")
	
	# Now simulate vehicle escaping dip with high speed
	vehicle.linear_velocity = Vector2(120, 0)
	vehicle._check_pothole_assist(0.1)
	assert(pothole_tracker["hint_state"] == false, "pothole_assist_hint must clear when vehicle speeds up out of pothole")
	
	root.remove_child(vehicle)
	vehicle.free()
	print("  ✓ Pothole struggle detection and recovery signal verified")

func test_hud_nitro_integration() -> void:
	print("-> [4/4] Testing HUD Nitro Elements and Controls...")
	
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	assert(hud_scene != null, "HUD scene must load")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()
	
	var nitro_bar: ProgressBar = hud.get_node_or_null("%NitroBar")
	var nitro_label: Label = hud.get_node_or_null("%NitroPercentageLabel")
	var nitro_button: TextureButton = hud.get_node_or_null("%NitroButton")
	
	assert(nitro_bar != null, "HUD must have %NitroBar")
	assert(nitro_label != null, "HUD must have %NitroPercentageLabel")
	assert(nitro_button != null, "HUD must have %NitroButton")
	assert(nitro_button.texture_normal != null, "NitroButton must have clean artwork texture")
	
	# Instantiate a Vehicle and bind it
	var vehicle_scene = load("res://scenes/vehicle/Vehicle.tscn")
	var vehicle = vehicle_scene.instantiate()
	root.add_child(vehicle)
	vehicle._ready()
	
	hud.bind_vehicle(vehicle)
	
	# Verify initial values
	assert(nitro_bar.value == 100.0, "HUD Nitro bar should show 100%")
	assert(nitro_label.text == "100%", "HUD Nitro label should display '100%'")
	
	# Simulate vehicle consuming nitro
	vehicle.current_nitro = 55.0
	vehicle.nitro_changed.emit(55.0, 100.0)
	assert(hud._target_nitro == 55.0, "HUDController _target_nitro must match vehicle nitro update")
	assert(nitro_label.text == "55%", "HUD Nitro percentage label must reflect 55%")
	
	# Test NitroButton touch simulation
	nitro_button.button_down.emit()
	assert(vehicle.is_nitro_requested == true, "Pressing NitroButton must set is_nitro_requested = true on vehicle")
	nitro_button.button_up.emit()
	assert(vehicle.is_nitro_requested == false, "Releasing NitroButton must set is_nitro_requested = false on vehicle")
	
	# Test Pothole Assist pulse on HUD
	vehicle.pothole_assist_hint.emit(true)
	assert(hud._pothole_pulse_active == true, "HUDController must activate pothole pulse when hint received")
	hud._process(0.05)
	
	vehicle.pothole_assist_hint.emit(false)
	assert(hud._pothole_pulse_active == false, "HUDController must deactivate pothole pulse when hint clears")
	
	root.remove_child(vehicle)
	vehicle.free()
	root.remove_child(hud)
	hud.free()
	print("  ✓ HUD NitroBar, NitroPercentageLabel, NitroButton touch, and Pothole pulse verified")
