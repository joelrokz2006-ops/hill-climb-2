class_name VehicleController
extends RigidBody2D

## VehicleController: 2D physics-based vehicle controller.
## Built using RigidBody2D with dual-wheel suspension joints, dynamic RPM audio, air tilt flips, and upgrade tiers.

signal crashed
signal fuel_changed(current: float, max_fuel: float)
signal upgraded(stat_name: String, level: int)

@export_group("Upgrade Levels (1-5)")
## Engine Power level (1 to 5)
@export_range(1, 5) var engine_level: int = 1:
	set(val):
		engine_level = clampi(val, 1, 5)
		_recalculate_upgrades()

## Tire Grip level (1 to 5)
@export_range(1, 5) var grip_level: int = 1:
	set(val):
		grip_level = clampi(val, 1, 5)
		_recalculate_upgrades()

## Suspension Dampening level (1 to 5)
@export_range(1, 5) var suspension_level: int = 1:
	set(val):
		suspension_level = clampi(val, 1, 5)
		_recalculate_upgrades()

## Fuel Tank Capacity level (1 to 5)
@export_range(1, 5) var fuel_tank_level: int = 1:
	set(val):
		fuel_tank_level = clampi(val, 1, 5)
		_recalculate_upgrades()

@export_group("Base Stats (Level 1)")
@export var base_motor_torque: float = 18000.0
@export var base_brake_torque: float = 12000.0
@export var base_max_wheel_speed: float = 80.0
@export var base_wheel_friction: float = 1.6
@export var base_suspension_softness: float = 0.6
@export var base_max_fuel: float = 100.0

@export_group("Current Active Physics")
## Effective motor drive torque applied to wheels
@export var motor_torque: float = 18000.0
## Effective braking torque applied when reversing
@export var brake_torque: float = 12000.0
## Maximum rotational wheel velocity in radians/sec
@export var max_wheel_speed: float = 80.0
## Rotational torque applied for mid-air flips and tilt balancing
@export var air_tilt_torque: float = 24000.0
## Maximum rotational velocity in the air to prevent uncontrolled spinning
@export var max_air_angular_velocity: float = 6.5
## Angular damping applied when airborne without tilt input to assist clean landings
@export var airborne_angular_damping: float = 2.0

@export_group("Fuel")
## Whether acceleration consumes fuel
@export var consumes_fuel: bool = true
## Maximum fuel capacity
@export var max_fuel: float = 100.0
## Fuel burn rate in units per second of acceleration
@export var fuel_burn_rate: float = 4.0

@onready var rear_wheel: RigidBody2D = get_node_or_null("RearWheel")
@onready var front_wheel: RigidBody2D = get_node_or_null("FrontWheel")
@onready var rear_joint: PinJoint2D = get_node_or_null("RearJoint")
@onready var front_joint: PinJoint2D = get_node_or_null("FrontJoint")
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
	_recalculate_upgrades()
	
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
	_update_audio(delta)
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
			# Out of fuel, cut off drive power
			pass
		else:
			# Drive forward (apply torque to wheels)
			if rear_wheel and rear_wheel.angular_velocity < max_wheel_speed:
				rear_wheel.apply_torque(motor_torque * accel_input)
			if front_wheel and front_wheel.angular_velocity < max_wheel_speed:
				front_wheel.apply_torque(motor_torque * 0.75 * accel_input)
			
			if consumes_fuel:
				current_fuel = maxf(0.0, current_fuel - fuel_burn_rate * delta)
				fuel_changed.emit(current_fuel, max_fuel)
				
	elif accel_input < -0.05:
		# Brake / Reverse
		if rear_wheel and rear_wheel.angular_velocity > -max_wheel_speed * 0.5:
			rear_wheel.apply_torque(brake_torque * accel_input)
		if front_wheel and front_wheel.angular_velocity > -max_wheel_speed * 0.5:
			front_wheel.apply_torque(brake_torque * 0.75 * accel_input)
	
	# Air rotation and flip control
	if not is_grounded:
		if absf(tilt_input) > 0.1:
			var can_spin: bool = (tilt_input > 0.0 and angular_velocity < max_air_angular_velocity) or (tilt_input < 0.0 and angular_velocity > -max_air_angular_velocity)
			if can_spin:
				apply_torque(air_tilt_torque * tilt_input)
			else:
				angular_velocity = lerpf(angular_velocity, signf(tilt_input) * max_air_angular_velocity, 5.0 * delta)
		else:
			# Auto-stabilize when airborne and tilt input is neutral
			angular_velocity = lerpf(angular_velocity, 0.0, airborne_angular_damping * delta)
	elif absf(tilt_input) > 0.1:
		# Minor ground pitch assist
		apply_torque(air_tilt_torque * 0.3 * tilt_input)

func _update_particles() -> void:
	var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
	var is_accelerating: bool = accel_input > 0.05 and (not consumes_fuel or current_fuel > 0.0)
	
	if exhaust_particles:
		exhaust_particles.emitting = is_accelerating
	
	if rear_dust:
		var wheel_spinning: bool = rear_wheel and absf(rear_wheel.angular_velocity) > 10.0
		rear_dust.emitting = is_grounded and (wheel_spinning or linear_velocity.length() > 30.0)

