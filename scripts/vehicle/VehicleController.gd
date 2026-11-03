class_name VehicleController
extends RigidBody2D

## VehicleController: 2D physics-based vehicle controller.
## Built using RigidBody2D with dual-wheel suspension joints, particle effects, and air tilt.

signal crashed
signal fuel_changed(current: float, max_fuel: float)

@export_group("Motor & Drive")
## Forward drive torque applied to wheels when accelerating (Nm equivalent in 2D engine)
@export var motor_torque: float = 18000.0
## Braking / reverse torque applied when pressing brake_reverse
@export var brake_torque: float = 12000.0
## Maximum rotational speed of the wheels in radians/sec
@export var max_wheel_speed: float = 80.0
## Rotational torque applied for mid-air balancing and tilting
@export var air_tilt_torque: float = 12000.0
## Angular damping applied only while airborne to assist in stable landings
@export var airborne_angular_damping: float = 1.5

@export_group("Fuel")
## Whether acceleration consumes fuel
@export var consumes_fuel: bool = true
## Maximum fuel capacity
@export var max_fuel: float = 100.0
## Fuel burn rate in units per second of acceleration
@export var fuel_burn_rate: float = 4.0

@onready var rear_wheel: RigidBody2D = get_node_or_null("RearWheel")
@onready var front_wheel: RigidBody2D = get_node_or_null("FrontWheel")
@onready var crash_detector: Area2D = get_node_or_null("CrashDetector")
@onready var exhaust_particles: CPUParticles2D = get_node_or_null("ExhaustParticles")
@onready var rear_dust: CPUParticles2D = get_node_or_null("RearDust")
@onready var engine_audio: AudioStreamPlayer2D = get_node_or_null("EngineAudio")
@onready var landing_audio: AudioStreamPlayer2D = get_node_or_null("LandingAudio")

var current_fuel: float = 100.0
var is_grounded: bool = false
var was_grounded: bool = false
var is_active: bool = true
var _previous_linear_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_fuel = max_fuel
	if crash_detector:
		crash_detector.body_entered.connect(_on_crash_detector_body_entered)
	
	if engine_audio and not engine_audio.playing:
		engine_audio.play()

func _physics_process(delta: float) -> void:
	if not is_active:
		_stop_effects()
		return
	
	_check_ground_contact()
	_handle_input(delta)
	_update_audio()
	_update_particles()
	
	was_grounded = is_grounded
	_previous_linear_velocity = linear_velocity

func _check_ground_contact() -> void:
	var rear_contact: bool = (rear_wheel.contact_monitor and rear_wheel.get_colliding_bodies().size() > 0) if rear_wheel else false
	var front_contact: bool = (front_wheel.contact_monitor and front_wheel.get_colliding_bodies().size() > 0) if front_wheel else false
	is_grounded = rear_contact or front_contact
	
	# Detect hard landing thud
	if not was_grounded and is_grounded and _previous_linear_velocity.y > 140.0:
		_play_landing_sound()

func _handle_input(delta: float) -> void:
	var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
	var tilt_input: float = Input.get_axis("tilt_left", "tilt_right")
	
	if accel_input > 0.05:
		if consumes_fuel and current_fuel <= 0.0:
			# Out of fuel, motor cut-off
			pass
		else:
			# Drive forward (apply torque to wheels)
			if rear_wheel and rear_wheel.angular_velocity < max_wheel_speed:
				rear_wheel.apply_torque(motor_torque * accel_input)
			if front_wheel and front_wheel.angular_velocity < max_wheel_speed:
				front_wheel.apply_torque(motor_torque * 0.7 * accel_input)
			
			if consumes_fuel:
				current_fuel = maxf(0.0, current_fuel - fuel_burn_rate * delta)
				fuel_changed.emit(current_fuel, max_fuel)
				
	elif accel_input < -0.05:
		# Brake / Reverse
		if rear_wheel and rear_wheel.angular_velocity > -max_wheel_speed * 0.5:
			rear_wheel.apply_torque(brake_torque * accel_input)
		if front_wheel and front_wheel.angular_velocity > -max_wheel_speed * 0.5:
			front_wheel.apply_torque(brake_torque * 0.7 * accel_input)
	
	# Mid-air orientation and tilt control
	if not is_grounded or absf(tilt_input) > 0.1:
		apply_torque(air_tilt_torque * tilt_input)
	
	# Mid-air rotational damping for stable landing control
	if not is_grounded:
		angular_velocity = lerpf(angular_velocity, 0.0, airborne_angular_damping * delta)

func _update_particles() -> void:
	var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
	var is_accelerating: bool = accel_input > 0.05 and (not consumes_fuel or current_fuel > 0.0)
	
	if exhaust_particles:
		exhaust_particles.emitting = is_accelerating
	
	if rear_dust:
		var wheel_spinning: bool = rear_wheel and absf(rear_wheel.angular_velocity) > 10.0
		rear_dust.emitting = is_grounded and (wheel_spinning or linear_velocity.length() > 30.0)

func _update_audio() -> void:
	if engine_audio:
		var speed_factor: float = clampf(linear_velocity.length() / 400.0, 0.0, 1.0)
		var accel_boost: float = 0.2 if Input.is_action_pressed("accelerate") else 0.0
		engine_audio.pitch_scale = lerpf(engine_audio.pitch_scale, 0.85 + (speed_factor * 0.8) + accel_boost, 0.1)

func _play_landing_sound() -> void:
	if landing_audio and not landing_audio.playing:
		landing_audio.play()

func _stop_effects() -> void:
	if exhaust_particles:
		exhaust_particles.emitting = false
	if rear_dust:
		rear_dust.emitting = false
	if engine_audio and engine_audio.playing:
		engine_audio.stop()

func _on_crash_detector_body_entered(body: Node) -> void:
	if not is_active:
		return
	# Ignore self or attached wheels
	if body == self or body == rear_wheel or body == front_wheel:
		return
	
	# Head or roof impact
	is_active = false
	_stop_effects()
	crashed.emit()

func refuel(amount: float) -> void:
	current_fuel = minf(max_fuel, current_fuel + amount)
	fuel_changed.emit(current_fuel, max_fuel)

func get_speed_kmh() -> float:
	# 100 px = 1 meter; speed in m/s * 3.6 = km/h
	return (linear_velocity.length() / 100.0) * 3.6

func reset_vehicle(at_position: Vector2) -> void:
	is_active = true
	current_fuel = max_fuel
	fuel_changed.emit(current_fuel, max_fuel)
	
	# Immediately update Node2D transform properties
	global_position = at_position
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	# Reset chassis physics transform and velocities via PhysicsServer2D
	var chassis_transform := Transform2D(0.0, at_position)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, chassis_transform)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	if rear_wheel:
		var rear_transform := Transform2D(0.0, at_position + Vector2(-36, 18))
		PhysicsServer2D.body_set_state(rear_wheel.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, rear_transform)
		PhysicsServer2D.body_set_state(rear_wheel.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
		PhysicsServer2D.body_set_state(rear_wheel.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
		
	if front_wheel:
		var front_transform := Transform2D(0.0, at_position + Vector2(36, 18))
		PhysicsServer2D.body_set_state(front_wheel.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, front_transform)
		PhysicsServer2D.body_set_state(front_wheel.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
		PhysicsServer2D.body_set_state(front_wheel.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	if engine_audio and not engine_audio.playing:
		engine_audio.play()
