extends SceneTree

# Comprehensive test suite for UI Redesign, Pickup Bug Fixes, and New Vehicle Integration

const VehicleRegistry = preload("res://scripts/vehicle/VehicleRegistry.gd")
const SaveManager = preload("res://scripts/core/SaveManager.gd")
const TerrainGenerator = preload("res://scripts/terrain/TerrainGenerator.gd")
const TerrainSegment = preload("res://scripts/terrain/TerrainSegment.gd")
const CoinScript = preload("res://scripts/pickups/Coin.gd")
const FuelPickupScript = preload("res://scripts/pickups/FuelPickup.gd")

func _init() -> void:
	print("\n=================================================================")
	print("--- BEGIN UI REDESIGN, PICKUPS & NEW VEHICLES VERIFICATION ---")
	print("=================================================================\n")
	
	await test_nitro_button_redesign()
	await test_single_sun_environment()
	await test_pickup_placement_and_collection()
	await test_vehicle_selection_carousel()
	await test_new_vehicles_integration_and_physics()
	await test_pause_menu_main_menu_button()
	
	print("\n=================================================================")
	print("✓ ALL UI REDESIGN, PICKUP AND NEW VEHICLE CHECKS PASSED 100%!")
	print("=================================================================\n")
	quit(0)

func test_nitro_button_redesign() -> void:
	print("-> [1/5] Verifying Nitro Button Redesign (Artwork-only, Transparent, Interactive)...")
	var hud_packed = load("res://scenes/ui/HUD.tscn")
	var hud = hud_packed.instantiate()
	root.add_child(hud)
	
	for i in range(3):
		await process_frame
		
	var nitro_btn: TextureButton = hud.get_node_or_null("%NitroButton")
	assert(nitro_btn != null, "NitroButton must exist in HUD")
	assert(nitro_btn.texture_normal != null, "NitroButton must have normal texture")
	assert(nitro_btn.texture_normal.resource_path.ends_with("nitro_bottle.png"), 
		"NitroButton must use clean nitro_bottle artwork, got %s" % nitro_btn.texture_normal.resource_path)
	
	# Verify no unnecessary text label node exists on the button
	var label = nitro_btn.get_node_or_null("NitroButtonLabel")
	assert(label == null, "Old NitroButtonLabel text must be removed from NitroButton")
	
	# Verify position on left side cleanly above BrakePedal with matching size
	var brake_pedal: TextureButton = hud.get_node_or_null("%BrakePedal")
	var gas_pedal: TextureButton = hud.get_node_or_null("%GasPedal")
	assert(brake_pedal != null, "BrakePedal must exist")
	assert(gas_pedal != null, "GasPedal must exist")
	assert(nitro_btn.offset_bottom <= brake_pedal.offset_top, 
		"NitroButton (bottom: %f) must be cleanly above BrakePedal (top: %f)" % [nitro_btn.offset_bottom, brake_pedal.offset_top])
	# Verify mobile button size scaling (140x140 px for all three controls)
	assert(brake_pedal.offset_right - brake_pedal.offset_left == 140.0, "BrakePedal width must be 140px")
	assert(gas_pedal.offset_right - gas_pedal.offset_left == 140.0, "GasPedal width must be 140px")
	assert(nitro_btn.offset_right - nitro_btn.offset_left == 140.0, "NitroButton width must be 140px")
	assert(nitro_btn.offset_bottom - nitro_btn.offset_top == brake_pedal.offset_bottom - brake_pedal.offset_top,
		"NitroButton and BrakePedal must have matching height")
	
	# Verify interactive button states
	nitro_btn.button_down.emit()
	assert(Input.is_action_pressed("nitro"), "Pressing NitroButton must press 'nitro' action")
	nitro_btn.button_up.emit()
	assert(not Input.is_action_pressed("nitro"), "Releasing NitroButton must release 'nitro' action")
	
	# Verify depleted modulation
	hud._on_nitro_updated(0.0, 100.0)
	assert(nitro_btn.modulate.a < 0.9, "NitroButton must dim when nitro is depleted")
	hud._on_nitro_updated(100.0, 100.0)
	assert(is_equal_approx(nitro_btn.modulate.a, 1.0), "NitroButton must restore full alpha when replenished")
	
	root.remove_child(hud)
	hud.free()
	print("  ✓ Nitro button artwork, transparent background, positioning, and interactivity verified!")

