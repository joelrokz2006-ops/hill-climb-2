@tool
class_name TerrainSegment
extends StaticBody2D

## TerrainSegment: Reusable terrain slice with synchronized visual and collision geometry.
## Provides multiple terrain shapes (flat, gentle hills, steep climb, valley dip, jump ramp)
## with smooth continuous transitions between consecutive segments.

enum SegmentType {
	FLAT,
	GENTLE_HILLS,
	STEEP_CLIMB,
	VALLEY_DIP,
	JUMP_RAMP,
	ROLLING_WAVES,
	PLATEAU_DROP,
	BUMPY_WASHBOARD,
	DOUBLE_CREST,
	CUSTOM
}

@export var segment_type: SegmentType = SegmentType.GENTLE_HILLS:
	set(val):
		segment_type = val
		if Engine.is_editor_hint():
			rebuild_segment()

@export var segment_length: float = 1200.0:
	set(val):
		segment_length = maxf(200.0, val)
		if Engine.is_editor_hint():
			rebuild_segment()

@export var start_height: float = 0.0:
	set(val):
		start_height = val
		if Engine.is_editor_hint():
			rebuild_segment()

@export var end_height: float = 0.0:
	set(val):
		end_height = val
		if Engine.is_editor_hint():
			rebuild_segment()

@export var start_slope: float = 0.0:
	set(val):
		start_slope = val
		if Engine.is_editor_hint():
			rebuild_segment()

@export var end_slope: float = 0.0:
	set(val):
		end_slope = val
		if Engine.is_editor_hint():
			rebuild_segment()

@export var amplitude: float = 80.0:
	set(val):
		amplitude = val
		if Engine.is_editor_hint():
			rebuild_segment()

@export var ground_depth: float = 900.0:
	set(val):
		ground_depth = maxf(400.0, val)
		if Engine.is_editor_hint():
			rebuild_segment()

@export var samples_count: int = 36:
	set(val):
		samples_count = clampi(val, 8, 120)
		if Engine.is_editor_hint():
			rebuild_segment()

@export_group("Visual Styling")
@export var ground_color: Color = Color(0.28, 0.19, 0.13, 1.0)
@export var subsoil_color: Color = Color(0.18, 0.12, 0.08, 1.0)
@export var grass_color: Color = Color(0.30, 0.68, 0.22, 1.0)
@export var grass_highlight_color: Color = Color(0.46, 0.82, 0.30, 1.0)
@export var grass_thickness: float = 12.0
@export var add_decorations: bool = true

@export_group("Physics")
@export var surface_friction: float = 1.0:
	set(val):
		surface_friction = val
		_update_physics_material()

var custom_surface_points: PackedVector2Array = PackedVector2Array()
var generated_surface_points: PackedVector2Array = PackedVector2Array()

@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var ground_polygon: Polygon2D = $GroundPolygon
@onready var subsoil_polygon: Polygon2D = get_node_or_null("SubsoilPolygon")
@onready var grass_line: Line2D = $GrassLine
@onready var grass_highlight_line: Line2D = get_node_or_null("GrassHighlightLine")
@onready var decorations_root: Node2D = get_node_or_null("DecorationsRoot")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	_update_physics_material()
	rebuild_segment()

func _update_physics_material() -> void:
	var phys_mat := PhysicsMaterial.new()
	phys_mat.friction = surface_friction
	phys_mat.rough = true
	physics_material_override = phys_mat

## Returns the starting surface point of this segment in local coordinates
func get_entry_point() -> Vector2:
	if generated_surface_points.is_empty():
		return Vector2(0.0, start_height)
	return generated_surface_points[0]

## Returns the exit surface point of this segment in local coordinates
func get_exit_point() -> Vector2:
	if generated_surface_points.is_empty():
		return Vector2(segment_length, end_height)
	return generated_surface_points[generated_surface_points.size() - 1]

## Returns the tangent slope (dy/dx) at the exit of this segment for seamless C1 joins
func get_exit_slope() -> float:
	if generated_surface_points.size() < 2:
		return end_slope
	var n := generated_surface_points.size()
	var p_last := generated_surface_points[n - 1]
	var p_prev := generated_surface_points[n - 2]
	var dx := p_last.x - p_prev.x
	if is_zero_approx(dx):
		return end_slope
	return (p_last.y - p_prev.y) / dx

