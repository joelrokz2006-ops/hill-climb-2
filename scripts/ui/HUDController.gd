class_name HUDController
extends Control

## HUDController: Displays real-time run telemetry, fuel status, rewards, and notifications.
## Binds cleanly to GameManager and Vehicle signals with zero hard-coded coupling.

@onready var distance_label: Label = %DistanceLabel
@onready var best_distance_label: Label = %BestDistanceLabel
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var fuel_percentage_label: Label = get_node_or_null("%FuelPercentageLabel")
@onready var low_fuel_indicator: Label = get_node_or_null("%LowFuelIndicator")
@onready var coins_label: Label = get_node_or_null("%CoinsLabel")

@onready var message_banner: PanelContainer = %MessageBanner
@onready var message_title_label: Label = get_node_or_null("%MessageTitleLabel")
@onready var message_label: Label = %MessageLabel
@onready var retry_hint_label: Label = get_node_or_null("%RetryHintLabel")
@onready var pause_banner: PanelContainer = get_node_or_null("%PauseBanner")

var game_manager_ref: Node
var _flash_timer: float = 0.0
var _is_low_fuel: bool = false

# Style boxes for dynamic fuel bar feedback
var _fuel_style_healthy: StyleBoxFlat
var _fuel_style_warning: StyleBoxFlat
var _fuel_style_critical: StyleBoxFlat

func _ready() -> void:
	_init_fuel_styles()
	
	if message_banner:
		message_banner.visible = false
	if pause_banner:
		pause_banner.visible = false
	if low_fuel_indicator:
		low_fuel_indicator.visible = false

func _init_fuel_styles() -> void:
	_fuel_style_healthy = StyleBoxFlat.new()
	_fuel_style_healthy.bg_color = Color(0.24, 0.78, 0.32, 1.0)
	_fuel_style_healthy.set_corner_radius_all(4)
	
	_fuel_style_warning = StyleBoxFlat.new()
	_fuel_style_warning.bg_color = Color(0.95, 0.70, 0.15, 1.0)
	_fuel_style_warning.set_corner_radius_all(4)
	
	_fuel_style_critical = StyleBoxFlat.new()
	_fuel_style_critical.bg_color = Color(0.92, 0.22, 0.18, 1.0)
	_fuel_style_critical.set_corner_radius_all(4)

func _process(delta: float) -> void:
	# Flash low fuel indicator when critical
	if _is_low_fuel:
		_flash_timer += delta * 6.0
		var alpha := (sin(_flash_timer) * 0.5) + 0.5
		if low_fuel_indicator:
			low_fuel_indicator.visible = true
			low_fuel_indicator.modulate.a = alpha
	else:
		if low_fuel_indicator and low_fuel_indicator.visible:
			low_fuel_indicator.visible = false

## Binds to GameManager signals
func bind_game_manager(gm: Node) -> void:
	game_manager_ref = gm
	if not is_instance_valid(gm):
		return
	
	if not gm.distance_updated.is_connected(_on_distance_updated):
		gm.distance_updated.connect(_on_distance_updated)
	if not gm.fuel_updated.is_connected(_on_fuel_updated):
		gm.fuel_updated.connect(_on_fuel_updated)
	if not gm.run_finished.is_connected(_on_run_finished):
		gm.run_finished.connect(_on_run_finished)
	if not gm.run_started.is_connected(_on_run_started):
		gm.run_started.connect(_on_run_started)
	
	# Connect coins signal if GameManager exposes it
	if gm.has_signal("coins_updated") and not gm.coins_updated.is_connected(_on_coins_updated):
		gm.coins_updated.connect(_on_coins_updated)
	
	# Connect pause signal if GameManager exposes it
	if gm.has_signal("run_paused") and not gm.run_paused.is_connected(_on_run_paused):
		gm.run_paused.connect(_on_run_paused)
		
	_update_best_distance()
	if "coins_collected" in gm:
		_on_coins_updated(gm.coins_collected)

