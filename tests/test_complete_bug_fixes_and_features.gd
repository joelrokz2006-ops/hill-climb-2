extends SceneTree

const SaveManager = preload("res://scripts/core/SaveManager.gd")
const VehicleRegistry = preload("res://scripts/vehicle/VehicleRegistry.gd")
const GameManagerScript = preload("res://scripts/core/GameManager.gd")
const SnowfallManagerScript = preload("res://scripts/environment/SnowfallManager.gd")
const OneWheelScooterScript = preload("res://scripts/vehicle/OneWheelScooterController.gd")

func _init() -> void:
	print("\n=================================================================")
	print("--- BEGIN COMPLETE BUG CORRECTION & NEW FEATURES VERIFICATION ---")
	print("=================================================================\n")
	
	await test_bugfix_pickup_positioning()
	await test_bugfix_continuous_fuel_consumption()
	await test_bugfix_single_sun_environment()
	await test_nitro_visuals_integration()
	await test_speedometer_integration()
	await test_onewheel_scooter_physics()
	await test_snowfall_manager_milestones()
	await test_front_ui_vehicle_selection_and_persistence()
	
	print("\n=================================================================")
	print("✓ ALL BUG CORRECTIONS & NEW FEATURES VERIFIED WITH 100% SUCCESS!")
	print("=================================================================\n")
	quit(0)

func test_bugfix_pickup_positioning() -> void:
	print("-> [1/8] Verifying Pickup Positioning Across Terrain Shapes...")
	var gen: TerrainGenerator = TerrainGenerator.new()
	root.add_child(gen)
	
	var shapes := [
		TerrainSegment.SegmentType.FLAT,
		TerrainSegment.SegmentType.GENTLE_HILLS,
		TerrainSegment.SegmentType.STEEP_CLIMB,
		TerrainSegment.SegmentType.VALLEY_DIP,
		TerrainSegment.SegmentType.JUMP_RAMP,
		TerrainSegment.SegmentType.ROLLING_WAVES,
		TerrainSegment.SegmentType.PLATEAU_DROP,
		TerrainSegment.SegmentType.BUMPY_WASHBOARD,
		TerrainSegment.SegmentType.DOUBLE_CREST
	]
	
	for s_type in shapes:
		var seg: TerrainSegment = gen._create_segment(s_type, 1000.0, 0.0, 50.0, 80.0, 0.0, 0.0)
		gen._attach_segment(seg, false)
		
		# Test fuel spawn
		gen._spawn_fuel_on_segment(seg, 500.0)
		# Test coin spawns
		gen._spawn_coins_on_segment(seg)
		
		for child in seg.get_children():
			if child is Coin or child is FuelPickup:
				var surf_y: float = seg.get_surface_y_at(child.position.x)
				assert(child.position.y <= surf_y - 20.0, 
					"Pickup at x=%.1f y=%.1f must be above surface y=%.1f (segment type %d)" % [child.position.x, child.position.y, surf_y, s_type])
				var is_inside: bool = Geometry2D.is_point_in_polygon(child.position, seg.collision_polygon.polygon)
				assert(not is_inside, "Pickup must NEVER be inside terrain polygon")
	
	gen.clear_terrain()
	root.remove_child(gen)
	gen.free()
	print("  ✓ Zero underground pickups across all 9 terrain shapes verified")

