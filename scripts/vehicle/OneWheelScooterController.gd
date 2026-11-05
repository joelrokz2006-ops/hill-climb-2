class_name OneWheelScooterController
extends VehicleController

## OneWheelScooterController: Specialized single-wheel electric vehicle controller.
## Implements active gyro-stabilization, dynamic rider lean, and responsive torque.

@export_group("Gyro Balance Assistance")
@export var balance_assistance_enabled: bool = true
## Proportional correction torque gain
@export var balance_kp: float = 3200.0
## Derivative / angular damping torque gain
@export var balance_kd: float = 320.0
## Maximum rider lean angle when tilting or accelerating (radians)
@export var max_lean_angle: float = 0.35
## Peak stabilization torque limit (prevents physics explosion)
@export var max_stabilization_torque: float = 16000.0

func _ready() -> void:
	super._ready()
	# One-Wheel Scooter default stat tuning
	mass = 7.0
	motor_torque = 1800.0
	brake_torque = 1400.0
	max_wheel_speed = 78.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_active:
		return
	_apply_gyro_stabilization(delta)

func _apply_gyro_stabilization(_delta: float) -> void:
	if not balance_assistance_enabled or not is_grounded:
		return
	
	var tilt_input: float = Input.get_axis("tilt_left", "tilt_right")
	var accel_input: float = Input.get_axis("brake_reverse", "accelerate")
	
	# Compute target lean: manual tilt takes precedence, otherwise gentle lean with throttle
	var target_lean: float = 0.0
	if absf(tilt_input) > 0.05:
		target_lean = tilt_input * max_lean_angle
	elif absf(accel_input) > 0.05:
		target_lean = accel_input * (max_lean_angle * 0.45)
		
	var angle_error: float = wrapf(rotation - target_lean, -PI, PI)
	var correction_torque: float = (-angle_error * balance_kp) - (angular_velocity * balance_kd)
	correction_torque = clampf(correction_torque, -max_stabilization_torque, max_stabilization_torque)
	apply_torque(correction_torque)
