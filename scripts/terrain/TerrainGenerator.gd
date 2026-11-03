class_name TerrainGenerator
extends Node2D

## TerrainGenerator: Procedural and segmented endless terrain manager.
## Spawns, aligns, and recycles TerrainSegment instances ahead of and behind a target node.
## Guarantees continuous collision geometry with zero gaps between adjacent segments.

signal segment_spawned(segment: TerrainSegment)
signal segment_despawned(segment: TerrainSegment)

@export var terrain_segment_scene: PackedScene = preload("res://scenes/terrain/TerrainSegment.tscn")
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
## Difficulty increase rate per kilometer (100,000 px)
@export var difficulty_growth: float = 0.25

var active_segments: Array[TerrainSegment] = []
var next_attach_point: Vector2 = Vector2.ZERO
var current_difficulty: float = 1.0
var segment_counter: int = 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	next_attach_point = initial_spawn_point
	
	if auto_find_target and not is_instance_valid(target):
		_find_target()
	
	# Pre-seed initial track with safe starting segment
	_generate_initial_track()

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

## Generates flat safety stretch followed by first gentle hills
func _generate_initial_track() -> void:
	clear_terrain()
	next_attach_point = initial_spawn_point
	
	# Segment 0: Flat runway at spawn (e.g. from -400 to 600)
	var flat_seg := _create_segment(TerrainSegment.SegmentType.FLAT, 1000.0, 0.0, 0.0, 0.0)
	_attach_segment(flat_seg)
	
	# Segment 1: Gentle introductory hill
	var intro_seg := _create_segment(TerrainSegment.SegmentType.GENTLE_HILLS, 1000.0, 0.0, -30.0, 50.0)
	_attach_segment(intro_seg)
	
	# Segment 2: Rolling starter wave
	var wave_seg := _create_segment(TerrainSegment.SegmentType.ROLLING_WAVES, 1000.0, 0.0, 20.0, 60.0)
	_attach_segment(wave_seg)

func _update_generation(target_x: float) -> void:
	# Keep generating until the end of the track is far enough ahead of the target
	while next_attach_point.x < target_x + generate_ahead_distance:
		var seg := _generate_next_procedural_segment()
		_attach_segment(seg)

func _update_culling(target_x: float) -> void:
	var cull_threshold := target_x - despawn_behind_distance
	while not active_segments.is_empty():
		var first_seg := active_segments[0]
		var exit_global_x := first_seg.global_position.x + first_seg.segment_length
		if exit_global_x < cull_threshold:
			active_segments.remove_at(0)
			segment_despawned.emit(first_seg)
			first_seg.queue_free()
		else:
			break

func _generate_next_procedural_segment() -> TerrainSegment:
	segment_counter += 1
	var progress_km := maxf(0.0, next_attach_point.x / 100000.0)
	current_difficulty = 1.0 + (progress_km * difficulty_growth)
	
	var seg_length := default_segment_length * rng.randf_range(0.9, 1.2)
	var amp := base_amplitude * clampf(current_difficulty, 1.0, 2.2) * rng.randf_range(0.85, 1.25)
	
	# Weighted random segment type
	var seg_type := _select_segment_type()
	
	# Target height change for end of segment (keep within world bounds)
	var height_change := rng.randf_range(-max_height_delta, max_height_delta)
	
	# Keep terrain generally between y = 100 and y = 600
	var predicted_end_y := next_attach_point.y + height_change
	if predicted_end_y < 120.0:
		height_change = absf(height_change) # Force slope down (increasing y)
	elif predicted_end_y > 550.0:
		height_change = -absf(height_change) # Force slope up (decreasing y)
	
	return _create_segment(seg_type, seg_length, 0.0, height_change, amp)

func _select_segment_type() -> TerrainSegment.SegmentType:
	var roll := rng.randf()
	if roll < 0.25:
		return TerrainSegment.SegmentType.GENTLE_HILLS
	elif roll < 0.50:
		return TerrainSegment.SegmentType.ROLLING_WAVES
	elif roll < 0.70:
		return TerrainSegment.SegmentType.VALLEY_DIP
	elif roll < 0.88:
		return TerrainSegment.SegmentType.STEEP_CLIMB
	else:
		return TerrainSegment.SegmentType.JUMP_RAMP

func _create_segment(
	type: TerrainSegment.SegmentType,
	length_val: float,
	start_h: float,
	end_h: float,
	amp: float
) -> TerrainSegment:
	var seg: TerrainSegment
	if terrain_segment_scene:
		seg = terrain_segment_scene.instantiate() as TerrainSegment
	else:
		seg = TerrainSegment.new()
	
	seg.segment_type = type
	seg.segment_length = length_val
	seg.start_height = start_h
	seg.end_height = end_h
	seg.amplitude = amp
	seg.samples_count = clampi(int(length_val / 30.0), 16, 64)
	seg.rebuild_segment()
	return seg

func _attach_segment(seg: TerrainSegment) -> void:
	add_child(seg)
	seg.global_position = next_attach_point - seg.get_entry_point()
	active_segments.append(seg)
	segment_spawned.emit(seg)
	
	# Update next attachment point to match segment's exit point
	var exit_local := seg.get_exit_point()
	next_attach_point = seg.global_position + exit_local

## Clears all active segments and resets generation state
func clear_terrain() -> void:
	for seg in active_segments:
		if is_instance_valid(seg):
			seg.queue_free()
	active_segments.clear()
	segment_counter = 0
	current_difficulty = 1.0
	next_attach_point = initial_spawn_point

## Resets generator to initial condition for a new run
func reset_generator(at_origin: Vector2 = Vector2(-400.0, 420.0)) -> void:
	initial_spawn_point = at_origin
	_generate_initial_track()
