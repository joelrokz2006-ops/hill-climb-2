class_name FollowCamera
extends Camera2D

## FollowCamera: Smoothly tracks the vehicle with velocity-based lookahead and vertical damping.

@export var target: Node2D
@export var follow_offset: Vector2 = Vector2(200.0, -80.0)
@export var lookahead_factor: float = 0.25
@export var max_lookahead: float = 300.0
@export var follow_smoothing_speed: float = 8.0

var trauma: float = 0.0
var _trauma_time: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = false # Custom lerp in physics process gives more responsive vehicle feel

## Adds subtle screen trauma shake (clamped to 1.0)
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	
	var target_pos: Vector2 = target.global_position + follow_offset
	
	# Add velocity-based lookahead if target is a physics body with velocity
	if target is RigidBody2D:
		var vel: Vector2 = (target as RigidBody2D).linear_velocity
		var lookahead: Vector2 = Vector2(clampf(vel.x * lookahead_factor, -100.0, max_lookahead), vel.y * 0.1)
		target_pos += lookahead
	
	global_position = global_position.lerp(target_pos, follow_smoothing_speed * delta)
	
	# Apply subtle trauma screen shake on hard landing / crash
	if trauma > 0.0:
		_trauma_time += delta * 25.0
		var shake_mag: float = trauma * trauma * 7.0 # Max 7 px subtle shake
		var shake_offset := Vector2(sin(_trauma_time * 1.7) * shake_mag, cos(_trauma_time * 2.3) * shake_mag)
		global_position += shake_offset
		trauma = maxf(0.0, trauma - delta * 2.2)