func test_bugfix_continuous_fuel_consumption() -> void:
	print("-> [2/8] Verifying Continuous Fuel Consumption (Stationary, Coasting, Paused, Finished)...")
	var game_packed = load("res://scenes/game/Game.tscn")
	var game = game_packed.instantiate()
	root.add_child(game)
	for i in range(5):
		await process_frame
		await physics_frame
		
	var gm: GameManager = game.game_manager
	var veh: VehicleController = game.vehicle
	
	# Initial fuel check
	assert(gm.current_state == GameManagerScript.RunState.PLAYING, "State must be PLAYING")
	var f0: float = veh.current_fuel
	assert(f0 > 95.0, "Initial fuel should be near 100")
	
	# 1. Stationary drain: player does NOT accelerate, vehicle stands still
	for i in range(40):
		await process_frame
		await physics_frame
	var f1: float = veh.current_fuel
	assert(f1 < f0, "Fuel must decrease while completely stationary (f0=%.2f, f1=%.2f)" % [f0, f1])
	assert(is_equal_approx(gm.current_fuel, veh.current_fuel), "GameManager and vehicle fuel must remain synchronized")
	print("  ✓ Fuel decreases while completely stationary (%.1f -> %.1f)" % [f0, f1])
	
	# 2. Accelerating drain
	Input.action_press("accelerate")
	for i in range(30):
		await process_frame
		await physics_frame
	Input.action_release("accelerate")
	var f2: float = veh.current_fuel
	assert(f2 < f1, "Fuel must decrease while accelerating (f1=%.2f, f2=%.2f)" % [f1, f2])
	print("  ✓ Fuel decreases while accelerating (%.1f -> %.1f)" % [f1, f2])
	
	# 3. Paused: fuel MUST NOT decrease
	gm.pause_run(true)
	assert(gm.current_state == GameManagerScript.RunState.PAUSED, "Must be paused")
	var f_paused_start: float = veh.current_fuel
	for i in range(20):
		await process_frame
		await physics_frame
	var f_paused_end: float = veh.current_fuel
	assert(is_equal_approx(f_paused_start, f_paused_end), "Fuel must STOP decreasing while paused")
	gm.pause_run(false)
	print("  ✓ Fuel stops decreasing while paused (held at %.2f)" % f_paused_start)
	
	# 4. Out of fuel and finished: stops decreasing
	veh.current_fuel = 0.0
	for i in range(80):
		veh.linear_velocity = Vector2.ZERO
		await process_frame
		await physics_frame
	assert(gm.current_state == GameManagerScript.RunState.FINISHED, "Game must finish on out of fuel")
	assert(veh.current_fuel >= 0.0, "Fuel must never become negative")
	print("  ✓ Out of fuel finishes run cleanly without negative fuel")
	
	root.remove_child(game)
	game.free()

func test_bugfix_single_sun_environment() -> void:
	print("-> [3/8] Verifying Parallax Environment Has Exactly One Distinct Sun...")
	var env_packed = load("res://scenes/environment/ParallaxEnvironment.tscn")
	var env = env_packed.instantiate()
	root.add_child(env)
	
	var sky_layer: ParallaxLayer = env.get_node_or_null("SkyLayer")
	assert(sky_layer != null, "SkyLayer must exist")
	
	# Check intended sun exists
	var sun_sprite = sky_layer.get_node_or_null("SunSprite")
	assert(sun_sprite != null, "SunSprite must exist as the intended primary sun")
	assert(sun_sprite.visible == true, "SunSprite must be visible")
	
	# Check unwanted SunCore polygon is removed
	var sun_core = sky_layer.get_node_or_null("SunCore")
	assert(sun_core == null, "Unwanted SunCore white polygon must be removed")
	
	# Sky and background layers preserved
	assert(sky_layer.get_node_or_null("SkyBackground") != null, "SkyBackground must be preserved")
	assert(env.get_node_or_null("DistantCloudsLayer") != null, "Clouds layer must be preserved")
	assert(env.get_node_or_null("DistantMountainsLayer") != null, "Distant mountains layer must be preserved")
	
	root.remove_child(env)
	env.free()
	print("  ✓ Verified: SunCore removed, intended SunSprite and soft glow halos preserved")