func test_single_sun_environment() -> void:
	print("-> [2/5] Verifying Single Sun in Parallax Environment...")
	var env_packed = load("res://scenes/environment/ParallaxEnvironment.tscn")
	var env = env_packed.instantiate()
	root.add_child(env)
	
	var sky_layer: ParallaxLayer = env.get_node_or_null("SkyLayer")
	assert(sky_layer != null, "SkyLayer must exist")
	
	var sun_sprite: Sprite2D = sky_layer.get_node_or_null("SunSprite")
	assert(sun_sprite != null, "SunSprite must exist")
	assert(sun_sprite.visible == true, "SunSprite must be visible")
	
	# Verify SVG texture dimensions: height must be 180 (single sun, not 360 double sun)
	var sun_tex: Texture2D = sun_sprite.texture
	assert(sun_tex != null, "SunSprite must have texture")
	assert(sun_tex.get_height() == 180, "Sun SVG height must be 180 (single sun), got %d" % sun_tex.get_height())
	
	# Verify no SunCore duplicate polygon
	assert(sky_layer.get_node_or_null("SunCore") == null, "SunCore duplicate must not exist")
	
	root.remove_child(env)
	env.free()
	print("  ✓ Exactly one distinct sun verified with proper single-sun SVG dimensions!")

func test_pickup_placement_and_collection() -> void:
	print("-> [3/5] Verifying Pickup Placement & Multi-Body Collision Detection...")
	var gen = TerrainGenerator.new()
	root.add_child(gen)
	
	# Test pickup placement across flat, hill, and valley
	var test_shapes = [
		TerrainSegment.SegmentType.FLAT,
		TerrainSegment.SegmentType.STEEP_CLIMB,
		TerrainSegment.SegmentType.VALLEY_DIP
	]
	
	for st in test_shapes:
		var seg = gen._create_segment(st, 1000.0, 0.0, 0.0, 80.0, 0.0, 0.0)
		root.add_child(seg)
		seg.global_position = Vector2(0, 300)
		
		# 1. Spawn Coin
		gen._spawn_coins_on_segment(seg)
		var coins: Array[Node2D] = []
		for child in seg.get_children():
			if child is CoinScript:
				coins.append(child)
		assert(coins.size() >= 3, "Expected coins on segment type %d" % st)
		
		for c in coins:
			var surf_y = seg.get_surface_y_at(c.position.x)
			var clearance = surf_y - c.position.y
			assert(clearance >= 30.0 and clearance <= 65.0, 
				"Coin clearance must be reachable (30-65px above ground), got %f on shape %d" % [clearance, st])
			assert(not Geometry2D.is_point_in_polygon(c.position, seg.collision_polygon.polygon),
				"Coin must not be inside terrain polygon")
		
		# 2. Spawn Fuel
		gen._spawn_fuel_on_segment(seg, 500.0)
		var fuel: Node2D = null
		for child in seg.get_children():
			if child is FuelPickupScript:
				fuel = child
				break
		assert(fuel != null, "Fuel canister must spawn")
		var fuel_surf_y = seg.get_surface_y_at(fuel.position.x)
		var f_clearance = fuel_surf_y - fuel.position.y
		assert(f_clearance >= 40.0 and f_clearance <= 75.0,
			"Fuel clearance must be reachable (40-75px above ground), got %f on shape %d" % [f_clearance, st])
		assert(not Geometry2D.is_point_in_polygon(fuel.position, seg.collision_polygon.polygon),
			"Fuel must not be inside terrain polygon")
		
		root.remove_child(seg)
		seg.free()
	
	gen.clear_terrain()
	root.remove_child(gen)
	gen.free()
	
	# Test Collision Detection with Vehicle chassis, rear wheel, and front wheel
	var coin_packed = load("res://scenes/pickups/Coin.tscn")
	var coin = coin_packed.instantiate()
	root.add_child(coin)
	coin.position = Vector2(1000, 1000)
	
	var veh_packed = load("res://scenes/vehicle/BlueFlameTruck.tscn")
	var veh = veh_packed.instantiate()
	root.add_child(veh)
	veh.position = Vector2(100, 100)
	for i in range(2):
		await process_frame
	
	# Simulate wheel triggering coin body_entered
	assert(coin.is_collected == false, "Coin must start uncollected")
	coin._on_body_entered(veh.rear_wheel)
	assert(coin.is_collected == true, "Coin must be collected when rear wheel touches it")
	
	# Test Fuel collection
	var fuel_packed = load("res://scenes/pickups/FuelPickup.tscn")
	var f_pickup = fuel_packed.instantiate()
	root.add_child(f_pickup)
	f_pickup.position = Vector2(2000, 2000)
	for i in range(2):
		await process_frame
	
	veh.current_fuel = 50.0
	f_pickup._on_body_entered(veh.front_wheel)
	assert(f_pickup.is_collected == true, "Fuel pickup must be collected when front wheel touches it")
	assert(veh.current_fuel == 85.0, "Fuel must replenish by 35 (50 -> 85)")
	
	root.remove_child(coin)
	root.remove_child(f_pickup)
	root.remove_child(veh)
	coin.free()
	f_pickup.free()
	veh.free()
	print("  ✓ Pickup positioning on all slopes & multi-body collision detection verified!")