## Returns the interpolated surface Y at local x coordinate (top ground contour)
func get_surface_y_at(local_x: float) -> float:
	if generated_surface_points.is_empty():
		return 0.0
	var first_pt := generated_surface_points[0]
	var last_pt := generated_surface_points[generated_surface_points.size() - 1]
	if local_x <= first_pt.x:
		return first_pt.y
	if local_x >= last_pt.x:
		return last_pt.y
	
	var idx := 0
	for i in range(generated_surface_points.size() - 1):
		if generated_surface_points[i + 1].x >= local_x:
			idx = i
			break
	
	var p1 := generated_surface_points[idx]
	var p2 := generated_surface_points[mini(idx + 1, generated_surface_points.size() - 1)]
	var span_x := p2.x - p1.x
	if is_zero_approx(span_x):
		return p1.y
	var alpha := (local_x - p1.x) / span_x
	return lerpf(p1.y, p2.y, alpha)

## Returns the interpolated surface position and upward-pointing surface normal at local x
func get_surface_point_and_normal_at(local_x: float) -> Dictionary:
	if generated_surface_points.is_empty():
		return {"point": Vector2(local_x, 0.0), "normal": Vector2.UP}
	
	var first_pt := generated_surface_points[0]
	var last_pt := generated_surface_points[generated_surface_points.size() - 1]
	var clamped_x := clampf(local_x, first_pt.x, last_pt.x)
	var idx := 0
	for i in range(generated_surface_points.size() - 1):
		if generated_surface_points[i + 1].x >= clamped_x:
			idx = i
			break
	
	var p1 := generated_surface_points[idx]
	var p2 := generated_surface_points[mini(idx + 1, generated_surface_points.size() - 1)]
	var span_x := p2.x - p1.x
	var alpha := 0.0 if is_zero_approx(span_x) else (clamped_x - p1.x) / span_x
	var pt := Vector2(clamped_x, lerpf(p1.y, p2.y, alpha))
	var dir := (p2 - p1).normalized() if p1.distance_squared_to(p2) > 0.0001 else Vector2.RIGHT
	var normal := Vector2(-dir.y, dir.x)
	if normal.y > 0.0:
		normal = -normal # Ensure pointing up into the air
	return {"point": pt, "normal": normal}

## Rebuilds the surface geometry and synchronizes collision + visual polygons
func rebuild_segment() -> void:
	_ensure_child_nodes()
	_generate_surface_points()
	_apply_geometry()

func set_custom_points(points: PackedVector2Array) -> void:
	segment_type = SegmentType.CUSTOM
	custom_surface_points = points.duplicate()
	rebuild_segment()

func _ensure_child_nodes() -> void:
	if not collision_polygon:
		collision_polygon = CollisionPolygon2D.new()
		collision_polygon.name = "CollisionPolygon2D"
		add_child(collision_polygon)
	
	if not ground_polygon:
		ground_polygon = Polygon2D.new()
		ground_polygon.name = "GroundPolygon"
		add_child(ground_polygon)
	
	if not subsoil_polygon:
		subsoil_polygon = Polygon2D.new()
		subsoil_polygon.name = "SubsoilPolygon"
		add_child(subsoil_polygon)
		move_child(subsoil_polygon, 0) # Base under ground
		
	if not grass_line:
		grass_line = Line2D.new()
		grass_line.name = "GrassLine"
		grass_line.visible = false
		add_child(grass_line)
	else:
		grass_line.visible = false
	
	if not grass_highlight_line:
		grass_highlight_line = Line2D.new()
		grass_highlight_line.name = "GrassHighlightLine"
		grass_highlight_line.visible = false
		add_child(grass_highlight_line)
	else:
		grass_highlight_line.visible = false
		
	if not decorations_root:
		decorations_root = Node2D.new()
		decorations_root.name = "DecorationsRoot"
		add_child(decorations_root)

