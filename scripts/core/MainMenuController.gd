class_name MainMenuController
extends Control

## MainMenuController: Oversees the startup menu, displaying high scores, bank balance,
## vehicle selection interface, and directing transitions into the Game run loop.

const SaveManager = preload("res://scripts/core/SaveManager.gd")
const VehicleRegistry = preload("res://scripts/vehicle/VehicleRegistry.gd")

signal start_game_requested
signal quit_requested

@onready var best_distance_label: Label = %BestDistanceLabel
@onready var total_coins_label: Label = %TotalCoinsLabel
@onready var runs_played_label: Label = %RunsPlayedLabel
@onready var start_button: Button = %StartButton
@onready var change_vehicle_button: Button = get_node_or_null("%ChangeVehicleButton")
@onready var reset_save_button: Button = %ResetSaveButton
@onready var quit_button: Button = %QuitButton

@onready var content_vbox: Control = get_node_or_null("%ContentVBox")
@onready var vehicle_select_panel: Control = get_node_or_null("%VehicleSelectPanel")
@onready var vehicle_cards_container: Container = get_node_or_null("%VehicleCardsContainer")
@onready var vehicle_select_back_button: Button = get_node_or_null("%VehicleSelectBackButton")
@onready var prev_vehicle_button: Button = get_node_or_null("%PrevVehicleButton")
@onready var next_vehicle_button: Button = get_node_or_null("%NextVehicleButton")
@onready var scroll_container: ScrollContainer = get_node_or_null("%ScrollContainer")

func _ready() -> void:
	refresh_stats()
	_connect_signals()
	if is_instance_valid(start_button):
		start_button.grab_focus()

func refresh_stats() -> void:
	var data := SaveManager.load_save()
	if is_instance_valid(best_distance_label):
		best_distance_label.text = "%d m" % int(data.get("best_distance", 0.0))
	if is_instance_valid(total_coins_label):
		total_coins_label.text = "%d" % int(data.get("total_coins", 0))
	if is_instance_valid(runs_played_label):
		runs_played_label.text = "%d" % int(data.get("runs_played", 0))

func _connect_signals() -> void:
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(change_vehicle_button) and not change_vehicle_button.pressed.is_connected(_on_change_vehicle_pressed):
		change_vehicle_button.pressed.connect(_on_change_vehicle_pressed)
	if is_instance_valid(vehicle_select_back_button) and not vehicle_select_back_button.pressed.is_connected(_on_vehicle_select_back_pressed):
		vehicle_select_back_button.pressed.connect(_on_vehicle_select_back_pressed)
	if is_instance_valid(prev_vehicle_button) and not prev_vehicle_button.pressed.is_connected(_on_prev_vehicle_pressed):
		prev_vehicle_button.pressed.connect(_on_prev_vehicle_pressed)
	if is_instance_valid(next_vehicle_button) and not next_vehicle_button.pressed.is_connected(_on_next_vehicle_pressed):
		next_vehicle_button.pressed.connect(_on_next_vehicle_pressed)
	if is_instance_valid(reset_save_button) and not reset_save_button.pressed.is_connected(_on_reset_pressed):
		reset_save_button.pressed.connect(_on_reset_pressed)
	if is_instance_valid(quit_button) and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	start_game_requested.emit()

func _on_change_vehicle_pressed() -> void:
	_open_vehicle_selection()

func _on_vehicle_select_back_pressed() -> void:
	_close_vehicle_selection()

