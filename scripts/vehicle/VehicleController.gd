class_name VehicleController
extends RigidBody2D

## VehicleController: 2D physics-based vehicle controller.
## Built using RigidBody2D with dual-wheel suspension joints and air rotation control.

signal crashed
signal fuel_changed(current: float, max_fuel: float)

@export_group("Motor & Drive")
@export var motor_torque: float = 18000.0
@export var brake_torque: float = 12000.0
@export var max_wheel_speed: float = 80.0
@export var air_tilt_torque: float = 12000.0

@export_group("Fuel")
@export var consumes_fuel: bool = true
@export var max_fuel: float = 100.0
@export var fuel_burn_rate: float = 4.0 # per second of acceleration

@onready var rear_wheel: RigidBody2D = $RearWheel
@onready var front_wheel: RigidBody2D = $FrontWheel
@onready var crash_detector: Area2D = $CrashDetector

var current_fuel: float = 100.0
var is_grounded: bool = false
var is_active: bool = true

func _ready() -> void:
	current_fuel = max_fuel
	if crash_detector:
		crash_detector.body_entered.connect(_on_crash_detector_body_entered)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	_check_ground_contact()
	_handle_input(delta)

func _check_ground_contact() -> void:
	var rear_contact: bool = (rear_wheel.contact_monitor and rear_wheel.get_colliding_bodies().size() > 0) if rear_wheel else false
	var front_contact: bool = (front_wheel.contact_monitor and front_wheel.get_colliding_bodies().size() > 0) if front_wheel else false
	is_grounded = rear_contact or front_contact

func _handle_input(delta: float) -> void:
	var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
	var tilt_input: float = Input.get_axis("tilt_left", "tilt_right")
	
	if accel_input > 0.05:
		if consumes_fuel and current_fuel <= 0.0:
			# Out of fuel, cannot apply forward motor torque
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
	
	# Air rotation control (active when airborne or tilting)
	if not is_grounded or absf(tilt_input) > 0.1:
		apply_torque(air_tilt_torque * tilt_input)

func _on_crash_detector_body_entered(body: Node) -> void:
	if not is_active:
		return
	# Ignore self / wheel collisions
	if body == self or body == rear_wheel or body == front_wheel:
		return
	
	# Head or roof impact with terrain
	is_active = false
	crashed.emit()

func reset_vehicle(at_position: Vector2) -> void:
	is_active = true
	current_fuel = max_fuel
	fuel_changed.emit(current_fuel, max_fuel)
	
	# Reset chassis physics transform and velocities via PhysicsServer2D for immediate effect
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
