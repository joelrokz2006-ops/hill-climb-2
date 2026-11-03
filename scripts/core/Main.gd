class_name MainController
extends Node

## MainController: Entry point for scene switching and lifecycle management.
## Keeps MainMenu and Game separated, enabling modular flow.

@export var default_game_scene: PackedScene = preload("res://scenes/game/Game.tscn")

@onready var scene_container: Node = $SceneContainer

var current_scene_node: Node = null

func _ready() -> void:
	load_game()

func load_game() -> void:
	_switch_scene(default_game_scene)

func _switch_scene(new_scene: PackedScene) -> void:
	if is_instance_valid(current_scene_node):
		current_scene_node.queue_free()
		current_scene_node = null
	
	if new_scene:
		current_scene_node = new_scene.instantiate()
		scene_container.add_child(current_scene_node)
