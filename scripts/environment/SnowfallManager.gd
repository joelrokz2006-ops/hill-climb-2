class_name SnowfallManager
extends CanvasLayer

## SnowfallManager: Coordinates dynamic procedural weather events based on distance milestones.
## Triggers snowfall with snowflake particle bursts and soft atmospheric fog overlays every 200 meters.

signal snowfall_started(milestone: int)
signal snowfall_ended(milestone: int)

@export_group("Event Milestones")
## Milestone trigger distance interval in meters
@export var activation_interval: float = 200.0
## Duration of snowfall event in seconds
@export var snowfall_duration: float = 12.0

@export_group("Particle Settings")
@export var particle_amount: int = 65
@export var particle_speed: float = 120.0
@export var wind_strength: float = 30.0
@export var particle_size_min: float = 0.15
@export var particle_size_max: float = 0.35
@export var overlay_opacity: float = 0.30

@onready var snow_particles: CPUParticles2D = get_node_or_null("SnowParticles")
@onready var blizzard_overlay: TextureRect = get_node_or_null("BlizzardOverlay")
@onready var fog_overlay_rect: TextureRect = get_node_or_null("FogOverlay")

var last_milestone: int = 0
var is_snowing: bool = false
var _active_timer: float = 0.0
var _game_manager_ref: Node = null

func _ready() -> void:
	layer = 2
	_init_visuals()
	_bind_game_manager()

func _init_visuals() -> void:
	if snow_particles:
		snow_particles.emitting = false
		snow_particles.amount = particle_amount
		snow_particles.initial_velocity_min = particle_speed * 0.7
		snow_particles.initial_velocity_max = particle_speed * 1.3
		snow_particles.gravity = Vector2(wind_strength, 80.0)
		snow_particles.scale_amount_min = particle_size_min
		snow_particles.scale_amount_max = particle_size_max
	
	if blizzard_overlay:
		blizzard_overlay.modulate.a = 0.0
	if fog_overlay_rect:
		fog_overlay_rect.modulate.a = 0.0

func _bind_game_manager() -> void:
	# Locate GameManager in tree if not explicitly wired
	var gm: Node = get_tree().root.find_child("GameManager", true, false)
	if is_instance_valid(gm):
		bind_game_manager(gm)

func bind_game_manager(gm: Node) -> void:
	_game_manager_ref = gm
	if not gm.distance_updated.is_connected(_on_distance_updated):
		gm.distance_updated.connect(_on_distance_updated)
	if not gm.run_started.is_connected(_on_run_started):
		gm.run_started.connect(_on_run_started)
	if gm.has_signal("run_finished") and not gm.run_finished.is_connected(_on_run_finished):
		gm.run_finished.connect(_on_run_finished)

func _process(delta: float) -> void:
	if is_snowing:
		_active_timer -= delta
		if _active_timer <= 0.0:
			stop_snowfall()

func _on_distance_updated(distance_m: float) -> void:
	if activation_interval <= 0.0:
		return
	
	# Detect crossed 200m milestones (e.g., 200m -> 1, 400m -> 2, etc.)
	var current_milestone := int(floor(distance_m / activation_interval))
	if current_milestone > last_milestone:
		last_milestone = current_milestone
		start_snowfall(last_milestone)

func _on_run_started() -> void:
	last_milestone = 0
	stop_snowfall_immediate()

func _on_run_finished(_dist: float = 0.0, _coins: int = 0, _reason: String = "") -> void:
	stop_snowfall()

func start_snowfall(milestone: int = -1) -> void:
	is_snowing = true
	_active_timer = snowfall_duration
	snowfall_started.emit(milestone if milestone >= 0 else last_milestone)
	
	if snow_particles:
		snow_particles.emitting = true
	
	var tw := create_tween()
	if tw:
		tw.set_parallel(true)
		if blizzard_overlay:
			tw.tween_property(blizzard_overlay, "modulate:a", overlay_opacity, 1.2)
		if fog_overlay_rect:
			tw.tween_property(fog_overlay_rect, "modulate:a", overlay_opacity * 0.8, 1.5)

func stop_snowfall() -> void:
	if not is_snowing:
		return
	is_snowing = false
	snowfall_ended.emit(last_milestone)
	
	if snow_particles:
		snow_particles.emitting = false
	
	var tw := create_tween()
	if tw:
		tw.set_parallel(true)
		if blizzard_overlay:
			tw.tween_property(blizzard_overlay, "modulate:a", 0.0, 1.5)
		if fog_overlay_rect:
			tw.tween_property(fog_overlay_rect, "modulate:a", 0.0, 1.5)

func stop_snowfall_immediate() -> void:
	is_snowing = false
	_active_timer = 0.0
	if snow_particles:
		snow_particles.emitting = false
	if blizzard_overlay:
		blizzard_overlay.modulate.a = 0.0
	if fog_overlay_rect:
		fog_overlay_rect.modulate.a = 0.0
