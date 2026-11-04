extends SceneTree

## Stage B & C Integration Test Suite
## Tests driving feel polish, camera trauma, stunts/milestones toasts, and endless procedural terrain integration in GameScene.

const GameManagerScript = preload("res://scripts/core/GameManager.gd")
const SaveManager = preload("res://scripts/core/SaveManager.gd")

func _init() -> void:
	print("=================================================================")
	print("--- BEGIN STAGE B & C COMPREHENSIVE INTEGRATION TEST SUITE ---")
	print("=================================================================")
	
	SaveManager.custom_save_path = "user://test_stage_bc_save.json"
	SaveManager.reset_save()
	
	# Load Game scene
	var game_packed := load("res://scenes/game/Game.tscn") as PackedScene
	assert(game_packed != null, "Game.tscn must load")
	var game: GameScene = game_packed.instantiate()
	root.add_child(game)
	
	for i in range(10):
		await process_frame
		await physics_frame
	
	var gm: GameManager = game.game_manager
	var vehicle: VehicleController = game.vehicle
	var hud: HUDController = game.hud
	var camera: FollowCamera = game.follow_camera
	
	# ---------------------------------------------------------
	# 1. Test Camera Trauma Shake & Landing Feedback (Stage B)
	# ---------------------------------------------------------
	print("-> [Stage B: 1/3] Testing Camera Trauma & Hard Landing...")
	assert(camera.trauma == 0.0, "Initial camera trauma must be 0")
	camera.add_trauma(0.5)
	assert(camera.trauma == 0.5, "add_trauma should increase camera trauma")
	
	# Advance 20 physics frames and check trauma decays
	for i in range(20):
		await physics_frame
	assert(camera.trauma < 0.5, "Camera trauma must decay over time")
	print("  ✓ Camera trauma shake and smooth decay verified (decayed to %.2f)" % camera.trauma)
	
	# ---------------------------------------------------------
	# 2. Test Stunt Feedback & Clean Landing Bonus (Stage B)
	# ---------------------------------------------------------
	print("-> [Stage B: 2/3] Testing Stunt Feedback & Clean Landing Bonus...")
	var initial_coins: int = gm.coins_collected
	
	# Trigger Backflip
	vehicle.trick_performed.emit("Backflip", 20)
	assert(gm.coins_collected == initial_coins + 20, "Backflip must award +20 coins to GameManager")
	assert(hud._toast_panel.visible == true, "HUD toast banner must be visible on stunt")
	assert("BACKFLIP" in hud._toast_title_label.text, "Toast title must display 'BACKFLIP'")
	print("  ✓ Backflip trick toast & reward verified (+20 coins)")
	
	# Trigger Clean Landing
	vehicle.clean_landed.emit(5)
	assert(gm.coins_collected == initial_coins + 25, "Clean landing must award +5 coins")
	assert("CLEAN LANDING" in hud._toast_title_label.text, "Toast title must display 'CLEAN LANDING'")
	print("  ✓ Clean landing toast & reward verified (+5 coins)")
	
	# ---------------------------------------------------------
	# 3. Test Distance Milestones (Stage B)
	# ---------------------------------------------------------
	print("-> [Stage B: 3/3] Testing Distance Milestones Toast...")
	hud._on_distance_updated(105.0)
	assert(100 in hud._milestones_reached, "100m milestone must be recorded")
	assert(hud._toast_panel.visible == true, "Milestone toast must be visible")
	assert("100 METERS" in hud._toast_title_label.text, "Toast must display '100 METERS'")
	print("  ✓ Distance milestone (100m) toast verified")
	
	# ---------------------------------------------------------
	# 4. Test Endless Procedural Terrain Integration in GameScene (Stage C)
	# ---------------------------------------------------------
	print("-> [Stage C: 1/3] Enabling Endless Procedural Terrain mode in Game.tscn...")
	game.use_procedural_terrain = true
	game.setup_terrain()
	
	for i in range(10):
		await process_frame
		await physics_frame
	
	var gen: TerrainGenerator = game.terrain_slot.get_node_or_null("TerrainGenerator")
	assert(gen != null, "TerrainGenerator must be active in terrain_slot when use_procedural_terrain=true")
	assert(game.terrain_slot.get_node_or_null("TestTrack") == null, "Static TestTrack must be removed in procedural mode")
	assert(gen.active_segments.size() >= 3, "TerrainGenerator must have initial active segments")
	print("  ✓ Endless procedural terrain generator active with %d initial segments" % gen.active_segments.size())
	
	# ---------------------------------------------------------
	# 5. Test Long Distance Simulation (5,000+ px & 25,000+ px) (Stage C)
	# ---------------------------------------------------------
	print("-> [Stage C: 2/3] Simulating long-distance travel past 25,000 px...")
	var test_distances: Array[float] = [2000.0, 5500.0, 12000.0, 26000.0]
	
	for dist_x in test_distances:
		vehicle.global_position.x = dist_x
		gen._update_generation(dist_x)
		gen._update_culling(dist_x)
		await process_frame
		
		var furthest_x: float = gen.next_attach_point.x
		assert(furthest_x > dist_x + gen.generate_ahead_distance - 1000.0, "Terrain must generate ahead of vehicle")
		assert(gen.active_segments.size() <= 8, "Segment pooling must keep active segment count bounded (was %d)" % gen.active_segments.size())
		assert(gen.segment_pool.size() > 0 or dist_x < 5000.0, "Old segments must be culled into segment pool")
	
	print("  ✓ Successfully simulated run to 26,000 px!")
	print("  ✓ Active segments bounded: %d active, %d pooled for reuse" % [gen.active_segments.size(), gen.segment_pool.size()])
	print("  ✓ Total coins generated: %d, Total fuel canisters generated: %d" % [gen.total_coins_spawned, gen.total_fuel_spawned])
	
	# ---------------------------------------------------------
	# 6. Test Restart in Procedural Mode (Stage C)
	# ---------------------------------------------------------
	print("-> [Stage C: 3/3] Testing clean restart in Procedural Mode...")
	game.restart_game()
	for i in range(15):
		await process_frame
		await physics_frame
	
	assert(absf(vehicle.global_position.x - game.spawn_position.x) < 5.0, "Vehicle must return to spawn position")
	assert(gm.current_state == GameManagerScript.RunState.PLAYING, "GameManager must be in PLAYING state after restart")
	assert(gen.segment_counter <= 2, "TerrainGenerator counter must reset on run restart (was %d)" % gen.segment_counter)
	assert(gen.active_segments.size() >= 3, "TerrainGenerator must re-seed initial segments on restart")
	print("  ✓ Clean restart in procedural mode verified")
	
	# Cleanup
	game.queue_free()
	SaveManager.reset_save()
	SaveManager.custom_save_path = ""
	
	print("=================================================================")
	print("✓ ALL STAGE B & C INTEGRATION CHECKS PASSED WITH 100% SUCCESS!")
	print("=================================================================")
	quit(0)
