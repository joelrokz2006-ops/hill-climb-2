class_name FuelPickup
extends Area2D

## FuelPickup: Reusable fuel canister pickup providing fuel replenishment.
## Disables on collection, triggers fuel vapor burst particles, and cleanly resets during run restarts.

signal collected(amount: float)

@export var fuel_amount: float = 35.0
@export var bob_height: float = 5.0
@export var bob_frequency: float = 3.5

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var popup_label: Label = $PopupLabel
@onready var vapor_particles: CPUParticles2D = get_node_or_null("VaporParticles")
@onready var glow_aura: Polygon2D = get_node_or_null("Visual/GlowAura")

var is_collected: bool = false
var _elapsed: float = 0.0
var _initial_visual_y: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2 # Vehicle layer
	body_entered.connect(_on_body_entered)
	if is_instance_valid(visual):
		_initial_visual_y = visual.position.y
	if is_instance_valid(popup_label):
		popup_label.visible = false
	if is_instance_valid(vapor_particles):
		vapor_particles.emitting = false

func _process(delta: float) -> void:
	if not is_collected and is_instance_valid(visual):
		_elapsed += delta
		visual.position.y = _initial_visual_y + sin(_elapsed * bob_frequency) * bob_height
		if is_instance_valid(glow_aura):
			var pulse := (sin(_elapsed * 4.0) * 0.15) + 0.85
			glow_aura.scale = Vector2(pulse, pulse)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	
	# Verify vehicle or wheel body
	var target_vehicle = null
	if body is VehicleController:
		target_vehicle = body
	elif body.get_parent() is VehicleController:
		target_vehicle = body.get_parent()
	elif body.name.ends_with("Wheel") and body.get_parent() is VehicleController:
		target_vehicle = body.get_parent()
	
	if target_vehicle == null:
		return
		
	is_collected = true
	collected.emit(fuel_amount)
	
	if target_vehicle.has_method("refuel"):
		target_vehicle.refuel(fuel_amount)
	
	# Also inform GameManager if in tree
	var gm = get_tree().root.find_child("GameManager", true, false)
	if is_instance_valid(gm) and gm.has_method("add_fuel"):
		gm.add_fuel(fuel_amount)
	
	# Visual collection feedback
	collision_shape.set_deferred("disabled", true)
	if is_instance_valid(visual):
		visual.visible = false
		
	if is_instance_valid(vapor_particles):
		vapor_particles.restart()
		vapor_particles.emitting = true
	
	_show_popup("+%.0f FUEL" % fuel_amount, Color(0.2, 0.95, 0.35))

func _show_popup(text_val: String, color_val: Color) -> void:
	if not is_instance_valid(popup_label):
		return
	popup_label.text = text_val
	popup_label.modulate = color_val
	popup_label.visible = true
	popup_label.position = Vector2(-30, -20)
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup_label, "position:y", -54.0, 0.6)
	tween.parallel().tween_property(popup_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): popup_label.visible = false)

func reset_pickup() -> void:
	is_collected = false
	_elapsed = 0.0
	collision_shape.set_deferred("disabled", false)
	if is_instance_valid(visual):
		visual.visible = true
		visual.position.y = _initial_visual_y
		visual.scale = Vector2.ONE
	if is_instance_valid(popup_label):
		popup_label.visible = false
	if is_instance_valid(vapor_particles):
		vapor_particles.emitting = false