## Modulate engine pitch (RPM) dynamically based on wheel angular velocity and throttle
func _update_audio(delta: float) -> void:
	if not engine_audio:
		return
	if not engine_audio.playing and is_active:
		engine_audio.play()
	
	var rear_ratio: float = absf(rear_wheel.angular_velocity) / max_wheel_speed if rear_wheel else 0.0
	var front_ratio: float = absf(front_wheel.angular_velocity) / max_wheel_speed if front_wheel else 0.0
	var wheel_speed_ratio: float = clampf(maxf(rear_ratio, front_ratio), 0.0, 1.0)
	var throttle_ratio: float = clampf(Input.get_action_strength("accelerate"), 0.0, 1.0)
	
	# Blend physical wheel speed with throttle response for authentic revving
	var speed_ratio: float = clampf((wheel_speed_ratio * 0.65) + (throttle_ratio * 0.35), 0.0, 1.0)
	var target_pitch: float = lerpf(0.8, 2.2, speed_ratio)
	
	engine_audio.pitch_scale = lerpf(engine_audio.pitch_scale, target_pitch, 12.0 * delta)

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
	if body == self or body == rear_wheel or body == front_wheel:
		return
	
	is_active = false
	_stop_effects()
	crashed.emit()

# --- UPGRADE SYSTEM HELPERS ---

## Recalculates effective physics variables from base values and current upgrade tiers
func _recalculate_upgrades() -> void:
	# 1. Engine Power: +20% torque and +12% top speed per level
	motor_torque = base_motor_torque * (1.0 + (engine_level - 1) * 0.20)
	brake_torque = base_brake_torque * (1.0 + (engine_level - 1) * 0.15)
	max_wheel_speed = base_max_wheel_speed * (1.0 + (engine_level - 1) * 0.12)
	
	# 2. Tire Grip: +22% friction per level
	var eff_friction: float = base_wheel_friction * (1.0 + (grip_level - 1) * 0.22)
	_apply_wheel_friction(eff_friction)
	
	# 3. Suspension: firmer damping, reduces softness by 0.08 per level
	var eff_softness: float = maxf(0.18, base_suspension_softness - (suspension_level - 1) * 0.08)
	if rear_joint:
		rear_joint.softness = eff_softness
	if front_joint:
		front_joint.softness = eff_softness
	
	# 4. Fuel Tank Capacity: +25% capacity per level
	var old_max: float = max_fuel if max_fuel > 0.0 else base_max_fuel
	max_fuel = base_max_fuel * (1.0 + (fuel_tank_level - 1) * 0.25)
	if old_max > 0.0:
		current_fuel = minf(max_fuel, current_fuel * (max_fuel / old_max))
	else:
		current_fuel = max_fuel

func _apply_wheel_friction(friction_val: float) -> void:
	if rear_wheel:
		if rear_wheel.physics_material_override:
			rear_wheel.physics_material_override = rear_wheel.physics_material_override.duplicate()
			rear_wheel.physics_material_override.friction = friction_val
	if front_wheel:
		if front_wheel.physics_material_override:
			front_wheel.physics_material_override = front_wheel.physics_material_override.duplicate()
			front_wheel.physics_material_override.friction = friction_val

## Returns dictionary containing current upgrade levels and calculated effective stats
func get_stats() -> Dictionary:
	var curr_friction: float = base_wheel_friction
	if rear_wheel and rear_wheel.physics_material_override:
		curr_friction = rear_wheel.physics_material_override.friction
	
	var curr_softness: float = base_suspension_softness
	if rear_joint:
		curr_softness = rear_joint.softness
	
	return {
		"engine_power": {
			"level": engine_level,
			"motor_torque": motor_torque,
			"max_wheel_speed": max_wheel_speed,
			"multiplier": 1.0 + (engine_level - 1) * 0.20
		},
		"tire_grip": {
			"level": grip_level,
			"friction": curr_friction,
			"multiplier": 1.0 + (grip_level - 1) * 0.22
		},
		"suspension": {
			"level": suspension_level,
			"softness": curr_softness,
			"multiplier": 1.0 + (suspension_level - 1) * 0.15
		},
		"fuel_tank": {
			"level": fuel_tank_level,
			"max_fuel": max_fuel,
			"multiplier": 1.0 + (fuel_tank_level - 1) * 0.25
		}
	}

## Applies a tier upgrade (1 to 5) to the specified stat
func apply_upgrade(stat_name: String, level: int) -> void:
	var target_level: int = clampi(level, 1, 5)
	var key: String = stat_name.to_lower().strip_edges()
	var canonical_name: String = ""
	
	match key:
		"engine", "engine_power", "engine power":
			engine_level = target_level
			canonical_name = "engine_power"
		"tire", "tire_grip", "grip", "tire grip":
			grip_level = target_level
			canonical_name = "tire_grip"
		"suspension", "suspension_dampening", "suspension dampening":
			suspension_level = target_level
			canonical_name = "suspension"
		"fuel", "fuel_tank", "fuel_capacity", "fuel tank", "fuel tank capacity":
			fuel_tank_level = target_level
			canonical_name = "fuel_tank"
		_:
			push_warning("VehicleController: Unknown upgrade stat name '%s'" % stat_name)
			return
	
	_recalculate_upgrades()
	upgraded.emit(canonical_name, target_level)

func refuel(amount: float) -> void:
	current_fuel = minf(max_fuel, current_fuel + amount)
	fuel_changed.emit(current_fuel, max_fuel)

func get_speed_kmh() -> float:
	return (linear_velocity.length() / 100.0) * 3.6

func reset_vehicle(at_position: Vector2) -> void:
	is_active = true
	current_fuel = max_fuel
	fuel_changed.emit(current_fuel, max_fuel)
	
	global_position = at_position
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
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