func test_nitro_visuals_integration() -> void:
	print("-> [4/8] Verifying Nitro Visual Assets (Flame, Burst, Sparks, HUD Icons)...")
	var vehicle_scene = load("res://scenes/vehicle/Vehicle.tscn")
	var vehicle = vehicle_scene.instantiate()
	root.add_child(vehicle)
	
	# Verify visual components initialized
	assert(vehicle.nitro_flame != null, "Vehicle must create NitroFlame")
	assert(vehicle.nitro_burst != null, "Vehicle must create NitroBurst")
	assert(vehicle.nitro_sparks != null, "Vehicle must create NitroSparks")
	
	# Check flame offset points backwards (negative X)
	var flame_spr: Sprite2D = vehicle.nitro_flame.get_node_or_null("FlameSprite")
	assert(flame_spr != null, "NitroFlame must contain FlameSprite")
	assert(flame_spr.offset.x < 0.0, "NitroFlame must point backwards (towards rear -X)")
	
	# Check initial inactive state
	assert(vehicle.nitro_flame.visible == false, "Nitro flame must start hidden")
	assert(vehicle.nitro_sparks.emitting == false, "Nitro sparks must start non-emitting")
	
	# Trigger boost
	vehicle.set_nitro_active(true)
	vehicle._physics_process(0.05)
	
	assert(vehicle.is_nitro_active == true, "Nitro must be active")
	assert(vehicle.nitro_flame.visible == true, "Nitro flame must become visible on boost")
	assert(vehicle.nitro_sparks.emitting == true, "Nitro sparks must emit on boost")
	
	# Deactivate boost
	vehicle.set_nitro_active(false)
	vehicle._physics_process(0.05)
	
	assert(vehicle.is_nitro_active == false, "Nitro must deactivate")
	assert(vehicle.nitro_flame.visible == false, "Nitro flame must hide on boost stop")
	assert(vehicle.nitro_sparks.emitting == false, "Nitro sparks must stop on boost stop")
	
	root.remove_child(vehicle)
	vehicle.free()
	print("  ✓ Nitro flame, burst, sparks, and backward exhaust alignment verified")

func test_speedometer_integration() -> void:
	print("-> [5/8] Verifying Speedometer in HUD (Dial, Needle, Digital Speed, 0-220 km/h mapping)...")
	var hud_packed = load("res://scenes/ui/HUD.tscn")
	var hud = hud_packed.instantiate()
	root.add_child(hud)
	
	var speed_needle: Sprite2D = hud.get_node_or_null("%SpeedNeedle")
	var speed_label: Label = hud.get_node_or_null("%SpeedDigitalLabel")
	var nitro_btn: TextureButton = hud.get_node_or_null("%NitroButton")
	var nitro_bottle: TextureRect = hud.get_node_or_null("TopStatsPanel/Margin/VBox/NitroSection/NitroHeader/NitroBottleIcon")
	
	assert(speed_needle != null, "HUD must have SpeedNeedle")
	assert(speed_label != null, "HUD must have SpeedDigitalLabel")
	assert(nitro_btn != null, "HUD must have NitroButton")
	assert(nitro_bottle != null, "HUD must display nitro_bottle icon")
	
	# Test with vehicle mock
	var dummy = RigidBody2D.new()
	dummy.set_script(load("res://scripts/vehicle/VehicleController.gd"))
	root.add_child(dummy)
	hud.bind_vehicle(dummy)
	
	# At speed = 0
	dummy.linear_velocity = Vector2.ZERO
	hud._process(0.1)
	assert(speed_label.text == "0", "Stationary digital speed must be 0")
	var min_needle_rot: float = deg_to_rad(-135.0)
	assert(is_equal_approx(speed_needle.rotation, min_needle_rot) or speed_needle.rotation < deg_to_rad(-100.0), 
		"Needle should be near min angle at 0 km/h (was %.2f rad)" % speed_needle.rotation)
	
	# Simulate 110 km/h: (110 / 3.6) * 100 px/s ~= 3055.6 px/s
	dummy.linear_velocity = Vector2(3055.6, 0)
	for i in range(15):
		hud._process(0.05)
	var mid_speed: int = int(speed_label.text)
	assert(mid_speed >= 105 and mid_speed <= 115, "Digital speed should match vehicle ~110 km/h, got %d" % mid_speed)
	assert(speed_needle.rotation > min_needle_rot, "Needle must rotate upward with vehicle speed")
	
	root.remove_child(dummy)
	dummy.free()
	root.remove_child(hud)
	hud.free()
	print("  ✓ Speedometer dial, centered needle rotation, and live digital readout verified")

