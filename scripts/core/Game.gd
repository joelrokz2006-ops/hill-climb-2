class_name GameScene
extends Node2D

## GameScene: Integration hub bringing together Vehicle, Terrain, Camera, and HUD.
## Owns vehicle spawn positioning, distance metric tracking, game-over detection, and local scene resets.

const GameManagerScript = preload("res://scripts/core/GameManager.gd")

signal return_to_main_menu_requested

@export var spawn_position: Vector2 = Vector2(0.0, 382.0)
## Whether to use endless procedural terrain (true) or fixed TestTrack (false)
@export var use_procedural_terrain: bool = false

@onready var game_manager: Node = $GameManager
@onready var terrain_slot: Node2D = $TerrainSlot
@onready var vehicle_slot: Node2D = $VehicleSlot
@onready var follow_camera: Camera2D = $FollowCamera
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Node = get_node_or_null("UILayer/HUD")
@onready var results_screen: Control = get_node_or_null("UILayer/ResultsScreen")
@onready var pause_menu: Control = get_node_or_null("UILayer/PauseMenu")
@onready var music_player: AudioStreamPlayer = get_node_or_null("MusicPlayer")
@onready var ambience_player: AudioStreamPlayer = get_node_or_null("AmbiencePlayer")

var vehicle: Node  # VehicleController — typed as Node to avoid parse-time class dependency
var start_x: float = 0.0
var _stopped_timer: float = 0.0

func _ready() -> void:
	_setup_vehicle()
	_setup_camera()
	setup_terrain()
	_setup_ui()
	_setup_audio()
	
	if is_instance_valid(game_manager):
		game_manager.run_restarted.connect(_on_run_restarted)
		game_manager.run_finished.connect(_on_run_finished)
		game_manager.start_run()

func _setup_vehicle() -> void:
	if vehicle_slot.get_child_count() > 0:
		vehicle = vehicle_slot.get_child(0)
	
	if is_instance_valid(vehicle):
		vehicle.global_position = spawn_position
		start_x = spawn_position.x
		if not vehicle.crashed.is_connected(_on_vehicle_crashed):
			vehicle.crashed.connect(_on_vehicle_crashed)
		if vehicle.has_signal("hard_landed") and not vehicle.hard_landed.is_connected(_on_vehicle_hard_landed):
			vehicle.hard_landed.connect(_on_vehicle_hard_landed)
		if is_instance_valid(game_manager) and game_manager.has_method("bind_vehicle"):
			game_manager.bind_vehicle(vehicle)

func setup_terrain() -> void:
	if not is_instance_valid(terrain_slot):
		return
	
	if use_procedural_terrain:
		# Remove static track if present
		var static_track = terrain_slot.get_node_or_null("TestTrack")
		if is_instance_valid(static_track):
			static_track.queue_free()
		
		var existing_gen = terrain_slot.get_node_or_null("TerrainGenerator")
		if not is_instance_valid(existing_gen):
			var gen: Node2D = Node2D.new()
			# Instantiate via preload to avoid parse-time class_name dependency
			var gen_script = load("res://scripts/terrain/TerrainGenerator.gd")
			gen.set_script(gen_script)
			gen.name = "TerrainGenerator"
			gen.set("target", vehicle)
			gen.set("auto_find_target", true)
			terrain_slot.add_child(gen)
	else:
		# Ensure TestTrack is present for controlled regression tests
		var existing_gen = terrain_slot.get_node_or_null("TerrainGenerator")
		if is_instance_valid(existing_gen):
			existing_gen.queue_free()
		
		var static_track = terrain_slot.get_node_or_null("TestTrack")
		if not is_instance_valid(static_track):
			var track_packed: PackedScene = preload("res://scenes/terrain/TestTrack.tscn")
			if track_packed:
				var track = track_packed.instantiate()
				track.name = "TestTrack"
				terrain_slot.add_child(track)

func _setup_camera() -> void:
	if is_instance_valid(follow_camera) and is_instance_valid(vehicle):
		follow_camera.set("target", vehicle)
		if follow_camera.has_method("snap_to_target"):
			follow_camera.snap_to_target()
		else:
			follow_camera.global_position = vehicle.global_position + Vector2(180.0, -50.0)

