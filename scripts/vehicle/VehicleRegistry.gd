class_name VehicleRegistry
extends RefCounted

## VehicleRegistry: Central catalog of vehicles, stat profiles, and upgrade configs.
## Serves as a completely decoupled contract for Garage, UI, and Level integration.

const ORDERED_IDS: Array[String] = [
	"blue_flame_truck",
	"orc_racer",
	"trophy_truck",
	"dune_buggy"
]

const VEHICLES: Dictionary = {
	"blue_flame_truck": {
		"id": "blue_flame_truck",
		"display_name": "Blue Flame Truck",
		"description": "Heavy off-road powerhouse with custom flame side panels, chrome rims, and roaring engine torque.",
		"scene_path": "res://scenes/vehicle/BlueFlameTruck.tscn",
		"preview_path": "res://assets/vehicles/blue_flame_truck/vehicle_assembled_preview.png",
		"unlock_cost": 0,
		"mass": 10.0,
		"stat_ratings": {
			"power": 5,
			"grip": 4,
			"suspension": 4,
			"fuel": 4
		}
	},
	"orc_racer": {
		"id": "orc_racer",
		"display_name": "Orc Racer",
		"description": "Aggressive, high-revving wasteland buggy built for rapid sprints and wild air stunt flips.",
		"scene_path": "res://scenes/vehicle/OrcRacer.tscn",
		"preview_path": "res://assets/vehicles/orc_racer/body.png",
		"unlock_cost": 350,
		"mass": 7.5,
		"stat_ratings": {
			"power": 4,
			"grip": 4,
			"suspension": 4,
			"fuel": 3
		}
	},
	"trophy_truck": {
		"id": "trophy_truck",
		"display_name": "Trophy Truck",
		"description": "Desert baja racing machine with extended suspension travel and superior rugged endurance.",
		"scene_path": "res://scenes/vehicle/TrophyTruck.tscn",
		"preview_path": "res://assets/vehicles/trophy_truck/assembled.png",
		"unlock_cost": 500,
		"mass": 9.0,
		"stat_ratings": {
			"power": 4,
			"grip": 4,
			"suspension": 5,
			"fuel": 4
		}
	},
	"dune_buggy": {
		"id": "dune_buggy",
		"display_name": "Electric Dune Buggy",
		"description": "Ultralight tubular roll-cage racer built for agile airtime, rapid tilts, and stunt flips.",
		"scene_path": "res://scenes/vehicle/DuneBuggy.tscn",
		"preview_path": "res://assets/vehicles/alternate/girl_buggy/body.png",
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
	for key in ORDERED_IDS:
		if VEHICLES.has(key):
			result.append(VEHICLES[key])
	return result

## Returns vehicle metadata for a given ID, or empty dictionary if invalid
static func get_vehicle(id: String) -> Dictionary:
	return VEHICLES.get(id, {})

## Returns all registered vehicle IDs
static func get_vehicle_ids() -> Array[String]:
	return ORDERED_IDS.duplicate()

## Returns true if the vehicle ID is recognized
static func has_vehicle(id: String) -> bool:
	return VEHICLES.has(id)

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