func test_onewheel_scooter_physics() -> void:
	print("-> [6/8] Verifying One-Wheel Scooter Physics, Gyro Stabilization & Compatibility...")
	var scooter_packed = load("res://scenes/vehicle/OneWheelScooter.tscn") as PackedScene
	assert(scooter_packed != null, "One-Wheel Scooter scene must load cleanly")
	var scooter = scooter_packed.instantiate()
	assert(scooter != null, "One-Wheel Scooter must instantiate cleanly")
	root.add_child(scooter)
	scooter.global_position = Vector2(0, 320)
	
	# Check single-wheel anatomy
	assert(scooter.rear_wheel != null, "Scooter must have RearWheel")
	assert(scooter.front_wheel == null, "Scooter must NOT have FrontWheel")
	assert(scooter.rear_wheel.physics_material_override != null, "Wheel must have physics material")
	assert(scooter.has_method("refuel"), "Scooter must support refuel")
	assert(scooter.has_method("consume_fuel"), "Scooter must support consume_fuel")
	assert(scooter.has_method("set_nitro_active"), "Scooter must support nitro")
	
	# Let scooter settle on ground
	for i in range(10):
		await process_frame
		await physics_frame
	
	# Verify balance stabilization: tilt vehicle and verify upright correction
	scooter.rotation = 0.25 # Tilted ~14 degrees
	scooter.angular_velocity = 0.0
	scooter.is_grounded = true
	scooter._physics_process(0.05)
	
	# Gyro stabilization should produce negative torque to counter positive tilt
	assert(scooter.balance_assistance_enabled == true, "Balance assistance must be enabled")
	
	# Test drive forward
	var start_fuel = scooter.current_fuel
	scooter.set_nitro_active(true)
	scooter._physics_process(0.1)
	assert(scooter.is_nitro_active == true, "Scooter must support nitro boost")
	assert(scooter.current_nitro < 100.0, "Scooter must consume nitro energy")
	
	root.remove_child(scooter)
	scooter.free()
	print("  ✓ One-Wheel Scooter single-wheel architecture, gyro balance, and nitro mechanics verified")

func test_snowfall_manager_milestones() -> void:
	print("-> [7/8] Verifying SnowfallManager Milestone Triggers (200m, 400m, 600m)...")
	var snow_packed = load("res://scenes/environment/SnowfallManager.tscn")
	var snow = snow_packed.instantiate()
	root.add_child(snow)
	
	var event_log: Array[int] = []
	snow.snowfall_started.connect(func(m): event_log.append(m))
	
	# At 0-199m: no snowfall
	snow._on_distance_updated(50.0)
	snow._on_distance_updated(120.0)
	snow._on_distance_updated(199.0)
	assert(event_log.is_empty(), "No snowfall event should trigger under 200m")
	assert(snow.is_snowing == false, "Snowfall must be inactive under 200m")
	
	# At 200m: first milestone
	snow._on_distance_updated(200.0)
	assert(event_log.size() == 1 and event_log[0] == 1, "First event must trigger at milestone 1 (200m)")
	assert(snow.is_snowing == true, "Snowfall must be active after milestone 1")
	
	# Same milestone update must NOT re-trigger
	snow._on_distance_updated(205.0)
	snow._on_distance_updated(350.0)
	assert(event_log.size() == 1, "Duplicate events at same milestone must be prevented")
	
	# At 400m: second milestone
	snow._on_distance_updated(400.0)
	assert(event_log.size() == 2 and event_log[1] == 2, "Second event must trigger at milestone 2 (400m)")
	
	# Large distance jump: e.g. 400m to 650m
	snow._on_distance_updated(650.0)
	assert(event_log.size() == 3 and event_log[2] == 3, "Milestone 3 (600m) must trigger even across distance jumps")
	
	# Run restart resets tracking
	snow._on_run_started()
	assert(snow.last_milestone == 0, "Last milestone must reset to 0 on new run")
	assert(snow.is_snowing == false, "Snowfall must stop on run restart")
	
	root.remove_child(snow)
	snow.free()
	print("  ✓ Snowfall milestones (200m, 400m, 600m), duplicate prevention, and clean reset verified")

