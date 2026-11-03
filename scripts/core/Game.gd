class_name GameScene
extends Node2D

## GameScene: Integration hub bringing together Vehicle, Terrain, Camera, and HUD.
## Owns vehicle spawn positioning, distance metric tracking, and local scene resets.

const GameManagerScript = preload("res://scripts/core/GameManager.gd")

@export var spawn_position: Vector2 = Vector2(0.0, 370.0)

@onready var game_manager = $GameManager
@onready var terrain_slot: Node2D = $TerrainSlot
@onready var vehicle_slot: Node2D = $VehicleSlot
@onready var follow_camera: Camera2D = $FollowCamera
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: HUDController = $UILayer/HUD

var vehicle: VehicleController
var start_x: float = 0.0

func _ready() -> void:
	_setup_vehicle()
	_setup_camera()
	_setup_hud()
	
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

func _setup_hud() -> void:
	if is_instance_valid(hud):
		if is_instance_valid(game_manager):
			hud.bind_game_manager(game_manager)
		if is_instance_valid(vehicle):
			hud.bind_vehicle(vehicle)

func _process(_delta: float) -> void:
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
	if is_instance_valid(vehicle):
		vehicle.reset_vehicle(spawn_position)

func restart_game() -> void:
	if is_instance_valid(game_manager):
		game_manager.restart_run()
	else:
		_on_run_restarted()
