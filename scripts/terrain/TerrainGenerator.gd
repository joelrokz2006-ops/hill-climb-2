class_name TerrainGenerator
extends Node2D

## TerrainGenerator: Procedural and segmented endless terrain manager.
## Spawns, aligns, recycles, and pools TerrainSegment instances ahead of and behind a target node.
## Intelligently distributes collectible Coin trails and Fuel canisters along terrain curves.
## Guarantees continuous collision geometry with zero gaps between adjacent segments.

signal segment_spawned(segment: TerrainSegment)
signal segment_despawned(segment: TerrainSegment)

@export var terrain_segment_scene: PackedScene = preload("res://scenes/terrain/TerrainSegment.tscn")
@export var coin_scene: PackedScene = preload("res://scenes/pickups/Coin.tscn")
@export var fuel_scene: PackedScene = preload("res://scenes/pickups/FuelPickup.tscn")
@export var target: Node2D
@export var auto_find_target: bool = true

@export_group("Generation Limits")
## How far ahead of the target terrain should be generated (in pixels)
@export var generate_ahead_distance: float = 3000.0
## How far behind the target terrain should be removed (in pixels)
@export var despawn_behind_distance: float = 2000.0
## Default length of each generated terrain segment
@export var default_segment_length: float = 1000.0
## Starting origin position for terrain generation
@export var initial_spawn_point: Vector2 = Vector2(-400.0, 420.0)

@export_group("Progression & Variety")
## Base amplitude for hills and valleys
@export var base_amplitude: float = 70.0
## Maximum climb or descent height delta per segment
@export var max_height_delta: float = 120.0
## Difficulty increase rate per 100 meters
@export var difficulty_growth: float = 0.15

@export_group("Pickups Distribution")
@export var enable_pickups: bool = true
## Spacing between consecutive fuel canister spawns (in pixels, ~130 meters)
@export var fuel_interval_distance: float = 13000.0
## Probability of generating coins on a procedural segment
@export var coin_spawn_chance: float = 0.75

var active_segments: Array[TerrainSegment] = []
var segment_pool: Array[TerrainSegment] = []
var next_attach_point: Vector2 = Vector2.ZERO
var current_difficulty: float = 1.0
var segment_counter: int = 0
var distance_since_last_fuel: float = 0.0
var total_coins_spawned: int = 0
var total_fuel_spawned: int = 0
var rng := RandomNumberGenerator.new()

# Track all active pickups spawned across segments for clean recycling
var _spawned_pickups: Array[Node2D] = []

func _ready() -> void:
	rng.randomize()
	next_attach_point = initial_spawn_point
	
	if auto_find_target and not is_instance_valid(target):
		_find_target()
	
	# Hook into GameManager restart signal if available in scene tree
	_connect_game_manager_signals()
	
	# Pre-seed initial track with safe starting segment
	_generate_initial_track()

func _connect_game_manager_signals() -> void:
	var gm := get_tree().root.find_child("GameManager", true, false)
	if is_instance_valid(gm) and gm.has_signal("run_restarted"):
		if not gm.run_restarted.is_connected(_on_game_manager_restarted):
			gm.run_restarted.connect(_on_game_manager_restarted)

func _on_game_manager_restarted() -> void:
	reset_generator(initial_spawn_point)

func _find_target() -> void:
	# Attempt to locate Vehicle in scene tree
	var vehicle_node = get_tree().get_first_node_in_group("vehicle")
	if is_instance_valid(vehicle_node) and vehicle_node is Node2D:
		target = vehicle_node
		return
	
	# Look for node named "Vehicle" under parent or siblings
	var parent_node := get_parent()
	if parent_node:
		var candidate = parent_node.find_child("Vehicle", true, false)
		if is_instance_valid(candidate) and candidate is Node2D:
			target = candidate
			return
		
		# Alternatively find Camera2D
		var cam = parent_node.find_child("FollowCamera", true, false)
		if is_instance_valid(cam) and cam is Node2D:
			target = cam
			return

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		if auto_find_target:
			_find_target()
		return
	
	var target_x: float = target.global_position.x
	_update_generation(target_x)
	_update_culling(target_x)

## Generates flat safety stretch followed by introductory gentle hills
func _generate_initial_track() -> void:
	clear_terrain()
	next_attach_point = initial_spawn_point
	distance_since_last_fuel = fuel_interval_distance * 0.4 # Pre-charge fuel countdown
	
	# Segment 0: Flat runway at spawn (e.g. from -400 to 600)
	var flat_seg := _create_segment(TerrainSegment.SegmentType.FLAT, 1000.0, 0.0, 0.0, 0.0)
	_attach_segment(flat_seg, false)
	
	# Segment 1: Gentle introductory hill with starter coins
	var intro_seg := _create_segment(TerrainSegment.SegmentType.GENTLE_HILLS, 1000.0, 0.0, -20.0, 45.0)
	_attach_segment(intro_seg, true)
	
	# Segment 2: Rolling starter wave with first fuel pickup
	var wave_seg := _create_segment(TerrainSegment.SegmentType.ROLLING_WAVES, 1000.0, 0.0, 20.0, 55.0)
	_attach_segment(wave_seg, true)

