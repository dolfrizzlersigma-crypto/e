extends Node
## Event Director - schedules and triggers horror events

# ============================================================================
# CONFIGURATION
# ============================================================================

const MIN_EVENT_INTERVAL: float = 180.0 # 3 minutes
const MAX_EVENT_INTERVAL: float = 420.0 # 7 minutes
const HORROR_INTENSITY_BASE: float = 0.2
const HORROR_INTENSITY_PER_CHAPTER: float = 0.15

# ============================================================================
# STATE
# ============================================================================

var event_library: Array = []
var active_events: Array = []
var event_cooldowns: Dictionary = {}
var horror_intensity: float = 0.2
var time_since_last_event: float = 0.0
var next_event_time: float = 300.0

# ============================================================================
# REFERENCES
# ============================================================================

@onready var player = get_node_or_null("/root/MainGame/Player")
@onready var world = get_node_or_null("/root/MainGame")
@onready var shift_manager = get_node_or_null("/root/MainGame/Systems/ShiftManager")
@onready var cctv_monitor = get_node_or_null("/root/MainGame/Plaza/SecurityOffice/CCTVMonitor")
@onready var breaker_panel = get_node_or_null("/root/MainGame/Plaza/BackArea/BreakerPanel")
@onready var motel_booking = get_node_or_null("/root/MainGame/Plaza/MotelOffice/MotelBooking")
@onready var customer_spawner = get_node_or_null("/root/MainGame/Systems/CustomerSpawner")

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_load_event_library()
	_calculate_horror_intensity()
	next_event_time = randf_range(MIN_EVENT_INTERVAL, MAX_EVENT_INTERVAL)

func _load_event_library() -> void:
	"""Load all available horror events"""
	event_library = [
		{"id": "phantom_customer", "intensity": 2, "category": "entity", "cooldown": 600.0},
		{"id": "lights_flicker", "intensity": 1, "category": "environmental", "cooldown": 300.0},
		{"id": "phone_call", "intensity": 2, "category": "audio", "cooldown": 900.0},
		{"id": "room_4_knocking", "intensity": 3, "category": "room_4", "cooldown": 1200.0},
		{"id": "shadow_figure", "intensity": 3, "category": "entity", "cooldown": 900.0},
		{"id": "time_loop", "intensity": 4, "category": "reality", "cooldown": 1800.0},
		{"id": "possessed_customer", "intensity": 3, "category": "customer", "cooldown": 1200.0},
		{"id": "power_surge", "intensity": 2, "category": "power", "cooldown": 600.0},
		{"id": "doppelganger", "intensity": 4, "category": "customer", "cooldown": 1800.0},
		{"id": "footage_playback", "intensity": 3, "category": "cctv", "cooldown": 900.0}
	]

# ============================================================================
# PROCESS
# ============================================================================

func _process(delta: float) -> void:
	time_since_last_event += delta

	_update_cooldowns(delta)

	if time_since_last_event >= next_event_time:
		trigger_random_event()

func _update_cooldowns(delta: float) -> void:
	"""Update event cooldowns"""
	for event_id in event_cooldowns.keys():
		event_cooldowns[event_id] -= delta
		if event_cooldowns[event_id] <= 0:
			event_cooldowns.erase(event_id)

# ============================================================================
# EVENT TRIGGERING
# ============================================================================

func trigger_random_event() -> void:
	"""Trigger a random horror event"""
	var eligible_events = _get_eligible_events()

	if eligible_events.is_empty():
		return

	# Weight events by intensity
	var selected_event = _select_weighted_event(eligible_events)

	if selected_event:
		trigger_event(selected_event["id"])

func trigger_event(event_id: String) -> void:
	"""Trigger a specific event by ID"""
	var event = _get_event_by_id(event_id)
	if not event:
		return

	print("Triggering horror event: %s" % event_id)

	# Add cooldown
	event_cooldowns[event_id] = event.get("cooldown", 600.0)

	# Execute event
	_execute_event(event)

	# Update timing
	time_since_last_event = 0.0
	next_event_time = randf_range(MIN_EVENT_INTERVAL, MAX_EVENT_INTERVAL)

	# Emit signal
	EventBus.horror_event_triggered.emit(event_id, event.get("intensity", 1))

# ============================================================================
# EVENT EXECUTION
# ============================================================================

func _execute_event(event: Dictionary) -> void:
	"""Execute an event using HorrorEvents implementations"""
	var event_id = event["id"]
	var context = _build_event_context()

	# Call appropriate horror event
	match event_id:
		"phantom_customer":
			HorrorEvents.event_phantom_customer(context)
		"lights_flicker":
			HorrorEvents.event_lights_flicker(context)
		"phone_call":
			HorrorEvents.event_phone_call(context)
		"room_4_knocking":
			HorrorEvents.event_room_4_knocking(context)
		"shadow_figure":
			HorrorEvents.event_shadow_figure(context)
		"time_loop":
			HorrorEvents.event_time_loop(context)
		"possessed_customer":
			HorrorEvents.event_possessed_customer(context)
		"power_surge":
			HorrorEvents.event_power_surge(context)
		"doppelganger":
			HorrorEvents.event_doppelganger(context)
		"footage_playback":
			HorrorEvents.event_footage_playback(context)

