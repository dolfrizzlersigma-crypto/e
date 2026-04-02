## PowerGrid - Manages the electrical breaker system and power zones.
## Handles blackouts, zone-by-zone power control, and generator backup.
class_name PowerGrid
extends Node

# --- Signals ---
signal zone_power_changed(zone_name: String, is_powered: bool)
signal blackout_started()
signal blackout_ended()
signal breaker_tripped(zone_name: String)
signal generator_started()
signal generator_stopped()

# --- Enums ---
enum PowerZone {
	SHOP,
	MOTEL_LOBBY,
	MOTEL_ROOMS,
	FUEL_FORECOURT,
	PARKING_LOT,
	EXTERIOR_SIGNS,
	UTILITY,
	BASEMENT,
}

# --- State ---
var zones: Dictionary = {}  # zone_name -> {powered, breaker_on, priority}
var is_generator_running: bool = false
var generator_fuel: float = 100.0  # Percentage
var total_load: float = 0.0
var max_load: float = 100.0

# --- Configuration ---
const GENERATOR_FUEL_BURN_RATE: float = 2.0  # Percent per minute
const GENERATOR_MAX_ZONES: int = 3  # Generator can only power 3 zones


func _ready() -> void:
	_initialize_zones()


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if is_generator_running:
		generator_fuel -= GENERATOR_FUEL_BURN_RATE * delta / 60.0
		if generator_fuel <= 0.0:
			generator_fuel = 0.0
			stop_generator()

	# Update electrical stability in GameManager
	var powered_count := 0
	for zone_name in zones:
		if zones[zone_name]["powered"]:
			powered_count += 1
	GameManager.electrical_stability = (float(powered_count) / zones.size()) * 100.0


## Initialize all power zones.
func _initialize_zones() -> void:
	zones = {
		"shop": {"powered": true, "breaker_on": true, "priority": 1, "load": 15.0},
		"motel_lobby": {"powered": true, "breaker_on": true, "priority": 2, "load": 10.0},
		"motel_rooms": {"powered": true, "breaker_on": true, "priority": 3, "load": 20.0},
		"fuel_forecourt": {"powered": true, "breaker_on": true, "priority": 1, "load": 15.0},
		"parking_lot": {"powered": true, "breaker_on": true, "priority": 4, "load": 10.0},
		"exterior_signs": {"powered": true, "breaker_on": true, "priority": 5, "load": 5.0},
		"utility": {"powered": true, "breaker_on": true, "priority": 2, "load": 10.0},
		"basement": {"powered": false, "breaker_on": false, "priority": 6, "load": 5.0},
	}
	_recalculate_load()


## Toggle a breaker for a specific zone.
func toggle_breaker(zone_name: String) -> bool:
	if not zones.has(zone_name):
		return false

	var zone: Dictionary = zones[zone_name]
	zone["breaker_on"] = not zone["breaker_on"]

	if zone["breaker_on"]:
		zone["powered"] = true
		zone_power_changed.emit(zone_name, true)
	else:
		zone["powered"] = false
		zone_power_changed.emit(zone_name, false)

	_recalculate_load()
	return zone["breaker_on"]


## Trip a breaker (usually from overload or horror event).
func trip_breaker(zone_name: String) -> void:
	if not zones.has(zone_name):
		return

	zones[zone_name]["breaker_on"] = false
	zones[zone_name]["powered"] = false
	breaker_tripped.emit(zone_name)
	zone_power_changed.emit(zone_name, false)
	_recalculate_load()

	# Increase stress when power goes out
	GameManager.stress += 3.0


## Trigger a full blackout.
func trigger_blackout() -> void:
	for zone_name in zones:
		zones[zone_name]["powered"] = false
		zones[zone_name]["breaker_on"] = false
	blackout_started.emit()
	GameManager.stress += 15.0
	GameManager.composure -= 5.0
	_recalculate_load()


## Restore all power (end of blackout event).
func restore_all_power() -> void:
	for zone_name in zones:
		zones[zone_name]["powered"] = true
		zones[zone_name]["breaker_on"] = true
	blackout_ended.emit()
	_recalculate_load()


## Start the backup generator (if upgraded).
func start_generator() -> bool:
	if not GameManager.has_upgrade("backup_generator"):
		DialogueManager.show_subtitle("Mara", "No backup generator. I need to fix the breakers manually.")
		return false

	if generator_fuel <= 0.0:
		DialogueManager.show_subtitle("Mara", "Generator is out of fuel.")
		return false

	is_generator_running = true
	# Power the highest priority zones
	var powered_count := 0
	var sorted_zones := _get_zones_by_priority()
	for zone_name in sorted_zones:
		if powered_count >= GENERATOR_MAX_ZONES:
			break
		zones[zone_name]["powered"] = true
		zone_power_changed.emit(zone_name, true)
		powered_count += 1

	generator_started.emit()
	return true


## Stop the backup generator.
func stop_generator() -> void:
	is_generator_running = false
	# If main power is still out, these zones go dark again
	for zone_name in zones:
		if not zones[zone_name]["breaker_on"]:
			zones[zone_name]["powered"] = false
			zone_power_changed.emit(zone_name, false)
	generator_stopped.emit()


## Check if a specific zone has power.
func is_zone_powered(zone_name: String) -> bool:
	if not zones.has(zone_name):
		return false
	return zones[zone_name]["powered"]


## Progressive blackout - power fails zone by zone (horror event).
func trigger_progressive_blackout(interval: float = 5.0) -> void:
	var zone_names := zones.keys()
	zone_names.shuffle()
	for i in range(zone_names.size()):
		var zone_name: String = zone_names[i]
		get_tree().create_timer(interval * i).timeout.connect(
			func(): trip_breaker(zone_name)
		)


## Get the breaker panel status for UI.
func get_breaker_status() -> Array[Dictionary]:
	var status: Array[Dictionary] = []
	for zone_name in zones:
		var zone: Dictionary = zones[zone_name]
		status.append({
			"zone": zone_name,
			"powered": zone["powered"],
			"breaker_on": zone["breaker_on"],
			"load": zone["load"],
		})
	return status


# --- Private ---

func _recalculate_load() -> void:
	total_load = 0.0
	for zone_name in zones:
		if zones[zone_name]["powered"]:
			total_load += zones[zone_name]["load"]


func _get_zones_by_priority() -> Array:
	var zone_list := []
	for zone_name in zones:
		zone_list.append({"name": zone_name, "priority": zones[zone_name]["priority"]})
	zone_list.sort_custom(func(a, b): return a["priority"] < b["priority"])
	var result := []
	for entry in zone_list:
		result.append(entry["name"])
	return result
