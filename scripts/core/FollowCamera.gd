class_name FollowCamera
extends Camera2D

## FollowCamera: Smoothly tracks the vehicle with velocity-based lookahead and vertical damping.

@export var target: Node2D
@export var follow_offset: Vector2 = Vector2(180.0, -50.0)
@export var lookahead_factor: float = 0.25
@export var max_lookahead: float = 300.0
@export var follow_smoothing_speed: float = 8.0

var trauma: float = 0.0
var _trauma_time: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = false # Custom lerp in physics process gives more responsive vehicle feel
	if is_instance_valid(target):
		snap_to_target()

## Instantly snaps camera to target position with follow offset (no lerp delay on start/reset)
func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + follow_offset

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
		var lookahead: Vector2 = Vector2(clampf(vel.x * lookahead_factor, -80.0, max_lookahead), clampf(vel.y * 0.08, -60.0, 60.0))
		target_pos += lookahead
	
	# Smoothly track horizontal motion while gently damping vertical terrain movement
	global_position.x = lerpf(global_position.x, target_pos.x, follow_smoothing_speed * delta)
	global_position.y = lerpf(global_position.y, target_pos.y, (follow_smoothing_speed * 0.65) * delta)
	
	# Apply subtle trauma screen shake on hard landing / crash
	if trauma > 0.0:
		_trauma_time += delta * 25.0
		var shake_mag: float = trauma * trauma * 7.0 # Max 7 px subtle shake
		var shake_offset := Vector2(sin(_trauma_time * 1.7) * shake_mag, cos(_trauma_time * 2.3) * shake_mag)
		global_position += shake_offset
		trauma = maxf(0.0, trauma - delta * 2.2)