func _update_generation(target_x: float) -> void:
	# Keep generating until the end of the track is far enough ahead of the target
	while next_attach_point.x < target_x + generate_ahead_distance:
		var seg := _generate_next_procedural_segment()
		_attach_segment(seg, enable_pickups)

func _update_culling(target_x: float) -> void:
	var cull_threshold := target_x - despawn_behind_distance
	while not active_segments.is_empty():
		var first_seg := active_segments[0]
		var exit_global_x := first_seg.global_position.x + first_seg.segment_length
		if exit_global_x < cull_threshold:
			active_segments.remove_at(0)
			segment_despawned.emit(first_seg)
			
			# Recycle pickups attached to this segment
			_cull_pickups_for_segment(first_seg)
			
			# Pool segment instead of freeing to avoid GC spikes
			first_seg.visible = false
			segment_pool.append(first_seg)
		else:
			break

func _cull_pickups_for_segment(seg: TerrainSegment) -> void:
	var remaining: Array[Node2D] = []
	for p in _spawned_pickups:
		if is_instance_valid(p):
			if p.get_parent() == seg or seg.is_ancestor_of(p):
				p.queue_free()
			else:
				remaining.append(p)
	_spawned_pickups = remaining

func _generate_next_procedural_segment() -> TerrainSegment:
	segment_counter += 1
	var progress_m := maxf(0.0, (next_attach_point.x - initial_spawn_point.x) / 100.0)
	current_difficulty = 1.0 + (progress_m / 250.0) * difficulty_growth
	current_difficulty = clampf(current_difficulty, 1.0, 3.0)
	
	var seg_length := default_segment_length * rng.randf_range(0.9, 1.25)
	var amp := base_amplitude * clampf(current_difficulty, 1.0, 2.4) * rng.randf_range(0.85, 1.25)
	
	# Weighted random segment type adapting to distance difficulty
	var seg_type := _select_segment_type(current_difficulty)
	
	# Height delta with spring bias towards comfortable baseline y = 380
	var height_change := rng.randf_range(-max_height_delta, max_height_delta)
	var center_bias := (380.0 - next_attach_point.y) * 0.35
	height_change = clampf(height_change + center_bias, -max_height_delta, max_height_delta)
	
	# Safety clamp bounds
	var predicted_end_y := next_attach_point.y + height_change
	if predicted_end_y < 160.0:
		height_change = absf(height_change) + 20.0
	elif predicted_end_y > 540.0:
		height_change = -absf(height_change) - 20.0
	
	return _create_segment(seg_type, seg_length, 0.0, height_change, amp)

func _select_segment_type(diff: float) -> TerrainSegment.SegmentType:
	var roll := rng.randf()
	if diff < 1.3:
		# Early / Intro stage: gentle, rolling hills
		if roll < 0.40:
			return TerrainSegment.SegmentType.GENTLE_HILLS
		elif roll < 0.70:
			return TerrainSegment.SegmentType.ROLLING_WAVES
		elif roll < 0.88:
			return TerrainSegment.SegmentType.VALLEY_DIP
		else:
			return TerrainSegment.SegmentType.JUMP_RAMP
	elif diff < 2.0:
		# Mid stage: introduces climbs, ramps, and washboards
		if roll < 0.22:
			return TerrainSegment.SegmentType.GENTLE_HILLS
		elif roll < 0.42:
			return TerrainSegment.SegmentType.ROLLING_WAVES
		elif roll < 0.60:
			return TerrainSegment.SegmentType.STEEP_CLIMB
		elif roll < 0.75:
			return TerrainSegment.SegmentType.VALLEY_DIP
		elif roll < 0.88:
			return TerrainSegment.SegmentType.JUMP_RAMP
		else:
			return TerrainSegment.SegmentType.BUMPY_WASHBOARD
	else:
		# Advanced / Pro stage: plateau drops, double crests, steeper challenges
		if roll < 0.15:
			return TerrainSegment.SegmentType.GENTLE_HILLS
		elif roll < 0.30:
			return TerrainSegment.SegmentType.STEEP_CLIMB
		elif roll < 0.45:
			return TerrainSegment.SegmentType.PLATEAU_DROP
		elif roll < 0.60:
			return TerrainSegment.SegmentType.DOUBLE_CREST
		elif roll < 0.75:
			return TerrainSegment.SegmentType.JUMP_RAMP
		elif roll < 0.88:
			return TerrainSegment.SegmentType.BUMPY_WASHBOARD
		else:
			return TerrainSegment.SegmentType.VALLEY_DIP

func _create_segment(
	type: TerrainSegment.SegmentType,
	length_val: float,
	start_h: float,
	end_h: float,
	amp: float
) -> TerrainSegment:
	var seg: TerrainSegment
	
	# Recycle from pool if available
	if not segment_pool.is_empty():
		seg = segment_pool.pop_back()
		seg.visible = true
	elif terrain_segment_scene:
		seg = terrain_segment_scene.instantiate() as TerrainSegment
	else:
		seg = TerrainSegment.new()
	
	seg.segment_type = type
	seg.segment_length = length_val
	seg.start_height = start_h
	seg.end_height = end_h
	seg.amplitude = amp
	seg.samples_count = clampi(int(length_val / 28.0), 16, 72)
	seg.rebuild_segment()
	return seg