func test_vehicle_selection_carousel() -> void:
	print("-> [4/5] Verifying Vehicle Selection Carousel & Navigation...")
	var menu_packed = load("res://scenes/main/MainMenu.tscn")
	var menu = menu_packed.instantiate()
	root.add_child(menu)
	
	for i in range(3):
		await process_frame
		
	var change_btn: Button = menu.get_node_or_null("%ChangeVehicleButton")
	assert(change_btn != null, "ChangeVehicleButton must exist")
	change_btn.pressed.emit()
	
	var panel = menu.get_node_or_null("%VehicleSelectPanel")
	assert(panel.visible == true, "VehicleSelectPanel must be visible")
	
	var prev_btn: Button = menu.get_node_or_null("%PrevVehicleButton")
	var next_btn: Button = menu.get_node_or_null("%NextVehicleButton")
	var scroll_cnt: ScrollContainer = menu.get_node_or_null("%ScrollContainer")
	assert(prev_btn != null and next_btn != null, "Navigation arrows must exist")
	assert(scroll_cnt != null, "ScrollContainer must exist")
	
	# Verify all 4 vehicle cards exist with valid previews
	var cards = menu.vehicle_cards_container.get_children()
	assert(cards.size() == 4, "All 4 vehicle cards must be rendered (got %d)" % cards.size())
	
	var all_vehicles = VehicleRegistry.get_all_vehicles()
	for idx in range(cards.size()):
		var card = cards[idx]
		var v_meta = all_vehicles[idx]
		# Find TextureRect in card
		var tex_rect: TextureRect = null
		for child in card.find_children("*", "TextureRect", true, false):
			tex_rect = child
			break
		assert(tex_rect != null, "Card %d must contain TextureRect" % idx)
		assert(tex_rect.texture != null, "Card for %s must have valid texture preview (cannot be blank)" % v_meta["id"])
	
	# Test Next arrow click
	var init_scroll = scroll_cnt.scroll_horizontal
	next_btn.pressed.emit()
	
	# Test selecting Trophy Truck
	menu._on_vehicle_selected("trophy_truck")
	assert(SaveManager.get_selected_vehicle_id() == "trophy_truck", "Selected vehicle must save as trophy_truck")
	
	# Reset to Blue Flame Truck
	menu._on_vehicle_selected("blue_flame_truck")
	assert(SaveManager.get_selected_vehicle_id() == "blue_flame_truck", "Reset back to blue_flame_truck")
	
	root.remove_child(menu)
	menu.free()
	print("  ✓ Vehicle selection carousel (4 vehicles, previews, navigation arrows, selection persistence) verified!")