func _on_prev_vehicle_pressed() -> void:
	if is_instance_valid(scroll_container):
		var target: int = maxi(0, scroll_container.scroll_horizontal - 190)
		var tw := create_tween()
		tw.tween_property(scroll_container, "scroll_horizontal", target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_next_vehicle_pressed() -> void:
	if is_instance_valid(scroll_container):
		var target: int = scroll_container.scroll_horizontal + 190
		var tw := create_tween()
		tw.tween_property(scroll_container, "scroll_horizontal", target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _open_vehicle_selection() -> void:
	if is_instance_valid(content_vbox):
		content_vbox.visible = false
	if is_instance_valid(vehicle_select_panel):
		vehicle_select_panel.visible = true
	_populate_vehicle_cards()
	call_deferred("_scroll_to_selected_vehicle")

func _scroll_to_selected_vehicle() -> void:
	if not is_instance_valid(scroll_container):
		return
	var current_id := SaveManager.get_selected_vehicle_id()
	var all_ids := VehicleRegistry.get_vehicle_ids()
	var idx := all_ids.find(current_id)
	if idx >= 0:
		scroll_container.scroll_horizontal = maxi(0, (idx - 1) * 190)

func _close_vehicle_selection() -> void:
	if is_instance_valid(vehicle_select_panel):
		vehicle_select_panel.visible = false
	if is_instance_valid(content_vbox):
		content_vbox.visible = true
	if is_instance_valid(change_vehicle_button):
		change_vehicle_button.grab_focus()

func _populate_vehicle_cards() -> void:
	if not is_instance_valid(vehicle_cards_container):
		return
	
	# Clear existing card children
	for child in vehicle_cards_container.get_children():
		child.queue_free()
	
	var current_selected: String = SaveManager.get_selected_vehicle_id()
	var all_vehicles: Array[Dictionary] = VehicleRegistry.get_all_vehicles()
	
	var font_future = load("res://assets/fonts/Kenney_Future.ttf")
	var font_bold = load("res://assets/fonts/Boxy-Bold.ttf")
	var font_narrow = load("res://assets/fonts/Kenney_Future_Narrow.ttf")
	
	for v_data in all_vehicles:
		var v_id: String = v_data.get("id", "")
		var v_name: String = v_data.get("display_name", "")
		var v_preview_path: String = v_data.get("preview_path", "")
		var is_selected: bool = (v_id == current_selected)
		
		# Card Panel
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(165, 290)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.10, 0.14, 0.22, 0.95)
		card_style.corner_radius_top_left = 10
		card_style.corner_radius_top_right = 10
		card_style.corner_radius_bottom_right = 10
		card_style.corner_radius_bottom_left = 10
		if is_selected:
			card_style.border_width_left = 2
			card_style.border_width_top = 2
			card_style.border_width_right = 2
			card_style.border_width_bottom = 2
			card_style.border_color = Color(0.3, 0.9, 0.5, 1.0) # Golden green glow
			card_style.shadow_color = Color(0.15, 0.85, 0.45, 0.3)
			card_style.shadow_size = 8
		else:
			card_style.border_width_left = 1
			card_style.border_width_top = 1
			card_style.border_width_right = 1
			card_style.border_width_bottom = 1
			card_style.border_color = Color(0.25, 0.35, 0.50, 0.8)
		card.add_theme_stylebox_override("panel", card_style)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(margin)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)
		
		# Vehicle Preview Texture
		var preview_rect := TextureRect.new()
		preview_rect.custom_minimum_size = Vector2(140, 95)
		preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not v_preview_path.is_empty() and ResourceLoader.exists(v_preview_path):
			preview_rect.texture = load(v_preview_path)
		vbox.add_child(preview_rect)
		
		# Vehicle Name
		var name_lbl := Label.new()
		name_lbl.text = v_name
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", font_narrow)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1) if is_selected else Color(0.85, 0.9, 0.95, 0.9))
		vbox.add_child(name_lbl)
		
		# Selection Status Label
		var status_lbl := Label.new()
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.add_theme_font_override("font", font_bold)
		status_lbl.add_theme_font_size_override("font_size", 11)
		if is_selected:
			status_lbl.text = "★ SELECTED"
			status_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5, 1.0))
		else:
			status_lbl.text = "READY"
			status_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78, 0.8))
		vbox.add_child(status_lbl)
		
		# Select / Active Button
		var sel_btn := Button.new()
		sel_btn.custom_minimum_size = Vector2(0, 36)
		sel_btn.add_theme_font_override("font", font_future)
		sel_btn.add_theme_font_size_override("font_size", 12)
		
		var btn_style := StyleBoxFlat.new()
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_right = 6
		btn_style.corner_radius_bottom_left = 6
		
		if is_selected:
			sel_btn.text = "ACTIVE"
			sel_btn.disabled = true
			btn_style.bg_color = Color(0.18, 0.38, 0.25, 0.9)
			btn_style.border_color = Color(0.3, 0.85, 0.5, 1.0)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			sel_btn.add_theme_stylebox_override("disabled", btn_style)
		else:
			sel_btn.text = "SELECT"
			sel_btn.disabled = false
			btn_style.bg_color = Color(0.18, 0.28, 0.44, 1.0)
			btn_style.border_color = Color(0.4, 0.65, 0.9, 1.0)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			sel_btn.add_theme_stylebox_override("normal", btn_style)
			var hover_style := btn_style.duplicate() as StyleBoxFlat
			hover_style.bg_color = Color(0.24, 0.38, 0.60, 1.0)
			sel_btn.add_theme_stylebox_override("hover", hover_style)
			
			var target_id := v_id
			sel_btn.pressed.connect(func(): _on_vehicle_selected(target_id))
			
		vbox.add_child(sel_btn)
		vehicle_cards_container.add_child(card)

func _on_vehicle_selected(vehicle_id: String) -> void:
	SaveManager.set_selected_vehicle_id(vehicle_id)
	_populate_vehicle_cards()

func _on_reset_pressed() -> void:
	SaveManager.reset_save()
	refresh_stats()
	if is_instance_valid(vehicle_select_panel) and vehicle_select_panel.visible:
		_populate_vehicle_cards()

func _on_quit_pressed() -> void:
	quit_requested.emit()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if is_instance_valid(vehicle_select_panel) and vehicle_select_panel.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_vehicle_selection()
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_start_pressed()