func _generate_surface_points() -> void:
	generated_surface_points.clear()
	
	if segment_type == SegmentType.CUSTOM and not custom_surface_points.is_empty():
		generated_surface_points = custom_surface_points.duplicate()
		return
	
	var pts := PackedVector2Array()
	
	for i in range(samples_count + 1):
		var t := float(i) / float(samples_count) # 0.0 to 1.0
		var x := t * segment_length
		var y := 0.0
		
		# Hermite cubic spline baseline matching start_height, start_slope, end_height, end_slope
		var h00 := 2.0 * t * t * t - 3.0 * t * t + 1.0
		var h10 := t * t * t - 2.0 * t * t + t
		var h01 := -2.0 * t * t * t + 3.0 * t * t
		var h11 := t * t * t - t * t
		var base_y := h00 * start_height + h10 * segment_length * start_slope + h01 * end_height + h11 * segment_length * end_slope
		
		# Hann-squared window guarantees zero first-derivative at t=0 and t=1, preserving exact C1 slope joins
		var window_hann := sin(t * PI)
		var window_hann_sq := window_hann * window_hann
		
		match segment_type:
			SegmentType.FLAT:
				y = base_y
				
			SegmentType.GENTLE_HILLS:
				# Smooth sine wave hill with Hann-squared window
				var wave := sin(t * TAU) * window_hann_sq * amplitude
				y = base_y - wave
				
			SegmentType.STEEP_CLIMB:
				# Steeper climb with subtle natural terrain ripple
				var ripple := sin(t * TAU * 1.5) * window_hann_sq * (amplitude * 0.25)
				y = base_y - ripple
				
			SegmentType.VALLEY_DIP:
				# Smooth rounded dip in the middle
				var dip := window_hann_sq * amplitude
				y = base_y + dip
				
			SegmentType.JUMP_RAMP:
				# Smooth launch crest with continuous slope
				var crest := sin(t * PI) * window_hann_sq * (amplitude * 1.1)
				y = base_y - crest
				
			SegmentType.ROLLING_WAVES:
				# Multiple rolling hills with seamless boundary tangency
				var wave1 := sin(t * TAU * 1.5) * 0.65
				var wave2 := sin(t * TAU * 3.0) * 0.35
				var wave_val := (wave1 + wave2) * window_hann_sq * amplitude
				y = base_y - wave_val
				
			SegmentType.PLATEAU_DROP:
				# Natural rounded mesa / rolling ridge (never a rectangular box or sharp cliff)
				var ridge := sin(t * PI) * window_hann_sq * (amplitude * 0.8)
				y = base_y - ridge
				
			SegmentType.BUMPY_WASHBOARD:
				# Small rhythmic ripples to exercise suspension
				var bumps := sin(t * TAU * 4.0) * window_hann_sq * (amplitude * 0.22)
				y = base_y - bumps
				
			SegmentType.DOUBLE_CREST:
				# Two rounded peaks with smooth saddle dip in between
				var crests := sin(t * TAU * 2.0) * window_hann_sq * (amplitude * 0.6)
				y = base_y - crests
				
		pts.append(Vector2(x, y))
	
	generated_surface_points = pts

# Preloaded ground and subsurface textures
const TEX_SOIL_SUBSURFACE: Texture2D = preload("res://assets/terrain/surfaces/brown_soil_subsurface.png")
const TEX_DIRT_STRATA: Texture2D = preload("res://assets/terrain/transitions/dirt_pattern_01.png")
const TEX_GRASS_EDGE: Texture2D = preload("res://assets/terrain/surfaces/grass_top_edge.png")

# Preloaded countryside scenery textures
const TEX_BUSHES: Array = [
	preload("res://assets/environment/countryside/bushes/bush_round_green.png"),
	preload("res://assets/environment/countryside/bushes/bush_shrub_01.png"),
	preload("res://assets/environment/countryside/bushes/bush_shrub_02.png"),
	preload("res://assets/environment/countryside/bushes/bush_shrub_03.png")
]
const TEX_FLOWERS: Array = [
	preload("res://assets/environment/countryside/plants/flower_yellow.png"),
	preload("res://assets/environment/countryside/plants/flower_purple.png"),
	preload("res://assets/environment/countryside/plants/grass_tuft_01.png"),
	preload("res://assets/environment/countryside/plants/mushroom_red.png"),
	preload("res://assets/environment/countryside/plants/mushroom_brown.png")
]
const TEX_ROCKS: Array = [
	preload("res://assets/terrain/rocks/small_stones_pebbles.png"),
	preload("res://assets/terrain/rocks/large_rock_boulder_01.png"),
	preload("res://assets/terrain/rocks/rock_hill_slope_left.png"),
	preload("res://assets/terrain/rocks/rock_hill_slope_right.png")
]
const TEX_PROPS: Array = [
	preload("res://assets/environment/countryside/fences/wooden_fence_01.png"),
	preload("res://assets/environment/countryside/fences/wooden_fence_broken.png"),
	preload("res://assets/environment/countryside/props/fallen_log_01.png"),
	preload("res://assets/environment/countryside/signs/wooden_signpost.png"),
	preload("res://assets/environment/countryside/signs/wooden_sign_arrow_right.png")
]

