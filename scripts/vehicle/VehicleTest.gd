class_name VehicleTest
extends Node2D

## VehicleTest: Dedicated standalone test bench for Member 2 (Vehicle Physics).
## Allows rapid iteration, tuning, and physics validation across varied slopes, drops, and bumps.

@export var spawn_position: Vector2 = Vector2(0.0, 320.0)

@onready var vehicle: VehicleController = $Vehicle
@onready var camera: Camera2D = $Camera2D
@onready var speed_label: Label = %SpeedLabel
@onready var fuel_label: Label = %FuelLabel
@onready var status_label: Label = %StatusLabel
@onready var grounded_label: Label = %GroundedLabel

func _ready() -> void:
	_ensure_input_actions()
	if vehicle:
		vehicle.global_position = spawn_position
		vehicle.crashed.connect(_on_vehicle_crashed)
		vehicle.fuel_changed.connect(_on_fuel_changed)
		if camera:
			camera.position = vehicle.position

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_reset_test()
		return
	
	if not vehicle:
		return
	
	# Smooth camera follow
	if camera:
		camera.position = camera.position.lerp(vehicle.position + Vector2(100, -40), 10.0 * delta)
	
	# Update telemetry UI
	if speed_label:
		speed_label.text = "Speed: %d km/h" % int(vehicle.get_speed_kmh())
	if fuel_label:
		fuel_label.text = "Fuel: %d%%" % int((vehicle.current_fuel / vehicle.max_fuel) * 100.0)
	if grounded_label:
		grounded_label.text = "Grounded: %s" % ("YES" if vehicle.is_grounded else "AIRBORNE")
		grounded_label.modulate = Color(0.2, 0.9, 0.3) if vehicle.is_grounded else Color(0.9, 0.6, 0.2)

func _on_vehicle_crashed() -> void:
	if status_label:
		status_label.text = "CRASHED! Press [R] to Reset"
		status_label.modulate = Color(1.0, 0.2, 0.2)

func _on_fuel_changed(current: float, max_f: float) -> void:
	if current <= 0.0 and status_label and vehicle.is_active:
		status_label.text = "OUT OF FUEL! Press [R] to Reset"
		status_label.modulate = Color(1.0, 0.6, 0.1)

func _reset_test() -> void:
	if vehicle:
		vehicle.reset_vehicle(spawn_position)
	if status_label:
		status_label.text = "Controls: [D/Right] Drive | [A/Left] Brake/Reverse | [A/D in Air] Tilt | [R] Reset"
		status_label.modulate = Color(1.0, 1.0, 1.0, 0.9)

func _ensure_input_actions() -> void:
	var bindings: Dictionary = {
		"accelerate": [KEY_D, KEY_RIGHT],
		"brake_reverse": [KEY_A, KEY_LEFT],
		"tilt_left": [KEY_A, KEY_LEFT],
		"tilt_right": [KEY_D, KEY_RIGHT],
		"restart": [KEY_R]
	}
	for action: String in bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key_code in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key_code
				InputMap.action_add_event(action, event)
