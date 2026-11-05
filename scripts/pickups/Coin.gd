class_name Coin
extends Area2D

## Coin: Collectible coin awarding currency and updating run score.
## Disables on collection, triggers sparkle particles, and cleanly resets during run restarts.

signal collected(value: int)

@export var coin_value: int = 5
@export var bob_height: float = 4.0
@export var bob_frequency: float = 4.0

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var popup_label: Label = $PopupLabel
@onready var sparkle_particles: CPUParticles2D = get_node_or_null("SparkleParticles")
@onready var glow_aura: Polygon2D = get_node_or_null("Visual/GlowAura")
@onready var audio_player: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayer2D")

var is_collected: bool = false
var _elapsed: float = 0.0
var _initial_visual_y: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2 # Vehicle layer
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if is_instance_valid(visual):
		_initial_visual_y = visual.position.y
	if is_instance_valid(popup_label):
		popup_label.visible = false
	if is_instance_valid(sparkle_particles):
		sparkle_particles.emitting = false

func _process(delta: float) -> void:
	if not is_collected and is_instance_valid(visual):
		_elapsed += delta
		visual.position.y = _initial_visual_y - (sin(_elapsed * bob_frequency) * 0.5 + 0.5) * bob_height
		# Subtle horizontal scale shimmer simulating 3D coin spin
		visual.scale.x = sin(_elapsed * 3.0)
		if is_instance_valid(glow_aura):
			var pulse := (sin(_elapsed * 5.0) * 0.15) + 0.85
			glow_aura.scale = Vector2(pulse, pulse)

func _is_vehicle(node: Node) -> bool:
	var curr: Node = node
	while curr != null and curr != get_tree().root:
		if curr.is_in_group("vehicle") or curr.has_method("consume_fuel") or curr.has_method("refuel") or curr.name == "Vehicle":
			return true
		curr = curr.get_parent()
	return false

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not _is_vehicle(body):
		return
	_collect()

func _on_area_entered(area: Area2D) -> void:
	if is_collected or not _is_vehicle(area):
		return
	_collect()

func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(coin_value)
	
	# Inform GameManager if in tree
	var gm = get_tree().root.find_child("GameManager", true, false)
	if is_instance_valid(gm) and gm.has_method("add_coins"):
		gm.add_coins(coin_value)
	
	# Visual & Audio collection feedback
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	if is_instance_valid(audio_player):
		audio_player.play()
	if is_instance_valid(visual):
		visual.visible = false
		
	if is_instance_valid(sparkle_particles):
		sparkle_particles.restart()
		sparkle_particles.emitting = true
	
	_show_popup("+%d" % coin_value, Color(1.0, 0.88, 0.25))

func _show_popup(text_val: String, color_val: Color) -> void:
	if not is_instance_valid(popup_label):
		return
	popup_label.text = text_val
	popup_label.modulate = color_val
	popup_label.visible = true
	popup_label.position = Vector2(-20, -18)
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup_label, "position:y", -48.0, 0.55)
	tween.parallel().tween_property(popup_label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func(): popup_label.visible = false)

func reset_pickup() -> void:
	is_collected = false
	_elapsed = 0.0
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", false)
	if is_instance_valid(visual):
		visual.visible = true
		visual.position.y = _initial_visual_y
	collision_shape.set_deferred("disabled", false)
	if is_instance_valid(visual):
		visual.visible = true
		visual.position.y = _initial_visual_y
		visual.scale = Vector2.ONE
	if is_instance_valid(popup_label):
		popup_label.visible = false
	if is_instance_valid(sparkle_particles):
		sparkle_particles.emitting = false