func _build_event_context() -> Dictionary:
	"""Build context dictionary for events"""
	return {
		"player": player,
		"world": world,
		"tree": get_tree(),
		"shift_manager": shift_manager,
		"cctv_monitor": cctv_monitor,
		"breaker_panel": breaker_panel,
		"motel_booking": motel_booking,
		"customer_spawner": customer_spawner,
		"register": get_node_or_null("/root/MainGame/Plaza/ConvenienceStore/CashRegister"),
		"room_4_door": get_node_or_null("/root/MainGame/Plaza/Motel/Room4Door"),
		"spawn_point": Vector3(5, 0, -8),
		"shadow_spawns": [Vector3(10, 0, -5), Vector3(-8, 0, 12), Vector3(0, 0, -15)],
		"active_customers": customer_spawner.active_customers if customer_spawner else []
	}
			_execute_power_event(event)
		"room":
			_execute_room_event(event)

	# Play audio cues
	for audio_cue in event.get("audio_cues", []):
		AudioManager.play_sfx(audio_cue)

	# Apply stat changes
	if event.has("composure_impact"):
		# Would affect player composure
		pass

func _execute_environmental_event(event: Dictionary) -> void:
	"""Execute environmental distortion event"""
	match event.get("id", ""):
		"lights_flicker_morse":
			_flicker_lights_pattern()
		"coffee_machine_start":
			_activate_coffee_machine()
		"doors_slam":
			_slam_random_doors()
		"temperature_drop":
			_trigger_temperature_change()
		_:
			print("Environmental event: %s" % event.get("description", ""))

func _execute_customer_event(event: Dictionary) -> void:
	"""Execute customer anomaly event"""
	# Spawn anomalous customer or modify existing customer
	print("Customer event: %s" % event.get("description", ""))

func _execute_cctv_event(event: Dictionary) -> void:
	"""Execute CCTV contradiction event"""
	EventBus.cctv_anomaly.emit(randi() % 16, event.get("description", ""))

func _execute_radio_event(event: Dictionary) -> void:
	"""Execute radio/phone horror event"""
	EventBus.radio_interference.emit(event.get("message", ""))

func _execute_power_event(event: Dictionary) -> void:
	"""Execute power grid event"""
	var zones = ["store", "motel", "exterior", "basement"]
	var random_zone = zones[randi() % zones.size()]
	EventBus.power_zone_failed.emit(random_zone)

func _execute_room_event(event: Dictionary) -> void:
	"""Execute room impossibility event"""
	print("Room event: %s" % event.get("description", ""))

# ============================================================================
# EVENT LIBRARY
# ============================================================================

func _load_event_library() -> void:
	"""Load all horror events into library"""
	event_library = [
		# Environmental (Low Intensity)
		{
			"id": "lights_flicker_morse",
			"category": "environmental",
			"intensity": 1,
			"description": "Lights flicker in Morse code pattern",
			"cooldown": 300.0,
			"min_chapter": 1,
			"audio_cues": ["lights_flicker"]
		},
		{
			"id": "coffee_machine_start",
			"category": "environmental",
			"intensity": 1,
			"description": "Coffee machine starts brewing on its own",
			"cooldown": 400.0,
			"min_chapter": 1,
			"audio_cues": ["coffee_brew"]
		},
		{
			"id": "doors_slam",
			"category": "environmental",
			"intensity": 2,
			"description": "Doors slam when no wind present",
			"cooldown": 500.0,
			"min_chapter": 2,
			"audio_cues": ["door_slam"]
		},
		# Customer Anomalies (Medium Intensity)
		{
			"id": "customer_wrong_reflection",
			"category": "customer",
			"intensity": 3,
			"description": "Customer's reflection doesn't match appearance",
			"cooldown": 600.0,
			"min_chapter": 2
		},
		{
			"id": "customer_mile_87",
			"category": "customer",
			"intensity": 3,
			"description": "Customer asks for directions to Mile 87",
			"cooldown": 800.0,
			"min_chapter": 2
		},
		# CCTV (Medium Intensity)
		{
			"id": "cctv_player_duplicate",
			"category": "cctv",
			"intensity": 3,
			"description": "CCTV shows player at register when elsewhere",
			"cooldown": 600.0,
			"min_chapter": 2
		},
		{
			"id": "cctv_phantom_car",
			"category": "cctv",
			"intensity": 2,
			"description": "Camera shows car at pump but none outside",
			"cooldown": 500.0,
			"min_chapter": 2
		},
		# Radio (Medium Intensity)
		{
			"id": "radio_predicts_customer",
			"category": "radio",
			"intensity": 3,
			"description": "Radio predicts customer 5 minutes early",
			"cooldown": 700.0,
			"min_chapter": 2,
			"message": "Customer arriving at pump 3..."
		},
		# Power (High Intensity)
		{
			"id": "power_cascade_failure",
			"category": "power",
			"intensity": 4,
			"description": "Power fails one zone at a time",
			"cooldown": 900.0,
			"min_chapter": 3,
			"audio_cues": ["power_out"]
		},
		# Room (High Intensity)
		{
			"id": "room_4_request",
			"category": "room",
			"intensity": 4,
			"description": "Guest checks into boarded Room 4",
			"cooldown": 1200.0,
			"min_chapter": 2
		}
	]

