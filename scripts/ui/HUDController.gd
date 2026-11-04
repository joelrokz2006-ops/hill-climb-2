class_name HUDController
extends Control

## HUDController: Displays real-time run telemetry, fuel status, rewards, and notifications.
## Binds cleanly to GameManager and Vehicle signals with zero hard-coded coupling.
## Responsive across mobile and desktop display aspect ratios.

@onready var distance_label: Label = %DistanceLabel
@onready var best_distance_label: Label = %BestDistanceLabel
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var fuel_percentage_label: Label = get_node_or_null("%FuelPercentageLabel")
@onready var low_fuel_indicator: Label = get_node_or_null("%LowFuelIndicator")
@onready var coins_label: Label = get_node_or_null("%CoinsLabel")
@onready var coins_panel: PanelContainer = get_node_or_null("CoinsPanel")

@onready var message_banner: PanelContainer = %MessageBanner
@onready var message_title_label: Label = get_node_or_null("%MessageTitleLabel")
@onready var message_label: Label = %MessageLabel
@onready var retry_hint_label: Label = get_node_or_null("%RetryHintLabel")
@onready var pause_banner: PanelContainer = get_node_or_null("%PauseBanner")

var game_manager_ref: Node
var _flash_timer: float = 0.0
var _is_low_fuel: bool = false
var _target_fuel: float = 100.0
var _last_coins_count: int = 0

# Style boxes for dynamic fuel bar feedback
var _fuel_style_healthy: StyleBoxFlat
var _fuel_style_warning: StyleBoxFlat
var _fuel_style_critical: StyleBoxFlat

# Stunt and distance milestone toast feedback
var _toast_panel: PanelContainer
var _toast_title_label: Label
var _toast_subtitle_label: Label
var _toast_tween: Tween
var _milestones_reached: Array[int] = []

func _ready() -> void:
	_init_fuel_styles()
	_init_toast_panel()
	
	if message_banner:
		message_banner.visible = false
	if pause_banner:
		pause_banner.visible = false
	if low_fuel_indicator:
		low_fuel_indicator.visible = false
		
	# Fallback auto-discovery if running in standalone scene
	call_deferred("_auto_discover_bindings")

func _auto_discover_bindings() -> void:
	if not is_instance_valid(game_manager_ref):
		var tree_root := get_tree().root
		if tree_root:
			var gm = tree_root.find_child("GameManager", true, false)
			if is_instance_valid(gm):
				bind_game_manager(gm)
			var veh = tree_root.find_child("Vehicle", true, false)
			if is_instance_valid(veh) and veh is VehicleController:
				bind_vehicle(veh)

func _init_fuel_styles() -> void:
	_fuel_style_healthy = StyleBoxFlat.new()
	_fuel_style_healthy.bg_color = Color(0.22, 0.82, 0.36, 1.0)
	_fuel_style_healthy.border_width_top = 1
	_fuel_style_healthy.border_color = Color(0.5, 0.95, 0.6, 0.8)
	_fuel_style_healthy.set_corner_radius_all(5)
	
	_fuel_style_warning = StyleBoxFlat.new()
	_fuel_style_warning.bg_color = Color(0.98, 0.72, 0.16, 1.0)
	_fuel_style_warning.border_width_top = 1
	_fuel_style_warning.border_color = Color(1.0, 0.88, 0.45, 0.8)
	_fuel_style_warning.set_corner_radius_all(5)
	
	_fuel_style_critical = StyleBoxFlat.new()
	_fuel_style_critical.bg_color = Color(0.95, 0.22, 0.18, 1.0)
	_fuel_style_critical.border_width_top = 1
	_fuel_style_critical.border_color = Color(1.0, 0.55, 0.5, 0.8)
	_fuel_style_critical.set_corner_radius_all(5)

func _process(delta: float) -> void:
	# Smoothly animate fuel bar towards target level during driving
	if fuel_bar and absf(fuel_bar.value - _target_fuel) > 0.1:
		fuel_bar.value = lerpf(fuel_bar.value, _target_fuel, delta * 12.0)
	
	# Pulse low fuel beacon when critical
	if _is_low_fuel:
		_flash_timer += delta * 7.0
		var alpha := (sin(_flash_timer) * 0.5) + 0.5
		if low_fuel_indicator:
			low_fuel_indicator.visible = true
			low_fuel_indicator.modulate.a = alpha
			var s := 1.0 + (sin(_flash_timer) * 0.08)
			low_fuel_indicator.scale = Vector2(s, s)
	else:
		if low_fuel_indicator and low_fuel_indicator.visible:
			low_fuel_indicator.visible = false
			low_fuel_indicator.scale = Vector2.ONE

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
	
	if gm.has_signal("coins_updated") and not gm.coins_updated.is_connected(_on_coins_updated):
		gm.coins_updated.connect(_on_coins_updated)
	
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
	if vehicle.has_signal("trick_performed") and not vehicle.trick_performed.is_connected(_on_trick_performed):
		vehicle.trick_performed.connect(_on_trick_performed)
	if vehicle.has_signal("airtime_landed") and not vehicle.airtime_landed.is_connected(_on_airtime_landed):
		vehicle.airtime_landed.connect(_on_airtime_landed)
	if vehicle.has_signal("clean_landed") and not vehicle.clean_landed.is_connected(_on_clean_landed):
		vehicle.clean_landed.connect(_on_clean_landed)

func _update_best_distance() -> void:
	if best_distance_label and is_instance_valid(game_manager_ref) and "best_distance" in game_manager_ref:
		best_distance_label.text = "Best: %d m" % int(game_manager_ref.best_distance)

