class_name GameManager
extends Node

## GameManager: Central coordinator for run states, scoring, and high-level game events.
## Designed to keep vehicle physics and UI decoupled via clean signals.

enum RunState {
	READY,
	PLAYING,
	PAUSED,
	FINISHED
}

signal run_started
signal run_paused(is_paused: bool)
signal run_finished(final_distance: float, coins: int)
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()

func _process(delta: float) -> void:
	if current_state == RunState.PLAYING:
		run_time += delta

func start_run() -> void:
	current_state = RunState.PLAYING
	current_distance = 0.0
	current_fuel = max_fuel
	coins_collected = 0
	run_time = 0.0
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
	if current_distance > best_distance:
		best_distance = current_distance
	
	run_finished.emit(current_distance, coins_collected)

func restart_run() -> void:
	get_tree().paused = false
	current_state = RunState.READY
	run_restarted.emit()
	start_run()

func update_distance(dist: float) -> void:
	if current_state != RunState.PLAYING:
		return
	if dist > current_distance:
		current_distance = dist
		distance_updated.emit(current_distance)

func consume_fuel(amount: float) -> void:
	if current_state != RunState.PLAYING:
		return
	current_fuel = maxf(0.0, current_fuel - amount)
	fuel_updated.emit(current_fuel, max_fuel)
	if current_fuel <= 0.0:
		finish_run("out_of_fuel")

func add_fuel(amount: float) -> void:
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