func _apply_geometry() -> void:
	if generated_surface_points.size() < 2:
		return
	
	var first_pt := generated_surface_points[0]
	var last_pt := generated_surface_points[generated_surface_points.size() - 1]
	
	const GLOBAL_DEEP_BOTTOM_Y: float = 2400.0
	var local_bottom_y: float = GLOBAL_DEEP_BOTTOM_Y - global_position.y
	var max_surf_y: float = first_pt.y
	for pt in generated_surface_points:
		if pt.y > max_surf_y:
			max_surf_y = pt.y
	local_bottom_y = maxf(local_bottom_y, max_surf_y + ground_depth)
	
	# 1. Build ground polygon closed at constant global bottom to eliminate seams and gaps
	var poly_pts := PackedVector2Array()
	for pt in generated_surface_points:
		poly_pts.append(pt)
	
	poly_pts.append(Vector2(last_pt.x, local_bottom_y))
	poly_pts.append(Vector2(first_pt.x, local_bottom_y))
	
	# Synchronize visual polygon and collision polygon exactly
	if collision_polygon:
		collision_polygon.polygon = poly_pts
	
	if ground_polygon:
		ground_polygon.polygon = poly_pts
		ground_polygon.color = Color(1, 1, 1, 1)
		ground_polygon.texture = TEX_SOIL_SUBSURFACE
		ground_polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# 2. Build subsoil polygon with slight offset for rich underground layering
	if subsoil_polygon:
		var subsoil_pts := PackedVector2Array()
		for pt in generated_surface_points:
			subsoil_pts.append(Vector2(pt.x, pt.y + 40.0))
		subsoil_pts.append(Vector2(last_pt.x, local_bottom_y))
		subsoil_pts.append(Vector2(first_pt.x, local_bottom_y))
		subsoil_polygon.polygon = subsoil_pts
		subsoil_polygon.color = Color(0.9, 0.9, 0.9, 1)
		subsoil_polygon.texture = TEX_DIRT_STRATA
		subsoil_polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# 3. Grass lines hidden to maintain pure brown soil/dirt terrain style
	if grass_line:
		grass_line.visible = false
	if grass_highlight_line:
		grass_highlight_line.visible = false
	
	# 4. Optional procedural surface details (rocks, boulders, fences, signs)
	if decorations_root:
		_build_decorations()

func _build_decorations() -> void:
	if not decorations_root:
		return
	for c in decorations_root.get_children():
		c.queue_free()
	
	if not add_decorations or generated_surface_points.size() < 4:
		return
	
	# Seeded deterministic decoration placement based on segment position
	var seed_val := int(absf(global_position.x) + 42)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# 1. Place 1 fence / signpost / prop
	if rng.randf() < 0.65:
		var prop_idx := rng.randi_range(2, generated_surface_points.size() - 3)
		var p_pt := generated_surface_points[prop_idx]
		var p_next := generated_surface_points[prop_idx + 1]
		var p_dir := (p_next - p_pt).normalized()
		var prop_tex: Texture2D = TEX_PROPS[rng.randi() % TEX_PROPS.size()]
		var prop_sprite := Sprite2D.new()
		prop_sprite.texture = prop_tex
		prop_sprite.z_index = -2
		var p_scale := rng.randf_range(0.35, 0.45)
		prop_sprite.scale = Vector2(p_scale, p_scale)
		prop_sprite.offset = Vector2(0, -prop_tex.get_height() * 0.5)
		prop_sprite.position = p_pt + Vector2(0, 2)
		prop_sprite.rotation = clampf(p_dir.angle() * 0.35, -0.3, 0.3)
		decorations_root.add_child(prop_sprite)

	# 2. Place 3-5 rocks and stone formations on the soil surface
	var num_rocks := rng.randi_range(3, 5)
	for s in range(num_rocks):
		var s_idx := rng.randi_range(2, generated_surface_points.size() - 3)
		var s_pt := generated_surface_points[s_idx]
		var s_next := generated_surface_points[s_idx + 1]
		var s_dir := (s_next - s_pt).normalized()
		var rock_tex: Texture2D = TEX_ROCKS[rng.randi() % TEX_ROCKS.size()]
		var rock_sprite := Sprite2D.new()
		rock_sprite.texture = rock_tex
		rock_sprite.z_index = -1
		var s_scale := rng.randf_range(0.28, 0.42)
		rock_sprite.scale = Vector2(s_scale, s_scale)
		rock_sprite.offset = Vector2(0, -rock_tex.get_height() * 0.5)
		rock_sprite.position = s_pt + Vector2(0, 1)
		rock_sprite.rotation = clampf(s_dir.angle() * 0.4, -0.35, 0.35)
		decorations_root.add_child(rock_sprite)
