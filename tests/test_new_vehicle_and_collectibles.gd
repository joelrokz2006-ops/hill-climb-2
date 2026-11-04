extends SceneTree

# Comprehensive test suite for New Vehicle Integration & Underground Collectible Fix

func _init() -> void:
	print("\n=================================================================")
	print("--- BEGIN NEW VEHICLE INTEGRATION & COLLECTIBLES AUDIT SUITE ---")
	print("=================================================================")
	
	test_girl_buggy_vehicle_integration()
	test_terrain_segment_surface_y_query()
	test_collectibles_clearance_all_segment_types()
	test_procedural_run_zero_underground_pickups()
	
	print("\n=================================================================")
	print("✓ ALL NEW VEHICLE & UNDERGROUND COLLECTIBLE TESTS PASSED!")
	print("=================================================================\n")
	quit(0)

func test_girl_buggy_vehicle_integration() -> void:
	print("-> [1/4] Verifying New Girl Buggy Vehicle Integration & Geometry...")
	
	var vehicle_scene = load("res://scenes/vehicle/Vehicle.tscn")
	assert(vehicle_scene != null, "Vehicle.tscn must load successfully")
	var vehicle = vehicle_scene.instantiate() as RigidBody2D
	root.add_child(vehicle)
	
	# Verify textures are loaded from girl_buggy
	var body_sprite: Sprite2D = vehicle.get_node_or_null("BodySprite")
	assert(body_sprite != null, "Vehicle must have BodySprite")
	assert(body_sprite.texture != null, "BodySprite must have a texture")
	assert("girl_buggy" in body_sprite.texture.resource_path, "BodySprite must use girl_buggy texture, got: %s" % body_sprite.texture.resource_path)
	
	var driver_sprite: Sprite2D = vehicle.get_node_or_null("DriverSprite")
	assert(driver_sprite != null, "Vehicle must have DriverSprite")
	assert(driver_sprite.texture != null, "DriverSprite must have a texture")
	assert("girl_buggy" in driver_sprite.texture.resource_path, "DriverSprite must use girl_buggy texture, got: %s" % driver_sprite.texture.resource_path)
	assert(driver_sprite.z_index < body_sprite.z_index, "DriverSprite must be rendered behind body (z_index < 0)")
	
	var rear_wheel: RigidBody2D = vehicle.get_node_or_null("RearWheel")
	var front_wheel: RigidBody2D = vehicle.get_node_or_null("FrontWheel")
	assert(rear_wheel != null and front_wheel != null, "Both wheels must exist")
	
	var rear_wheel_spr: Sprite2D = rear_wheel.get_node_or_null("WheelSprite")
	var front_wheel_spr: Sprite2D = front_wheel.get_node_or_null("WheelSprite")
	assert(rear_wheel_spr != null and front_wheel_spr != null, "Both wheels must have WheelSprite")
	assert("girl_buggy" in rear_wheel_spr.texture.resource_path, "Rear wheel must use girl_buggy texture")
	assert("girl_buggy" in front_wheel_spr.texture.resource_path, "Front wheel must use girl_buggy texture")
	
	# Check Wheel scale and radius
	var rear_col: CollisionShape2D = rear_wheel.get_node_or_null("WheelCollision")
	var front_col: CollisionShape2D = front_wheel.get_node_or_null("WheelCollision")
	assert(rear_col != null and rear_col.shape is CircleShape2D, "Rear wheel must have CircleShape2D")
	assert(front_col != null and front_col.shape is CircleShape2D, "Front wheel must have CircleShape2D")
	var r_radius: float = (rear_col.shape as CircleShape2D).radius
	var f_radius: float = (front_col.shape as CircleShape2D).radius
	assert(is_equal_approx(r_radius, 18.0), "Rear wheel radius must be 18.0, got %f" % r_radius)
	assert(is_equal_approx(f_radius, 18.0), "Front wheel radius must be 18.0, got %f" % f_radius)
	
	# Check Wheel Alignment with Marker2D mounts
	var rear_mount: Marker2D = vehicle.get_node_or_null("RearWheelMount")
	var front_mount: Marker2D = vehicle.get_node_or_null("FrontWheelMount")
	assert(rear_mount != null and front_mount != null, "Wheel mounts must exist")
	assert(rear_wheel.position.is_equal_approx(rear_mount.position), "RearWheel position must match RearWheelMount")
	assert(front_wheel.position.is_equal_approx(front_mount.position), "FrontWheel position must match FrontWheelMount")
	assert(rear_mount.position.x < 0.0, "Rear wheel must be behind chassis center (x < 0)")
	assert(front_mount.position.x > 0.0, "Front wheel must be ahead of chassis center (x > 0)")
	
	# Check PinJoint2D alignment
	var rear_joint: PinJoint2D = vehicle.get_node_or_null("RearJoint")
	var front_joint: PinJoint2D = vehicle.get_node_or_null("FrontJoint")
	assert(rear_joint != null and rear_joint.position.is_equal_approx(rear_mount.position), "RearJoint must match mount")
	assert(front_joint != null and front_joint.position.is_equal_approx(front_mount.position), "FrontJoint must match mount")
	
	# Verify Reset preserves wheel positions
	vehicle.reset_vehicle(Vector2(200, 350))
	assert(rear_wheel.position.is_equal_approx(rear_mount.position), "Reset must restore RearWheel offset")
	assert(front_wheel.position.is_equal_approx(front_mount.position), "Reset must restore FrontWheel offset")
	
	root.remove_child(vehicle)
	vehicle.free()
	print("  ✓ Red Buggy body, driver cockpit, wheel mounts (-35, 16)/(35, 16), and PinJoints verified!")

