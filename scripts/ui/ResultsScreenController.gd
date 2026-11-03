class_name ResultsScreenController
extends Control

## ResultsScreenController: End-of-run results screen displaying distance, records, rewards, and retry flow.
## Operates decoupled from gameplay via GameManager signals.

@onready var title_label: Label = %TitleLabel
@onready var reason_label: Label = %ReasonLabel
@onready var distance_value_label: Label = %DistanceValueLabel
@onready var best_value_label: Label = %BestValueLabel
@onready var coins_value_label: Label = %CoinsValueLabel
@onready var time_value_label: Label = %TimeValueLabel
@onready var new_record_badge: Label = %NewRecordBadge
@onready var retry_button: Button = %RetryButton

var game_manager_ref: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if is_instance_valid(retry_button):
		retry_button.pressed.connect(_on_retry_pressed)

func bind_game_manager(gm: Node) -> void:
	game_manager_ref = gm
	if not is_instance_valid(gm):
		return
	
	if gm.has_signal("run_finished") and not gm.run_finished.is_connected(_on_run_finished):
		gm.run_finished.connect(_on_run_finished)
	if gm.has_signal("run_started") and not gm.run_started.is_connected(_on_run_started):
		gm.run_started.connect(_on_run_started)
	if gm.has_signal("run_restarted") and not gm.run_restarted.is_connected(_on_run_started):
		gm.run_restarted.connect(_on_run_started)

func _on_run_started() -> void:
	visible = false

func _on_run_finished(final_distance: float, coins: int = 0, reason: String = "") -> void:
	visible = true
	
	# Determine title & styling based on finish reason
	match reason:
		"crashed":
			title_label.text = "DRIVER CRASHED!"
			title_label.modulate = Color(0.98, 0.28, 0.24)
			reason_label.text = "Vehicle sustained fatal impact"
		"out_of_fuel":
			title_label.text = "OUT OF FUEL!"
			title_label.modulate = Color(0.98, 0.65, 0.15)
			reason_label.text = "Fuel depleted while ascending"
		_:
			title_label.text = "RUN FINISHED"
			title_label.modulate = Color(0.35, 0.75, 1.0)
			reason_label.text = "Good driving effort!"
	
	distance_value_label.text = "%d m" % int(final_distance)
	
	var best_dist: float = final_distance
	var is_record: bool = false
	var run_time: float = 0.0
	
	if is_instance_valid(game_manager_ref):
		if "best_distance" in game_manager_ref:
			best_dist = game_manager_ref.best_distance
		if "is_new_record" in game_manager_ref:
			is_record = game_manager_ref.is_new_record
		if "run_time" in game_manager_ref:
			run_time = game_manager_ref.run_time
			
	best_value_label.text = "%d m" % int(best_dist)
	coins_value_label.text = "+%d" % coins
	time_value_label.text = "%.1f s" % run_time
	
	if is_instance_valid(new_record_badge):
		new_record_badge.visible = is_record
	
	if is_instance_valid(retry_button):
		retry_button.grab_focus()

func _on_retry_pressed() -> void:
	visible = false
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("restart_run"):
		game_manager_ref.restart_run()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_retry_pressed()