func _get_event_by_id(event_id: String) -> Dictionary:
	"""Get event by ID"""
	for event in event_library:
		if event["id"] == event_id:
			return event
	return {}

func _get_eligible_events() -> Array:
	"""Get events that can currently trigger"""
	var eligible = []

	for event in event_library:
		# Check chapter requirement
		if event.get("min_chapter", 1) > GameManager.current_chapter:
			continue

		# Check cooldown
		if event_cooldowns.has(event["id"]) and event_cooldowns[event["id"]] > 0:
			continue

		# Check intensity vs horror level
		if event.get("intensity", 1) > horror_intensity * 5:
			continue

		eligible.append(event)

	return eligible

func _select_weighted_event(events: Array) -> Dictionary:
	"""Select event with intensity-based weighting"""
	if events.is_empty():
		return {}

	# Weight lower intensity events higher
	var total_weight = 0.0
	var weights = []

	for event in events:
		var intensity = event.get("intensity", 1)
		var weight = 6.0 - intensity # Inverse weighting
		weights.append(weight)
		total_weight += weight

	var roll = randf() * total_weight
	var cumulative = 0.0

	for i in range(events.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return events[i]

	return events[0]

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _flicker_lights_pattern() -> void:
	"""Flicker lights in a pattern"""
	# Would control lighting system
	pass

func _activate_coffee_machine() -> void:
	"""Turn on coffee machine"""
	# Would activate coffee machine
	pass

func _slam_random_doors() -> void:
	"""Slam a random door"""
	# Would trigger door animation
	pass

func _trigger_temperature_change() -> void:
	"""Change ambient temperature"""
	# Would modify environment effects
	pass

# ============================================================================
# INTENSITY MANAGEMENT
# ============================================================================

func _calculate_horror_intensity() -> void:
	"""Calculate horror intensity based on chapter"""
	horror_intensity = HORROR_INTENSITY_BASE + (GameManager.current_chapter - 1) * HORROR_INTENSITY_PER_CHAPTER
	horror_intensity = clamp(horror_intensity, 0.0, 1.0)
	AudioManager.adjust_horror_mix(horror_intensity)

func _update_cooldowns(delta: float) -> void:
	"""Update event cooldowns"""
	for event_id in event_cooldowns.keys():
		event_cooldowns[event_id] -= delta
		if event_cooldowns[event_id] <= 0:
			event_cooldowns.erase(event_id)

func set_horror_intensity(intensity: float) -> void:
	"""Manually set horror intensity"""
	horror_intensity = clamp(intensity, 0.0, 1.0)
	AudioManager.adjust_horror_mix(horror_intensity)

func _get_event_by_id(event_id: String) -> Dictionary:
	"""Get event by ID"""
	for event in event_library:
		if event["id"] == event_id:
			return event
	return {}

func _get_eligible_events() -> Array:
	"""Get events that can currently trigger"""
	var eligible = []

	for event in event_library:
		# Check chapter requirement
		if event.get("min_chapter", 1) > GameManager.current_chapter:
			continue

		# Check cooldown
		if event_cooldowns.has(event["id"]) and event_cooldowns[event["id"]] > 0:
			continue

		# Check intensity vs horror level
		if event.get("intensity", 1) > horror_intensity * 5:
			continue

		eligible.append(event)

	return eligible

func _select_weighted_event(events: Array) -> Dictionary:
	"""Select event with intensity-based weighting"""
	if events.is_empty():
		return {}

	# Weight lower intensity events higher
	var total_weight = 0.0
	var weights = []

	for event in events:
		var intensity = event.get("intensity", 1)
		var weight = 6.0 - intensity # Inverse weighting
		weights.append(weight)
		total_weight += weight

	var roll = randf() * total_weight
	var cumulative = 0.0

	for i in range(events.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return events[i]

	return events[0]
