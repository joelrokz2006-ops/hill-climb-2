class_name MainMenuController
extends Control

## MainMenuController: Oversees the startup menu, displaying high scores, bank balance,
## and directing transitions into the Game run loop.

const SaveManager = preload("res://scripts/core/SaveManager.gd")

signal start_game_requested
signal quit_requested

@onready var best_distance_label: Label = %BestDistanceLabel
@onready var total_coins_label: Label = %TotalCoinsLabel
@onready var runs_played_label: Label = %RunsPlayedLabel
@onready var start_button: Button = %StartButton
@onready var reset_save_button: Button = %ResetSaveButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	refresh_stats()
	_connect_signals()
	if is_instance_valid(start_button):
		start_button.grab_focus()

func refresh_stats() -> void:
	var data := SaveManager.load_save()
	if is_instance_valid(best_distance_label):
		best_distance_label.text = "%d m" % int(data.get("best_distance", 0.0))
	if is_instance_valid(total_coins_label):
		total_coins_label.text = "%d" % int(data.get("total_coins", 0))
	if is_instance_valid(runs_played_label):
		runs_played_label.text = "%d" % int(data.get("runs_played", 0))

func _connect_signals() -> void:
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(reset_save_button) and not reset_save_button.pressed.is_connected(_on_reset_pressed):
		reset_save_button.pressed.connect(_on_reset_pressed)
	if is_instance_valid(quit_button) and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	start_game_requested.emit()

func _on_reset_pressed() -> void:
	SaveManager.reset_save()
	refresh_stats()

func _on_quit_pressed() -> void:
	quit_requested.emit()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_start_pressed()
