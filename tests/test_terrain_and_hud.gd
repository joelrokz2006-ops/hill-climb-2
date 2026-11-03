extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- BEGIN MEMBER 3 TEST SUITE ---")
	print("========================================")
	
	# Test 1: TerrainSegment geometry and collision synchronization
	print("-> Testing TerrainSegment scene and geometry...")
	var seg_packed: PackedScene = load("res://scenes/terrain/TerrainSegment.tscn")
	assert(seg_packed != null, "TerrainSegment.tscn must load successfully")
	var seg: TerrainSegment = seg_packed.instantiate()
	root.add_child(seg)
	
	assert(seg.collision_layer == 1, "Terrain must be on Collision Layer 1")
	assert(seg.collision_mask == 2, "Terrain must have Collision Mask 2 for vehicles")
	
	for s_type in [
		TerrainSegment.SegmentType.FLAT,
		TerrainSegment.SegmentType.GENTLE_HILLS,
		TerrainSegment.SegmentType.STEEP_CLIMB,
		TerrainSegment.SegmentType.VALLEY_DIP,
		TerrainSegment.SegmentType.JUMP_RAMP,
		TerrainSegment.SegmentType.ROLLING_WAVES
	]:
		seg.segment_type = s_type
		seg.rebuild_segment()
		assert(seg.collision_polygon.polygon.size() > 0, "Collision polygon must have vertices")
		assert(seg.ground_polygon.polygon.size() == seg.collision_polygon.polygon.size(), "Visual polygon and collision polygon must have identical vertex count")
		assert(seg.collision_polygon.polygon == seg.ground_polygon.polygon, "Visual polygon and collision geometry must match exactly")
		print("  ✓ SegmentType %s verified: %d vertices match perfectly" % [s_type, seg.collision_polygon.polygon.size()])
	
	var entry_pt := seg.get_entry_point()
	var exit_pt := seg.get_exit_point()
	assert(exit_pt.x > entry_pt.x, "Exit point x must be greater than entry point x")
	seg.queue_free()
	print("✓ TerrainSegment verified")
	
	# Test 2: TerrainGenerator seamless progression and recycling
	print("-> Testing TerrainGenerator procedural generation and culling...")
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
	print("  ✓ Active segments generated: %d" % gen.active_segments.size())
	
	# Verify seamless connection between consecutive segments
	for i in range(gen.active_segments.size() - 1):
		var curr_seg := gen.active_segments[i]
		var next_seg := gen.active_segments[i + 1]
		var curr_exit := curr_seg.global_position + curr_seg.get_exit_point()
		var next_entry := next_seg.global_position + next_seg.get_entry_point()
		var gap := curr_exit.distance_to(next_entry)
		assert(gap < 0.01, "Segments must join with 0 gap (gap was %f)" % gap)
	print("  ✓ Seamless joins verified: 0 gap between adjacent segment collisions")
	
	# Advance target forward by 3000px and verify new segments generate and old ones cull
	dummy_target.position.x = 3500.0
	gen._process(0.016)
	await process_frame
	
	var front_x := gen.active_segments[gen.active_segments.size() - 1].global_position.x
	assert(front_x >= 3500.0, "Generator must extend terrain ahead of moving target")
	print("  ✓ Endless terrain progression verified: leading segment extended to x = %f" % front_x)
	
	dummy_target.queue_free()
	gen.clear_terrain()
	gen.queue_free()
	print("✓ TerrainGenerator verified")
	
	# Test 3: ParallaxEnvironment structure and movement
	print("-> Testing ParallaxEnvironment layers...")
	var parallax_packed: PackedScene = load("res://scenes/environment/ParallaxEnvironment.tscn")
	assert(parallax_packed != null, "ParallaxEnvironment.tscn must load successfully")
	var parallax_env: ParallaxEnvironment = parallax_packed.instantiate()
	root.add_child(parallax_env)
	
	var sky_layer = parallax_env.get_node_or_null("SkyLayer")
	var distant_clouds = parallax_env.get_node_or_null("DistantCloudsLayer")
	var distant_mountains = parallax_env.get_node_or_null("DistantMountainsLayer")
	var mid_hills = parallax_env.get_node_or_null("MidHillsLayer")
	var near_hills = parallax_env.get_node_or_null("NearHillsLayer")
	
	assert(sky_layer != null, "SkyLayer must exist")
	assert(distant_clouds != null, "DistantCloudsLayer must exist")
	assert(distant_mountains != null, "DistantMountainsLayer must exist")
	assert(mid_hills != null, "MidHillsLayer must exist")
	assert(near_hills != null, "NearHillsLayer must exist")
	
	assert(distant_mountains.motion_scale.x < mid_hills.motion_scale.x, "Distant mountains must move slower than mid hills")
	assert(mid_hills.motion_scale.x < near_hills.motion_scale.x, "Mid hills must move slower than near hills")
	print("  ✓ Parallax relative depth scales verified: distant=%f < mid=%f < near=%f" % [
		distant_mountains.motion_scale.x,
		mid_hills.motion_scale.x,
		near_hills.motion_scale.x
	])
	
	parallax_env.queue_free()
	print("✓ ParallaxEnvironment verified")
	
	# Test 4: HUDController and signal integration
	print("-> Testing HUDController updates and notifications...")
	var hud_packed: PackedScene = load("res://scenes/ui/HUD.tscn")
	assert(hud_packed != null, "HUD.tscn must load successfully")
	var hud: HUDController = hud_packed.instantiate()
	root.add_child(hud)
	
	var gm := GameManager.new()
	root.add_child(gm)
	hud.bind_game_manager(gm)
	
	# Distance update
	gm.start_run()
	gm.update_distance(158.4)
	assert(hud.distance_label.text == "158 m", "Distance label must format distance as integer meters")
	print("  ✓ HUD Distance metric: %s" % hud.distance_label.text)
	
	# Fuel update & Low fuel trigger
	gm.fuel_updated.emit(15.0, 100.0)
	assert(hud.fuel_bar.value == 15.0, "Fuel bar value must match fuel update")
	assert(hud._is_low_fuel == true, "Low fuel warning flag must activate below 20%")
	print("  ✓ HUD Low fuel warning state correctly triggered")
	
	# Coins update
	gm.add_coins(25)
	assert(hud.coins_label.text == "25", "Coins label must display coins count")
	print("  ✓ HUD Coins display: %s" % hud.coins_label.text)
	
	# Pause banner
	gm.pause_run(true)
	assert(hud.pause_banner.visible == true, "Pause banner must appear on pause")
	gm.pause_run(false)
	assert(hud.pause_banner.visible == false, "Pause banner must disappear on resume")
	print("  ✓ HUD Pause banner toggle verified")
	
	# Crash notification
	hud._on_vehicle_crashed()
	assert(hud.message_banner.visible == true, "Message banner must appear on crash")
	assert("CRASHED" in hud.message_title_label.text, "Crash title must be displayed")
	print("  ✓ HUD Crash banner verified: %s" % hud.message_title_label.text)
	
	# Run finished notification
	gm.finish_run("complete")
	assert(hud.message_banner.visible == true, "Message banner must appear on run finished")
	assert("FINISHED" in hud.message_title_label.text, "Finished title must be displayed")
	print("  ✓ HUD Run finished banner verified: %s" % hud.message_title_label.text)
	
	hud.queue_free()
	gm.queue_free()
	print("✓ HUDController verified")
	
	# Test 5: Full Vehicle Driving on Procedural Track
	print("-> Testing Vehicle physics driving on ProceduralTrack scene...")
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