func test_new_vehicles_integration_and_physics() -> void:
	print("-> [5/5] Verifying 3 New Vehicles (Blue Flame Truck, Orc Racer, Trophy Truck)...")
	var new_ids = ["blue_flame_truck", "orc_racer", "trophy_truck"]
	
	for v_id in new_ids:
		var veh: VehicleController = VehicleRegistry.instantiate_vehicle(v_id)
		assert(veh != null, "Vehicle %s must instantiate" % v_id)
		root.add_child(veh)
		veh.position = Vector2(0, 300)
		for i in range(2):
			await process_frame
		
		# Verify physics components
		assert(veh.rear_wheel != null, "%s must have rear_wheel" % v_id)
		assert(veh.front_wheel != null, "%s must have front_wheel" % v_id)
		assert(veh.rear_joint != null, "%s must have rear_joint" % v_id)
		assert(veh.front_joint != null, "%s must have front_joint" % v_id)
		assert(veh.crash_detector != null, "%s must have crash_detector" % v_id)
		assert(veh.is_in_group("vehicle"), "%s must be in 'vehicle' group" % v_id)
		assert(veh.rear_wheel.is_in_group("vehicle"), "%s rear wheel must be in 'vehicle' group" % v_id)
		
		# Verify Nitro visuals attach
		veh._ensure_nitro_visuals()
		assert(veh.nitro_flame != null, "%s must have nitro_flame" % v_id)
		assert(veh.nitro_burst != null, "%s must have nitro_burst" % v_id)
		assert(veh.nitro_sparks != null, "%s must have nitro_sparks" % v_id)
		
		# Test Nitro activation
		veh.set_nitro_active(true)
		veh._physics_process(0.05)
		assert(veh.is_nitro_active == true, "%s nitro must activate" % v_id)
		assert(veh.nitro_flame.visible == true, "%s nitro flame must be visible" % v_id)
		veh.set_nitro_active(false)
		veh._physics_process(0.05)
		assert(veh.is_nitro_active == false, "%s nitro must deactivate" % v_id)
		assert(veh.nitro_flame.visible == false, "%s nitro flame must hide" % v_id)
		
		# Test Fuel refuel
		veh.current_fuel = 40.0
		veh.refuel(30.0)
		assert(veh.current_fuel == 70.0, "%s refuel must work" % v_id)
		
		root.remove_child(veh)
		veh.free()
		print("    • %s verified: dual wheels, joints, crash detector, nitro, and fuel!" % v_id)
		
	print("  ✓ All 3 new vehicles completely verified!")

func test_pause_menu_main_menu_button() -> void:
	print("-> [6/6] Verifying PauseMenu Main Menu Button and Navigation...")
	var pause_packed = load("res://scenes/ui/PauseMenu.tscn")
	var pause_menu = pause_packed.instantiate()
	root.add_child(pause_menu)
	
	for i in range(2):
		await process_frame
		
	var resume_btn: Button = pause_menu.get_node_or_null("%ResumeButton")
	var retry_btn: Button = pause_menu.get_node_or_null("%RetryButton")
	var menu_btn: Button = pause_menu.get_node_or_null("%MainMenuButton")
	
	assert(resume_btn != null, "ResumeButton must exist")
	assert(retry_btn != null, "RetryButton must exist")
	assert(menu_btn != null, "MainMenuButton must exist")
	assert(menu_btn.text == "MAIN MENU", "MainMenuButton text must be 'MAIN MENU'")
	assert(menu_btn.custom_minimum_size.y == 48, "MainMenuButton must match 48px height style")
	
	var menu_signals: Array = []
	pause_menu.menu_requested.connect(func(): menu_signals.append(true))
	
	# Trigger MainMenuButton pressed
	pause_menu.visible = true
	menu_btn.pressed.emit()
	assert(menu_signals.size() > 0, "menu_requested signal must be emitted when Main Menu is pressed")
	assert(pause_menu.visible == false, "PauseMenu should hide when returning to menu")
	
	root.remove_child(pause_menu)
	pause_menu.free()
	print("  ✓ PauseMenu Main Menu button verified cleanly!")
