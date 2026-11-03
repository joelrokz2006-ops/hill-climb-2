class_name HUDController
extends Control

## HUDController: Displays run telemetry (distance, fuel, coins) and control prompts.
## Listens to signals from GameManager and Vehicle to avoid tight coupling.

@onready var distance_label: Label = %DistanceLabel
@onready var best_distance_label: Label = %BestDistanceLabel
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var message_banner: PanelContainer = %MessageBanner
@onready var message_label: Label = %MessageLabel

var game_manager_ref: GameManager

func _ready() -> void:
	if message_banner:
		message_banner.visible = false

func bind_game_manager(gm: GameManager) -> void:
	game_manager_ref = gm
	if not is_instance_valid(gm):
		return
	
	gm.distance_updated.connect(_on_distance_updated)
	gm.fuel_updated.connect(_on_fuel_updated)
	gm.run_finished.connect(_on_run_finished)
	gm.run_started.connect(_on_run_started)
	_update_best_distance()

func bind_vehicle(vehicle: VehicleController) -> void:
	if is_instance_valid(vehicle):
		vehicle.fuel_changed.connect(_on_fuel_updated)
		vehicle.crashed.connect(_on_vehicle_crashed)

func _update_best_distance() -> void:
	if best_distance_label and is_instance_valid(game_manager_ref):
		best_distance_label.text = "Best: %d m" % int(game_manager_ref.best_distance)

func _on_distance_updated(new_distance: float) -> void:
	if distance_label:
		distance_label.text = "Distance: %d m" % int(new_distance)

func _on_fuel_updated(current: float, max_val: float) -> void:
	if fuel_bar:
		fuel_bar.max_value = max_val
		fuel_bar.value = current

func _on_run_started() -> void:
	if message_banner:
		message_banner.visible = false
	_update_best_distance()
	if distance_label:
		distance_label.text = "Distance: 0 m"

func _on_vehicle_crashed() -> void:
	if message_banner and message_label:
		message_banner.visible = true
		message_label.text = "VEHICLE CRASHED!\nPress [R] to Retry"

func _on_run_finished(final_distance: float, _coins: int) -> void:
	if message_banner and message_label:
		message_banner.visible = true
		message_label.text = "RUN FINISHED!\nDistance: %d m\nPress [R] to Retry" % int(final_distance)
	_update_best_distance()
