extends SceneTree

const SaveManager = preload("res://scripts/core/SaveManager.gd")
const MainMenuController = preload("res://scripts/core/MainMenuController.gd")

func _init() -> void:
	print("==================================================")
	print("--- BEGIN MAIN MENU & PERSISTENCE TEST SUITE ---")
	print("==================================================")
	
	# ----------------------------------------------------
	# PART 1: TEST SAVEMANAGER PERSISTENCE & FILE I/O
	# ----------------------------------------------------
	print("-> Testing SaveManager serialization and persistence...")
	SaveManager.custom_save_path = "user://test_save_unit_test.json"
	SaveManager.reset_save()
	
	var initial_data: Dictionary = SaveManager.load_save()
	assert(initial_data.get("best_distance", -1.0) == 0.0, "Initial best_distance should be 0")
	assert(initial_data.get("total_coins", -1) == 0, "Initial total_coins should be 0")
	print("  ✓ SaveManager default initialization verified")
	
	# Record Run 1: 150m, 12 coins
	var rec1: Dictionary = SaveManager.record_run(150.0, 12)
	assert(rec1["is_new_record"] == true, "Run 1 must be a new record")
	assert(rec1["best_distance"] == 150.0, "Run 1 best distance must be 150.0")
	assert(rec1["total_coins"] == 12, "Run 1 total coins must be 12")
	assert(rec1["runs_played"] == 1, "Runs played must be 1")
	print("  ✓ Run 1 recorded: best_distance = 150m, total_coins = 12 (NEW RECORD)")
	
	# Record Run 2: 95m (no record), 8 coins
	var rec2: Dictionary = SaveManager.record_run(95.0, 8)
	assert(rec2["is_new_record"] == false, "Run 2 should not be a record")
	assert(rec2["best_distance"] == 150.0, "Best distance should remain 150.0")
	assert(rec2["total_coins"] == 20, "Total coins must accumulate to 20")
	assert(rec2["runs_played"] == 2, "Runs played must be 2")
	print("  ✓ Run 2 recorded: best_distance preserved at 150m, coins accumulated to 20")
	
	# Re-read from disk to prove persistence
	var disk_data: Dictionary = SaveManager.load_save()
	assert(disk_data["best_distance"] == 150.0, "Persisted best_distance must match disk file")
	assert(disk_data["total_coins"] == 20, "Persisted total_coins must match disk file")
	print("  ✓ Disk reload verified: persistent data matches expectations")
	
	# ----------------------------------------------------
	# PART 2: TEST MAIN MENU SCENE UI & STAT DISPLAY
	# ----------------------------------------------------
	print("-> Testing MainMenu.tscn UI and stat display...")
	var menu_packed = load("res://scenes/main/MainMenu.tscn")
	assert(menu_packed != null, "MainMenu.tscn must load successfully")
	var menu_instance = menu_packed.instantiate()
	root.add_child(menu_instance)
	
	for i in range(5):
		await process_frame
	
	var best_lbl: Label = menu_instance.get_node("%BestDistanceLabel")
	var coins_lbl: Label = menu_instance.get_node("%TotalCoinsLabel")
	var runs_lbl: Label = menu_instance.get_node("%RunsPlayedLabel")
	
	assert(best_lbl != null and best_lbl.text == "150 m", "Best distance UI label should display '150 m'")
	assert(coins_lbl != null and coins_lbl.text == "20", "Total coins UI label should display '20'")
	assert(runs_lbl != null and runs_lbl.text == "2", "Runs played UI label should display '2'")
	print("  ✓ MainMenu UI displays live stats from SaveManager accurately")
	
	var flags := { "start_fired": false }
	menu_instance.start_game_requested.connect(func(): flags["start_fired"] = true)
	var start_btn: Button = menu_instance.get_node("%StartButton")
	assert(start_btn != null, "StartButton must exist in MainMenu")
	start_btn.pressed.emit()
	assert(flags["start_fired"] == true, "Start button press must emit start_game_requested")
	print("  ✓ StartButton emits start_game_requested signal")
	
	menu_instance.queue_free()
	for i in range(5):
		await process_frame
	
	# ----------------------------------------------------
	# PART 3: TEST MAIN SCENE TRANSITION FLOW
	# ----------------------------------------------------
	print("-> Testing Main.tscn Scene Switcher (Menu -> Game -> Menu)...")
	var main_packed = load("res://scenes/main/Main.tscn")
	assert(main_packed != null, "Main.tscn must load successfully")
	var main_node = main_packed.instantiate()
	root.add_child(main_node)
	
	for i in range(10):
		await process_frame
	
	# 1. MainMenu should be active initially
	var initial_child = main_node.get_node("SceneContainer").get_child(0)
	assert(initial_child is MainMenuController, "SceneContainer should initially hold MainMenu")
	print("  ✓ Game boots into MainMenu by default")
	
	# 2. Trigger Start Drive -> Game loads
	initial_child.start_game_requested.emit()
	for i in range(10):
		await process_frame
	
	var active_game = main_node.get_node_or_null("SceneContainer/Game")
	assert(active_game != null, "Game scene must be instantiated upon starting drive")
	print("  ✓ Transition to Game scene verified")
	
	# 3. Trigger Return to Menu -> MainMenu returns
	active_game.exit_to_main_menu()
	for i in range(10):
		await process_frame
	
	var returned_menu = main_node.get_node("SceneContainer").get_child(0)
	assert(returned_menu is MainMenuController, "SceneContainer should return to MainMenu")
	print("  ✓ Return to MainMenu transition verified")
	
	# Cleanup test save
	SaveManager.reset_save()
	SaveManager.custom_save_path = ""
	
	print("==================================================")
	print("✓ ALL MAIN MENU & PERSISTENCE TESTS PASSED!")
	print("==================================================")
	quit(0)