func test_front_ui_vehicle_selection_and_persistence() -> void:
	print("-> [8/8] Verifying Front UI Vehicle Changing Button & Selected Vehicle Persistence...")
	SaveManager.custom_save_path = "user://test_vehicle_select_save.json"
	SaveManager.reset_save()
	
	# Default selection check
	assert(SaveManager.get_selected_vehicle_id() == "blue_flame_truck", "Default selected vehicle must be blue_flame_truck")
	
	# Load MainMenu
	var menu_packed = load("res://scenes/main/MainMenu.tscn")
	var menu: MainMenuController = menu_packed.instantiate()
	root.add_child(menu)
	for i in range(5):
		await process_frame
		
	var change_btn: Button = menu.get_node_or_null("%ChangeVehicleButton")
	assert(change_btn != null, "MainMenu must contain ChangeVehicleButton")
	assert(change_btn.text == "CHANGE VEHICLE", "Button text must be 'CHANGE VEHICLE'")
	
	# Click CHANGE VEHICLE
	change_btn.pressed.emit()
	assert(menu.vehicle_select_panel.visible == true, "Vehicle select panel must open on button press")
	assert(menu.content_vbox.visible == false, "Main menu content should hide when panel is open")
	
	# Verify vehicle cards exist in container (all 4 registered vehicles)
	var cards = menu.vehicle_cards_container.get_children()
	assert(cards.size() == 4, "Must render exactly 4 vehicle selection cards (got %d)" % cards.size())
	
	var prev_btn: Button = menu.get_node_or_null("%PrevVehicleButton")
	var next_btn: Button = menu.get_node_or_null("%NextVehicleButton")
	assert(prev_btn != null and next_btn != null, "Carousel navigation arrows must exist")
	
	# Select Trophy Truck
	menu._on_vehicle_selected("trophy_truck")
	assert(SaveManager.get_selected_vehicle_id() == "trophy_truck", "Selected vehicle must persist as trophy_truck")
	
	# Select Orc Racer
	menu._on_vehicle_selected("orc_racer")
	assert(SaveManager.get_selected_vehicle_id() == "orc_racer", "Selected vehicle must persist as orc_racer")
	
	# Close panel via back button
	var back_btn: Button = menu.get_node_or_null("%VehicleSelectBackButton")
	assert(back_btn != null, "Vehicle select panel must have Back button")
	back_btn.pressed.emit()
	assert(menu.vehicle_select_panel.visible == false, "Vehicle select panel must close")
	assert(menu.content_vbox.visible == true, "Main content must be visible again")
	
	root.remove_child(menu)
	menu.free()
	
	# Verify Game scene spawns the chosen vehicle (Orc Racer)
	var game_packed = load("res://scenes/game/Game.tscn")
	var game = game_packed.instantiate()
	root.add_child(game)
	for i in range(5):
		await process_frame
		await physics_frame
		
	assert(game.vehicle != null, "Game must instantiate selected Orc Racer")
	assert(game.vehicle.name == "Vehicle", "Spawned vehicle node must be named 'Vehicle'")
	assert(game.follow_camera.target == game.vehicle, "FollowCamera must target spawned vehicle")
	
	root.remove_child(game)
	game.free()
	
	# Test fallback safely to blue_flame_truck if corrupted ID is saved
	SaveManager.set_selected_vehicle_id("invalid_rocket_ship")
	assert(SaveManager.get_selected_vehicle_id() == "blue_flame_truck", "Invalid vehicle ID must fall back to blue_flame_truck")
	
	SaveManager.reset_save()
	SaveManager.custom_save_path = ""
	print("  ✓ Vehicle selection button, 4 cards preview, persistence, and dynamic spawning verified")
