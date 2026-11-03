class_name MainController
extends Node

## MainController: Master scene switcher and lifecycle manager.
## Orchestrates clean transitions between MainMenu and Game scenes.

@export var default_game_scene: PackedScene = preload("res://scenes/game/Game.tscn")
@export var default_menu_scene: PackedScene = preload("res://scenes/main/MainMenu.tscn")
@export var start_with_menu: bool = true

@onready var scene_container: Node = $SceneContainer

var current_scene_node: Node = null

func _ready() -> void:
	if start_with_menu and default_menu_scene != null:
		load_menu()
	else:
		load_game()

func load_menu() -> void:
	_switch_scene(default_menu_scene)
	if is_instance_valid(current_scene_node):
		if current_scene_node.has_signal("start_game_requested") and not current_scene_node.start_game_requested.is_connected(load_game):
			current_scene_node.start_game_requested.connect(load_game)

func load_game() -> void:
	_switch_scene(default_game_scene)
	if is_instance_valid(current_scene_node):
		if current_scene_node.has_signal("return_to_main_menu_requested") and not current_scene_node.return_to_main_menu_requested.is_connected(load_menu):
			current_scene_node.return_to_main_menu_requested.connect(load_menu)

func _switch_scene(new_scene: PackedScene) -> void:
	if not is_instance_valid(scene_container):
		scene_container = get_node_or_null("SceneContainer")
	if not is_instance_valid(scene_container):
		push_error("MainController: SceneContainer is missing!")
		return

	if is_instance_valid(current_scene_node):
		current_scene_node.queue_free()
		current_scene_node = null
	
	if new_scene:
		current_scene_node = new_scene.instantiate()
		scene_container.add_child(current_scene_node)
