## UpgradeManager - Manages facility upgrades and their gameplay effects.
## Tracks available, purchased, and active upgrades.
extends Node

# --- Signals ---
signal upgrade_purchased(upgrade_id: String)
signal upgrade_effect_applied(upgrade_id: String)

# --- Upgrade Registry ---
var _upgrade_definitions: Dictionary = {}
var _purchased: Array[String] = []


func _ready() -> void:
	_register_all_upgrades()


## Check if an upgrade is purchased.
func is_purchased(upgrade_id: String) -> bool:
	return upgrade_id in _purchased


## Get the definition of an upgrade.
func get_upgrade(upgrade_id: String) -> Dictionary:
	return _upgrade_definitions.get(upgrade_id, {})


## Get all available upgrades (not yet purchased).
func get_available_upgrades() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for id in _upgrade_definitions:
		if id not in _purchased:
			var upgrade := _upgrade_definitions[id].duplicate()
			upgrade["id"] = id
			var prereqs: Array = upgrade.get("prerequisites", [])
			var can_buy := true
			for prereq in prereqs:
				if prereq not in _purchased:
					can_buy = false
					break
			upgrade["can_purchase"] = can_buy
			available.append(upgrade)
	return available


## Purchase an upgrade.
func purchase(upgrade_id: String) -> bool:
	if upgrade_id in _purchased:
		return false
	var upgrade := _upgrade_definitions.get(upgrade_id, {})
	if upgrade.is_empty():
		return false

	var cost: float = upgrade.get("cost", 0.0)
	if GameManager.cash < cost:
		return false

	var prereqs: Array = upgrade.get("prerequisites", [])
	for prereq in prereqs:
		if prereq not in _purchased:
			return false

	GameManager.cash -= cost
	_purchased.append(upgrade_id)
	GameManager.purchased_upgrades = _purchased.duplicate()
	upgrade_purchased.emit(upgrade_id)
	_apply_upgrade_effect(upgrade_id)
	return true


## Get save data.
func get_save_data() -> Dictionary:
	return {"purchased": _purchased}


## Load save data.
func load_save_data(data: Dictionary) -> void:
	_purchased.assign(data.get("purchased", []))
	for id in _purchased:
		_apply_upgrade_effect(id)


# --- Private ---

func _apply_upgrade_effect(upgrade_id: String) -> void:
	var upgrade := _upgrade_definitions.get(upgrade_id, {})
	if upgrade.has("facility_bonus"):
		GameManager.facility_condition += upgrade["facility_bonus"]
	if upgrade.has("security_bonus"):
		GameManager.security_level += upgrade["security_bonus"]
	if upgrade.has("electrical_bonus"):
		GameManager.electrical_stability += upgrade["electrical_bonus"]
	upgrade_effect_applied.emit(upgrade_id)


func _register_all_upgrades() -> void:
	_upgrade_definitions = {
		# --- Security ---
		"better_cameras": {
			"name": "Upgraded CCTV Cameras",
			"description": "Higher resolution cameras with night vision. Reveals more detail on the security monitor.",
			"cost": 150.0,
			"category": "security",
			"facility_bonus": 2.0,
			"security_bonus": 10.0,
			"prerequisites": [],
		},
		"motion_sensors": {
			"name": "Motion Sensors",
			"description": "Detects movement in blind spots. Triggers alerts on the security panel.",
			"cost": 200.0,
			"category": "security",
			"security_bonus": 15.0,
			"prerequisites": ["better_cameras"],
		},
		"panic_shutters": {
			"name": "Panic Shutter System",
			"description": "Emergency steel shutters for the shop windows. Activated from behind the counter.",
			"cost": 350.0,
			"category": "security",
			"security_bonus": 20.0,
			"prerequisites": ["motion_sensors"],
		},

		# --- Power ---
		"backup_generator": {
			"name": "Backup Generator",
			"description": "Keeps critical systems running during blackouts. Requires fuel.",
			"cost": 300.0,
			"category": "power",
			"electrical_bonus": 20.0,
			"prerequisites": [],
		},
		"improved_floodlights": {
			"name": "Improved Floodlights",
			"description": "Brighter exterior lighting. Reduces shadow areas in the parking lot.",
			"cost": 120.0,
			"category": "power",
			"security_bonus": 5.0,
			"facility_bonus": 3.0,
			"prerequisites": [],
		},

		# --- Motel ---
		"stronger_locks": {
			"name": "Reinforced Room Locks",
			"description": "Heavier deadbolts for all motel rooms. Guests feel safer.",
			"cost": 180.0,
			"category": "motel",
			"security_bonus": 8.0,
			"prerequisites": [],
		},
		"laundry_repair": {
			"name": "Laundry Machine Repair",
			"description": "Fix the broken washing machines. Reduces room turnover time.",
			"cost": 100.0,
			"category": "motel",
			"facility_bonus": 5.0,
			"prerequisites": [],
		},
		"storm_windows": {
			"name": "Storm Windows",
			"description": "Impact-resistant windows for motel rooms. Protects during severe weather.",
			"cost": 200.0,
			"category": "motel",
			"facility_bonus": 5.0,
			"prerequisites": [],
		},

		# --- Shop ---
		"shelf_labels": {
			"name": "Shelf Labels",
			"description": "Organized shelf labels make restocking faster and customers happier.",
			"cost": 40.0,
			"category": "shop",
			"facility_bonus": 3.0,
			"prerequisites": [],
		},
		"coffee_machine_upgrade": {
			"name": "Fast Coffee Machine",
			"description": "Upgraded coffee maker brews twice as fast.",
			"cost": 80.0,
			"category": "shop",
			"facility_bonus": 2.0,
			"prerequisites": [],
		},
		"receipt_printer": {
			"name": "Fast Receipt Printer",
			"description": "Thermal printer that processes transactions faster.",
			"cost": 60.0,
			"category": "shop",
			"facility_bonus": 1.0,
			"prerequisites": [],
		},
		"extra_storage": {
			"name": "Extra Storage Shelving",
			"description": "More stockroom capacity. Hold more items between deliveries.",
			"cost": 90.0,
			"category": "shop",
			"facility_bonus": 3.0,
			"prerequisites": [],
		},

		# --- Fuel ---
		"pump_diagnostics": {
			"name": "Pump Diagnostic System",
			"description": "Digital readouts on fuel pumps. Detect malfunctions before customers complain.",
			"cost": 160.0,
			"category": "fuel",
			"facility_bonus": 4.0,
			"prerequisites": [],
		},

		# --- Maintenance ---
		"bathroom_auto_clean": {
			"name": "Auto-Clean Bathroom Fixtures",
			"description": "Self-cleaning toilets and sinks. Reduces bathroom maintenance time.",
			"cost": 250.0,
			"category": "maintenance",
			"facility_bonus": 8.0,
			"prerequisites": [],
		},
		"radio_booster": {
			"name": "Radio Signal Booster",
			"description": "Stronger CB radio reception. Hear transmissions more clearly... for better or worse.",
			"cost": 100.0,
			"category": "communications",
			"prerequisites": [],
		},

		# --- Story ---
		"hidden_archive": {
			"name": "Hidden Archive Access",
			"description": "Unlocks the sealed records room in the basement. What did the previous owners hide?",
			"cost": 500.0,
			"category": "story",
			"prerequisites": ["better_cameras", "backup_generator"],
		},
	}
