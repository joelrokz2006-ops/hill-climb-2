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
		add_child(grass_line)
	
	if not grass_highlight_line:
		grass_highlight_line = Line2D.new()
		grass_highlight_line.name = "GrassHighlightLine"
		add_child(grass_highlight_line)
		
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
	var step_x := segment_length / float(samples_count)
	
	for i in range(samples_count + 1):
		var t := float(i) / float(samples_count) # 0.0 to 1.0
		var x := t * segment_length
		var y := 0.0
		
		# Linear baseline interpolation between start and end height
		var base_y := lerpf(start_height, end_height, t)
		
		match segment_type:
			SegmentType.FLAT:
				y = base_y
				
			SegmentType.GENTLE_HILLS:
				# Smooth sine wave hill
				var wave := sin(t * TAU) * amplitude
				y = base_y - wave
				
			SegmentType.STEEP_CLIMB:
				# Steeper slope with smooth s-curve easing
				var eased_t := smoothstep(0.0, 1.0, t)
				var climb := (end_height - start_height) * eased_t + start_height
				var ripple := sin(t * TAU * 2.0) * (amplitude * 0.25)
				y = climb - ripple
				
			SegmentType.VALLEY_DIP:
				# Smooth dip in the middle then climbs back up
				var dip := sin(t * PI) * amplitude
				y = base_y + dip
				
			SegmentType.JUMP_RAMP:
				# Ramp leading to a crest lip followed by steep drop
				if t < 0.7:
					var ramp_t := t / 0.7
					y = base_y - (sin(ramp_t * PI * 0.5) * amplitude * 1.5)
				else:
					var land_t := (t - 0.7) / 0.3
					y = (base_y - amplitude * 1.5) + (smoothstep(0.0, 1.0, land_t) * (amplitude * 1.5 + (end_height - base_y)))
					
			SegmentType.ROLLING_WAVES:
				# Multiple rolling hills
				var wave1 := sin(t * TAU * 1.5) * amplitude
				var wave2 := sin(t * TAU * 3.0) * (amplitude * 0.35)
				y = base_y - (wave1 + wave2)
				
		pts.append(Vector2(x, y))
	
	generated_surface_points = pts

func _apply_geometry() -> void:
	if generated_surface_points.size() < 2:
		return
	
	var first_pt := generated_surface_points[0]
	var last_pt := generated_surface_points[generated_surface_points.size() - 1]
	
	# 1. Build ground polygon closed at bottom
	var poly_pts := PackedVector2Array()
	for pt in generated_surface_points:
		poly_pts.append(pt)
	
	var bottom_y := maxf(first_pt.y, last_pt.y) + ground_depth
	poly_pts.append(Vector2(last_pt.x, bottom_y))
	poly_pts.append(Vector2(first_pt.x, bottom_y))
	
	# Synchronize visual polygon and collision polygon exactly
	if collision_polygon:
		collision_polygon.polygon = poly_pts
	
	if ground_polygon:
		ground_polygon.polygon = poly_pts
		ground_polygon.color = ground_color
	
	# 2. Build subsoil polygon with slight offset for rich underground layering
	if subsoil_polygon:
		var subsoil_pts := PackedVector2Array()
		for pt in generated_surface_points:
			subsoil_pts.append(Vector2(pt.x, pt.y + 40.0))
		subsoil_pts.append(Vector2(last_pt.x, bottom_y))
		subsoil_pts.append(Vector2(first_pt.x, bottom_y))
		subsoil_polygon.polygon = subsoil_pts
		subsoil_polygon.color = subsoil_color
	
	# 3. Grass surface line
	if grass_line:
		grass_line.points = generated_surface_points
		grass_line.width = grass_thickness
		grass_line.default_color = grass_color
		grass_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		grass_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		grass_line.joint_mode = Line2D.LINE_JOINT_ROUND
		grass_line.antialiased = true
	
	# 4. Grass highlight line (subtle top highlight)
	if grass_highlight_line:
		var highlight_pts := PackedVector2Array()
		for pt in generated_surface_points:
			highlight_pts.append(Vector2(pt.x, pt.y - 2.0))
		grass_highlight_line.points = highlight_pts
		grass_highlight_line.width = maxf(2.0, grass_thickness * 0.3)
		grass_highlight_line.default_color = grass_highlight_color
		grass_highlight_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		grass_highlight_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		grass_highlight_line.joint_mode = Line2D.LINE_JOINT_ROUND
		grass_highlight_line.antialiased = true
	
	# 5. Optional procedural surface details (bushes, rocks)
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
	
	var num_decorations := int(segment_length / 280.0)
	for d in range(num_decorations):
		var idx := rng.randi_range(2, generated_surface_points.size() - 3)
		var pt := generated_surface_points[idx]
		var pt_next := generated_surface_points[idx + 1]
		var dir := (pt_next - pt).normalized()
		var normal := Vector2(-dir.y, dir.x)
		if normal.y > 0.0:
			normal = -normal # Point upward from ground
		
		# Place either a grass tuft or small rock
		var is_rock := rng.randf() > 0.6
		if is_rock:
			var rock := Polygon2D.new()
			rock.color = Color(0.48, 0.44, 0.40, 1.0)
			var r_size := rng.randf_range(4.0, 9.0)
			rock.polygon = PackedVector2Array([
				Vector2(-r_size, 0),
				Vector2(-r_size * 0.6, -r_size * 0.8),
				Vector2(r_size * 0.4, -r_size),
				Vector2(r_size, -r_size * 0.5),
				Vector2(r_size * 0.8, 0)
			])
			rock.position = pt + normal * 2.0
			rock.rotation = dir.angle()
			decorations_root.add_child(rock)
		else:
			# Grass tuft
			var tuft := Line2D.new()
			tuft.width = 2.5
			tuft.default_color = Color(0.38, 0.78, 0.25, 0.9)
			tuft.begin_cap_mode = Line2D.LINE_CAP_ROUND
			tuft.end_cap_mode = Line2D.LINE_CAP_ROUND
			var h := rng.randf_range(8.0, 14.0)
			tuft.points = PackedVector2Array([
				Vector2.ZERO,
				Vector2(rng.randf_range(-4, 4), -h)
			])
			tuft.position = pt
			decorations_root.add_child(tuft)