func _attach_segment(seg: TerrainSegment, allow_pickups: bool = true) -> void:
	if seg.get_parent() != self:
		add_child(seg)
	
	seg.global_position = next_attach_point - seg.get_entry_point()
	active_segments.append(seg)
	segment_spawned.emit(seg)
	
	# Spawn collectibles on this segment if requested
	if allow_pickups and enable_pickups:
		_populate_segment_pickups(seg)
	
	# Update next attachment point to match segment's exit point
	var exit_local := seg.get_exit_point()
	next_attach_point = seg.global_position + exit_local
	distance_since_last_fuel += seg.segment_length

func _populate_segment_pickups(seg: TerrainSegment) -> void:
	# 1. Fuel canister placement
	if distance_since_last_fuel >= fuel_interval_distance and fuel_scene:
		distance_since_last_fuel = 0.0
		_spawn_fuel_on_segment(seg, seg.segment_length * 0.5)
		return # Avoid overcrowding fuel segment with too many coins
	
	# 2. Coin patterns placement
	if rng.randf() <= coin_spawn_chance and coin_scene:
		_spawn_coins_on_segment(seg)

func _spawn_fuel_on_segment(seg: TerrainSegment, local_x: float) -> void:
	var surface_info := seg.get_surface_point_and_normal_at(local_x)
	var fuel_inst := fuel_scene.instantiate() as Node2D
	seg.add_child(fuel_inst)
	# Position strictly above surface normal (+38px clearance)
	fuel_inst.position = surface_info.point + (surface_info.normal * 38.0)
	fuel_inst.add_to_group("pickups")
	_spawned_pickups.append(fuel_inst)
	total_fuel_spawned += 1

func _spawn_coins_on_segment(seg: TerrainSegment) -> void:
	var seg_type := seg.segment_type
	var num_coins := rng.randi_range(3, 5)
	total_coins_spawned += num_coins
	
	match seg_type:
		TerrainSegment.SegmentType.JUMP_RAMP:
			# Arc of coins soaring off the crest lip
			var start_x := seg.segment_length * 0.55
			var span := seg.segment_length * 0.35
			for i in range(num_coins):
				var t := float(i) / float(maxi(1, num_coins - 1))
				var cx := start_x + (t * span)
				var surface_info := seg.get_surface_point_and_normal_at(cx)
				var arc_height := sin(t * PI) * 55.0
				var coin_inst := coin_scene.instantiate() as Node2D
				seg.add_child(coin_inst)
				coin_inst.position = surface_info.point + (surface_info.normal * (36.0 + arc_height))
				coin_inst.add_to_group("pickups")
				_spawned_pickups.append(coin_inst)
				
		TerrainSegment.SegmentType.DOUBLE_CREST, TerrainSegment.SegmentType.PLATEAU_DROP:
			# Evenly spaced contour trail across the elevated feature
			var start_x := seg.segment_length * 0.25
			var span := seg.segment_length * 0.5
			for i in range(num_coins):
				var t := float(i) / float(maxi(1, num_coins - 1))
				var cx := start_x + (t * span)
				var surface_info := seg.get_surface_point_and_normal_at(cx)
				var coin_inst := coin_scene.instantiate() as Node2D
				seg.add_child(coin_inst)
				coin_inst.position = surface_info.point + (surface_info.normal * 34.0)
				coin_inst.add_to_group("pickups")
				_spawned_pickups.append(coin_inst)
				
		_:
			# Standard contour trail following hill / slope
			var start_x := seg.segment_length * 0.3
			var span := seg.segment_length * 0.4
			for i in range(num_coins):
				var t := float(i) / float(maxi(1, num_coins - 1))
				var cx := start_x + (t * span)
				var surface_info := seg.get_surface_point_and_normal_at(cx)
				var coin_inst := coin_scene.instantiate() as Node2D
				seg.add_child(coin_inst)
				coin_inst.position = surface_info.point + (surface_info.normal * 32.0)
				coin_inst.add_to_group("pickups")
				_spawned_pickups.append(coin_inst)

## Clears all active segments and resets generation state
func clear_terrain() -> void:
	for p in _spawned_pickups:
		if is_instance_valid(p):
			p.queue_free()
	_spawned_pickups.clear()
	
	for seg in active_segments:
		if is_instance_valid(seg):
			seg.queue_free()
	active_segments.clear()
	
	for seg in segment_pool:
		if is_instance_valid(seg):
			seg.queue_free()
	segment_pool.clear()
	
	segment_counter = 0
	current_difficulty = 1.0
	distance_since_last_fuel = 0.0
	total_coins_spawned = 0
	total_fuel_spawned = 0
	next_attach_point = initial_spawn_point

## Resets generator to initial condition for a new run
func reset_generator(at_origin: Vector2 = Vector2(-400.0, 420.0)) -> void:
	initial_spawn_point = at_origin
	_generate_initial_track()
