class_name PauseMenuController
extends Control

## PauseMenuController: Handles the pause overlay, resume, and restart actions.

signal menu_requested

@onready var resume_button: Button = %ResumeButton
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton

var game_manager_ref: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if is_instance_valid(resume_button):
		resume_button.pressed.connect(_on_resume_pressed)
	if is_instance_valid(retry_button):
		retry_button.pressed.connect(_on_retry_pressed)
	if is_instance_valid(main_menu_button):
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func bind_game_manager(gm: Node) -> void:
	game_manager_ref = gm
	if not is_instance_valid(gm):
		return
	
	if gm.has_signal("run_paused") and not gm.run_paused.is_connected(_on_run_paused):
		gm.run_paused.connect(_on_run_paused)
	if gm.has_signal("run_started") and not gm.run_started.is_connected(_on_run_started):
		gm.run_started.connect(_on_run_started)
	if gm.has_signal("run_restarted") and not gm.run_restarted.is_connected(_on_run_started):
		gm.run_restarted.connect(_on_run_started)

func _on_run_paused(is_paused: bool) -> void:
	visible = is_paused
	if visible and is_instance_valid(resume_button):
		resume_button.grab_focus()

func _on_run_started() -> void:
	visible = false

func _on_resume_pressed() -> void:
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("pause_run"):
		game_manager_ref.pause_run(false)
	else:
		visible = false
		get_tree().paused = false

func _on_retry_pressed() -> void:
	visible = false
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("restart_run"):
		game_manager_ref.restart_run()

func _on_main_menu_pressed() -> void:
	visible = false
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("pause_run"):
		game_manager_ref.pause_run(false)
	else:
		get_tree().paused = false
	menu_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_resume_pressed()
	elif event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		_on_retry_pressed()