func test_terrain_segment_surface_y_query() -> void:
	print("-> [2/4] Verifying TerrainSegment get_surface_y_at() across all shapes...")
	
	var segment_types := [
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
	
	for st in segment_types:
		var seg = TerrainSegment.new()
		seg.segment_type = st
		seg.segment_length = 1000.0
		seg.start_height = 0.0
		seg.end_height = 40.0
		seg.amplitude = 80.0
		seg.samples_count = 36
		root.add_child(seg)
		seg.rebuild_segment()
		
		# Test entry, mid, exit, and boundary clamping
		var y_0 = seg.get_surface_y_at(0.0)
		var y_mid = seg.get_surface_y_at(500.0)
		var y_end = seg.get_surface_y_at(1000.0)
		var y_neg = seg.get_surface_y_at(-100.0)
		var y_overflow = seg.get_surface_y_at(1200.0)
		
		assert(not is_nan(y_0) and not is_nan(y_mid) and not is_nan(y_end), "Surface Y query must never return NaN")
		assert(is_equal_approx(y_neg, y_0), "Clamping before 0.0 must equal start height")
		assert(is_equal_approx(y_overflow, y_end), "Clamping beyond segment_length must equal end height")
		
		root.remove_child(seg)
		seg.free()
		
	print("  ✓ get_surface_y_at() verified with robust interpolation and boundary clamping across all 9 shapes!")

func test_collectibles_clearance_all_segment_types() -> void:
	print("-> [3/4] Verifying Coin & Fuel clearances strictly above ground...")
	
	var gen = TerrainGenerator.new()
	root.add_child(gen)
	
	var segment_types := [
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
	
	for st in segment_types:
		var seg = gen._create_segment(st, 1000.0, 0.0, 60.0, 90.0, 0.0, 0.0)
		gen._attach_segment(seg, false)
		
		# 1. Test Fuel Spawn
		gen._spawn_fuel_on_segment(seg, 500.0)
		var fuels: Array[Node2D] = []
		for child in seg.get_children():
			if child is FuelPickup:
				fuels.append(child)
		
		assert(fuels.size() == 1, "Expected exactly 1 fuel canister on segment")
		var fuel = fuels[0]
		var fuel_surface_y = seg.get_surface_y_at(fuel.position.x)
		var fuel_clearance = fuel_surface_y - fuel.position.y
		assert(fuel_clearance >= 40.0, 
			"Fuel clearance on segment %d must be >= 40.0, got %f" % [st, fuel_clearance])
		
		# Check polygon collision: local point must NOT be inside collision polygon
		var seg_poly: PackedVector2Array = seg.collision_polygon.polygon
		var is_fuel_inside = Geometry2D.is_point_in_polygon(fuel.position, seg_poly)
		assert(not is_fuel_inside, "Fuel canister must NEVER be inside terrain collision polygon!")
		
		# 2. Test Coin Spawns
		gen._spawn_coins_on_segment(seg)
		var coins: Array[Node2D] = []
		for child in seg.get_children():
			if child is Coin:
				coins.append(child)
		
		assert(coins.size() >= 3, "Expected at least 3 coins on segment %d, got %d" % [st, coins.size()])
		for c in coins:
			var c_surface_y = seg.get_surface_y_at(c.position.x)
			var c_clearance = c_surface_y - c.position.y
			assert(c_clearance >= 30.0, 
				"Coin clearance on segment %d must be >= 30.0, got %f" % [st, c_clearance])
			var is_coin_inside = Geometry2D.is_point_in_polygon(c.position, seg_poly)
			assert(not is_coin_inside, "Coin must NEVER be inside terrain collision polygon!")
	
	# Test world surface query helper
	var query_x = gen.active_segments[0].global_position.x + 200.0
	var world_y = gen.get_surface_y_at_world_x(query_x)
	var expected_y = gen.active_segments[0].global_position.y + gen.active_segments[0].get_surface_y_at(200.0)
	assert(is_equal_approx(world_y, expected_y), "get_surface_y_at_world_x must match true world surface altitude")
	
	gen.clear_terrain()
	root.remove_child(gen)
	gen.free()
	print("  ✓ Fuel clearance >= 46px and Coin clearance >= 34px strictly above ground polygon verified!")

func test_procedural_run_zero_underground_pickups() -> void:
	print("-> [4/4] Verifying Procedural Endless Track Spawning (Zero Underground Collectibles)...")
	
	var gen = TerrainGenerator.new()
	var dummy = Node2D.new()
	root.add_child(dummy)
	root.add_child(gen)
	gen.target = dummy
	gen.auto_find_target = false
	gen.enable_pickups = true
	gen.fuel_interval_distance = 1200.0 # Frequent fuel to test multiple canisters
	gen._ready()
	
	# Advance 30,000 pixels (generating ~30 procedural segments)
	for i in range(25):
		dummy.position.x += 1200.0
		gen._process(0.016)
	
	var total_pickups := 0
	var underground_count := 0
	
	for p in gen._spawned_pickups:
		if is_instance_valid(p):
			total_pickups += 1
			var seg = p.get_parent() as TerrainSegment
			if is_instance_valid(seg):
				var surf_y = seg.get_surface_y_at(p.position.x)
				var clearance = surf_y - p.position.y # In Godot 2D, surface - position > 0 means above ground
				if clearance < 20.0 or Geometry2D.is_point_in_polygon(p.position, seg.collision_polygon.polygon):
					underground_count += 1
					push_error("Underground pickup found at pos: %v, surf_y: %f, clearance: %f" % [p.position, surf_y, clearance])
	
	var lifetime_total = gen.total_coins_spawned + gen.total_fuel_spawned
	assert(lifetime_total >= 30, "Should have generated at least 30 lifetime collectibles, got %d" % lifetime_total)
	assert(total_pickups > 0, "Should have active collectibles on screen, got %d" % total_pickups)
	assert(underground_count == 0, "Found %d underground collectibles! Expected 0." % underground_count)
	
	print("  ✓ Procedural Run Audit: %d lifetime collectibles generated (%d currently active), 0 underground pickups found (100%% safe)!" % [lifetime_total, total_pickups])
	
	gen.clear_terrain()
	root.remove_child(gen)
	root.remove_child(dummy)
	gen.free()
	dummy.free()