func _setup_ui() -> void:
	if is_instance_valid(hud):
		if is_instance_valid(game_manager):
			hud.bind_game_manager(game_manager)
		if is_instance_valid(vehicle):
			hud.bind_vehicle(vehicle)
			
	if is_instance_valid(results_screen) and results_screen.has_method("bind_game_manager"):
		results_screen.bind_game_manager(game_manager)
		
	if is_instance_valid(pause_menu) and pause_menu.has_method("bind_game_manager"):
		pause_menu.bind_game_manager(game_manager)

func _setup_audio() -> void:
	if is_instance_valid(music_player):
		if not music_player.finished.is_connected(_on_music_finished):
			music_player.finished.connect(_on_music_finished)
	if is_instance_valid(ambience_player):
		if not ambience_player.finished.is_connected(_on_ambience_finished):
			ambience_player.finished.connect(_on_ambience_finished)

func _on_music_finished() -> void:
	if is_instance_valid(music_player):
		music_player.play()

func _on_ambience_finished() -> void:
	if is_instance_valid(ambience_player):
		ambience_player.play()

func _on_run_finished(_dist: float, _coins: int = 0, _reason: String = "") -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = -22.0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart_game()
		return
	if Input.is_action_just_pressed("pause") and is_instance_valid(game_manager):
		if game_manager.current_state != GameManagerScript.RunState.FINISHED:
			game_manager.toggle_pause()
		return
		
	if not is_instance_valid(vehicle) or not is_instance_valid(game_manager):
		return
	
	if game_manager.current_state == GameManagerScript.RunState.PLAYING and vehicle.is_active:
		# Distance in meters (100 pixels = 1 meter), strictly monotonic from spawn_x
		var dist_meters: float = maxf(0.0, (vehicle.global_position.x - start_x) / 100.0)
		if dist_meters < 0.005:
			dist_meters = 0.0
		game_manager.update_distance(dist_meters)
		
		# Check Out of Fuel game-over condition:
		# When fuel is depleted and vehicle has naturally coasted to a halt
		if vehicle.current_fuel <= 0.0:
			if vehicle.linear_velocity.length() < 18.0:
				_stopped_timer += delta
				if _stopped_timer >= 1.0:
					game_manager.finish_run("out_of_fuel")
			else:
				_stopped_timer = 0.0
		else:
			_stopped_timer = 0.0

func _on_vehicle_hard_landed(severity: float) -> void:
	if is_instance_valid(follow_camera) and follow_camera.has_method("add_trauma"):
		follow_camera.add_trauma(severity * 0.4)

func _on_vehicle_crashed() -> void:
	if is_instance_valid(follow_camera) and follow_camera.has_method("add_trauma"):
		follow_camera.add_trauma(0.7)
	if is_instance_valid(game_manager) and game_manager.current_state == GameManagerScript.RunState.PLAYING:
		game_manager.finish_run("crashed")

func _on_run_restarted() -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = -12.0
		if not music_player.playing:
			music_player.play()
	_stopped_timer = 0.0
	start_x = spawn_position.x
	if is_instance_valid(vehicle):
		vehicle.reset_vehicle(spawn_position)
	if is_instance_valid(follow_camera) and is_instance_valid(vehicle):
		if follow_camera.has_method("snap_to_target"):
			follow_camera.snap_to_target()
		else:
			follow_camera.global_position = vehicle.global_position + Vector2(180.0, -50.0)
	
	# If procedural generator is active, reset it to spawn origin
	if is_instance_valid(terrain_slot):
		var gen = terrain_slot.get_node_or_null("TerrainGenerator")
		if is_instance_valid(gen) and gen.has_method("reset_generator"):
			gen.reset_generator(Vector2(-1200.0, 420.0))
			
	_reset_pickups()

func _reset_pickups() -> void:
	# Resets all collectible items in terrain or pickup containers
	var pickups = get_tree().get_nodes_in_group("pickups")
	for p in pickups:
		if p.has_method("reset_pickup"):
			p.reset_pickup()
			
	# Also inspect children of terrain slot for any pickups
	if is_instance_valid(terrain_slot):
		_reset_pickups_in_node(terrain_slot)

func _reset_pickups_in_node(parent: Node) -> void:
	for child in parent.get_children():
		if child.has_method("reset_pickup"):
			child.reset_pickup()
		if child.get_child_count() > 0:
			_reset_pickups_in_node(child)

func restart_game() -> void:
	if is_instance_valid(game_manager):
		game_manager.restart_run()
	else:
		_on_run_restarted()

func exit_to_main_menu() -> void:
	if is_instance_valid(game_manager):
		game_manager.pause_run(false)
	return_to_main_menu_requested.emit()