## Binds to VehicleController signals
func bind_vehicle(vehicle: VehicleController) -> void:
	if not is_instance_valid(vehicle):
		return
	if not vehicle.fuel_changed.is_connected(_on_fuel_updated):
		vehicle.fuel_changed.connect(_on_fuel_updated)
	if not vehicle.crashed.is_connected(_on_vehicle_crashed):
		vehicle.crashed.connect(_on_vehicle_crashed)

func _update_best_distance() -> void:
	if best_distance_label and is_instance_valid(game_manager_ref) and "best_distance" in game_manager_ref:
		best_distance_label.text = "Best: %d m" % int(game_manager_ref.best_distance)

func _on_distance_updated(new_distance: float) -> void:
	if distance_label:
		distance_label.text = "%d m" % int(new_distance)

func _on_fuel_updated(current: float, max_val: float) -> void:
	if fuel_bar:
		fuel_bar.max_value = max_val
		fuel_bar.value = current
	
	var pct: float = (current / max_val) * 100.0 if max_val > 0.0 else 0.0
	if fuel_percentage_label:
		fuel_percentage_label.text = "%d%%" % int(pct)
	
	# Dynamic color and low-fuel warning state
	if pct <= 20.0:
		_is_low_fuel = true
		if fuel_bar and _fuel_style_critical:
			fuel_bar.add_theme_stylebox_override("fill", _fuel_style_critical)
	elif pct <= 45.0:
		_is_low_fuel = false
		if fuel_bar and _fuel_style_warning:
			fuel_bar.add_theme_stylebox_override("fill", _fuel_style_warning)
	else:
		_is_low_fuel = false
		if fuel_bar and _fuel_style_healthy:
			fuel_bar.add_theme_stylebox_override("fill", _fuel_style_healthy)

func _on_coins_updated(count: int) -> void:
	if coins_label:
		coins_label.text = str(count)

func _on_run_paused(is_paused: bool) -> void:
	if pause_banner:
		pause_banner.visible = is_paused

func _on_run_started() -> void:
	_is_low_fuel = false
	if message_banner:
		message_banner.visible = false
	if pause_banner:
		pause_banner.visible = false
	if low_fuel_indicator:
		low_fuel_indicator.visible = false
	
	_update_best_distance()
	if distance_label:
		distance_label.text = "0 m"
	if coins_label and is_instance_valid(game_manager_ref) and "coins_collected" in game_manager_ref:
		coins_label.text = str(game_manager_ref.coins_collected)

func _on_vehicle_crashed() -> void:
	if message_banner:
		message_banner.visible = true
	if message_title_label:
		message_title_label.text = "DRIVER CRASHED!"
		message_title_label.modulate = Color(0.98, 0.28, 0.24)
	if message_label:
		var current_dist: int = int(game_manager_ref.current_distance) if is_instance_valid(game_manager_ref) and "current_distance" in game_manager_ref else 0
		var best_dist: int = int(game_manager_ref.best_distance) if is_instance_valid(game_manager_ref) and "best_distance" in game_manager_ref else 0
		message_label.text = "Distance: %d m\nBest: %d m" % [current_dist, best_dist]
	if retry_hint_label:
		retry_hint_label.text = "Press [R] to Retry"

func _on_run_finished(final_distance: float, coins: int) -> void:
	if message_banner:
		message_banner.visible = true
	if message_title_label:
		message_title_label.text = "RUN FINISHED!"
		message_title_label.modulate = Color(0.35, 0.85, 0.45)
	if message_label:
		var best_dist: int = int(game_manager_ref.best_distance) if is_instance_valid(game_manager_ref) and "best_distance" in game_manager_ref else int(final_distance)
		message_label.text = "Distance: %d m\nCoins: %d\nBest: %d m" % [int(final_distance), coins, best_dist]
	if retry_hint_label:
		retry_hint_label.text = "Press [R] to Retry"
	_update_best_distance()