func _on_distance_updated(new_distance: float) -> void:
	if distance_label:
		distance_label.text = "%d m" % int(new_distance)
	
	# Check distance milestones (100m, 250m, 500m, 1000m, 1500m, 2000m, 3000m, 5000m)
	var current_int: int = int(new_distance)
	for m in [100, 250, 500, 1000, 1500, 2000, 3000, 5000]:
		if current_int >= m and not (m in _milestones_reached):
			_milestones_reached.append(m)
			show_toast("🏁 %d METERS REACHED! 🏁" % m, "Keep Climbing!", Color(0.25, 0.9, 0.55))

func _on_trick_performed(trick_name: String, reward_coins: int) -> void:
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("add_coins"):
		game_manager_ref.add_coins(reward_coins)
	show_toast("★ %s! ★" % trick_name.to_upper(), "+%d Coins" % reward_coins, Color(1.0, 0.85, 0.2))

func _on_airtime_landed(duration: float, reward_coins: int) -> void:
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("add_coins"):
		game_manager_ref.add_coins(reward_coins)
	show_toast("★ BIG AIR! (%.1fs) ★" % duration, "+%d Coins" % reward_coins, Color(0.35, 0.85, 1.0))

func _on_clean_landed(bonus_coins: int) -> void:
	if is_instance_valid(game_manager_ref) and game_manager_ref.has_method("add_coins"):
		game_manager_ref.add_coins(bonus_coins)
	show_toast("CLEAN LANDING!", "+%d Coins" % bonus_coins, Color(0.35, 0.95, 0.45))

func _on_fuel_updated(current: float, max_val: float) -> void:
	_target_fuel = current
	if fuel_bar:
		fuel_bar.max_value = max_val
		fuel_bar.value = current # Immediate sync for assertion safety
	
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
		# Subtle pop animation on coin count increase
		if count > _last_coins_count and is_instance_valid(coins_panel):
			var tw := create_tween()
			tw.tween_property(coins_panel, "scale", Vector2(1.1, 1.1), 0.1)
			tw.tween_property(coins_panel, "scale", Vector2.ONE, 0.15)
	_last_coins_count = count

func _on_run_paused(is_paused: bool) -> void:
	if pause_banner:
		pause_banner.visible = is_paused

func _on_run_started() -> void:
	_is_low_fuel = false
	_milestones_reached.clear()
	if is_instance_valid(_toast_panel):
		_toast_panel.visible = false
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
		_last_coins_count = game_manager_ref.coins_collected

func _on_vehicle_crashed() -> void:
	if is_instance_valid(_toast_panel):
		_toast_panel.visible = false
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

func _on_run_finished(final_distance: float, coins: int = 0, reason: String = "") -> void:
	if is_instance_valid(_toast_panel):
		_toast_panel.visible = false
	if message_banner:
		message_banner.visible = true
	if message_title_label:
		match reason:
			"crashed":
				message_title_label.text = "DRIVER CRASHED!"
				message_title_label.modulate = Color(0.98, 0.28, 0.24)
			"out_of_fuel":
				message_title_label.text = "OUT OF FUEL!"
				message_title_label.modulate = Color(0.98, 0.65, 0.15)
			_:
				message_title_label.text = "RUN FINISHED!"
				message_title_label.modulate = Color(0.35, 0.85, 0.45)
	if message_label:
		var best_dist: int = int(game_manager_ref.best_distance) if is_instance_valid(game_manager_ref) and "best_distance" in game_manager_ref else int(final_distance)
		message_label.text = "Distance: %d m\nCoins: %d\nBest: %d m" % [int(final_distance), coins, best_dist]
	if retry_hint_label:
		retry_hint_label.text = "Press [R] to Retry"
	_update_best_distance()

# --- TOAST NOTIFICATIONS (STUNTS & MILESTONES) ---

func _init_toast_panel() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.anchors_preset = Control.PRESET_CENTER_TOP
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_top = 0.0
	_toast_panel.offset_left = -170.0
	_toast_panel.offset_top = 22.0
	_toast_panel.offset_right = 170.0
	_toast_panel.offset_bottom = 84.0
	_toast_panel.visible = false
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.16, 0.94)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.92, 0.82, 0.25, 0.9)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	_toast_panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	
	_toast_title_label = Label.new()
	_toast_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_title_label.add_theme_font_size_override("font_size", 16)
	_toast_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	vbox.add_child(_toast_title_label)
	
	_toast_subtitle_label = Label.new()
	_toast_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_subtitle_label.add_theme_font_size_override("font_size", 13)
	_toast_subtitle_label.add_theme_color_override("font_color", Color(0.85, 0.94, 0.98))
	vbox.add_child(_toast_subtitle_label)
	
	margin.add_child(vbox)
	_toast_panel.add_child(margin)
	add_child(_toast_panel)

func show_toast(title: String, subtitle: String = "", highlight_color: Color = Color(1.0, 0.85, 0.2)) -> void:
	if not is_instance_valid(_toast_panel):
		_init_toast_panel()
	
	_toast_title_label.text = title
	_toast_title_label.add_theme_color_override("font_color", highlight_color)
	_toast_subtitle_label.text = subtitle
	_toast_subtitle_label.visible = subtitle != ""
	
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_panel.scale = Vector2(0.85, 0.85)
	_toast_panel.pivot_offset = Vector2(170.0, 31.0)
	
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.16)
	_toast_tween.tween_property(_toast_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_toast_tween.chain().tween_interval(1.5)
	
	_toast_tween.chain().tween_property(_toast_panel, "modulate:a", 0.0, 0.25)
	_toast_tween.tween_callback(func(): _toast_panel.visible = false)
