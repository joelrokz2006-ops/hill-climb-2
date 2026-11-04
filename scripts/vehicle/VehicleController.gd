class_name VehicleController
extends RigidBody2D

## VehicleController: 2D physics-based vehicle controller.
## Dual-wheel suspension joints, dynamic RPM audio, air tilt flips, stunts & airtime detection, and upgrade tiers.

signal crashed
signal fuel_changed(current: float, max_fuel: float)
signal upgraded(stat_name: String, level: int)
signal trick_performed(trick_name: String, reward_coins: int)
signal airtime_landed(duration: float, reward_coins: int)
signal hard_landed(severity: float)
signal clean_landed(bonus_coins: int)

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
@export var base_motor_torque: float = 75000.0
@export var base_brake_torque: float = 45000.0
@export var base_max_wheel_speed: float = 80.0
@export var base_wheel_friction: float = 1.6
@export var base_suspension_softness: float = 0.6
@export var base_max_fuel: float = 100.0

@export_group("Current Active Physics")
## Effective motor drive torque applied to wheels
@export var motor_torque: float = 75000.0
## Effective braking torque applied when reversing
@export var brake_torque: float = 45000.0
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
@onready var skid_audio: AudioStreamPlayer2D = get_node_or_null("SkidAudio")
@onready var rear_strut: Line2D = get_node_or_null("RearStrutVisual")
@onready var front_strut: Line2D = get_node_or_null("FrontStrutVisual")

var current_fuel: float = 100.0
var is_grounded: bool = false
var was_grounded: bool = false
var is_active: bool = true
var _previous_linear_velocity: Vector2 = Vector2.ZERO

var _initial_rear_wheel_offset: Vector2 = Vector2(-36, 18)
var _initial_front_wheel_offset: Vector2 = Vector2(36, 18)

# Stunt and airtime tracking
var air_time: float = 0.0
var air_rotation_accum: float = 0.0
var _last_air_rotation: float = 0.0
var wheelie_time: float = 0.0

func _ready() -> void:
	if rear_wheel:
		_initial_rear_wheel_offset = rear_wheel.position
	if front_wheel:
		_initial_front_wheel_offset = front_wheel.position
	current_fuel = max_fuel
	_recalculate_upgrades()
	
	if crash_detector:
		crash_detector.body_entered.connect(_on_crash_detector_body_entered)
	
	if engine_audio and not engine_audio.playing:
		engine_audio.play()

func _process(_delta: float) -> void:
	_update_struts()

func _physics_process(delta: float) -> void:
	if not is_active:
		_stop_effects()
		return
	
	_check_ground_contact()
	_track_stunts(delta)
	_handle_input(delta)
	_update_audio(delta)
	_update_particles()
	
	was_grounded = is_grounded
	_previous_linear_velocity = linear_velocity

func set_active(active: bool) -> void:
	is_active = active
	if not active:
		_stop_effects()
		air_time = 0.0
		air_rotation_accum = 0.0
		wheelie_time = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		if rear_wheel:
			rear_wheel.angular_velocity = 0.0
		if front_wheel:
			front_wheel.angular_velocity = 0.0

func _check_ground_contact() -> void:
	var rear_contact: bool = (rear_wheel.contact_monitor and rear_wheel.get_colliding_bodies().size() > 0) if rear_wheel else false
	var front_contact: bool = (front_wheel.contact_monitor and front_wheel.get_colliding_bodies().size() > 0) if front_wheel else false
	is_grounded = rear_contact or front_contact
	
	# Detect hard landing thud
	if not was_grounded and is_grounded:
		var impact_y: float = _previous_linear_velocity.y
		if impact_y > 140.0:
			_play_landing_sound()
			hard_landed.emit(clampf((impact_y - 140.0) / 300.0, 0.2, 1.0))

