extends Node
## Power grid management system

# ============================================================================
# POWER ZONES
# ============================================================================

var power_zones: Dictionary = {
	"store": {
		"powered": true,
		"breaker_id": 1,
		"lights": [],
		"equipment": []
	},
	"motel": {
		"powered": true,
		"breaker_id": 2,
		"lights": [],
		"equipment": []
	},
	"exterior": {
		"powered": true,
		"breaker_id": 3,
		"lights": [],
		"equipment": []
	},
	"basement": {
		"powered": true,
		"breaker_id": 4,
		"lights": [],
		"equipment": []
	}
}

# ============================================================================
# STATE
# ============================================================================

var backup_generator_active: bool = false
var total_power_failure: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("PowerGrid initialized")

# ============================================================================
# POWER CONTROL
# ============================================================================

func cut_power_zone(zone_name: String) -> void:
	"""Cut power to a specific zone"""
	if not power_zones.has(zone_name):
		return

	var zone = power_zones[zone_name]
	if not zone["powered"]:
		return

	zone["powered"] = false

	# Turn off all lights in zone
	for light in zone["lights"]:
		if is_instance_valid(light):
			light.visible = false

	EventBus.power_zone_failed.emit(zone_name)
	AudioManager.play_sfx("power_out")

func restore_power_zone(zone_name: String) -> void:
	"""Restore power to a specific zone"""
	if not power_zones.has(zone_name):
		return

	var zone = power_zones[zone_name]
	if zone["powered"]:
		return

	zone["powered"] = true

	# Turn on all lights in zone
	for light in zone["lights"]:
		if is_instance_valid(light):
			light.visible = true

	EventBus.power_zone_restored.emit(zone_name)
	AudioManager.play_sfx("power_on")

func toggle_breaker(breaker_id: int) -> bool:
	"""Toggle a circuit breaker"""
	for zone_name in power_zones:
		var zone = power_zones[zone_name]
		if zone["breaker_id"] == breaker_id:
			if zone["powered"]:
				cut_power_zone(zone_name)
			else:
				restore_power_zone(zone_name)
			return true
	return false

# ============================================================================
# TOTAL POWER FAILURE
# ============================================================================

func trigger_blackout() -> void:
	"""Cut power to all zones"""
	total_power_failure = true

	for zone_name in power_zones:
		cut_power_zone(zone_name)

	AudioManager.play_sfx("total_blackout")

func activate_backup_generator() -> bool:
	"""Activate backup generator"""
	if backup_generator_active:
		return false

	backup_generator_active = true

	# Restore critical zones
	restore_power_zone("store")

	AudioManager.play_sfx("generator_start")
	return true

# ============================================================================
# ZONE REGISTRATION
# ============================================================================

func register_light(zone_name: String, light: Light3D) -> void:
	"""Register a light to a power zone"""
	if power_zones.has(zone_name):
		power_zones[zone_name]["lights"].append(light)

func register_equipment(zone_name: String, equipment: Node) -> void:
	"""Register equipment to a power zone"""
	if power_zones.has(zone_name):
		power_zones[zone_name]["equipment"].append(equipment)

# ============================================================================
# HORROR EVENTS
# ============================================================================

func cascade_power_failure() -> void:
	"""Power fails one zone at a time (horror event)"""
	var zones = power_zones.keys()

	for zone_name in zones:
		cut_power_zone(zone_name)
		await get_tree().create_timer(5.0).timeout

func flicker_lights_zone(zone_name: String, duration: float = 5.0) -> void:
	"""Flicker lights in a zone"""
	if not power_zones.has(zone_name):
		return

	var zone = power_zones[zone_name]
	var end_time = Time.get_ticks_msec() / 1000.0 + duration

	while Time.get_ticks_msec() / 1000.0 < end_time:
		for light in zone["lights"]:
			if is_instance_valid(light):
				light.visible = !light.visible

		await get_tree().create_timer(0.1).timeout

	# Ensure lights are on at end
	for light in zone["lights"]:
		if is_instance_valid(light) and zone["powered"]:
			light.visible = true
