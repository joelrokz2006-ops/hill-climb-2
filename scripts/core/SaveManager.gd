class_name SaveManager
extends RefCounted

## SaveManager: Centralized save & load persistence for Hill Climb 2D.
## Manages high scores, collected coins, upgrade tiers, and settings in user://savegame.json.

const DEFAULT_SAVE_PATH: String = "user://savegame.json"

const DEFAULT_SAVE_DATA: Dictionary = {
	"version": 1,
	"best_distance": 0.0,
	"total_coins": 0,
	"runs_played": 0,
	"sound_volume": 1.0,
	"music_volume": 1.0,
	"upgrades": {
		"engine": 1,
		"tires": 1,
		"suspension": 1,
		"fuel_tank": 1
	}
}

## Optional custom path for isolated testing
static var custom_save_path: String = ""

static func get_save_path() -> String:
	if not custom_save_path.is_empty():
		return custom_save_path
	return DEFAULT_SAVE_PATH

static func load_save() -> Dictionary:
	var path := get_save_path()
	if not FileAccess.file_exists(path):
		return DEFAULT_SAVE_DATA.duplicate(true)
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("SaveManager: Failed to open save file for read at %s" % path)
		return DEFAULT_SAVE_DATA.duplicate(true)
	
	var text := file.get_as_text()
	file.close()
	
	var json_data = JSON.parse_string(text)
	if not (json_data is Dictionary):
		push_warning("SaveManager: Save data corrupted or invalid at %s, using defaults." % path)
		return DEFAULT_SAVE_DATA.duplicate(true)
	
	# Merge loaded data with defaults to ensure all required keys exist
	var merged := DEFAULT_SAVE_DATA.duplicate(true)
	for key in json_data.keys():
		merged[key] = json_data[key]
		
	return merged

static func save_game(data: Dictionary) -> bool:
	var path := get_save_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open save file for write at %s" % path)
		return false
	
	var json_string := JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true

static func get_best_distance() -> float:
	var data := load_save()
	return float(data.get("best_distance", 0.0))

static func get_total_coins() -> int:
	var data := load_save()
	return int(data.get("total_coins", 0))

static func get_runs_played() -> int:
	var data := load_save()
	return int(data.get("runs_played", 0))

static func record_run(distance: float, coins: int) -> Dictionary:
	var data := load_save()
	data["runs_played"] = int(data.get("runs_played", 0)) + 1
	data["total_coins"] = int(data.get("total_coins", 0)) + maxi(0, coins)
	
	var prev_best: float = float(data.get("best_distance", 0.0))
	var is_new_record: bool = false
	if distance > prev_best:
		data["best_distance"] = distance
		is_new_record = true
	
	save_game(data)
	return {
		"is_new_record": is_new_record,
		"best_distance": float(data["best_distance"]),
		"total_coins": int(data["total_coins"]),
		"runs_played": int(data["runs_played"])
	}

static func reset_save() -> bool:
	var path := get_save_path()
	if FileAccess.file_exists(path):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove(path.get_file())
	return save_game(DEFAULT_SAVE_DATA.duplicate(true))