func _track_stunts(delta: float) -> void:
	var rear_contact: bool = (rear_wheel.contact_monitor and rear_wheel.get_colliding_bodies().size() > 0) if rear_wheel else false
	var front_contact: bool = (front_wheel.contact_monitor and front_wheel.get_colliding_bodies().size() > 0) if front_wheel else false

	if not is_grounded:
		air_time += delta
		var delta_rot: float = wrapf(rotation - _last_air_rotation, -PI, PI)
		air_rotation_accum += delta_rot
		_last_air_rotation = rotation
		
		# Check completed 360 degree flips (TAU radians)
		if air_rotation_accum >= TAU * 0.95:
			air_rotation_accum -= TAU
			trick_performed.emit("Backflip", 20)
		elif air_rotation_accum <= -TAU * 0.95:
			air_rotation_accum += TAU
			trick_performed.emit("Frontflip", 20)
		wheelie_time = 0.0
	else:
		# Vehicle just landed from airborne
		if not was_grounded and is_active:
			if air_time >= 1.2:
				var air_reward: int = int(air_time * 10)
				airtime_landed.emit(air_time, air_reward)
			elif air_time >= 0.75 and absf(rotation) < 0.25:
				# Clean landing bonus when touching down flat after jump
				clean_landed.emit(5)
		
		air_time = 0.0
		air_rotation_accum = 0.0
		_last_air_rotation = rotation
		
		# Wheelie detection: rear wheel grounded, front wheel in the air, driving forward
		if rear_contact and not front_contact and linear_velocity.x > 50.0 and is_active:
			wheelie_time += delta
			if wheelie_time >= 1.0:
				wheelie_time = 0.0
				trick_performed.emit("Wheelie", 10)
		else:
			wheelie_time = 0.0

func _handle_input(delta: float) -> void:
	var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
	var tilt_input: float = Input.get_axis("tilt_left", "tilt_right")
	
	# Low fuel sputtering physical warning when tank < 15%
	var sputter_mult: float = 1.0
	if consumes_fuel and current_fuel < 15.0 and current_fuel > 0.0:
		sputter_mult = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.015)
	
	if accel_input > 0.05:
		if consumes_fuel and current_fuel <= 0.0:
			# Out of fuel, cut off drive power
			pass
		else:
			# Drive forward (apply torque to wheels with smooth saturation at top speed)
			var effective_accel: float = accel_input * sputter_mult
			if rear_wheel and rear_wheel.angular_velocity < max_wheel_speed:
				var rear_factor: float = clampf((max_wheel_speed - rear_wheel.angular_velocity) / (max_wheel_speed * 0.25), 0.0, 1.0)
				rear_wheel.apply_torque(motor_torque * effective_accel * rear_factor)
			if front_wheel and front_wheel.angular_velocity < max_wheel_speed:
				var front_factor: float = clampf((max_wheel_speed - front_wheel.angular_velocity) / (max_wheel_speed * 0.25), 0.0, 1.0)
				front_wheel.apply_torque(motor_torque * 0.75 * effective_accel * front_factor)
			
			if consumes_fuel:
				consume_fuel(fuel_burn_rate * delta)
				
	elif accel_input < -0.05:
		# Brake / Reverse
		if rear_wheel and rear_wheel.angular_velocity > -max_wheel_speed * 0.5:
			var rear_brake_factor: float = clampf((max_wheel_speed * 0.5 + rear_wheel.angular_velocity) / (max_wheel_speed * 0.2), 0.0, 1.0)
			rear_wheel.apply_torque(brake_torque * accel_input * rear_brake_factor)
		if front_wheel and front_wheel.angular_velocity > -max_wheel_speed * 0.5:
			var front_brake_factor: float = clampf((max_wheel_speed * 0.5 + front_wheel.angular_velocity) / (max_wheel_speed * 0.2), 0.0, 1.0)
			front_wheel.apply_torque(brake_torque * 0.75 * accel_input * front_brake_factor)
	
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

