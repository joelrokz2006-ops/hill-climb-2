class_name VehicleRegistry
extends RefCounted

## VehicleRegistry: Central catalog of vehicles, stat profiles, and upgrade configs.
## Serves as a completely decoupled contract for Garage, UI, and Level integration.

const VEHICLES: Dictionary = {
	"classic_car": {
		"id": "classic_car",
		"display_name": "Classic Hill Climber",
		"description": "Well-balanced red roadster, ideal for mastering hill climbing and smooth landings.",
		"scene_path": "res://scenes/vehicle/Vehicle.tscn",
		"unlock_cost": 0,
		"mass": 8.0,
		"stat_ratings": {
			"power": 3,
			"grip": 3,
			"suspension": 3,
			"fuel": 3
		}
	},
	"monster_truck": {
		"id": "monster_truck",
		"display_name": "Beast Monster Truck",
		"description": "Heavyweight brute with massive 28px tires and high-clearance suspension.",
		"scene_path": "res://scenes/vehicle/MonsterTruck.tscn",
		"unlock_cost": 250,
		"mass": 12.0,
		"stat_ratings": {
			"power": 5,
			"grip": 4,
			"suspension": 5,
			"fuel": 3
		}
	},
	"dune_buggy": {
		"id": "dune_buggy",
		"display_name": "Electric Dune Buggy",
		"description": "Ultralight tubular roll-cage racer built for agile airtime, rapid tilts, and stunt flips.",
		"scene_path": "res://scenes/vehicle/DuneBuggy.tscn",
		"unlock_cost": 450,
		"mass": 6.0,
		"stat_ratings": {
			"power": 4,
			"grip": 4,
			"suspension": 4,
			"fuel": 4
		}
	}
}

## Returns an array of all vehicle metadata dictionaries
static func get_all_vehicles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in ["classic_car", "monster_truck", "dune_buggy"]:
		if VEHICLES.has(key):
			result.append(VEHICLES[key])
	return result

## Returns vehicle metadata for a given ID, or empty dictionary if invalid
static func get_vehicle(id: String) -> Dictionary:
	return VEHICLES.get(id, {})

## Returns all registered vehicle IDs
static func get_vehicle_ids() -> Array[String]:
	return ["classic_car", "monster_truck", "dune_buggy"]

## Instantiates and returns a VehicleController instance for the specified vehicle ID
static func instantiate_vehicle(id: String) -> VehicleController:
	var entry: Dictionary = get_vehicle(id)
	if entry.is_empty():
		push_error("VehicleRegistry: Unknown vehicle ID '%s'" % id)
		return null
	
	var packed: PackedScene = load(entry["scene_path"]) as PackedScene
	if not packed:
		push_error("VehicleRegistry: Failed to load scene '%s'" % entry["scene_path"])
		return null
		
	return packed.instantiate() as VehicleController

## Calculates coin cost required to upgrade a stat to the next level
static func get_upgrade_cost(current_level: int) -> int:
	match current_level:
		1: return 50
		2: return 120
		3: return 250
		4: return 500
		_: return 0 # Max level reached
