class_name GameManager
extends Node

## GameManager: Central coordinator for run states, scoring, and high-level game events.
## Designed to keep vehicle physics and UI decoupled via clean signals.

const SaveManager = preload("res://scripts/core/SaveManager.gd")

enum RunState {
	READY,
	PLAYING,
	PAUSED,
	FINISHED
}

signal run_started
signal run_paused(is_paused: bool)
signal run_finished(final_distance: float, coins: int, reason: String)
signal run_restarted
signal distance_updated(new_distance: float)
signal fuel_updated(current: float, max_fuel: float)
signal coins_updated(count: int)

var current_state: RunState = RunState.READY
var current_distance: float = 0.0
var best_distance: float = 0.0
var current_fuel: float = 100.0
var max_fuel: float = 100.0
var coins_collected: int = 0
var run_time: float = 0.0
var finish_reason: String = ""
var is_new_record: bool = false
var vehicle_ref: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	best_distance = SaveManager.get_best_distance()

func bind_vehicle(veh: Node) -> void:
	vehicle_ref = veh
	if is_instance_valid(veh):
		if "current_fuel" in veh and "max_fuel" in veh:
			current_fuel = float(veh.current_fuel)
			max_fuel = float(veh.max_fuel)
		if veh.has_signal("fuel_changed") and not veh.fuel_changed.is_connected(_on_vehicle_fuel_changed):
			veh.fuel_changed.connect(_on_vehicle_fuel_changed)

func _on_vehicle_fuel_changed(curr: float, max_f: float) -> void:
	current_fuel = curr
	max_fuel = max_f
	fuel_updated.emit(current_fuel, max_fuel)

func _process(delta: float) -> void:
	if current_state == RunState.PLAYING:
		run_time += delta

func start_run() -> void:
	current_state = RunState.PLAYING
	current_distance = 0.0
	coins_collected = 0
	run_time = 0.0
	finish_reason = ""
	is_new_record = false
	
	if is_instance_valid(vehicle_ref):
		if "current_fuel" in vehicle_ref and "max_fuel" in vehicle_ref:
			current_fuel = float(vehicle_ref.current_fuel)
			max_fuel = float(vehicle_ref.max_fuel)
	else:
		current_fuel = max_fuel
	
	run_started.emit()
	fuel_updated.emit(current_fuel, max_fuel)
	distance_updated.emit(current_distance)
	coins_updated.emit(coins_collected)

func pause_run(is_paused: bool) -> void:
	if current_state != RunState.PLAYING and current_state != RunState.PAUSED:
		return
	
	current_state = RunState.PAUSED if is_paused else RunState.PLAYING
	get_tree().paused = is_paused
	run_paused.emit(is_paused)

func toggle_pause() -> void:
	if current_state == RunState.PLAYING:
		pause_run(true)
	elif current_state == RunState.PAUSED:
		pause_run(false)

func finish_run(reason: String = "") -> void:
	if current_state == RunState.FINISHED:
		return
	
	current_state = RunState.FINISHED
	finish_reason = reason
	
	if is_instance_valid(vehicle_ref) and vehicle_ref.has_method("set_active"):
		vehicle_ref.set_active(false)
	
	var save_result := SaveManager.record_run(current_distance, coins_collected)
	best_distance = float(save_result["best_distance"])
	is_new_record = bool(save_result["is_new_record"])
	
	run_finished.emit(current_distance, coins_collected, finish_reason)

func restart_run() -> void:
	get_tree().paused = false
	current_state = RunState.READY
	run_restarted.emit()
	start_run()

func update_distance(dist: float) -> void:
	if current_state != RunState.PLAYING:
		return
	var valid_dist: float = maxf(0.0, dist)
	if valid_dist > current_distance:
		current_distance = valid_dist
		distance_updated.emit(current_distance)

func consume_fuel(amount: float) -> void:
	if current_state != RunState.PLAYING:
		return
	if is_instance_valid(vehicle_ref) and vehicle_ref.has_method("consume_fuel"):
		vehicle_ref.consume_fuel(amount)
	else:
		current_fuel = maxf(0.0, current_fuel - amount)
		fuel_updated.emit(current_fuel, max_fuel)

func add_fuel(amount: float) -> void:
	if is_instance_valid(vehicle_ref) and vehicle_ref.has_method("refuel"):
		vehicle_ref.refuel(amount)
	else:
		current_fuel = minf(max_fuel, current_fuel + amount)
		fuel_updated.emit(current_fuel, max_fuel)

func add_coins(amount: int) -> void:
	coins_collected += amount
	coins_updated.emit(coins_collected)

## Programmatically verifies and sets up required input actions if not present in InputMap
func _ensure_input_actions() -> void:
	var bindings: Dictionary = {
		"accelerate": [KEY_D, KEY_RIGHT],
		"brake_reverse": [KEY_A, KEY_LEFT],
		"tilt_left": [KEY_A, KEY_LEFT],
		"tilt_right": [KEY_D, KEY_RIGHT],
		"restart": [KEY_R],
		"pause": [KEY_ESCAPE, KEY_P]
	}
	
	for action: String in bindings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key_code in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key_code
				InputMap.action_add_event(action, event)
