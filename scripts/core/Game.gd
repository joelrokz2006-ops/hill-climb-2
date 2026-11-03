class_name GameScene
extends Node2D

## GameScene: Integration hub bringing together Vehicle, Terrain, Camera, and HUD.
## Owns vehicle spawn positioning, distance metric tracking, game-over detection, and local scene resets.

const GameManagerScript = preload("res://scripts/core/GameManager.gd")

signal return_to_main_menu_requested

@export var spawn_position: Vector2 = Vector2(0.0, 360.0)

@onready var game_manager: Node = $GameManager
@onready var terrain_slot: Node2D = $TerrainSlot
@onready var vehicle_slot: Node2D = $VehicleSlot
@onready var follow_camera: Camera2D = $FollowCamera
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: HUDController = get_node_or_null("UILayer/HUD")
@onready var results_screen: Control = get_node_or_null("UILayer/ResultsScreen")
@onready var pause_menu: Control = get_node_or_null("UILayer/PauseMenu")

var vehicle: VehicleController
var start_x: float = 0.0
var _stopped_timer: float = 0.0

func _ready() -> void:
	_setup_vehicle()
	_setup_camera()
	_setup_ui()
	
	if is_instance_valid(game_manager):
		game_manager.run_restarted.connect(_on_run_restarted)
		game_manager.start_run()

func _setup_vehicle() -> void:
	if vehicle_slot.get_child_count() > 0:
		vehicle = vehicle_slot.get_child(0) as VehicleController
	
	if is_instance_valid(vehicle):
		vehicle.global_position = spawn_position
		start_x = spawn_position.x
		if not vehicle.crashed.is_connected(_on_vehicle_crashed):
			vehicle.crashed.connect(_on_vehicle_crashed)

func _setup_camera() -> void:
	if is_instance_valid(follow_camera) and is_instance_valid(vehicle):
		follow_camera.set("target", vehicle)
		follow_camera.global_position = vehicle.global_position

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

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart_game()
		return
	if Input.is_action_just_pressed("pause") and is_instance_valid(game_manager):
		game_manager.toggle_pause()
		return
		
	if not is_instance_valid(vehicle) or not is_instance_valid(game_manager):
		return
	
	if game_manager.current_state == GameManagerScript.RunState.PLAYING:
		# Distance in meters (100 pixels = 1 meter)
		var dist_meters: float = maxf(0.0, (vehicle.global_position.x - start_x) / 100.0)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()
	elif event.is_action_pressed("pause"):
		if is_instance_valid(game_manager):
			game_manager.toggle_pause()

func _on_vehicle_crashed() -> void:
	if is_instance_valid(game_manager):
		game_manager.finish_run("crashed")

func _on_run_restarted() -> void:
	_stopped_timer = 0.0
	if is_instance_valid(vehicle):
		vehicle.reset_vehicle(spawn_position)
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
