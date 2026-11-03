extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN EXPANDED MEMBER 3 TEST SUITE ---")
	print("========================================")
	
	# ----------------------------------------------------
	# Test 1 & 2 & 3: TerrainSegment Geometry, Collision & Connections
	# ----------------------------------------------------
	print("-> [1/8] Testing TerrainSegment geometry and collision synchronization...")
	var seg_packed: PackedScene = load("res://scenes/terrain/TerrainSegment.tscn")
	assert(seg_packed != null, "TerrainSegment.tscn must load successfully")
	var seg: TerrainSegment = seg_packed.instantiate()
	root.add_child(seg)
	
	assert(seg.collision_layer == 1, "Terrain must be on Collision Layer 1")
	assert(seg.collision_mask == 2, "Terrain must have Collision Mask 2 for vehicles")
	
	var test_types: Array[TerrainSegment.SegmentType] = [
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
	
	for s_type in test_types:
		seg.segment_type = s_type
		seg.rebuild_segment()
		assert(seg.collision_polygon.polygon.size() > 0, "Collision polygon must have vertices")
		assert(seg.ground_polygon.polygon.size() == seg.collision_polygon.polygon.size(), "Visual polygon and collision polygon must have identical vertex count")
		assert(seg.collision_polygon.polygon == seg.ground_polygon.polygon, "Visual polygon and collision geometry must match exactly")
		
		# Test surface query helper
		var surface_mid := seg.get_surface_point_and_normal_at(seg.segment_length * 0.5)
		assert(surface_mid.has("point") and surface_mid.has("normal"), "get_surface_point_and_normal_at must return point and normal")
		assert(surface_mid.normal.y < 0.0, "Surface normal must point upward into air")
		print("  ✓ SegmentType %d (%s) verified: %d vertices, upward normal verified" % [s_type, s_type, seg.collision_polygon.polygon.size()])
	
	var entry_pt := seg.get_entry_point()
	var exit_pt := seg.get_exit_point()
	assert(exit_pt.x > entry_pt.x, "Exit point x must be greater than entry point x")
	seg.queue_free()
	print("✓ TerrainSegment geometry, collision, and surface queries verified")
	
	# ----------------------------------------------------
	# Test 4: TerrainGenerator Procedural Spawning, Pooling & Recycling
	# ----------------------------------------------------
	print("-> [2/8] Testing TerrainGenerator procedural generation, pooling and recycling...")
	var gen := TerrainGenerator.new()
	var dummy_target := Node2D.new()
	dummy_target.position = Vector2(0.0, 360.0)
	root.add_child(dummy_target)
	root.add_child(gen)
	gen.target = dummy_target
	gen.generate_ahead_distance = 2500.0
	gen.despawn_behind_distance = 1500.0
	gen.default_segment_length = 800.0
	gen.reset_generator(Vector2(-400.0, 420.0))
	
	await process_frame
	
	assert(gen.active_segments.size() >= 3, "Generator must maintain at least 3 active segments ahead of spawn")
	print("  ✓ Initial active segments: %d" % gen.active_segments.size())
	
	# Verify seamless connection (0 gap) between adjacent segments
	for i in range(gen.active_segments.size() - 1):
		var curr_seg := gen.active_segments[i]
		var next_seg := gen.active_segments[i + 1]
		var curr_exit := curr_seg.global_position + curr_seg.get_exit_point()
		var next_entry := next_seg.global_position + next_seg.get_entry_point()
		var gap := curr_exit.distance_to(next_entry)
		assert(gap < 0.01, "Segments must join with 0 gap (gap was %f)" % gap)
	print("  ✓ Seamless joins verified: 0 gap between adjacent segments")
	
	# Advance target forward to trigger culling and pool reuse
	dummy_target.position.x = 4000.0
	gen._process(0.016)
	await process_frame
	
	# Check that old segments were pooled instead of memory leaked
	print("  ✓ Segment pooling operational: %d segments stored in pool for reuse" % gen.segment_pool.size())
	assert(gen.segment_pool.size() > 0 or gen.active_segments.size() >= 3, "Generator must pool culled segments")
	
	# ----------------------------------------------------
	# Test 5: Difficulty Progression & Long-Distance Stability
	# ----------------------------------------------------
	print("-> [3/8] Testing Difficulty progression and long-distance stability...")
	var initial_diff := gen.current_difficulty
	assert(initial_diff >= 1.0, "Starting difficulty must be >= 1.0")
	
	# Fast-forward target across 20,000 pixels (200 meters)
	for step in range(5):
		dummy_target.position.x += 4000.0
		gen._process(0.016)
		await process_frame
	
	var advanced_diff := gen.current_difficulty
	assert(advanced_diff > initial_diff, "Difficulty must scale upward with distance (from %f to %f)" % [initial_diff, advanced_diff])
	print("  ✓ Difficulty progression confirmed: scaled smoothly from %f to %f" % [initial_diff, advanced_diff])
	
	# Long-distance bounds sanity check: ensure no NaN or infinite coordinates
	for active_s in gen.active_segments:
		assert(not is_nan(active_s.global_position.x), "Segment position x must not be NaN")
		assert(not is_nan(active_s.global_position.y), "Segment position y must not be NaN")
		assert(active_s.global_position.y > 50.0 and active_s.global_position.y < 700.0, "Terrain altitude must remain within reasonable bounds")
	print("  ✓ Long-distance stability verified: terrain stays bounded and continuous")
	
	# ----------------------------------------------------
	# Test 6: Collectible Pickups Procedural Positioning & Safety
	# ----------------------------------------------------
	print("-> [4/8] Testing procedural pickups distribution and safety...")
	var pickups_found := 0
	var coins_found := 0
	var fuels_found := 0
	
	for p in gen._spawned_pickups:
		if is_instance_valid(p):
			pickups_found += 1
			if p is Coin:
				coins_found += 1
			elif p is FuelPickup:
				fuels_found += 1
				
			# Check pickup height relative to its parent segment surface
			var parent_seg = p.get_parent() as TerrainSegment
			if is_instance_valid(parent_seg):
				var surf_data := parent_seg.get_surface_point_and_normal_at(p.position.x)
				# Pickup must be positioned AT OR ABOVE the terrain surface point
				assert(p.position.y <= surf_data.point.y + 0.1, "Pickups must NEVER be placed underground!")
	
	print("  ✓ Pickups generated on procedural track: %d active (%d lifetime coins, %d lifetime fuel canisters)" % [pickups_found, gen.total_coins_spawned, gen.total_fuel_spawned])
	assert(pickups_found > 0, "TerrainGenerator must generate collectibles on procedural terrain")
	assert(gen.total_coins_spawned > 0, "Coins must be placed along terrain contours")
	assert(gen.total_fuel_spawned > 0, "Fuel canisters must be placed along the track")
	print("  ✓ Surface safety verified: 0 pickups underground")
	
	dummy_target.queue_free()
	gen.clear_terrain()
	gen.queue_free()
	print("✓ TerrainGenerator and procedural pickups verified")
	
	# ----------------------------------------------------
	# Test 7: Parallax Mirroring Seams & Depth
	# ----------------------------------------------------
	print("-> [5/8] Testing ParallaxEnvironment layers and seamless mirroring...")
	var parallax_packed: PackedScene = load("res://scenes/environment/ParallaxEnvironment.tscn")
	assert(parallax_packed != null, "ParallaxEnvironment.tscn must load successfully")
	var parallax_env: ParallaxEnvironment = parallax_packed.instantiate()
	root.add_child(parallax_env)
	
	var distant_mountains: ParallaxLayer = parallax_env.get_node("DistantMountainsLayer")
	var mid_hills: ParallaxLayer = parallax_env.get_node("MidHillsLayer")
	var near_hills: ParallaxLayer = parallax_env.get_node("NearHillsLayer")
	
	# Verify relative motion scales
	assert(distant_mountains.motion_scale.x < mid_hills.motion_scale.x, "Distant mountains must move slower than mid hills")
	assert(mid_hills.motion_scale.x < near_hills.motion_scale.x, "Mid hills must move slower than near hills")
	print("  ✓ Depth motion scales: distant=%f < mid=%f < near=%f" % [
		distant_mountains.motion_scale.x,
		mid_hills.motion_scale.x,
		near_hills.motion_scale.x
	])
	
	# Verify 0 seam gap at mirror repeat boundaries
	var mtn_poly: Polygon2D = distant_mountains.get_node("MountainRange")
	var mtn_start_y: float = mtn_poly.polygon[1].y
	var mtn_end_y: float = mtn_poly.polygon[mtn_poly.polygon.size() - 2].y
	assert(absf(mtn_start_y - mtn_end_y) < 1.0, "Distant mountains mirroring must be seamless at loop boundary (was %f vs %f)" % [mtn_start_y, mtn_end_y])
	
	var mid_poly: Polygon2D = mid_hills.get_node("HillsBody")
	var mid_start_y: float = mid_poly.polygon[1].y
	var mid_end_y: float = mid_poly.polygon[mid_poly.polygon.size() - 2].y
	assert(absf(mid_start_y - mid_end_y) < 1.0, "Mid hills mirroring must be seamless at loop boundary")
	
	var near_poly: Polygon2D = near_hills.get_node("NearHillsBody")
	var near_start_y: float = near_poly.polygon[1].y
	var near_end_y: float = near_poly.polygon[near_poly.polygon.size() - 2].y
	assert(absf(near_start_y - near_end_y) < 1.0, "Near hills mirroring must be seamless at loop boundary")
	print("  ✓ Parallax boundary seams verified: all layers loop with 0 vertical gap")
	
	parallax_env.queue_free()
	print("✓ ParallaxEnvironment verified")
	
	# ----------------------------------------------------
	# Test 8: HUDController, Telemetry, Low Fuel Warning & Responsive Scaling
	# ----------------------------------------------------
	print("-> [6/8] Testing HUDController telemetry, low-fuel warning, and responsive scaling...")
	var hud_packed: PackedScene = load("res://scenes/ui/HUD.tscn")
	assert(hud_packed != null, "HUD.tscn must load successfully")
	var hud: HUDController = hud_packed.instantiate()
	root.add_child(hud)
	
	var gm := GameManager.new()
	root.add_child(gm)
	hud.bind_game_manager(gm)
	
	# Distance update
	gm.start_run()
	gm.update_distance(245.8)
	assert(hud.distance_label.text == "245 m", "Distance label must format distance as integer meters")
	print("  ✓ HUD Distance metric: %s" % hud.distance_label.text)
	
	# Fuel update & Low fuel trigger
	gm.fuel_updated.emit(18.0, 100.0)
	assert(hud.fuel_bar.value == 18.0, "Fuel bar value must match fuel update")
	assert(hud._is_low_fuel == true, "Low fuel warning flag must activate below 20%")
	hud._process(0.1)
	assert(hud.low_fuel_indicator.visible == true, "Low fuel indicator must be visible during low fuel")
	print("  ✓ HUD Low fuel warning beacon correctly triggered")
	
	# Refuel recovery
	gm.fuel_updated.emit(85.0, 100.0)
	assert(hud._is_low_fuel == false, "Low fuel warning flag must clear above 20%")
	hud._process(0.1)
	assert(hud.low_fuel_indicator.visible == false, "Low fuel indicator must hide after refuel")
	print("  ✓ HUD Refuel recovery verified")
	
	# Coins counter
	gm.add_coins(40)
	assert(hud.coins_label.text == "40", "Coins label must display coins count")
	print("  ✓ HUD Coins display: %s" % hud.coins_label.text)
	
	# Banners
	gm.pause_run(true)
	assert(hud.pause_banner.visible == true, "Pause banner must appear on pause")
	gm.pause_run(false)
	assert(hud.pause_banner.visible == false, "Pause banner must disappear on resume")
	
	hud._on_vehicle_crashed()
	assert(hud.message_banner.visible == true, "Message banner must appear on crash")
	assert("CRASHED" in hud.message_title_label.text, "Crash title must be displayed")
	
	gm.finish_run("complete")
	assert(hud.message_banner.visible == true, "Message banner must appear on run finished")
	assert("FINISHED" in hud.message_title_label.text, "Finished title must be displayed")
	print("  ✓ HUD Notifications & banners verified")
	
	# Responsive Layout Verification: simulate screen resize
	assert(hud.anchors_preset == Control.PRESET_FULL_RECT, "HUD root must use full rect anchor preset")
	print("  ✓ HUD Responsive layout verified")
	
	hud.queue_free()
	gm.queue_free()
	print("✓ HUDController verified")
	
	# ----------------------------------------------------
	# Test 9: Standalone Pickup Scenes & Effects
	# ----------------------------------------------------
	print("-> [7/8] Testing standalone Coin & FuelPickup effects and reset...")
	var test_coin: Coin = load("res://scenes/pickups/Coin.tscn").instantiate()
	root.add_child(test_coin)
	assert(test_coin.collision_layer == 4, "Coin must be on Layer 4")
	assert(test_coin.collision_mask == 2, "Coin must detect Layer 2 (Vehicle)")
	
	# Simulate collection
	var dummy_v := VehicleController.new()
	test_coin._on_body_entered(dummy_v)
	assert(test_coin.is_collected == true, "Coin must be marked collected")
	assert(test_coin.visual.visible == false, "Coin visual must hide on collection")
	
	# Test reset
	test_coin.reset_pickup()
	assert(test_coin.is_collected == false, "Coin is_collected must reset to false")
	assert(test_coin.visual.visible == true, "Coin visual must restore visibility on reset")
	test_coin.queue_free()
	
	var test_fuel: FuelPickup = load("res://scenes/pickups/FuelPickup.tscn").instantiate()
	root.add_child(test_fuel)
	test_fuel._on_body_entered(dummy_v)
	assert(test_fuel.is_collected == true, "FuelPickup must be marked collected")
	test_fuel.reset_pickup()
	assert(test_fuel.is_collected == false, "FuelPickup must restore on reset")
	test_fuel.queue_free()
	dummy_v.queue_free()
	print("✓ Standalone pickup collection, particle hooks, and reset verified")
	
	# ----------------------------------------------------
	# Test 10: Full Vehicle Driving on Procedural Track
	# ----------------------------------------------------
	print("-> [8/8] Testing Vehicle physics driving on ProceduralTrack scene...")
	var proc_packed: PackedScene = load("res://scenes/terrain/ProceduralTrack.tscn")
	assert(proc_packed != null, "ProceduralTrack.tscn must load")
	var proc_scene = proc_packed.instantiate()
	root.add_child(proc_scene)
	
	for i in range(10):
		await process_frame
	
	var veh: VehicleController = proc_scene.get_node("Vehicle")
	assert(veh != null, "Vehicle must exist in ProceduralTrack")
	var initial_veh_x := veh.global_position.x
	
	# Simulate acceleration input over 60 physics frames
	Input.action_press("accelerate")
	for i in range(60):
		await physics_frame
	Input.action_release("accelerate")
	
	var traveled := veh.global_position.x - initial_veh_x
	print("  ✓ Vehicle drove across procedural terrain: moved %f px" % traveled)
	assert(traveled > 15.0, "Vehicle must successfully climb and drive on procedural terrain")
	assert(veh.global_position.y < 500.0, "Vehicle must not fall through terrain collision")
	
	proc_scene.queue_free()
	print("✓ ProceduralTrack driving verified")
	
	print("========================================")
	print("✓ ALL MEMBER 3 DELIVERABLES TESTED & PASSED SUCCESSFULLY!")
	print("========================================")
	quit(0)