func _update_struts() -> void:
	if rear_strut and rear_wheel:
		var local_rear: Vector2 = to_local(rear_wheel.global_position)
		rear_strut.points = PackedVector2Array([Vector2(-36, 4), local_rear])
	if front_strut and front_wheel:
		var local_front: Vector2 = to_local(front_wheel.global_position)
		front_strut.points = PackedVector2Array([Vector2(36, 4), local_front])

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
	if engine_audio:
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
	
	# Tire Skid / Screech audio
	if skid_audio:
		var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
		var is_braking_hard: bool = accel_input < -0.15 and is_grounded and linear_velocity.length() > 60.0
		var is_wheel_spinning: bool = is_grounded and rear_wheel and absf(rear_wheel.angular_velocity) > 40.0 and linear_velocity.length() < 70.0
		
		if (is_braking_hard or is_wheel_spinning) and is_active:
			if not skid_audio.playing:
				skid_audio.play()
			skid_audio.volume_db = lerpf(skid_audio.volume_db, -6.0, 10.0 * delta)
		else:
			skid_audio.volume_db = lerpf(skid_audio.volume_db, -80.0, 10.0 * delta)
			if skid_audio.volume_db < -50.0 and skid_audio.playing:
				skid_audio.stop()

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
	if skid_audio and skid_audio.playing:
		skid_audio.stop()

func _on_crash_detector_body_entered(body: Node) -> void:
	if not is_active:
		return
	if body == self or body == rear_wheel or body == front_wheel:
		return
	
	is_active = false
	air_time = 0.0
	air_rotation_accum = 0.0
	wheelie_time = 0.0
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

## Serializes current upgrade levels into a Dictionary for SaveManager persistence
func serialize_upgrades() -> Dictionary:
	return {
		"engine_level": engine_level,
		"grip_level": grip_level,
		"suspension_level": suspension_level,
		"fuel_tank_level": fuel_tank_level
	}

## Restores upgrade levels from a Dictionary provided by SaveManager
func deserialize_upgrades(data: Dictionary) -> void:
	if data.has("engine_level"):
		engine_level = clampi(int(data["engine_level"]), 1, 5)
	if data.has("grip_level"):
		grip_level = clampi(int(data["grip_level"]), 1, 5)
	if data.has("suspension_level"):
		suspension_level = clampi(int(data["suspension_level"]), 1, 5)
	if data.has("fuel_tank_level"):
		fuel_tank_level = clampi(int(data["fuel_tank_level"]), 1, 5)
	_recalculate_upgrades()

func consume_fuel(amount: float) -> void:
	if not consumes_fuel:
		return
	current_fuel = maxf(0.0, current_fuel - amount)
	fuel_changed.emit(current_fuel, max_fuel)

func refuel(amount: float) -> void:
	current_fuel = clampf(current_fuel + amount, 0.0, max_fuel)
	fuel_changed.emit(current_fuel, max_fuel)

func get_speed_kmh() -> float:
	return (linear_velocity.length() / 100.0) * 3.6

func reset_vehicle(at_position: Vector2) -> void:
	is_active = true
	current_fuel = max_fuel
	air_time = 0.0
	air_rotation_accum = 0.0
	_last_air_rotation = 0.0
	wheelie_time = 0.0
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
		rear_wheel.position = _initial_rear_wheel_offset
		rear_wheel.rotation = 0.0
		rear_wheel.linear_velocity = Vector2.ZERO
		rear_wheel.angular_velocity = 0.0
		var rear_transform := Transform2D(0.0, at_position + _initial_rear_wheel_offset)
		PhysicsServer2D.body_set_state(rear_wheel.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, rear_transform)
		PhysicsServer2D.body_set_state(rear_wheel.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
		PhysicsServer2D.body_set_state(rear_wheel.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
		
	if front_wheel:
		front_wheel.position = _initial_front_wheel_offset
		front_wheel.rotation = 0.0
		front_wheel.linear_velocity = Vector2.ZERO
		front_wheel.angular_velocity = 0.0
		var front_transform := Transform2D(0.0, at_position + _initial_front_wheel_offset)
		PhysicsServer2D.body_set_state(front_wheel.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, front_transform)
		PhysicsServer2D.body_set_state(front_wheel.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
		PhysicsServer2D.body_set_state(front_wheel.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	_update_struts()
	
	if engine_audio and not engine_audio.playing:
		engine_audio.play()
	if skid_audio and skid_audio.playing:
		skid_audio.stop()
